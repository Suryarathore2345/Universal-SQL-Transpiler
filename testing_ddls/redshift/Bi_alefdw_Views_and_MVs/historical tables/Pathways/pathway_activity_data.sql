DROP TABLE IF EXISTS bi_alefdw_dev.pathway_activity_data;
CREATE TABLE bi_alefdw_dev.pathway_activity_data as

WITH fact_levels_recommended AS (SELECT flr_created_time,
                                        flr_course_dw_id,
                                        flr_level_dw_id,
                                        flr_class_dw_id,
                                        flr_student_dw_id,
                                        flr_course_activity_container_dw_id,
                                        caa_activity_dw_id,
                                        caa_activity_type,
                                        flr_recommendation_type
                                 FROM (SELECT flr_created_time,
                                              flr_course_dw_id,
                                              flr_level_dw_id,
                                              flr_class_dw_id,
                                              flr_student_dw_id,
                                              flr_course_activity_container_dw_id,
                                              caa_activity_dw_id,
                                              caa_activity_type,
                                              flr_recommendation_type,
                                              ROW_NUMBER() OVER (
                                                  PARTITION BY flr_student_dw_id,
                                                      caa_activity_dw_id ORDER BY flr_created_time
                                                  ) AS rank
                                       FROM alefdw.fact_levels_recommended flr
                                                INNER JOIN alefdw.dim_course_activity_association dccaa
                                                           ON dccaa.caa_container_dw_id =
                                                              flr.flr_course_activity_container_dw_id
                                                               AND dccaa.caa_status = 1
                                                               AND flr_status = 1) flrdplaa
                                 WHERE flrdplaa.rank = 1),
     fact_teacher_activity AS (SELECT fpta_created_time                    AS flr_created_time,
                                      fpta_course_dw_id                    AS flr_course_dw_id,
                                      fpta_class_dw_id                     AS flr_class_dw_id,
                                      fpta_student_dw_id                   AS flr_student_dw_id,
                                      fpta_course_activity_container_dw_id AS flr_course_activity_container_dw_id,
                                      fpta_activity_dw_id                  AS caa_activity_dw_id,
                                      fpta_activity_type                   AS caa_activity_type,
                                      -1                                   AS flr_recommendation_type -- integer code for flr_recommendation_type (modified to fit values less than 4)
                               FROM (SELECT fpta_created_time,
                                            fpta_pathway_dw_id,
                                            fpta_course_dw_id,
                                            fpta_class_dw_id,
                                            fpta_student_dw_id,
                                            fpta_level_dw_id,
                                            fpta_course_activity_container_dw_id,
                                            fpta_activity_dw_id,
                                            fpta_activity_type,
                                            fpta_action_name,
                                            ROW_NUMBER() OVER (
                                                PARTITION BY fpta_student_dw_id,
                                                    fpta_activity_dw_id ORDER BY fpta_created_time DESC
                                                ) AS rank
                                     FROM alefdw.fact_pathway_teacher_activity) fpta
                               WHERE fpta.fpta_action_name = 1
                                 AND fpta.fpta_student_dw_id IN
                                     (SELECT DISTINCT flr_student_dw_id
                                      FROM fact_levels_recommended) --only taking teacher activities for placed students
                                 AND fpta.rank = 1),

     fact_levels_recommended_last AS (SELECT flr_created_time,
                                             flr_course_dw_id,
                                             flr_class_dw_id,
                                             flr_student_dw_id,
                                             flr_course_activity_container_dw_id,
                                             caa_activity_dw_id,
                                             caa_activity_type,
                                             flr_recommendation_type
                                      FROM fact_levels_recommended
                                      UNION ALL
                                      SELECT flr_created_time,
                                             flr_course_dw_id,
                                             flr_class_dw_id,
                                             flr_student_dw_id,
                                             flr_course_activity_container_dw_id,
                                             caa_activity_dw_id,
                                             caa_activity_type,
                                             flr_recommendation_type
                                      FROM fact_teacher_activity),
     fact_pathway_activity_completed_last AS ( -- to take latest attempt of completed activity
         SELECT *
         FROM (SELECT fpac.fpac_learning_session_id,
                      fpac.fpac_attempt,
                      fpac.fpac_activity_dw_id,
                      fpac.fpac_created_time,
                      fpac.fpac_student_dw_id,
                      fpac.fpac_score,
                      ROW_NUMBER() OVER (
                          PARTITION BY fpac_learning_session_id ORDER BY fpac_attempt DESC
                          ) AS rank
               FROM alefdw.fact_pathway_activity_completed fpac
                        INNER JOIN alefdw.dim_course_activity_association dccaa
                                   ON dccaa.caa_activity_dw_id = fpac.fpac_activity_dw_id
                                       AND dccaa.caa_status = 1) x
         WHERE rank = 1),
     fact_learning_experience_last AS (SELECT *
                                       FROM (SELECT fle_lesson_category,
                                                    fle_total_time,
                                                    fle_created_time,
                                                    fle_student_dw_id,
                                                    fle_lo_dw_id,
                                                    fle_ls_id,
                                                    fle_attempt,
                                                    fle_total_score,
                                                    fle_exp_id,
                                                    fle_abbreviation,
                                                    SUM((CASE
                                                             WHEN fle_lesson_category = 'INTERIM_CHECKPOINT' THEN
                                                                 CASE
                                                                     WHEN fle.fle_total_time >= 0 AND fle.fle_total_time <= 1200
                                                                         THEN fle.fle_total_time
                                                                     WHEN fle.fle_total_time > 1200 THEN 1200
                                                                     ELSE 0
                                                                     END
                                                             WHEN fle_lesson_category = 'INSTRUCTIONAL_LESSON' THEN
                                                                 CASE
                                                                     WHEN fle.fle_total_time >= 0 AND fle.fle_total_time <= 900
                                                                         THEN fle.fle_total_time
                                                                     WHEN fle.fle_total_time > 900 THEN 900
                                                                     ELSE 0
                                                                     END
                                                        END))
                                                        OVER (PARTITION BY trunc(fle_created_time),fle_student_dw_id,fle_lo_dw_id) AS calc_fle_total_time, MAX((CASE
                                                                                                                                                                    WHEN fle_lesson_category = 'INTERIM_CHECKPOINT'
                                                                                                                                                                        THEN
                                                                                                                                                                        CASE
                                                                                                                                                                            WHEN fle.fle_total_time > 1200
                                                                                                                                                                                THEN 1
                                                                                                                                                                            ELSE 0
                                                                                                                                                                            END
                                                                                                                                                                    WHEN fle_lesson_category = 'INSTRUCTIONAL_LESSON'
                                                                                                                                                                        THEN
                                                                                                                                                                        CASE
                                                                                                                                                                            WHEN fle.fle_total_time > 900
                                                                                                                                                                                THEN 1
                                                                                                                                                                            ELSE 0
                                                                                                                                                                            END
                                                   END))
                                                   OVER (PARTITION BY trunc(fle_created_time),fle_student_dw_id,fle_lo_dw_id) AS calc_capped_time_flag, ROW_NUMBER() OVER (
                                                        PARTITION BY fle_ls_id ORDER BY fle_created_time DESC, fle_attempt DESC
                                                        )                                                                      AS rank
                                             FROM alefdw.fact_learning_experience fle
                                             WHERE fle_material_type = 'PATHWAY'
                                               AND fle_abbreviation <> 'NA'
                                               AND fle_lesson_category <> 'DIAGNOSTIC_TEST') fle
                                       WHERE rank = 1),
     pathway_adt_students as (SELECT distinct fle.fle_student_dw_id             AS adt_student_dw_id,
                                              CASE
                                                  WHEN dcsa.cs_subject_dw_id = 129 THEN 'Arabits'
                                                  ELSE dc.class_gen_subject END AS class_gen_subject,
                                              fle.fle_created_time
                              FROM alefdw.fact_learning_experience fle
                                       INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                                  ON ds.student_dw_id = fle.fle_student_dw_id
                                       INNER JOIN alefdw.dim_class dc
                                                  ON fle.fle_class_dw_id = dc.class_dw_id
                                       LEFT JOIN alefdw.dim_course_subject_association dcsa
                                                 ON md5(dcsa.cs_course_id) = md5(dc.class_material_id)
                                                     AND dcsa.cs_status = 1
                                                     AND dcsa.cs_subject_dw_id = 129
                              WHERE fle_lesson_category = 'DIAGNOSTIC_TEST'
                                AND fle_is_activity_completed = TRUE
                                AND fle_exp_id = 'n/a'),
     pathway_class_total_students as (SELECT dsc.school_dw_id,
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
                                                 WHEN dcsa.cs_subject_dw_id = 129 THEN 'Arabits'
                                                 ELSE dc.class_gen_subject END             AS curr_subject_name,
                                             dc.class_curriculum_subject_id                AS curr_subject_id,
                                             dc.class_material_id,
                                             date_part('year', dsc.academic_year_end_date) AS academic_year_end_year
                                      FROM alefdw.dim_class dc
                                               INNER JOIN alefdw.dim_class_user dcu
                                                          ON dcu.class_user_class_dw_id = dc.class_dw_id
                                               INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                                          ON MD5(dc.class_school_id) = MD5(dsc.school_id)
                                                              AND dsc.academic_year_id = dc.class_academic_year_id
                                               INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                                          ON dcu.class_user_user_dw_id = ds.student_dw_id
                                                              AND dsc.school_dw_id = ds.student_school_dw_id
                                                              AND ds.student_status = 1
                                               INNER JOIN alefdw.dim_grade dg
                                                          ON dg.grade_dw_id = ds.student_grade_dw_id
                                                              AND md5(dsc.academic_year_id) = md5(dg.academic_year_id)
                                                              AND dg.grade_status = 1
                                               LEFT JOIN alefdw.dim_course_subject_association dcsa
                                                         ON md5(dcsa.cs_course_id) = md5(dc.class_material_id)
                                                             AND dcsa.cs_status = 1
                                                             AND dcsa.cs_subject_dw_id = 129
                                      WHERE dcu.class_user_status = 1
                                        AND dcu.class_user_role_dw_id = 2
                                        AND dcu.class_user_attach_status = 1
                                        AND dc.class_course_status = 'ACTIVE'
                                        AND dc.class_material_type = 'PATHWAY'
                                        AND dc.class_status = 1)
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
                pcts.academic_year_end_year,
                fle.fle_student_dw_id                                               AS active_student_dw_id,
                dcr.course_dw_id                                                    AS pathway_dw_id,
                dcr.course_name                                                     AS pathway_name,
                dcr.course_lang_code                                                AS pathway_lang_code,
                pcts.curr_subject_name,
                dcac.course_activity_container_dw_id                                AS pathway_level_dw_id,
                flr.flr_class_dw_id,
                flr.caa_activity_dw_id                                              AS plaa_activity_dw_id,
                flr.flr_student_dw_id,
                pnadt.adt_student_dw_id,
                convert_timezone('UTC', pcts.tenant_timezone, flr.flr_created_time) AS flr_created_time,
                flc.flc_course_activity_container_dw_id                             AS level_dw_id_completed,
                convert_timezone('UTC', pcts.tenant_timezone, flc.flc_created_time) AS level_completed_time,
                fpac.fpac_learning_session_id,
                fpac.fpac_activity_dw_id,
                fpac.fpac_created_time                                              AS activity_completed_time,
                trunc(fpac.fpac_created_time)                                       AS activity_date,
                convert_timezone('UTC', pcts.tenant_timezone,
                                 fpac.fpac_created_time)                            AS activity_completed_time_local,
                fpac.fpac_student_dw_id,
                fpac.fpac_score,
                fpac.fpac_attempt,
                fle.calc_fle_total_time                                             AS fle_total_time,
                fle.calc_capped_time_flag                                           AS fle_capped_time_flag,
                fle.fle_total_score,
                fle_exp_id,
                trunc(fle.fle_created_time)                                         AS fle_activity_date,
                convert_timezone('UTC', pcts.tenant_timezone, fle.fle_created_time) AS fle_activity_time_local,
                fle_abbreviation,
                fle.fle_attempt, -- to be removed later -  fpac.fpac_attempt has an issue at the moment
                CASE flr.caa_activity_type
                    WHEN 1 THEN 'ACTIVITY'
                    WHEN 2 THEN 'INTERIM_CHECKPOINT' END                            AS activity_type,
                flr.flr_recommendation_type,
                CASE
                    WHEN (flr.flr_recommendation_type < 4 AND curr_subject_name <> 'Science')
                        THEN 'BY DIAGNOSTIC TEST'
                    WHEN (flr.flr_recommendation_type < 4 AND curr_subject_name = 'Science')
                        THEN 'AT GRADE LEVEL'
                    WHEN flr.flr_recommendation_type = 4
                        THEN 'MANUALLY'
                    WHEN flr.flr_recommendation_type = 5
                        THEN 'AT GRADE LEVEL'
                    WHEN flr.flr_recommendation_type = 6
                        THEN 'AT BEGINNING OF COURSE'
                    END                                                             AS placement_type,
                CASE
                    WHEN flr.caa_activity_dw_id IS NOT NULL THEN
                        CASE
                            WHEN fpac.fpac_student_dw_id IS NOT NULL
                                THEN 'COMPLETED'
                            WHEN fle.fle_student_dw_id IS NOT NULL AND fpac.fpac_student_dw_id IS NULL
                                THEN 'IN PROGRESS'
                            WHEN flr.flr_student_dw_id IS NOT NULL AND fle.fle_student_dw_id IS NULL
                                THEN 'NON STARTED'
                            END
                    END                                                             AS activity_status,
                (6.0 - flf.lesson_feedback_rating)                                  AS lesson_feedback_rate
