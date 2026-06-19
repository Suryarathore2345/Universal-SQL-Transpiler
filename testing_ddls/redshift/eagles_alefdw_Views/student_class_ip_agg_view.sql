CREATE OR REPLACE VIEW eagles_alefdw_dev.student_class_ip_agg_view AS
SELECT student_id,
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
       MD5(CAST(school_dw_id AS TEXT) || '-' ||
            CAST(grade_name AS TEXT) || '-' ||
            class_gen_subject || '-' ||
           TO_CHAR(week_start_date ,'YYYY-MM-DD') || '-' ||
           TO_CHAR(week_end_date, 'YYYY-MM-DD')
        ) AS index_column,
       COUNT(DISTINCT CASE lo_status WHEN 'Completed' THEN lo_to_finish END)           AS completed_lessons,
       AVG(CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN CAST(fle_score AS decimal(10, 2)) END) AS average_score
FROM bi_alefdw.instructional_plan_dm_view
WHERE lower(class_title) NOT LIKE '%power skills%'
  AND lower(class_title) NOT LIKE '%extra resources%'
  AND lower(class_gen_subject) != 'alef stars'
  AND student_id IS NOT NULL
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
HAVING completed_lessons > 0
WITH NO SCHEMA BINDING;