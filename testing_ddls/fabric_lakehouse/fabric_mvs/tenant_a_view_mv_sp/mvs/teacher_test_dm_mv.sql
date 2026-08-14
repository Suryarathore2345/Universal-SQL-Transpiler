CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.teacher_test_dm_mv AS
WITH cte_teachers AS 
(
    SELECT DISTINCT
        teacher_dw_id,
        teacher_id,
        class_dw_id
    FROM {{rs_coredw}}.dim_class dc
    JOIN {{rs_coredw}}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    LEFT JOIN {{rs_coredw}}.dim_teacher dt
        ON dcu.class_user_user_dw_id = dt.teacher_dw_id
        AND dt.teacher_status = 1
        AND teacher_id NOT IN (
            SELECT DISTINCT teacher_id FROM {{rs_bi_coredw}}.exclude_teacher_id
        )
    WHERE class_status = 1
      AND dcu.class_user_role_dw_id = 1
      AND class_course_status = 'ACTIVE'
      AND class_user_status = 1
      AND dcu.class_user_attach_status = 1
),

tt_lq_assigned AS (
    SELECT DISTINCT
        dtt.tt_dw_id,
        dtt.tt_test_id,
        dttbla.ttbla_dw_id,
        dttbla.ttbla_test_blueprint_id,
        COUNT(DISTINCT dttbla.ttbla_lesson_id)  AS lessons_assigned,
        COUNT(DISTINCT ttia_test_item_id)        AS questions_assigned
    FROM {{rs_coredw}}.dim_teacher_test_blueprint_lesson_association AS dttbla
    JOIN {{rs_coredw}}.dim_learning_objective lo
        ON lo.lo_id = dttbla.ttbla_lesson_id
        AND lo.lo_status = 1
    JOIN {{rs_coredw}}.dim_teacher_test dtt
        ON dtt.tt_test_blueprint_id = dttbla.ttbla_test_blueprint_id
    JOIN {{rs_coredw}}.dim_teacher_test_item_association dttia
        ON dttia.ttia_test_id = dtt.tt_test_id
        AND dttbla.ttbla_status = 1
        AND dttia.ttia_status = 1
    GROUP BY dtt.tt_dw_id, dtt.tt_test_id, dttbla.ttbla_dw_id, dttbla.ttbla_test_blueprint_id
),

tt_assigned_students AS (
    SELECT DISTINCT
        ttca_test_id,
        ttca_dw_id,
        ttca_test_delivery_id,
        ttca_test_candidate_id
    FROM {{rs_coredw}}.dim_teacher_test_candidate_association AS ttca
    JOIN {{rs_bi_coredw}}.bi_student_dim ds
        ON ds.student_id = ttca.ttca_test_candidate_id
    WHERE ttca_status = 1
      AND student_status = 1
),