FROM pathway_class_total_students pcts
         LEFT JOIN alefdw.dim_course dcr
                   ON pcts.class_material_id = dcr.course_id
                       AND dcr.course_status = 1
                       AND dcr.course_type = 'PATHWAY'
         LEFT JOIN fact_levels_recommended_last flr
                   ON pcts.pathway_student_dw_id = flr.flr_student_dw_id
                       AND dcr.course_dw_id = flr.flr_course_dw_id
         LEFT JOIN alefdw.dim_course_activity_container dcac
                   ON md5(dcac.course_activity_container_course_id) = md5(dcr.course_id)
                       AND dcac.course_activity_container_dw_id = flr.flr_course_activity_container_dw_id
                       AND dcac.course_activity_container_status = 1
                       AND dcac.course_activity_container_attach_status = 1
         LEFT JOIN alefdw.fact_level_completed flc
                   ON flc.flc_course_activity_container_dw_id = flr.flr_course_activity_container_dw_id
                       AND flc.flc_student_dw_id = flr.flr_student_dw_id
         LEFT JOIN fact_pathway_activity_completed_last fpac
                   ON fpac.fpac_student_dw_id = flr.flr_student_dw_id
                       AND fpac.fpac_activity_dw_id = flr.caa_activity_dw_id
         LEFT JOIN fact_learning_experience_last fle
                   ON fle.fle_student_dw_id = flr.flr_student_dw_id
                       AND fle.fle_lo_dw_id = flr.caa_activity_dw_id
                       AND trunc(fle.fle_created_time) >= pcts.academic_year_start_date
                       AND trunc(fle.fle_created_time) < pcts.academic_year_end_date
         LEFT JOIN alefdw.fact_lesson_feedback flf
                   ON flf.lesson_feedback_lo_dw_id = fpac.fpac_activity_dw_id
                       AND flf.lesson_feedback_student_dw_id = fpac.fpac_student_dw_id
                       AND flf.lesson_feedback_rating > 0
         LEFT JOIN pathway_adt_students pnadt
                   ON pcts.pathway_student_dw_id = pnadt.adt_student_dw_id
                       AND pcts.curr_subject_name = pnadt.class_gen_subject;