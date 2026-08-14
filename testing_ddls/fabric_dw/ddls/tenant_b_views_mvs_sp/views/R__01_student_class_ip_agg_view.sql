CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.student_class_ip_agg_view AS
SELECT
    student_id,
    student_dw_id,
    school_id,
    school_dw_id,
    school_name,
    grade_k12grade,
    class_dw_id,
    class_title,
    class_gen_subject,
    week_start_date,
    week_end_date,
    -- index_column: MD5(school_dw_id) + '-' + grade_k12grade + '-' + class_gen_subject + '-' + week_start_date + '-' + week_end_date
    CONVERT(VARCHAR(64), HASHBYTES('MD5', 
        CONVERT(VARCHAR(200), school_dw_id) 
        + '-' + CONVERT(VARCHAR(200), grade_name) 
        + '-' + CONVERT(VARCHAR(200), class_gen_subject)
        + '-' + CONVERT(VARCHAR(10), week_start_date, 23)
        + '-' + CONVERT(VARCHAR(10), week_end_date, 23)
    ), 2) AS index_column,
    COUNT(DISTINCT CASE WHEN lo_status = 'Completed' THEN lo_to_finish END) AS completed_lessons,
    AVG(CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN CONVERT(decimal(38,2), fle_score) END) AS average_score
FROM ${RS_BI_COREDW}.instructional_plan_dm_view
WHERE class_title NOT LIKE '%power skills%'
  AND class_title NOT LIKE '%extra resources%'
  AND class_gen_subject <> 'core stars'
  AND student_id IS NOT NULL
GROUP BY
    student_id,
    student_dw_id,
    school_id,
    school_dw_id,
    school_name,
    grade_k12grade,
    class_dw_id,
    class_title,
    class_gen_subject,
    week_start_date,
    week_end_date,
    CONVERT(VARCHAR(64), HASHBYTES('MD5', 
        CONVERT(VARCHAR(200), school_dw_id) 
        + '-' + CONVERT(VARCHAR(200), grade_name) 
        + '-' + CONVERT(VARCHAR(200), class_gen_subject)
        + '-' + CONVERT(VARCHAR(10), week_start_date, 23)
        + '-' + CONVERT(VARCHAR(10), week_end_date, 23)
    ), 2)
HAVING
    COUNT(DISTINCT CASE WHEN lo_status = 'Completed' THEN lo_to_finish END) > 0;