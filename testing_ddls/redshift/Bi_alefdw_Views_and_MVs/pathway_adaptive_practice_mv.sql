
CREATE MATERIALIZED VIEW bi_alefdw_dev.pathway_adaptive_practice_mv AS
--total registered in pathway
with pathway_class_total_students AS (SELECT dsc.school_dw_id,
                                             dsc.school_name,
                                             dsc.tenant_id,
                                             dsc.tenant_name,
                                             dsc.organisation_dw_id,
                                             dsc.school_organisation,
                                             dsc.school_composition,
                                             dsc.school_label,
                                             dsc.tenant_timezone,
                                             dsc.academic_year_start_date,
                                             dsc.academic_year_end_date,
                                             dcu.class_user_user_dw_id                     AS pathway_student_dw_id,
                                             ds.student_grade_dw_id,
                                             ds.student_special_needs,
                                             dg.grade_name,
                                             dg.grade_id,
                                             CASE
                                                 WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry')
                                                     THEN 'Science'
                                                 WHEN dcsa.cs_subject_dw_id IS NOT NULL
                                                     THEN 'Arabits'
                                                 ELSE dc.class_gen_subject END             AS curr_subject_name,
                                             dc.class_curriculum_subject_id                AS curr_subject_id,
                                             dc.class_material_id,
                                             date_part('year', dsc.academic_year_start_date) || '-' ||
                                             date_part('year', dsc.academic_year_end_date) AS academic_year,
                                             date_part('year', dsc.academic_year_end_date) AS academic_year_end_year
                                      FROM alefdw.dim_class dc
                                               INNER JOIN alefdw.dim_class_user dcu
                                                          ON dcu.class_user_class_dw_id = dc.class_dw_id
                                               INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                                          ON dc.class_school_id = dsc.school_id
                                               INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                                          ON dcu.class_user_user_dw_id = ds.student_dw_id
                                                              AND dsc.school_dw_id = ds.student_school_dw_id
                                                              AND ds.student_status = 1
                                               INNER JOIN alefdw.dim_grade dg
                                                          ON dg.grade_dw_id = ds.student_grade_dw_id
                                                              AND dsc.academic_year_id = dg.academic_year_id
                                                              AND dg.grade_status = 1
                                               LEFT JOIN alefdw.dim_course_subject_association dcsa
                                                         ON dcsa.cs_course_id = dc.class_material_id
                                                             AND dcsa.cs_status = 1
                                                             AND dcsa.cs_subject_dw_id IN (129, 503)
                                      WHERE dcu.class_user_status = 1
                                        AND dcu.class_user_role_dw_id = 2
                                        AND dcu.class_user_attach_status = 1
                                        AND dc.class_course_status = 'ACTIVE'
                                        AND dc.class_material_type = 'PATHWAY'
                                        AND dc.class_status = 1),

