CREATE MATERIALIZED VIEW bi_alefdw_dev.core_course_learning_experience_mv AS
SELECT fle_class_dw_id,
       COALESCE(fle_section_dw_id, 10001) AS fle_section_dw_id,
       fle_lo_dw_id,
       COALESCE(fle_source, 'NA') AS fle_source,
       COUNT(DISTINCT fle_student_dw_id)                                                             AS total_students_fact,
       COUNT(DISTINCT CASE WHEN fle_completion_node is true THEN fle_student_dw_id END)              AS total_completed_students,
       COUNT(DISTINCT CASE WHEN fle_completion_node is true AND lo.lo_max_stars > 0 THEN fle_student_dw_id END) AS total_completed_students_score,
       SUM( CASE WHEN fle_completion_node is true AND lo.lo_max_stars > 0 and fle_is_retry is false then COALESCE(fle_total_score,fle_score) end)  AS fle_score, --  coalesce because in ay 2020-2021 in use was fle_score only
       COUNT(DISTINCT CASE WHEN fle_completion_node is true AND lo.lo_max_stars > 0 and fle_is_retry is false  AND COALESCE(fle_total_score,fle_score) >= 70 THEN fle_student_dw_id END) AS meets_completed_students,
       COUNT(DISTINCT CASE WHEN fle_completion_node is true  AND lo.lo_max_stars > 0 and fle_is_retry is false  AND COALESCE(fle_total_score,fle_score) >= 50 AND COALESCE(fle_total_score,fle_score) < 70 THEN fle_student_dw_id END) AS approaching_completed_students,
       COUNT(DISTINCT CASE WHEN fle_completion_node is true  AND lo.lo_max_stars > 0 and fle_is_retry is false  AND COALESCE(fle_total_score,fle_score) < 50 AND COALESCE(fle_total_score,fle_score) >= 0 THEN fle_student_dw_id END)  AS below_completed_students,
       SUM(CASE WHEN  fle.fle_total_time <= 900 THEN fle.fle_total_time
                WHEN fle.fle_total_time > 900 THEN 900
                ELSE 0 END)                                                                          AS session_time
FROM alefdw.fact_learning_experience fle
    JOIN alefdw.dim_learning_objective lo
        ON lo.lo_dw_id = fle.fle_lo_dw_id
        AND lo.lo_status = 1
WHERE fle_abbreviation <> 'NA'
AND fle_activity_type NOT IN ('INTERIM_CHECKPOINT', 'DIAGNOSTIC_TEST')
AND fle_material_type <> 'PATHWAY'
AND fle_is_additional_resource <> TRUE
AND NVL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON'
AND fle_ls_id NOT IN (select distinct fle_ls_id from alefdw.fact_learning_experience where fle_state = 4)
GROUP BY 1, 2, 3, 4;
