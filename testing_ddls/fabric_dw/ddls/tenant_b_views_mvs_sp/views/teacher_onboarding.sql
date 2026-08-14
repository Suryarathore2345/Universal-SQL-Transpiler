CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.vw_teacher_onboarding AS
WITH total_teachers AS (
    SELECT DISTINCT
        teacher_dw_id,
        teacher_school_dw_id,
        FIRST_VALUE(teacher_status) OVER (
            PARTITION BY teacher_dw_id, teacher_school_dw_id
            ORDER BY teacher_created_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_status
    FROM ${RS_COREDW}.dim_teacher
    WHERE (
        (teacher_status = 2
         AND CONVERT(DATE, GETDATE()) >= CONVERT(DATE, teacher_created_time)
         AND CONVERT(DATE, GETDATE()) < CONVERT(DATE, teacher_active_until)
        )
        OR teacher_status = 1
    )
),

teacher_onboarding AS (
    SELECT DISTINCT
        tl.teacher_dw_id,
        ds.school_dw_id,
        FIRST_VALUE(tl.login_local_date_time) OVER (
            PARTITION BY tl.teacher_dw_id, ds.school_dw_id
            ORDER BY tl.login_local_date_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_first_login_date,
        FIRST_VALUE(tl.login_local_date_time) OVER (
            PARTITION BY tl.teacher_dw_id, ds.school_dw_id
            ORDER BY tl.login_local_date_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_last_login_date
    FROM ${RS_BI_COREDW}.teacher_login tl
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim ds
        ON ds.school_dw_id = tl.school_dw_id
       AND CONVERT(DATE, tl.login_local_date_time) >= ds.academic_year_start_date
)
SELECT DISTINCT
    tch.teacher_dw_id,
    tch.teacher_school_dw_id AS school_dw_id,
    tch.teacher_status,
    ton.teacher_first_login_date,
    ton.teacher_last_login_date
FROM total_teachers tch
LEFT JOIN teacher_onboarding ton
    ON tch.teacher_dw_id = ton.teacher_dw_id
   AND tch.teacher_school_dw_id = ton.school_dw_id;