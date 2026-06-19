CREATE MATERIALIZED VIEW bi_alefdw_dev.core_course_ic_experience_mv AS
SELECT fle_class_dw_id,
       COALESCE(fle_section_dw_id, 10001) AS fle_section_dw_id,
       fle_lo_dw_id,
       COUNT(DISTINCT fle_student_dw_id)                                                             AS total_students_fact,
       COUNT(DISTINCT CASE WHEN fle_completion_node is true THEN fle_student_dw_id END)              AS total_completed_students,
       COUNT(DISTINCT CASE WHEN fle_completion_node is true AND fle_total_score >= 70 THEN fle_student_dw_id END) AS meets_completed_students,
       COUNT(DISTINCT CASE WHEN fle_completion_node is true AND fle_total_score >= 50 AND fle_total_score < 70 THEN fle_student_dw_id END) AS approaching_completed_students,
       COUNT(DISTINCT CASE WHEN fle_completion_node is true AND fle_total_score < 50 AND fle_total_score >= 0 THEN fle_student_dw_id END)  AS below_completed_students,
       SUM(CASE WHEN fle_completion_node is true THEN fle_total_score END)                           AS fle_score,
       SUM(CASE WHEN  fle.fle_total_time <= 1200 THEN fle.fle_total_time
                WHEN fle.fle_total_time > 1200 THEN 1200
                ELSE 0 END)                                                                          AS session_time -- interim checkpoints time limit is at 1200 sec
FROM alefdw.fact_learning_experience fle
    JOIN alefdw.dim_interim_checkpoint ic
        ON ic.ic_dw_id = fle.fle_lo_dw_id
        AND ic_status = 1
WHERE fle_abbreviation <> 'NA'
AND fle_activity_type = 'INTERIM_CHECKPOINT'
AND fle_material_type <> 'PATHWAY'
AND fle_ls_id NOT IN (select distinct fle_ls_id from alefdw.fact_learning_experience where fle_state = 4)
GROUP BY 1, 2, 3;