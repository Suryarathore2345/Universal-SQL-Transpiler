CREATE OR ALTER VIEW ${os_bi_coredw}.alain_login_aggregated_view AS
SELECT
    calendar_year_end_date,
    calendar_month_end_date,
    calendar_month_start_date,
    week_start_date,
    week_end_date,
    tenant_dw_id,
    tenant_name,
    content_repository_dw_id,
    content_repository_name,
    academic_year_start_date,
    academic_year_end_date,
    AY,
    student_dw_id AS user_dw_id,
    school_dw_id,
    school_name,
    grade_name,
    section_dw_id,
    section_name,
    first_login_date,
    is_active,
    active_days,
    'student' AS label
FROM ${rs_bi_coredw}.alain_students_login

UNION

SELECT
    calendar_year_end_date,
    calendar_month_end_date,
    calendar_month_start_date,
    week_start_date,
    week_end_date,
    tenant_dw_id,
    tenant_name,
    content_repository_dw_id,
    content_repository_name,
    academic_year_start_date,
    academic_year_end_date,
    AY,
    teacher_dw_id AS user_dw_id,
    school_dw_id,
    school_name,
    'n/a' AS grade_name,
    -10 AS section_dw_id,
    'n/a' AS section_name,
    first_login_date,
    is_active,
    active_days,
    'teachers' AS label
FROM ${rs_bi_coredw}.alain_teachers_login;