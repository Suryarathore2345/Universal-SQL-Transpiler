CREATE OR REPLACE VIEW eagles_alefdw_dev.pathway_nlf_principal_dm_view AS
WITH pathway_class_total_students AS (SELECT dsc.school_dw_id,
                                             dsc.school_id,
                                             dsc.school_name,
                                             dsc.tenant_timezone,
                                             dsc.academic_year_start_date,
                                             dsc.academic_year_end_date,
                                             date_part('year', dsc.academic_year_start_date) || '-' ||
                                             date_part('year', dsc.academic_year_end_date) AS academic_year,
                                             dcu.class_user_user_dw_id                     AS pathway_student_dw_id,
                                             ds.student_id,
                                             ds.student_grade_dw_id,
                                             dg.grade_k12grade                             AS grade_name,
                                             dg.grade_id,
                                             sc.section_alias,
                                             CASE
                                                 WHEN dc.class_gen_subject IN ('Physics', 'Biology', 'Chemistry')
                                                     THEN 'Science'
                                                 WHEN dcsa.cs_subject_dw_id IS NOT NULL THEN 'Arabits'
                                                 ELSE dc.class_gen_subject
                                                 END                                       AS subject_name,
                                             dc.class_material_id,
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
     students_placed AS (SELECT DISTINCT cr.course_id,
                                         fpp_student_dw_id AS placed_student_dw_id
                         FROM alefdw.fact_pathway_placement fpp
                                  INNER JOIN alefdw.dim_course cr
                                             ON cr.course_dw_id = fpp.fpp_course_dw_id
                                                 AND cr.course_status = 1),
     adaptive_practice_fact AS (SELECT student_dw_id,
                                       pathway_id,
                                       level_dw_id,
                                       DATE_TRUNC('month', created_time) AS month,
                                       level_proficiency_tier,
                                       ROW_NUMBER() OVER (
                                           PARTITION BY student_dw_id, pathway_id, level_dw_id, DATE_TRUNC('month', created_time)
                                           ORDER BY created_time DESC
                                           )                             AS rn
                                FROM alefdw.fact_adaptive_practice_progress
                                WHERE event_type = 'AdaptivePracticeAnswerSubmittedEvent'
                                QUALIFY rn = 1),
     skills_started_fact AS (SELECT slp.student_dw_id,
                                    caa.caa_container_dw_id,
                                    caa.caa_course_id,
                                    date_trunc('month', slp.created_time) AS month,
                                    COUNT(DISTINCT slp.skill_dw_id)       AS skills_started
                             FROM alefdw.fact_pathway_skill_learning_progress slp
                                      INNER JOIN alefdw.dim_course_activity_association caa
                                                 ON caa.caa_course_id = slp.material_id
                                                     AND caa.caa_activity_dw_id = slp.skill_dw_id
                             WHERE event_type = 'SkillExperienceStarted'
                             GROUP BY 1, 2, 3, 4),
     skills_active_fact AS (select slp.student_dw_id,
                                   caa.caa_container_dw_id,
                                   caa.caa_course_id,
                                   date_trunc('month', slp.created_time) as month,
                                   COUNT(DISTINCT slp.skill_dw_id)       as skills_active
                            from alefdw.fact_pathway_skill_learning_progress slp
                                     INNER JOIN alefdw.dim_course_activity_association caa
                                                ON caa.caa_course_id = slp.material_id
                                                    AND caa.caa_activity_dw_id = slp.skill_dw_id
                            where event_type = 'SkillExperienceFinished'
                            group by 1, 2, 3, 4),
     skills_to_review AS (SELECT student_dw_id,
                                 level_dw_id,
                                 date_trunc('month', sgt.created_time) as month,
                                 COUNT(distinct skill_dw_id)           AS skills_to_review
                          FROM alefdw.fact_pathway_skill_gap_tracker sgt
                          WHERE status = 'INTRODUCED'
                            AND NOT EXISTS(SELECT 1
                                           FROM alefdw.fact_pathway_skill_gap_tracker sgt2
                                           WHERE sgt.student_dw_id = sgt2.student_dw_id
                                             AND sgt.skill_dw_id = sgt2.skill_dw_id
                                             AND sgt2.status = 'RESOLVED')
                          GROUP BY 1, 2, 3),
     fact_table AS (SELECT COALESCE(ap.student_dw_id, sk.student_dw_id) AS started_student_dw_id,
                           COALESCE(ap.student_dw_id, sa.student_dw_id) AS active_student_dw_id,
                           COALESCE(ap.pathway_id, sk.caa_course_id)    AS course_id,
                           ap.level_dw_id,
                           COALESCE(ap.month, sk.month)::DATE           AS month,
                           level_proficiency_tier,
                           skills_started,
                           skills_active,
                           skills_to_review
                    FROM skills_started_fact sk
                             FULL OUTER JOIN adaptive_practice_fact ap
                                             ON ap.student_dw_id = sk.student_dw_id
                                                 AND ap.level_dw_id = sk.caa_container_dw_id
                                                 AND ap.month = sk.month
                             LEFT JOIN skills_active_fact sa
                                       ON sk.student_dw_id = sa.student_dw_id
                                           AND sk.caa_container_dw_id = sa.caa_container_dw_id
                                           AND sk.month = sa.month
                             LEFT JOIN skills_to_review str
                                       ON ap.student_dw_id = str.student_dw_id
                                           AND ap.level_dw_id = str.level_dw_id
                                           AND ap.month = str.month)
SELECT pcts.*,
       sp.placed_student_dw_id,
       ft.*,
       dcac.course_activity_container_domain   AS domain,
       dcac.course_activity_container_longname AS level_name
FROM pathway_class_total_students pcts
         LEFT JOIN students_placed sp
                   ON sp.course_id = pcts.class_material_id
                       AND sp.placed_student_dw_id = pcts.pathway_student_dw_id
         LEFT JOIN fact_table ft
                   ON pcts.class_material_id = ft.course_id
                       AND pcts.pathway_student_dw_id = ft.started_student_dw_id
                       AND ft.month
                          BETWEEN date_trunc('month', academic_year_start_date) AND date_trunc('month', academic_year_end_date)
         LEFT JOIN alefdw.dim_course_activity_container dcac
                   ON dcac.course_activity_container_dw_id = ft.level_dw_id
                       AND dcac.course_activity_container_status = 1
WITH NO SCHEMA BINDING;