CREATE OR ALTER  VIEW ${os_bi_coredw}.teacher_test_dm_view AS
WITH cte_teachers AS (
    SELECT DISTINCT
        dt.teacher_dw_id,
        dt.teacher_id,
        dc.class_dw_id
    FROM ${rs_coredw}.dim_class dc
    JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    LEFT JOIN ${rs_coredw}.dim_teacher dt
        ON dcu.class_user_user_dw_id = dt.teacher_dw_id
       AND dt.teacher_status = 1
       AND NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = dt.teacher_id)  -- OPT-8
    WHERE dc.class_status = 1
      AND dcu.class_user_role_dw_id = 1
      AND dc.class_course_status = 'ACTIVE'
      AND dcu.class_user_status = 1
      AND dcu.class_user_attach_status = 1
),

tt_lq_assigned AS (
    SELECT DISTINCT
        dtt.tt_dw_id,
        dtt.tt_test_id,
        dttbla.ttbla_dw_id,
        dttbla.ttbla_test_blueprint_id,
        COUNT(DISTINCT dttbla.ttbla_lesson_id)  AS lessons_assigned,
        COUNT(DISTINCT dttia.ttia_test_item_id) AS questions_assigned
    FROM ${rs_coredw}.dim_teacher_test_blueprint_lesson_association AS dttbla
    JOIN ${rs_coredw}.dim_learning_objective lo
        ON lo.lo_id = dttbla.ttbla_lesson_id
       AND lo.lo_status = 1
    JOIN ${rs_coredw}.dim_teacher_test dtt
        ON dtt.tt_test_blueprint_id = dttbla.ttbla_test_blueprint_id
    JOIN ${rs_coredw}.dim_teacher_test_item_association dttia
        ON dttia.ttia_test_id = dtt.tt_test_id
       AND dttbla.ttbla_status = 1
       AND dttia.ttia_status = 1
    GROUP BY
        dtt.tt_dw_id,
        dtt.tt_test_id,
        dttbla.ttbla_dw_id,
        dttbla.ttbla_test_blueprint_id
),

tt_assigned_students AS (
    SELECT DISTINCT
        ttca.ttca_test_id,
        ttca.ttca_dw_id,
        ttca.ttca_test_delivery_id,
        ttca.ttca_test_candidate_id
    FROM ${rs_coredw}.dim_teacher_test_candidate_association AS ttca
    JOIN ${rs_bi_coredw}.bi_student_dim ds
         ON ds.student_id = ttca.ttca_test_candidate_id
    WHERE ttca.ttca_status = 1
      AND ds.student_status = 1
),