dim_teacher_test AS (
    -- PUBLISHED tests (INNER JOINs)
    SELECT DISTINCT
        tt.tt_dw_id,
        tt.tt_test_id,
        tt.tt_test_class_id                                                         AS class_id,
        tt.tt_test_created_by_id                                                    AS teacher_id,
        tt.tt_test_title,
        tt.tt_test_blueprint_id,
        tt.tt_test_status,
        CAST(from_utc_timestamp(tt.tt_created_time, sc.tenant_timezone) AS DATE)    AS tt_created_date,
        from_utc_timestamp(tt.tt_created_time, sc.tenant_timezone)                  AS created_time,
        CAST(from_utc_timestamp(tt.tt_updated_time, sc.tenant_timezone) AS DATE)    AS published_date,
        from_utc_timestamp(tt.tt_updated_time, sc.tenant_timezone)                  AS published_time,
        tas.ttca_test_candidate_id                                                  AS tt_assigned_student_id,
        from_utc_timestamp(ds.ttds_test_start_time, sc.tenant_timezone)             AS ttds_test_start_time,
        from_utc_timestamp(ds.ttds_test_end_time, sc.tenant_timezone)               AS ttds_test_end_time,
        CASE
            WHEN DATE(tt.tt_created_time) = DATE(ds.ttds_test_start_time) THEN 'today'
            WHEN DATE(tt.tt_created_time) < DATE(ds.ttds_test_start_time) THEN 'future_date'
            ELSE 'other'
        END                                                                         AS tt_start_date_flag,
        lqa.lessons_assigned,
        lqa.questions_assigned,
        ds.ttds_dw_id,
        ds.ttds_test_delivery_id
    FROM {{rs_coredw}}.dim_teacher_test tt
    JOIN {{rs_coredw}}.dim_class dc
        ON dc.class_id = tt.tt_test_class_id
        AND tt.tt_status = 1
    JOIN {{rs_bi_coredw}}.bi_active_schools_dim sc
        ON dc.class_school_id = sc.school_id
        AND CAST(tt.tt_created_time AS DATE) >= sc.academic_year_start_date
        AND CAST(tt.tt_created_time AS DATE) <= sc.academic_year_end_date
    JOIN {{rs_coredw}}.dim_teacher_test_delivery_settings ds
        ON ds.ttds_test_id = tt.tt_test_id
        AND ds.ttds_status = 1
    JOIN tt_lq_assigned lqa
        ON lqa.tt_test_id = tt.tt_test_id
    JOIN tt_assigned_students tas
        ON tas.ttca_test_delivery_id = ds.ttds_test_delivery_id
    WHERE tt.tt_status = 1
      AND UPPER(tt.tt_test_status) = 'PUBLISHED'

    UNION ALL

    -- DRAFT / VALID tests (LEFT JOINs)
    SELECT DISTINCT
        tt.tt_dw_id,
        tt.tt_test_id,
        tt.tt_test_class_id                                                         AS class_id,
        tt.tt_test_created_by_id                                                    AS teacher_id,
        tt.tt_test_title,
        tt.tt_test_blueprint_id,
        tt.tt_test_status,
        CAST(from_utc_timestamp(tt.tt_created_time, sc.tenant_timezone) AS DATE)    AS tt_created_date,
        from_utc_timestamp(tt.tt_created_time, sc.tenant_timezone)                  AS created_time,
        CAST(from_utc_timestamp(tt.tt_updated_time, sc.tenant_timezone) AS DATE)    AS published_date,
        from_utc_timestamp(tt.tt_updated_time, sc.tenant_timezone)                  AS published_time,
        tas.ttca_test_candidate_id                                                  AS tt_assigned_student_id,
        from_utc_timestamp(ds.ttds_test_start_time, sc.tenant_timezone)             AS ttds_test_start_time,
        from_utc_timestamp(ds.ttds_test_end_time, sc.tenant_timezone)               AS ttds_test_end_time,
        CASE
            WHEN DATE(tt.tt_created_time) = DATE(ds.ttds_test_start_time) THEN 'today'
            WHEN DATE(tt.tt_created_time) < DATE(ds.ttds_test_start_time) THEN 'future_date'
            ELSE 'other'
        END                                                                         AS tt_start_date_flag,
        lqa.lessons_assigned,
        lqa.questions_assigned,
        ds.ttds_dw_id,
        ds.ttds_test_delivery_id
    FROM {{rs_coredw}}.dim_teacher_test tt
    JOIN {{rs_coredw}}.dim_class dc
        ON dc.class_id = tt.tt_test_class_id
        AND tt.tt_status = 1
    JOIN {{rs_bi_coredw}}.bi_active_schools_dim sc
        ON dc.class_school_id = sc.school_id
        AND CAST(tt.tt_created_time AS DATE) >= sc.academic_year_start_date
        AND CAST(tt.tt_created_time AS DATE) <= sc.academic_year_end_date
    LEFT JOIN {{rs_coredw}}.dim_teacher_test_delivery_settings ds
        ON ds.ttds_test_id = tt.tt_test_id
        AND ds.ttds_status = 1
    LEFT JOIN tt_lq_assigned lqa
        ON lqa.tt_test_id = tt.tt_test_id
    LEFT JOIN tt_assigned_students tas
        ON tas.ttca_test_delivery_id = ds.ttds_test_delivery_id
    WHERE tt.tt_status = 1
      AND (UPPER(tt.tt_test_status) = 'DRAFT' OR UPPER(tt.tt_test_status) = 'VALID')
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
    UPPER(dc.class_gen_subject) AS class_gen_subject,
    UPPER(dc.class_title)       AS class_title,
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

    -- Student test start time: first fttcp_created_time per candidate+test
    from_utc_timestamp(
        FIRST_VALUE(fttcp.fttcp_created_time) OVER (
            PARTITION BY fttcp.fttcp_candidate_dw_id, tt.tt_dw_id
            ORDER BY fttcp.fttcp_created_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ),
        sc.tenant_timezone
    )                                                                               AS student_test_start_time,

    -- Student test end time: last fttcp_created_time where status = RECORDER_COMPLETED
    from_utc_timestamp(
        LAST_VALUE(
            CASE WHEN fttcp.fttcp_status = 'RECORDER_COMPLETED' THEN fttcp.fttcp_created_time END
        ) OVER (
            PARTITION BY fttcp.fttcp_candidate_dw_id, tt.tt_dw_id
            ORDER BY fttcp.fttcp_created_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ),
        sc.tenant_timezone
    )                                                                               AS student_test_end_time,

    fttcp.fttcp_candidate_dw_id,

    -- Time spent in minutes: difference between last updated_at and first created_at per delivery+candidate
    (
        UNIX_TIMESTAMP(
            LAST_VALUE(fttcp.fttcp_updated_at) OVER (
                PARTITION BY fttcp.fttcp_test_delivery_dw_id, fttcp.fttcp_candidate_dw_id
                ORDER BY
                    CASE
                        WHEN fttcp.fttcp_created_at IS NULL THEN 1
                        ELSE 0
                    END,
                    fttcp.fttcp_created_at DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            )
        )
        -
        UNIX_TIMESTAMP(
            FIRST_VALUE(fttcp.fttcp_created_at) OVER (
                PARTITION BY fttcp.fttcp_test_delivery_dw_id, fttcp.fttcp_candidate_dw_id
                ORDER BY
                CASE
                        WHEN fttcp.fttcp_updated_at IS NULL THEN 0
                        ELSE 1
                    END,
                    fttcp.fttcp_updated_at ASC
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            )
        )
    ) / 60000.0                                                                        AS stud_time_spent_in_mins,

    FIRST_VALUE(fttcp.fttcp_stars_awarded) OVER (
        PARTITION BY fttcp.fttcp_candidate_dw_id, fttcp.fttcp_test_delivery_dw_id
        ORDER BY
            CASE WHEN fttcp.fttcp_updated_at IS NULL THEN 1 ELSE 0 END,
            fttcp.fttcp_updated_at ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                                               AS stars_earned,

    FIRST_VALUE(fttcp.fttcp_score) OVER (
        PARTITION BY fttcp.fttcp_candidate_dw_id, fttcp.fttcp_test_delivery_dw_id
        ORDER BY
            CASE WHEN fttcp.fttcp_updated_at IS NULL THEN 1 ELSE 0 END,
            fttcp.fttcp_updated_at ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                                               AS test_score,

    FIRST_VALUE(fttcp.fttcp_status) OVER (
        PARTITION BY fttcp.fttcp_candidate_dw_id, fttcp.fttcp_test_delivery_dw_id
        ORDER BY
            CASE WHEN fttcp.fttcp_updated_at IS NULL THEN 1 ELSE 0 END,
            fttcp.fttcp_updated_at ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                                                               AS completion_status,

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
                     AND DATE(FIRST_VALUE(fttcp.fttcp_updated_at) OVER (
                             PARTITION BY fttcp.fttcp_test_delivery_dw_id, fttcp.fttcp_candidate_dw_id
                         )) <= DATE(tt.ttds_test_end_time)
                    THEN 'completed_within_due_date'
                WHEN tt.ttds_test_end_time IS NULL
                    THEN 'NO_DUE_DATE'
                ELSE 'completed_outside_due_date'
            END
        ELSE 'NOT_COMPLETED'
    END                                                                             AS tt_due_date_adoption_flag

FROM cte_teachers ct
JOIN {{rs_coredw}}.dim_class dc
    ON dc.class_dw_id = ct.class_dw_id
    AND dc.class_course_status = 'ACTIVE'
JOIN {{rs_coredw}}.dim_course dcr
    ON dcr.course_id = dc.class_material_id
    AND dcr.course_status = 1
JOIN {{rs_bi_coredw}}.bi_active_schools_dim sc
    ON dc.class_school_id = sc.school_id
JOIN {{rs_coredw}}.dim_grade dg
    ON dg.grade_id = dc.class_grade_id
LEFT JOIN dim_teacher_test tt
    ON ct.teacher_id = tt.teacher_id
    AND dc.class_id = tt.class_id
LEFT JOIN {{rs_coredw}}.fact_teacher_test_candidate_progress fttcp
    ON fttcp.fttcp_test_delivery_id = tt.ttds_test_delivery_id
    AND tt.tt_assigned_student_id = fttcp.fttcp_candidate_id
    AND fttcp.fttcp_created_time >= CAST(sc.academic_year_start_date AS TIMESTAMP)
    AND fttcp.fttcp_created_time < DATE_ADD(CAST(sc.academic_year_end_date AS TIMESTAMP), 1);