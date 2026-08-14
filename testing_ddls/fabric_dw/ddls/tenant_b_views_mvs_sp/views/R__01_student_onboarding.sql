CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.vw_student_onboarding AS
WITH total_students AS
(
    SELECT DISTINCT
        ds.student_school_dw_id,
        ds.student_dw_id,
        ds.student_id,
        FIRST_VALUE(ds.student_status) OVER (
            PARTITION BY ds.student_dw_id
            ORDER BY ds.student_created_time DESC , student_status ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS student_current_status
    FROM ${RS_BI_COREDW}.bi_student_dim ds
),

student_onboarding AS
(
    SELECT DISTINCT
        sl.student_dw_id,
        ds.school_dw_id,
        FIRST_VALUE(sl.login_local_date_time) OVER (
            PARTITION BY sl.student_dw_id
            ORDER BY sl.login_local_date_time ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS student_first_login_date,
        FIRST_VALUE(sl.login_local_date_time) OVER (
            PARTITION BY sl.student_dw_id
            ORDER BY sl.login_local_date_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS student_last_login_date
    FROM ${RS_BI_COREDW}.student_login sl
    INNER JOIN ${RS_COREDW}.dim_student st
        ON sl.student_dw_id = st.student_dw_id
       AND sl.school_dw_id = st.student_school_dw_id
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim ds
        ON ds.school_dw_id = sl.school_dw_id
       AND CONVERT(DATE, sl.login_local_date_time) >= ds.academic_year_start_date
)

SELECT DISTINCT
    std.student_dw_id,
    std.student_id,
    std.student_school_dw_id AS school_dw_id,
    sch.school_id,
    sch.school_name,
    std.student_current_status AS student_status,
    son.student_first_login_date,
    son.student_last_login_date
FROM total_students std
INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim sch
    ON sch.school_dw_id = std.student_school_dw_id
LEFT JOIN student_onboarding son
    ON std.student_dw_id = son.student_dw_id
   AND std.student_school_dw_id = son.school_dw_id
WHERE std.student_current_status = 1;