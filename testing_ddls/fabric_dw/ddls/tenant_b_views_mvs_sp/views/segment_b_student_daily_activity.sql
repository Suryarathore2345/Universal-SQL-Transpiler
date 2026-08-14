CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.pathway_student_daily_activity
AS
WITH adaptive_practice_fact AS (
    SELECT
        ap.student_dw_id,
        CONVERT(DATE, ap.created_time) AS datest,
        ap.pathway_dw_id,
        MAX(
            CASE
                WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry') THEN 'Science'
                WHEN dcsa.cs_subject_dw_id IS NOT NULL THEN 'Arabits'
                ELSE dc.class_gen_subject
            END
        ) AS class_gen_subject
    FROM ${RS_COREDW}.fact_adaptive_practice_progress ap
    INNER JOIN ${RS_COREDW}.dim_class dc
        ON ap.pathway_id = dc.class_material_id
       AND ap.class_dw_id = dc.class_dw_id
       AND dc.class_status = 1
    LEFT JOIN ${RS_COREDW}.dim_course_subject_association dcsa
        ON dcsa.cs_course_id = dc.class_material_id
       AND dcsa.cs_status = 1
       AND dcsa.cs_subject_dw_id IN (129, 503)
    WHERE ap.event_type = 'AdaptivePracticeAnswerSubmittedEvent'
    GROUP BY
        ap.student_dw_id,
        CONVERT(DATE, ap.created_time),
        ap.pathway_dw_id
),
skills_active_fact AS (
    SELECT
        slp.student_dw_id,
        CONVERT(DATE, slp.created_time) AS datest,
        slp.material_dw_id,
        MAX(
            CASE
                WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry') THEN 'Science'
                WHEN dcsa.cs_subject_dw_id IS NOT NULL THEN 'Arabits'
                ELSE dc.class_gen_subject
            END
        ) AS class_gen_subject
    FROM ${RS_COREDW}.fact_pathway_skill_learning_progress slp
    INNER JOIN ${RS_COREDW}.dim_class dc
        ON dc.class_material_id = slp.material_id
       AND dc.class_dw_id       = slp.class_dw_id
       AND dc.class_status      = 1
    LEFT JOIN ${RS_COREDW}.dim_course_subject_association dcsa
        ON dcsa.cs_course_id    = dc.class_material_id
       AND dcsa.cs_status       = 1
       AND dcsa.cs_subject_dw_id IN (129, 503)
    WHERE slp.event_type = 'SkillExperienceFinished'
    GROUP BY
        slp.student_dw_id,
        CONVERT(DATE, slp.created_time),
        slp.material_dw_id
)
SELECT
    ISNULL(ap.student_dw_id, sa.student_dw_id)        AS student_dw_id,
    ISNULL(ap.class_gen_subject, sa.class_gen_subject) AS class_gen_subject,
    ISNULL(ap.datest, sa.datest)                      AS datest
FROM adaptive_practice_fact ap
FULL OUTER JOIN skills_active_fact sa
    ON ap.student_dw_id = sa.student_dw_id
   AND ap.datest        = sa.datest
   AND ap.pathway_dw_id = sa.material_dw_id;