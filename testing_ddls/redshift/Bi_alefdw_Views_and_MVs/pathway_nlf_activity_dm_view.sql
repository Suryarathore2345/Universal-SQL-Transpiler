CREATE
OR REPLACE VIEW bi_alefdw_dev.pathway_nlf_activity_dm_view AS
WITH pathway_student_details AS (SELECT DISTINCT pathway_student_dw_id,
                                                 fpp_student_dw_id,
                                                 adt_student_dw_id,
                                                 CASE WHEN fpp_placement_type = 4 THEN fpp_student_dw_id END AS adt_placed_student_dw_id,
                                                 course_dw_id,
                                                 school_name,
                                                 school_dw_id,
                                                 organisation_dw_id,
                                                 school_organisation,
                                                 tenant_id,
                                                 tenant_name,
                                                 grade_name,
                                                 curr_subject_name,
                                                 academic_year
                                 FROM bi_alefdw.pathway_adaptive_practice_mv),
     adaptive_practice AS (SELECT student_dw_id,
                                  course_dw_id,
                                  pathway_activity_date,
                                  academic_year,
                                  count(DISTINCT question_id) AS questions
                           FROM bi_alefdw.pathway_adaptive_practice_mv pap
                           WHERE (student_dw_id, course_dw_id, academic_year, level_dw_id, question_id,
                                  session_attempt) IN
                                 (SELECT student_dw_id,
                                         course_dw_id,
                                         academic_year,
                                         level_dw_id,
                                         question_id,
                                         max(session_attempt)
                                  from bi_alefdw.pathway_adaptive_practice_mv
                                  GROUP by 1, 2, 3, 4, 5)
                           GROUP BY 1, 2, 3, 4),

     skill_learning AS (SELECT skill_learning_student_dw_id,
                               material_dw_id,
                               skill_learning_date_time::DATE AS skill_learning_date,
                               academic_year,
                               COUNT(DISTINCT CASE
                                                  WHEN is_component_completed
                                                      THEN skill_component_id
                                   END)                       AS components_completed,
                               COUNT(DISTINCT CASE
                                                  WHEN is_skill_learning_completed
                                                      THEN skill_learning_dw_id
                                   END)                       AS skills_completed
                        FROM bi_alefdw.pathway_skill_learning_dm_view psl
                        GROUP BY 1, 2, 3, 4),

     nlf_joined AS (SELECT DISTINCT student_dw_id,
                                    course_dw_id,
                                    pathway_activity_date AS activity_date,
                                    academic_year,
                                    questions > 0         AS onboarded_flag,
                                    questions > 0         AS active_flag,
                                    NULL::BOOLEAN         AS actively_engaged_flag,
                                    questions,
                                    NULL::INT             AS skills
                    FROM adaptive_practice
                    UNION
                    SELECT DISTINCT skill_learning_student_dw_id,
                                    material_dw_id,
                                    skill_learning_date      AS activity_date,
                                    academic_year,
                                    TRUE                     AS onboarded_flag,
                                    components_completed > 0 AS active_flag,
                                    skills_completed > 0     AS actively_engaged_flag,
                                    NULL::INT                AS questions,
                                    skills_completed
                    FROM skill_learning)

SELECT psd.pathway_student_dw_id      AS nlf_pathway_student_dw_id,
       psd.course_dw_id               AS nlf_course_dw_id,
       psd.academic_year              AS nlf_academic_year,
       psd.curr_subject_name          AS nlf_curr_subject_name,
       psd.grade_name                 AS nlf_grade_name,
       psd.tenant_name                AS nlf_tenant_name,
       psd.school_name                AS nlf_school_name,
       psd.school_organisation        AS nlf_school_organisation,
       psd.tenant_id                  AS nlf_tenant_id,
       psd.school_dw_id               AS nlf_school_dw_id,
       psd.organisation_dw_id         AS nlf_organisation_dw_id,
       nlf.student_dw_id              AS nlf_student_dw_id,
       nlf.activity_date              AS nlf_activity_date,
       BOOL_OR(onboarded_flag)        AS nlf_is_onboarded,
       BOOL_OR(active_flag)           AS nlf_is_active,
       BOOL_OR(actively_engaged_flag) AS nlf_is_actively_engaged,
       MAX(questions)                 AS nlf_questions_submitted,
       MAX(skills)                    AS nlf_skills_learned
FROM pathway_student_details psd
         LEFT JOIN nlf_joined nlf
                   ON nlf.student_dw_id = psd.pathway_student_dw_id
                       AND nlf.course_dw_id = psd.course_dw_id
                       AND nlf.academic_year = psd.academic_year
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 WITH NO SCHEMA BINDING;