CREATE OR REPLACE VIEW bi_alefdw_dev.core_course_classlearning_agg_view AS
WITH class_total_students AS (
    SELECT
        COALESCE(cts.class_dw_id, cts_prev.class_dw_id) AS class_dw_id,
        COALESCE(cts.section_dw_id, cts_prev.class_section_dw_id) AS section_dw_id,
        COALESCE(cts.section_name, cts_prev.class_section_name) AS section_name,
        COALESCE(cts.class_total_students, cts_prev.class_total_students) AS class_total_students
    FROM
        bi_alefdw.class_total_students_mv cts
    FULL OUTER JOIN bi_alefdw.class_total_students_prev_ay_mv cts_prev ON cts.class_dw_id = cts_prev.class_dw_id
),
core_course_learning_experience AS (
    SELECT fle_class_dw_id,
           student_section_dw_id AS fle_section_dw_id,
           lo_attempted AS fle_lo_dw_id,
           coalesce(fle_source, 'NA') AS fle_source,
           COUNT(student_dw_id)                                                          AS total_students_fact,
           COUNT(distinct case lo_status when 'Completed' then student_dw_id end)        AS total_completed_students,
           COUNT(distinct case when lo_status = 'Completed' AND fle_score >= 0 then student_dw_id end) AS total_completed_students_score,
           SUM(CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN fle_score  END) AS fle_score,
           COUNT(DISTINCT CASE WHEN lo_status = 'Completed' and fle_score >= 70 THEN student_dw_id END) AS meets_completed_students,
           COUNT(DISTINCT CASE WHEN lo_status = 'Completed' and fle_score >= 50 AND fle_score < 70 THEN student_dw_id END) AS approaching_completed_students,
           COUNT(DISTINCT CASE WHEN lo_status = 'Completed' and fle_score < 50 AND fle_score >= 0 THEN student_dw_id END)  AS below_completed_students,
           SUM(session_time)                                                             AS session_time
    FROM bi_alefdw.students_lesson_progress_mv
    GROUP BY 1,2,3,4
    UNION ALL
    SELECT *
    FROM bi_alefdw.core_course_learning_experience_mv ccfle
    WHERE NOT EXISTS(SELECT 1 FROM bi_alefdw.students_lesson_progress_mv slp WHERE ccfle.fle_class_dw_id = slp.fle_class_dw_id)
)
SELECT cont.*,
       cts.section_dw_id,
       cts.section_name,
       cts.class_total_students,
       fact.fle_source,
       fact.total_students_fact,
       fact.total_completed_students,
       fact.total_completed_students_score,
       fact.total_students_fact - fact.total_completed_students AS total_inprogress_students,
       fact.fle_score,
       fact.meets_completed_students,
       fact.approaching_completed_students,
       fact.below_completed_students,
       fact.fle_score/fact.total_completed_students::FLOAT      AS avg_score,
       fact.session_time
FROM bi_alefdw.core_class_activity_content_mv cont
    INNER JOIN class_total_students cts
        ON cts.class_dw_id = cont.class_dw_id
    LEFT JOIN core_course_learning_experience fact
        ON fact.fle_class_dw_id  = cont.class_dw_id
        AND fact.fle_lo_dw_id = cont.activity_dw_id
        AND fact.fle_section_dw_id = cts.section_dw_id
WITH NO SCHEMA BINDING;