--total students who took adt
     pathway_adt_students AS (-- -- getting student' test last record by same learning session and attempt
         SELECT DISTINCT fasr_student_dw_id               adt_student_dw_id,
                         fasr_created_time                adt_created_time,
                         initcap(fasr_class_subject_name) class_gen_subject
         FROM alefdw.fact_adt_student_report fasr
         WHERE fasr_status = 1
           AND DATE(fasr_created_time) >= '2025-07-01'

         UNION

         SELECT DISTINCT candidate_dw_id AS adt_student_dw_id,
                         created_time    AS adt_created_time,
                         initcap(CASE
                                     WHEN framework = 'CEFR'
                                         THEN 'Arabits'
                                     ELSE subject
                             END)        AS class_gen_subject
         FROM alefdw.fact_candidate_assessment_progress fcap
         WHERE event_type = 'CandidateReportGeneratedDataEvent'
           and academic_year_tag = '2025-2026'

         UNION

         --ADDED THIRD UNION TO CATER FOR MISSING STUDENTS WITH NO ADT REPORT BUT ADT COMPLETED
         SELECT DISTINCT fle.fle_student_dw_id AS adt_student_dw_id,
                         fle.fle_created_time  AS adt_created_time,
                         CASE
                             WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry')
                                 THEN 'Science'
                             WHEN dcsa.cs_subject_dw_id IS NOT NULL
                                 THEN 'Arabits'
                             ELSE dc.class_gen_subject END
         FROM alefdw.fact_learning_experience fle
                  INNER JOIN bi_alefdw.bi_student_dim_mv ds
                             ON ds.student_dw_id = fle.fle_student_dw_id
                  INNER JOIN alefdw.dim_class dc
                             ON fle.fle_class_dw_id = dc.class_dw_id
                                 and class_status = 1
                  LEFT JOIN alefdw.dim_course_subject_association dcsa
                            ON md5(dcsa.cs_course_id) = md5(dc.class_material_id)
                                AND dcsa.cs_status = 1
                                AND dcsa.cs_subject_dw_id IN (129, 503)
         WHERE fle_lesson_category = 'DIAGNOSTIC_TEST'
           AND fle_exp_ls_flag IS FALSE),

     --unique adaptive practice events for current date
     adaptive_practive_events AS (SELECT DISTINCT created_time::DATE        AS local_date,
                                                  created_time              AS local_date_time,
                                                  pathway_dw_id,
                                                  class_dw_id,
                                                  school_dw_id,
                                                  student_dw_id,
                                                  student_id,
                                                  level_dw_id,
                                                  session_id                AS adaptive_practice_id,
                                                  question_skill_dw_id      AS skill_dw_id,
                                                  question_id,
                                                  attempt_number,
                                                  session_attempt,
                                                  is_answer_correct,
                                                  question_difficulty_label AS question_difficulty,
                                                  FIRST_VALUE(time_spent)
                                                  OVER (PARTITION BY student_dw_id, level_dw_id, level_proficiency_tier ORDER BY created_time DESC
                                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                                            AS time_spent_adaptive_practice,
                                                  time_spent_on_question,
                                                  level_proficiency_score,
                                                  level_proficiency_tier,
                                                  skill_proficiency_score,
                                                  skill_proficiency_tier,
                                                  hint_used,
                                                  academic_year_tag,
                                                  answer_score,
                                                  CASE
                                                      WHEN level_proficiency_score >= 0.75
                                                          THEN level_dw_id
                                                      END                   AS level_completed_dw_id,
                                                  CASE
                                                      WHEN level_proficiency_score >= 0.75
                                                          THEN FIRST_VALUE(created_time)
                                                               OVER (PARTITION BY student_dw_id, level_completed_dw_id ORDER BY created_time
                                                                   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                                                      END                   AS level_completed_date
                                  FROM alefdw.fact_adaptive_practice_progress ap
                                  WHERE event_type = 'AdaptivePracticeAnswerSubmittedEvent'),

     fact_adaptive_practice AS (SELECT DISTINCT apel.*
                                FROM adaptive_practive_events apel
                                WHERE (apel.student_dw_id, level_dw_id, skill_dw_id, question_id, attempt_number) IN
                                      (SELECT student_dw_id, level_dw_id, skill_dw_id, question_id, max(attempt_number)
                                       FROM adaptive_practive_events
                                       GROUP BY 1, 2, 3, 4)),

     fact_pathway_placement as (SELECT DISTINCT flr_created_time        AS fpp_created_time,
                                                flr_student_dw_id       AS fpp_student_dw_id,
                                                flr_course_dw_id        AS fpp_course_dw_id,
                                                course_id,
                                                flr_academic_year       AS fpp_academic_year,
                                                flr_recommendation_type AS fpp_placement_type
                                FROM (SELECT flr_created_time,
                                             flr_student_dw_id,
                                             flr_course_dw_id,
                                             flr_recommendation_type,
                                             flr_course_activity_container_dw_id,
                                             flr_academic_year,
                                             row_number()
                                             OVER (PARTITION BY flr_student_dw_id, flr_course_activity_container_dw_id, flr_academic_year ORDER BY flr_created_time) AS rank
                                      FROM alefdw.fact_levels_recommended
                                      WHERE flr_recommendation_type NOT IN (2, 3)
                                        AND flr_academic_year = '2025-2026') flr
                                         JOIN alefdw.dim_course dcr
                                              ON flr_course_dw_id = dcr.course_dw_id
                                where flr.rank = 1
                                  AND dcr.course_status = 1),

     pathway_events AS (SELECT local_date,
                               local_date_time,
                               pathway_dw_id,
                               class_dw_id,
                               student_dw_id,
                               level_dw_id,
                               skill_dw_id         AS activity_dw_id,
                               time_spent_adaptive_practice,
                               level_completed_dw_id,
                               level_completed_date,
                               answer_score,
                               question_id,
                               attempt_number,
                               session_attempt,
                               is_answer_correct,
                               question_difficulty,
                               time_spent_on_question,
                               level_proficiency_score,
                               level_proficiency_tier,
                               skill_proficiency_score,
                               skill_proficiency_tier,
                               hint_used,
                               academic_year_tag,
                               adaptive_practice_id,
                               'ADAPTIVE PRACTICE' AS activity_type,
                               NULL                AS activity_status
                        FROM fact_adaptive_practice),

     skill_proficiency_update AS (SELECT DISTINCT student_dw_id,
                                                  skill_dw_id,
                                                  academic_year_tag,
                                                  skill_proficiency_tier,
                                                  skill_proficiency_score,
                                                  previous_proficiency_tier,
                                                  status,
                                                  created_time::DATE update_date
                                  FROM alefdw.fact_student_proficiency_tracker
                                  WHERE event_type = 'SkillProficiencyUpdatedEvent'),

     level_proficiency_update AS (SELECT DISTINCT student_dw_id,
                                                  level_dw_id,
                                                  academic_year_tag,
                                                  level_proficiency_tier,
                                                  level_proficiency_score,
                                                  previous_proficiency_tier,
                                                  status,
                                                  created_time::date update_date
                                  FROM alefdw.fact_student_proficiency_tracker
                                  WHERE event_type = 'LevelProficiencyUpdatedEvent'),

     skill_gap_tracker AS (SELECT student_dw_id,
                                  skill_dw_id,
                                  skill_gap_number,
                                  LISTAGG(status, ',') WITHIN GROUP (ORDER BY created_time)       AS skill_gap_status,
                                  LISTAGG(created_time, ',') WITHIN GROUP (ORDER BY created_time) AS skill_gap_created_time
                           FROM (SELECT DISTINCT student_dw_id,
                                                 skill_dw_id,
                                                 status,
                                                 created_time,
                                                 row_number()
                                                 OVER (PARTITION BY student_dw_id, skill_dw_id, status ORDER BY created_time) skill_gap_number
                                 FROM alefdw.fact_pathway_skill_gap_tracker) sgt
                           group by 1, 2, 3)
SELECT DISTINCT pcts.tenant_id,
                pcts.tenant_name,
                pcts.organisation_dw_id,
                pcts.school_organisation,
                pcts.school_composition,
                pcts.school_dw_id,
                pcts.school_name,
                pcts.school_label,
                pcts.student_grade_dw_id,
                pcts.grade_name,
                pcts.pathway_student_dw_id,
                pcts.student_special_needs,
                pcts.academic_year_start_date,
                pcts.academic_year_end_date,
                cast((extract(YEAR FROM pcts.academic_year_start_date) || '-' ||
                      extract(YEAR FROM pcts.academic_year_end_date)) AS VARCHAR)   AS academic_year,
                dcr.course_dw_id,
                dcr.course_name                                                     AS pathway_name,
                dcr.course_lang_code                                                AS pathway_lang_code,
                pcts.curr_subject_name,
                dcac.course_activity_container_dw_id                                AS pathway_level_dw_id,
                pnadt.adt_student_dw_id,
                pnadt.class_gen_subject                                             AS adt_subject_name,
                pnadt.adt_created_time::DATE                                        AS adt_completed_date,
                fpp.fpp_student_dw_id,
                fpp.fpp_course_dw_id,
                fpp.fpp_placement_type,
                fpp.fpp_created_time::DATE                                          AS placement_date,
                path.local_date                                                     AS pathway_activity_date,
                path.local_date_time                                                AS pathway_activity_time,
                convert_timezone('UTC', pcts.tenant_timezone, path.local_date_time) AS pathway_activity_date_local,
                path.pathway_dw_id,
                path.class_dw_id,
                path.student_dw_id,
                path.level_dw_id,
                path.activity_dw_id,  --skill dw id
                path.time_spent_adaptive_practice,
                dcr.course_placement_type                                           AS course_placement_type,
                path.level_completed_dw_id,
                path.level_completed_date,
                convert_timezone('UTC', pcts.tenant_timezone,
                                 path.level_completed_date)                         AS level_completed_date_local,
                path.answer_score,
                path.question_id,
                path.attempt_number,
                path.session_attempt,
                path.is_answer_correct,
                path.question_difficulty,
                path.time_spent_on_question,
                path.level_proficiency_score,
                path.level_proficiency_tier,
                path.skill_proficiency_score,
                path.skill_proficiency_tier,
                path.hint_used,
                path.academic_year_tag,
                path.adaptive_practice_id,
                path.activity_type                                                  AS pathway_activity_type,
                path.activity_status, --only for teacher assigned activities
                spu.status                                                          AS skill_proficiency_status,
                spu.previous_proficiency_tier                                       AS skill_previous_proficiency_tier,
                spu.update_date                                                     AS skill_proficiency_update_date,
                lpu.status                                                          AS level_proficiency_status,
                lpu.previous_proficiency_tier                                       AS level_previous_proficiency_tier,
                lpu.update_date                                                     AS level_proficiency_update_date,
                SPLIT_PART(sgt.skill_gap_status, ',', 1)                            AS is_skill_gap_introduced,
                SPLIT_PART(sgt.skill_gap_created_time, ',', 1)                      AS skill_gap_introduced_time,
                SPLIT_PART(sgt.skill_gap_status, ',', 2)                            AS is_skill_gap_resolved,
                SPLIT_PART(sgt.skill_gap_created_time, ',', 2)                      AS skill_gap_resolved_time
FROM pathway_class_total_students pcts
         LEFT JOIN alefdw.dim_course dcr
                   ON fnv_hash(pcts.class_material_id) = fnv_hash(dcr.course_id)
                       AND dcr.course_status = 1
                       AND dcr.course_type = 'PATHWAY'
         LEFT JOIN fact_pathway_placement fpp
                   ON fpp.fpp_student_dw_id = pcts.pathway_student_dw_id
                       AND pcts.class_material_id = fpp.course_id
                       AND pcts.academic_year = fpp.fpp_academic_year
         LEFT JOIN pathway_events path
                   ON path.student_dw_id = pcts.pathway_student_dw_id
                       AND path.pathway_dw_id = dcr.course_dw_id
                       AND local_date BETWEEN
                          pcts.academic_year_start_date and pcts.academic_year_end_date
         LEFT JOIN skill_proficiency_update spu
                   ON spu.student_dw_id = path.student_dw_id
                       AND spu.skill_dw_id = path.activity_dw_id
                       AND spu.skill_proficiency_score = path.skill_proficiency_score
                       AND path.activity_type = 'ADAPTIVE PRACTICE'
         LEFT JOIN level_proficiency_update lpu
                   ON lpu.student_dw_id = path.student_dw_id
                       AND lpu.level_dw_id = path.level_dw_id
                       AND lpu.level_proficiency_score = path.level_proficiency_score
                       AND path.activity_type = 'ADAPTIVE PRACTICE'
         LEFT JOIN skill_gap_tracker sgt
                   ON sgt.student_dw_id = path.student_dw_id
                       AND sgt.skill_dw_id = path.activity_dw_id
                       AND path.activity_type = 'ADAPTIVE PRACTICE'
         LEFT JOIN alefdw.dim_course_activity_container dcac
                   ON md5(dcac.course_activity_container_course_id) = md5(dcr.course_id)
                       AND dcac.course_activity_container_dw_id = path.level_dw_id
                       AND dcac.course_activity_container_status = 1
                       AND dcac.course_activity_container_attach_status = 1
         LEFT JOIN pathway_adt_students pnadt
                   ON pcts.pathway_student_dw_id = pnadt.adt_student_dw_id
                       AND lower(pcts.curr_subject_name) = lower(pnadt.class_gen_subject)
                       AND DATE(pnadt.adt_created_time) BETWEEN
                          pcts.academic_year_start_date AND pcts.academic_year_end_date;