dim_teacher_test AS (
    ----------------------------------------------------------------------
    -- PUBLISHED tests
    ----------------------------------------------------------------------
    SELECT DISTINCT
        tt.tt_dw_id,
        tt.tt_test_id,
        tt.tt_test_class_id          AS class_id,
        tt.tt_test_created_by_id     AS teacher_id,
        tt.tt_test_title,
        tt.tt_test_blueprint_id,
        tt.tt_test_status,
        CONVERT(
            DATE,
            tt.tt_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS tt_created_date,
        CONVERT(
            DATETIME2,
            tt.tt_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS created_time,
        CONVERT(
            DATE,
            tt.tt_updated_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS published_date,
        CONVERT(
            DATETIME2,
            tt.tt_updated_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS published_time,
        tas.ttca_test_candidate_id AS tt_assigned_student_id,
        CONVERT(
            DATETIME2,
            ds.ttds_test_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS ttds_test_start_time,
        CONVERT(
            DATETIME2,
            ds.ttds_test_end_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS ttds_test_end_time,
        CASE
            WHEN CONVERT(DATE, tt.tt_created_time) = CONVERT(DATE, ds.ttds_test_start_time)
                THEN 'today'
            WHEN CONVERT(DATE, tt.tt_created_time) < CONVERT(DATE, ds.ttds_test_start_time)
                THEN 'future_date'
            ELSE 'other'
        END AS tt_start_date_flag,
        lqa.lessons_assigned,
        lqa.questions_assigned,
        ds.ttds_dw_id,
        ds.ttds_test_delivery_id
    FROM ${rs_coredw}.dim_teacher_test tt
    JOIN ${rs_coredw}.dim_class dc
        ON dc.class_id = tt.tt_test_class_id
       AND tt.tt_status = 1
    JOIN ${rs_bi_coredw}.bi_active_schools_dim sc
        ON dc.class_school_id = sc.school_id
       AND tt.tt_created_time >= CONVERT(DATETIME2, sc.academic_year_start_date)  -- OPT-15: SARGable rewrite
       AND tt.tt_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, sc.academic_year_end_date))  -- OPT-15: SARGable rewrite

    JOIN ${rs_coredw}.dim_teacher_test_delivery_settings ds
        ON ds.ttds_test_id = tt.tt_test_id
       AND ds.ttds_status = 1
    JOIN tt_lq_assigned lqa
        ON lqa.tt_test_id = tt.tt_test_id
    JOIN tt_assigned_students tas
        ON tas.ttca_test_delivery_id = ds.ttds_test_delivery_id
    WHERE tt.tt_status = 1
      AND tt.tt_test_status = 'PUBLISHED'

    UNION ALL

    ----------------------------------------------------------------------
    -- DRAFT / VALID tests (may not have delivery yet)
    ----------------------------------------------------------------------
    SELECT DISTINCT
        tt.tt_dw_id,
        tt.tt_test_id,
        tt.tt_test_class_id          AS class_id,
        tt.tt_test_created_by_id     AS teacher_id,
        tt.tt_test_title,
        tt.tt_test_blueprint_id,
        tt.tt_test_status,
        CONVERT(
            DATE,
            tt.tt_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS tt_created_date,
        CONVERT(
            DATETIME2,
            tt.tt_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS created_time,
        CONVERT(
            DATE,
            tt.tt_updated_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS published_date,
        CONVERT(
            DATETIME2,
            tt.tt_updated_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS published_time,
        tas.ttca_test_candidate_id AS tt_assigned_student_id,
        CONVERT(
            DATETIME2,
            ds.ttds_test_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS ttds_test_start_time,
        CONVERT(
            DATETIME2,
            ds.ttds_test_end_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
        ) AS ttds_test_end_time,
        CASE
            WHEN CONVERT(DATE, tt.tt_created_time) = CONVERT(DATE, ds.ttds_test_start_time)
                THEN 'today'
            WHEN CONVERT(DATE, tt.tt_created_time) < CONVERT(DATE, ds.ttds_test_start_time)
                THEN 'future_date'
            ELSE 'other'
        END AS tt_start_date_flag,
        lqa.lessons_assigned,
        lqa.questions_assigned,
        ds.ttds_dw_id,
        ds.ttds_test_delivery_id
    FROM ${rs_coredw}.dim_teacher_test tt
    JOIN ${rs_coredw}.dim_class dc
        ON dc.class_id = tt.tt_test_class_id
       AND tt.tt_status = 1
    JOIN ${rs_bi_coredw}.bi_active_schools_dim sc
        ON dc.class_school_id = sc.school_id
       AND tt.tt_created_time >= CONVERT(DATETIME2, sc.academic_year_start_date)  -- OPT-15: SARGable rewrite
       AND tt.tt_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, sc.academic_year_end_date))  -- OPT-15: SARGable rewrite

    LEFT JOIN ${rs_coredw}.dim_teacher_test_delivery_settings ds
        ON ds.ttds_test_id = tt.tt_test_id
       AND ds.ttds_status = 1
    LEFT JOIN tt_lq_assigned lqa
        ON lqa.tt_test_id = tt.tt_test_id
    LEFT JOIN tt_assigned_students tas
        ON tas.ttca_test_delivery_id = ds.ttds_test_delivery_id
    WHERE tt.tt_status = 1
      AND (
            tt.tt_test_status = 'DRAFT'
         OR tt.tt_test_status = 'VALID'
      )
)

SELECT DISTINCT
    ct.teacher_dw_id,
    sc.school_name,
    sc.school_dw_id,
    sc.school_organisation,
    sc.tenant_name,
    dg.grade_k12grade,
    dg.grade_name,
    sc.academic_year_type,
    sc.academic_year_start_date,
    sc.academic_year_end_date,
    UPPER(dc.class_gen_subject) as class_gen_subject,
    UPPER(dc.class_title) as class_title,
    dc.class_dw_id,
    dcr.course_type,
    tt.tt_dw_id,
    tt.tt_test_id,
    tt.class_id,
    tt.teacher_id,
    tt.tt_test_title,
    tt.tt_test_blueprint_id,
    tt.tt_test_status,
    tt.tt_created_date,
    tt.created_time,
    tt.published_date,
    tt.published_time,
    tt.tt_assigned_student_id,
    tt.ttds_test_start_time,
    tt.ttds_test_end_time,
    tt.tt_start_date_flag,
    tt.lessons_assigned,
    tt.questions_assigned,
    tt.ttds_dw_id,
    tt.ttds_test_delivery_id,

    CONVERT(
        DATETIME2,
        FIRST_VALUE(fttcp.fttcp_created_time) OVER (
            PARTITION BY fttcp.fttcp_candidate_dw_id, tt.tt_dw_id
            ORDER BY
                fttcp.fttcp_created_time ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )
        AT TIME ZONE 'UTC'
        AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
    ) AS student_test_start_time,

    CONVERT(
        DATETIME2,
        LAST_VALUE(
            CASE
                WHEN fttcp.fttcp_status = 'RECORDER_COMPLETED'
                    THEN fttcp.fttcp_created_time
                ELSE NULL
            END
        ) OVER (
            PARTITION BY fttcp.fttcp_candidate_dw_id, tt.tt_dw_id
            ORDER BY
                fttcp.fttcp_created_time ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )
        AT TIME ZONE 'UTC'
        AT TIME ZONE ISNULL(sc.windows_timezone, 'UTC')
    ) AS student_test_end_time,

    fttcp.fttcp_candidate_dw_id,

    CONVERT(
    FLOAT(53),
    DATEDIFF(
        SECOND,
        FIRST_VALUE(fttcp.fttcp_created_at) OVER (
            PARTITION BY
                fttcp.fttcp_test_delivery_dw_id,
                fttcp.fttcp_candidate_dw_id
            ORDER BY
                CASE
                    WHEN fttcp.fttcp_created_at IS NULL THEN 1
                    ELSE 0
                END,
                fttcp.fttcp_created_at ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ),
        LAST_VALUE(fttcp.fttcp_updated_at) OVER (
            PARTITION BY
                fttcp.fttcp_test_delivery_dw_id,
                fttcp.fttcp_candidate_dw_id
            ORDER BY
                CASE
                    WHEN fttcp.fttcp_updated_at IS NULL THEN 0
                    ELSE 1
                END,
                fttcp.fttcp_updated_at DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )
    )
    ) / 60.0 AS stud_time_spent_in_mins,

    FIRST_VALUE(fttcp.fttcp_stars_awarded) OVER (
        PARTITION BY fttcp.fttcp_candidate_dw_id, fttcp.fttcp_test_delivery_dw_id
        ORDER BY
            CASE WHEN fttcp.fttcp_updated_at IS NULL THEN 1 ELSE 0 END,
            fttcp.fttcp_updated_at ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS stars_earned,

    FIRST_VALUE(fttcp.fttcp_score) OVER (
        PARTITION BY fttcp.fttcp_candidate_dw_id, fttcp.fttcp_test_delivery_dw_id
        ORDER BY
            CASE WHEN fttcp.fttcp_updated_at IS NULL THEN 1 ELSE 0 END,
            fttcp.fttcp_updated_at ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS test_score,

    FIRST_VALUE(fttcp.fttcp_status) OVER (
        PARTITION BY fttcp.fttcp_candidate_dw_id, fttcp.fttcp_test_delivery_dw_id
        ORDER BY
            CASE WHEN fttcp.fttcp_updated_at IS NULL THEN 1 ELSE 0 END,
            fttcp.fttcp_updated_at ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS completion_status,

    -- tt_due_date_adoption_flag
    CASE
        WHEN FIRST_VALUE(fttcp.fttcp_status) OVER (
                 PARTITION BY fttcp.fttcp_candidate_dw_id, fttcp.fttcp_test_delivery_dw_id
                 ORDER BY
                     CASE WHEN fttcp.fttcp_updated_at IS NULL THEN 1 ELSE 0 END,
                     fttcp.fttcp_updated_at ASC
                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
             ) = 'RECORDER_COMPLETED'
        THEN
            CASE
                WHEN tt.ttds_test_end_time IS NOT NULL
                     AND CONVERT(
                             DATE,
                             FIRST_VALUE(fttcp.fttcp_updated_at) OVER (
                                 PARTITION BY fttcp.fttcp_test_delivery_dw_id, fttcp.fttcp_candidate_dw_id
                                 ORDER BY
                                     CASE WHEN fttcp.fttcp_updated_at IS NULL THEN 1 ELSE 0 END,
                                     fttcp.fttcp_updated_at ASC
                                 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                             )
                         ) <= CONVERT(DATE, tt.ttds_test_end_time)
                THEN 'completed_within_due_date'
                WHEN tt.ttds_test_end_time IS NULL
                THEN 'NO_DUE_DATE'
                ELSE 'completed_outside_due_date'
            END
        ELSE 'NOT_COMPLETED'
    END AS tt_due_date_adoption_flag

FROM cte_teachers ct
JOIN ${rs_coredw}.dim_class dc
    ON dc.class_dw_id = ct.class_dw_id
   AND dc.class_course_status = 'ACTIVE'
JOIN ${rs_coredw}.dim_course dcr
    ON dcr.course_id = dc.class_material_id
   AND dcr.course_status = 1
JOIN ${rs_bi_coredw}.bi_active_schools_dim sc
    ON dc.class_school_id = sc.school_id

JOIN ${rs_coredw}.dim_grade dg
    ON dg.grade_id = dc.class_grade_id
LEFT JOIN dim_teacher_test tt
    ON ct.teacher_id = tt.teacher_id
   AND dc.class_id = tt.class_id
LEFT JOIN ${rs_coredw}.fact_teacher_test_candidate_progress fttcp
    ON fttcp.fttcp_test_delivery_id = tt.ttds_test_delivery_id
   AND tt.tt_assigned_student_id = fttcp.fttcp_candidate_id
   AND fttcp.fttcp_created_time >= CONVERT(DATETIME2, sc.academic_year_start_date)
   AND fttcp.fttcp_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, sc.academic_year_end_date));
