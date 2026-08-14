CREATE OR ALTER VIEW ${os_bi_coredw}.teacher_activity_curriculum_view AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date AS local_date,
        uae_week_number AS uae_week_num,
        uae_year_week_number AS uae_wy_num,
        calendar_year_month_number AS year_month
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date BETWEEN DATEADD(DAY, -365, CONVERT(DATE, GETDATE()))
                           AND CONVERT(DATE, GETDATE())
),

active_in_curriculum_base AS (
    SELECT DISTINCT
        CONVERT(
            DATE,
            fta.fta_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sch.windows_timezone, 'UTC')
        ) AS local_date,

        DATETRUNC(
            iso_week,
            fta.fta_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sch.windows_timezone, 'UTC')
        ) AS week_local_date,

        DATETRUNC(
            MONTH,
            fta.fta_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sch.windows_timezone, 'UTC')
        ) AS month_local_date,

        fta.fta_school_dw_id,
        fta.fta_teacher_dw_id
    FROM ${rs_coredw}.fact_teacher_activities fta
    JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
        ON fta.fta_school_dw_id = sch.school_dw_id
       AND fta.fta_created_time >= CONVERT(DATETIME2, sch.academic_year_start_date)  -- OPT-15: SARGable rewrite
       AND fta.fta_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, sch.academic_year_end_date))  -- OPT-15: SARGable rewrite

    CROSS APPLY (
        SELECT value
        FROM STRING_SPLIT(fta.fta_object_id, '/', 1)
        WHERE ordinal = 4
    ) parts
    WHERE parts.value IN (
        SELECT DISTINCT CONVERT(VARCHAR(4000), lo_id)
        FROM ${rs_coredw}.dim_learning_objective
        WHERE lo_curriculum_subject_id = 963534
    )
),

active_in_curriculum AS (
    SELECT DISTINCT
        local_date,
        week_local_date,
        month_local_date,
        fta_school_dw_id,

        DENSE_RANK() OVER (
            PARTITION BY local_date, fta_school_dw_id
            ORDER BY fta_teacher_dw_id ASC
        )
        +
        DENSE_RANK() OVER (
            PARTITION BY local_date, fta_school_dw_id
            ORDER BY fta_teacher_dw_id DESC
        ) - 1 AS active_in_curriculum,

        DENSE_RANK() OVER (
            PARTITION BY week_local_date, fta_school_dw_id
            ORDER BY fta_teacher_dw_id ASC
        )
        +
        DENSE_RANK() OVER (
            PARTITION BY week_local_date, fta_school_dw_id
            ORDER BY fta_teacher_dw_id DESC
        ) - 1 AS weekly_active_in_curriculum,

        DENSE_RANK() OVER (
            PARTITION BY month_local_date, fta_school_dw_id
            ORDER BY fta_teacher_dw_id ASC
        )
        +
        DENSE_RANK() OVER (
            PARTITION BY month_local_date, fta_school_dw_id
            ORDER BY fta_teacher_dw_id DESC
        ) - 1 AS monthly_active_in_curriculum,

        DENSE_RANK() OVER (
            PARTITION BY fta_school_dw_id
            ORDER BY fta_teacher_dw_id ASC
        )
        +
        DENSE_RANK() OVER (
            PARTITION BY fta_school_dw_id
            ORDER BY fta_teacher_dw_id DESC
        ) - 1 AS alltime_active_in_curriculum
    FROM active_in_curriculum_base
),

total_in_curriculum AS (
    SELECT
        dd.local_date,
        dsc.school_dw_id,
        dsc.school_name,
        dc.class_academic_year_id AS content_academic_year_id,
        DATEPART(YEAR, dsc.academic_year_end_date) AS content_academic_year_name,
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date))
        + '-' +
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        dsc.tenant_name,
        COUNT(DISTINCT dcu.class_user_user_dw_id) AS total_teacher_curriculum
    FROM ${rs_coredw}.dim_class dc
    JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dc.class_school_id = dsc.school_id
       AND dsc.academic_year_id = dc.class_academic_year_id
    LEFT JOIN ${rs_coredw}.dim_course_subject_association csa
        ON csa.cs_course_id = dc.class_material_id
       AND csa.cs_status = 1
    CROSS JOIN date_dimension dd
    WHERE
        (
            (dcu.class_user_status = 2
             AND dd.local_date >= CONVERT(DATE, dcu.class_user_created_time)
             AND dd.local_date <  CONVERT(DATE, dcu.class_user_active_until))
         OR (dcu.class_user_status = 1
             AND dd.local_date >= CONVERT(DATE, dcu.class_user_created_time))
        )
      AND dcu.class_user_role_dw_id = 1
      AND dcu.class_user_attach_status = 1
      AND dc.class_status = 1
      AND dc.class_course_status = 'ACTIVE'
      AND (csa.cs_subject_dw_id = 129 OR dc.class_curriculum_subject_id = 963534)
    GROUP BY
        dd.local_date,
        dsc.school_dw_id,
        dsc.school_name,
        dc.class_academic_year_id,
        DATEPART(YEAR, dsc.academic_year_end_date),
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date))
        + '-' +
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)),
        dsc.tenant_name
)

SELECT DISTINCT
    dd.local_date,
    dd.uae_week_num,
    dd.uae_wy_num,
    dd.year_month,
    tc.academic_year,
    tc.tenant_name,
    tc.school_name,
    tc.school_dw_id,
    ac.active_in_curriculum,
    ac.weekly_active_in_curriculum,
    ac.monthly_active_in_curriculum,
    ac.alltime_active_in_curriculum,
    tc.total_teacher_curriculum
FROM total_in_curriculum tc
INNER JOIN date_dimension dd
    ON tc.local_date = dd.local_date
LEFT JOIN active_in_curriculum ac
    ON tc.school_dw_id = ac.fta_school_dw_id
   AND tc.local_date = ac.local_date;
