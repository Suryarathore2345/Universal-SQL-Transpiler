CREATE OR REPLACE VIEW eagles_alefdw_dev.pathway_student_daily_activity AS
WITH adaptive_practice_fact AS(
SELECT
        ap.student_dw_id,
        DATE(ap.created_time) AS datest,
        ap.pathway_dw_id,
        MAX( CASE WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry') THEN 'Science'
                  WHEN dcsa.cs_subject_dw_id IS NOT NULL THEN 'Arabits'
                  ELSE dc.class_gen_subject
             END) AS class_gen_subject
FROM alefdw.fact_adaptive_practice_progress ap
INNER JOIN alefdw.dim_class dc
    ON ap.pathway_id = dc.class_material_id
    AND ap.class_dw_id = dc.class_dw_id
    AND dc.class_status = 1
LEFT JOIN alefdw.dim_course_subject_association dcsa
    ON dcsa.cs_course_id = dc.class_material_id
    AND dcsa.cs_status = 1
    AND dcsa.cs_subject_dw_id IN (129, 503)
WHERE event_type = 'AdaptivePracticeAnswerSubmittedEvent'
GROUP BY 1, 2, 3
),
skills_active_fact AS (
select slp.student_dw_id,
       DATE(slp.created_time)  as datest,
       slp.material_dw_id,
       MAX(CASE WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry') THEN 'Science'
                WHEN dcsa.cs_subject_dw_id IS NOT NULL THEN 'Arabits'
                ELSE dc.class_gen_subject
             END) AS class_gen_subject
FROM alefdw.fact_pathway_skill_learning_progress slp
INNER JOIN alefdw.dim_class dc
    ON dc.class_material_id = slp.material_id
    AND dc.class_dw_id = slp.class_dw_id
    AND dc.class_status = 1
LEFT JOIN alefdw.dim_course_subject_association dcsa
    ON dcsa.cs_course_id = dc.class_material_id
    AND dcsa.cs_status = 1
    AND dcsa.cs_subject_dw_id IN (129, 503)
WHERE event_type = 'SkillExperienceFinished'
GROUP BY 1, 2, 3
)
SELECT COALESCE(ap.student_dw_id, sa.student_dw_id) AS student_dw_id,
       COALESCE(ap.class_gen_subject, sa.class_gen_subject) AS class_gen_subject,
       COALESCE(ap.datest, sa.datest) AS datest
FROM adaptive_practice_fact ap
FULL OUTER JOIN skills_active_fact sa
    ON ap.student_dw_id = sa.student_dw_id
    AND ap.datest = sa.datest
    AND ap.pathway_dw_id = sa.material_dw_id
WITH NO SCHEMA BINDING;

