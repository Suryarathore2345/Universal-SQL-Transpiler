CREATE OR REPLACE VIEW eagles_alefdw_dev.pathway_nlf_teacher_agg_view AS
WITH pathway_class_total_students AS (SELECT DISTINCT dsc.school_dw_id,
                                                      dsc.school_id,
                                                      dsc.school_name,
                                                      dsc.academic_year_start_date,
                                                      dsc.academic_year_end_date,
                                                      date_part('year', dsc.academic_year_start_date) || '-' ||
                                                      date_part('year', dsc.academic_year_end_date) AS academic_year,
                                                      dcu.class_user_user_dw_id                     AS pathway_student_dw_id,
                                                      dg.grade_k12grade                             AS grade_name,
                                                      sc.section_alias,
                                                      CASE
                                                          WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry')
                                                              THEN 'Science'
                                                          WHEN dcsa.cs_subject_dw_id IS NOT NULL THEN 'Arabits'
                                                          ELSE dc.class_gen_subject
                                                          END                                       AS subject_name,
                                                      class_title,
                                                      class_dw_id
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
                                               INNER JOIN alefdw.dim_section sc
                                                          ON ds.student_section_dw_id = sc.section_dw_id
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

     adaptive_practice_fact AS (SELECT DISTINCT ap.student_dw_id,
                                                ap.class_dw_id,
                                                ap.pathway_dw_id,
                                                CAST(ap.created_time AS DATE) AS ap_created_date
                                FROM alefdw.fact_adaptive_practice_progress ap
                                WHERE event_type = 'AdaptivePracticeAnswerSubmittedEvent'),

     skills_active_fact AS (SELECT DISTINCT slp.student_dw_id,
                                            slp.class_dw_id,
                                            slp.material_dw_id,
                                            CAST(slp.created_time AS DATE) AS saf_created_date
                            FROM alefdw.fact_pathway_skill_learning_progress slp
                            WHERE event_type = 'SkillExperienceFinished'),

     skills_started_fact AS (SELECT DISTINCT slp.student_dw_id,
                                             slp.class_dw_id,
                                             slp.material_dw_id,
                                             CAST(slp.created_time AS DATE) AS ssf_created_date
                             FROM alefdw.fact_pathway_skill_learning_progress slp
                             WHERE event_type = 'SkillExperienceStarted'),

     skills_gaps_introduced AS (SELECT student_dw_id,
                                       class_dw_id,
                                       pathway_dw_id,
                                       CAST(sgt.created_time AS DATE) AS sgi_created_date,
                                       COUNT(DISTINCT skill_dw_id)    AS skill_gaps
                                FROM alefdw.fact_pathway_skill_gap_tracker sgt
                                WHERE status = 'INTRODUCED'
                                  AND NOT EXISTS(SELECT 1
                                                 FROM alefdw.fact_pathway_skill_gap_tracker sgt2
                                                 WHERE sgt.student_dw_id = sgt2.student_dw_id
                                                   AND sgt.skill_dw_id = sgt2.skill_dw_id
                                                   AND sgt2.status = 'RESOLVED')
                                GROUP BY student_dw_id,
                                         class_dw_id,
                                         sgi_created_date,
                                         pathway_dw_id),

     students_agg
         AS (SELECT DISTINCT COALESCE(ssf.ssf_created_date, saf.saf_created_date, ap.ap_created_date) AS created_date,
                             COALESCE(ssf.class_dw_id, saf.class_dw_id, ap.class_dw_id)               AS class_dw_id,
                             COALESCE(ssf.material_dw_id, saf.material_dw_id, ap.pathway_dw_id)       AS course_dw_id,
                             COALESCE(ssf.student_dw_id, saf.student_dw_id, ap.student_dw_id)         AS started_student_dw_id,
                             COALESCE(saf.student_dw_id, ap.student_dw_id)                            AS active_student_dw_id,
                             skill_gaps
             FROM skills_started_fact ssf
                      FULL OUTER JOIN adaptive_practice_fact ap
                                      ON ap.student_dw_id = ssf.student_dw_id
                                          AND ap.class_dw_id = ssf.class_dw_id
                                          AND ap.ap_created_date = ssf.ssf_created_date
                      FULL OUTER JOIN skills_active_fact saf
                                      ON ssf.student_dw_id = saf.student_dw_id
                                          AND ssf.class_dw_id = saf.class_dw_id
                                          AND ssf.ssf_created_date = saf.saf_created_date
                      LEFT JOIN skills_gaps_introduced sgi
                                ON ap.student_dw_id = sgi.student_dw_id
                                    AND ap.class_dw_id = sgi.class_dw_id
                                    AND ap.ap_created_date = sgi.sgi_created_date),

     students_agg_monthly AS (SELECT agg.class_dw_id,
                                     agg.course_dw_id,
                                     CAST(DATE_TRUNC('month', agg.created_date) AS DATE) AS activity_month,
                                     agg.started_student_dw_id,
                                     agg.active_student_dw_id,
                                     SUM(agg.skill_gaps)                                 AS skill_gaps,
                                     COUNT(DISTINCT CASE
                                                        WHEN active_student_dw_id IS NOT NULL
                                                            THEN agg.created_date END)   AS active_days
                              FROM students_agg agg
                              GROUP BY agg.class_dw_id,
                                       agg.course_dw_id,
                                       activity_month,
                                       agg.started_student_dw_id,
                                       agg.active_student_dw_id)

SELECT pct.teacher_id,
       pcts.section_alias,
       pcts.grade_name,
       pcts.school_name,
       pcts.school_dw_id,
       pcts.school_id,
       pcts.academic_year,
       pcts.subject_name,
       pcts.class_dw_id,
       pcts.class_title,
       activity_month,
       active_student_dw_id,
       started_student_dw_id,
       skill_gaps,
       active_days
FROM pathway_class_total_students pcts
         JOIN students_agg_monthly sda
              ON pcts.pathway_student_dw_id = sda.started_student_dw_id
                  AND pcts.class_dw_id = sda.class_dw_id
                  AND sda.activity_month
                     BETWEEN date_trunc('month', academic_year_start_date) AND date_trunc('month', academic_year_end_date)
         LEFT JOIN eagles_alefdw.pathway_class_teacher pct
                   ON pct.class_dw_id = sda.class_dw_id
WITH NO SCHEMA BINDING;