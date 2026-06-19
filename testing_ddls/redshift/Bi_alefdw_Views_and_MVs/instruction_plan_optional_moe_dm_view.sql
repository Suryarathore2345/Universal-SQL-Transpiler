CREATE OR REPLACE VIEW bi_alefdw_dev.instruction_plan_optional_moe_dm_view
AS

WITH Learning_Objective as (SELECT lo_dw_id, lo_code, lo_title, lo_created_time
                            FROM alefdw.dim_learning_objective dip_dlo
                            WHERE nvl(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
                              AND lo_status = 1
                              AND lo_code in
                                  ('CD_MLO_001_EN_V1', 'CD_MLO_002_EN_V1', 'CD_MLO_003_EN_V1', 'CD_MLO_004_EN_V1',
                                   'CD_MLO_005_EN_V1',
                                   'CD_MLO_001_AR', 'CD_MLO_002_AR', 'CD_MLO_003_AR', 'CD_MLO_004_AR',
                                   'CD_MLO_005_AR'
                                      )),

     Civil_lo AS (SELECT DISTINCT caa_course_id,
                                  lo_code,
                                  caa_course_dw_id,
                                  caa_created_time,
                                  caa_activity_id,
                                  caa_activity_dw_id,
                                  caa_activity_pacing,
                                  caa_activity_is_optional,
                                  caa_activity_type,
                                  caa_attach_status,
                                  caa_status,
                                  ROW_NUMBER()
                                  OVER (PARTITION BY caa_course_id, caa_activity_id ORDER BY caa_created_time DESC) AS rank
                  FROM alefdw.dim_course_activity_association
                           INNER JOIN Learning_Objective
                                      ON caa_activity_dw_id = lo_dw_id
                                          AND caa_activity_is_optional = TRUE
                  WHERE TRUE
                  QUALIFY rank = 1),

     academic_year AS (SELECT school_dw_id,
                              MAX(date_part_year(academic_year_end_date)) AS max_year
                       FROM bi_alefdw.bi_all_schools_dim_mv
                       GROUP BY school_dw_id),

     class_teachers AS (SELECT dc.class_dw_id,
                               dcu.class_user_attach_status,
                               dc.class_course_status,
                               dsc.academic_year_end_date,
                               LISTAGG(DISTINCT dt.teacher_id, ',')
                               WITHIN GROUP (ORDER BY dcu.class_user_created_time) AS teacher_ids
                        FROM alefdw.dim_class dc
                                 JOIN alefdw.dim_class_user dcu
                                      ON dcu.class_user_class_dw_id = dc.class_dw_id
                                          AND dcu.class_user_role_dw_id = 1
                                 JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                                      ON dsc.school_id = dc.class_school_id
                                          AND dsc.academic_year_id = dc.class_academic_year_id
                                 LEFT JOIN alefdw.dim_teacher dt
                                           ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                                               AND teacher_id NOT IN (SELECT DISTINCT teacher_id
                                                                      FROM bi_alefdw.exclude_teacher_id)
                                 JOIN academic_year lay ON dsc.school_dw_id = lay.school_dw_id
                        WHERE dc.class_material_type <> 'PATHWAY'
                          AND (
                            (date_part_year(dsc.academic_year_end_date) = lay.max_year
                                AND dc.class_course_status = 'ACTIVE'
                                AND dcu.class_user_attach_status = 1)
                                OR
                            (date_part_year(dsc.academic_year_end_date) < lay.max_year
                                AND dc.class_course_status = 'CONCLUDED')
                            )
                        GROUP BY 1, 2, 3, 4),

     COMPLETED_LESSONS AS (select fle.fle_ls_id,
                                  fle.fle_dw_id,
                                  lo.lo_dw_id,
                                  lo.lo_title,
                                  fle_student_dw_id,
                                  fle_grade_dw_id,
                                  fle_school_dw_id,
                                  fle_section_dw_id,
                                  academic_year_start_date,
                                  academic_year_end_date,
                                  fle_created_time::DATE                           as                       lesson_progress_date,
                                  'Completed'                                      AS                       lo_status,
                                  case when lo.lo_max_stars > 0 then fle_score end as                       fle_score,
                                  ROW_NUMBER() over (PARTITION BY fle_ls_id ORDER BY fle_created_time desc) rnk
                           FROM alefdw.fact_learning_experience fle
                                    JOIN alefdw.dim_learning_objective lo
                                         ON lo.lo_dw_id = fle_lo_dw_id
                                    JOIN Learning_Objective cd
                                         ON cd.lo_code = lo.lo_code
                                    JOIN bi_alefdw.bi_all_schools_dim_mv ac
                                         ON ac.academic_year_dw_id = fle.fle_academic_year_dw_id
                                             AND ac.school_dw_id = fle.fle_school_dw_id
                           where fle_completion_node is true
                             AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
                             AND fle_material_type <> 'PATHWAY' --
                             AND nvl(lo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
                           QUALIFY rnk = 1),

     INPROGRESS_LESSONS AS (SELECT fle_dw_id,
                                   lo_dw_id,
                                   lo_title,
                                   fle_student_dw_id,
                                   fle_grade_dw_id,
                                   fle_school_dw_id,
                                   fle_section_dw_id,
                                   academic_year_start_date,
                                   academic_year_end_date,
                                   lesson_progress_date,
                                   0             as fle_score,
                                   'In-Progress' AS lo_status
                            FROM (SELECT fle_ls_id,
                                         lo.lo_dw_id,
                                         lo_title,
                                         fle_student_dw_id,
                                         fle_grade_dw_id,
                                         fle_school_dw_id,
                                         fle_section_dw_id,
                                         academic_year_start_date,
                                         academic_year_end_date,
                                         MAX(fle_dw_id)                 fle_dw_id,
                                         MAX(fle_created_time)::DATE as lesson_progress_date
                                  FROM alefdw.fact_learning_experience fle
                                           JOIN Learning_Objective lo
                                                on lo.lo_dw_id = fle_lo_dw_id
                                           JOIN bi_alefdw.bi_all_schools_dim_mv ac
                                                ON ac.academic_year_dw_id = fle.fle_academic_year_dw_id
                                                    AND ac.school_dw_id = fle.fle_school_dw_id
                                  WHERE fle_ls_id NOT IN (select fle_ls_id from COMPLETED_LESSONS)
                                    AND fle_attempt = 1
                                    AND fle_activity_type <> 'INTERIM_CHECKPOINT'
                                    AND fle_material_type <> 'PATHWAY'
                                    AND fle_abbreviation <> 'NA'
                                  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9) a),

     LESSON_PROGRESS AS (SELECT fle_dw_id,
                                lo_dw_id,
                                lo_title,
                                fle_student_dw_id,
                                fle_grade_dw_id,
                                fle_school_dw_id,
                                fle_section_dw_id,
                                academic_year_start_date,
                                academic_year_end_date,
                                fle_score,
                                lo_status,
                                lesson_progress_date
                         FROM INPROGRESS_LESSONS
                         UNION ALL
                         SELECT fle_dw_id,
                                lo_dw_id,
                                lo_title,
                                fle_student_dw_id,
                                fle_grade_dw_id,
                                fle_school_dw_id,
                                fle_section_dw_id,
                                academic_year_start_date,
                                academic_year_end_date,
                                fle_score,
                                lo_status,
                                lesson_progress_date
                         FROM COMPLETED_LESSONS),

     student_lessons_assigned AS (SELECT DISTINCT d_cu.class_user_user_dw_id,
                                                  d_cu.class_user_class_dw_id,
                                                  dcs.curr_subject_dw_id,
                                                  lo.lo_dw_id,
                                                  lo.lo_title,
                                                  dip.caa_activity_dw_id,
                                                  ac.academic_year_start_date,
                                                  ac.academic_year_end_date,
                                                  ac.school_dw_id,
                                                  dc.class_course_status
                                  FROM alefdw.dim_class_user d_cu
                                           INNER JOIN alefdw.dim_class dc
                                                      ON dc.class_dw_id = d_cu.class_user_class_dw_id
                                           INNER JOIN alefdw.dim_curriculum_subject dcs
                                                      ON md5(dc.class_curriculum_subject_id) = md5(dcs.curr_subject_id)
                                           INNER JOIN alefdw.dim_course_activity_association dip
                                                      ON dc.class_material_id = dip.caa_course_id
                                           INNER JOIN Learning_Objective lo
                                                      ON lo.lo_dw_id = dip.caa_activity_dw_id
                                           INNER JOIN bi_alefdw.bi_all_schools_dim_mv ac
                                                      ON ac.school_id = dc.class_school_id
                                                          AND ac.academic_year_id = dc.class_academic_year_id
                                           INNER JOIN academic_year lay
                                                      ON ac.school_dw_id = lay.school_dw_id
                                  WHERE d_cu.class_user_role_dw_id = 2
                                    AND dc.class_material_type <> 'PATHWAY'
                                    AND (
                                      (date_part_year(ac.academic_year_end_date) = lay.max_year
                                          AND dc.class_course_status = 'ACTIVE'
                                          AND d_cu.class_user_attach_status = 1
                                          AND dip.caa_attach_status = 1
                                          AND dip.caa_status = 1)
                                          OR
                                      (date_part_year(ac.academic_year_end_date) < lay.max_year
                                          AND dc.class_course_status = 'CONCLUDED')
                                      )),

     class_total_students_civil_defense as (SELECT dc.class_dw_id,
                                                   lo_code,
                                                   lo_title,
                                                   class_material_id,
                                                   class_title,
                                                   class_gen_subject,
                                                   class_curriculum_id,
                                                   class_academic_year_id,
                                                   academic_year_start_date,
                                                   ac.academic_year_end_date,
                                                   class_content_academic_year,
                                                   dc.class_course_status,
                                                   class_material_type,
                                                   class_grade_id,
                                                   class_section_id,
                                                   class_curriculum_grade_id,
                                                   ac.school_dw_id,
                                                   NVL(dsec.section_dw_id, '10001')      AS class_section_dw_id,
                                                   initcap(NVL(dsec.section_name, 'NA')) AS class_section_name,
                                                   dcg.curr_grade_dw_id,
                                                   dcg.curr_grade_name,
                                                   dg.grade_name,
                                                   dcs.curr_subject_dw_id,
                                                   dcs.curr_subject_name,
                                                   teacher_ids,
                                                   count(DISTINCT class_user_user_dw_id) AS class_total_students
                                            FROM alefdw.dim_class dc
                                                     INNER JOIN alefdw.dim_class_user dcu
                                                                ON dc.class_dw_id = dcu.class_user_class_dw_id
                                                     INNER JOIN bi_alefdw.bi_all_schools_dim_mv ac
                                                                ON ac.school_id = dc.class_school_id
                                                                    AND fnv_hash(ac.academic_year_id) =
                                                                        fnv_hash(dc.class_academic_year_id)
                                                     INNER JOIN alefdw.dim_curriculum_subject dcs
                                                                ON md5(dc.class_curriculum_subject_id) = md5(dcs.curr_subject_id)
                                                     INNER JOIN alefdw.dim_course_activity_association dip
                                                                ON dc.class_material_id = dip.caa_course_id
                                                     INNER JOIN Learning_Objective lo
                                                                ON lo.lo_dw_id = dip.caa_activity_dw_id
                                                     INNER JOIN academic_year lay
                                                                ON ac.school_dw_id = lay.school_dw_id
                                                     LEFT JOIN alefdw.dim_curriculum_grade dcg
                                                               ON dc.class_curriculum_grade_id =
                                                                  dcg.curr_grade_id
                                                     LEFT JOIN alefdw.dim_grade dg
                                                               ON md5(dg.grade_id) = md5(dc.class_grade_id)
                                                     LEFT JOIN alefdw.dim_section dsec
                                                               ON md5(dsec.section_id) = md5(dc.class_section_id)
                                                     LEFT JOIN class_teachers ct
                                                               ON ct.class_dw_id = dc.class_dw_id
                                            Where class_user_role_dw_id = 2
                                              AND (
                                                (date_part_year(ac.academic_year_end_date) = lay.max_year
                                                    AND dc.class_course_status = 'ACTIVE'
                                                    AND dcu.class_user_attach_status = 1
                                                    AND dip.caa_attach_status = 1
                                                    AND class_active_until is null
                                                    AND dip.caa_status = 1)
                                                    OR
                                                (date_part_year(ac.academic_year_end_date) < lay.max_year
                                                    AND dc.class_course_status = 'CONCLUDED')
                                                )
                                            GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
                                                     20, 21, 22, 23, 24, 25),


     students_learning_progress_civil_defense as (SELECT fl.*,
                                                         nvl(lps.fle_score, 0) as fle_score,
                                                         lps.lo_status,
                                                         lps.lesson_progress_date
                                                  FROM (SELECT DISTINCT dd.full_date               AS local_date,
                                                                        dcu.class_user_class_dw_id AS fle_class_dw_id,
                                                                        fle_lo_dw_id               AS lo_attempted,
                                                                        lo_code,
                                                                        fle_lesson_category,
                                                                        fle_dw_id,
                                                                        fle_ls_id,
                                                                        ds.student_dw_id,
                                                                        ds.student_section_dw_id,
                                                                        fle_academic_year_dw_id,
                                                                        ds.student_tags,
                                                                        dg.grade_k12grade,
                                                                        ac.academic_year_start_date,
                                                                        ac.academic_year_end_date,
                                                                        CASE
                                                                            WHEN fle.fle_total_time <= 900
                                                                                THEN fle.fle_total_time
                                                                            WHEN fle.fle_total_time > 900
                                                                                THEN 900
                                                                            ELSE 0
                                                                            END                    AS session_time
                                                        FROM alefdw.fact_learning_experience fle
                                                                 INNER JOIN Learning_Objective
                                                                            ON fle_lo_dw_id = lo_dw_id
                                                                 INNER JOIN bi_alefdw.bi_all_schools_dim_mv ac
                                                                            ON ac.school_dw_id = fle.fle_school_dw_id
                                                                                AND ac.academic_year_dw_id =
                                                                                    fle.fle_academic_year_dw_id
                                                                 INNER JOIN alefdw.dim_student ds
                                                                            ON fle.fle_student_dw_id =
                                                                               ds.student_dw_id
                                                                                AND ac.school_dw_id =
                                                                                    ds.student_school_dw_id
                                                                 INNER JOIN alefdw.dim_grade dg
                                                                            ON dg.grade_dw_id = fle.fle_grade_dw_id
                                                                 INNER JOIN alefdw.dim_date dd
                                                                            ON fle.fle_date_dw_id = dd.date_id
                                                                 INNER JOIN student_lessons_assigned dcu
                                                                            ON fle.fle_student_dw_id = dcu.class_user_user_dw_id
                                                        WHERE fle_abbreviation <> 'NA'
                                                          AND fle_activity_type <> 'INTERIM_CHECKPOINT'
                                                          AND fle_material_type <> 'PATHWAY') fl
                                                           JOIN LESSON_PROGRESS lps
                                                               ON fl.fle_dw_id = lps.fle_dw_id
                                                               AND fl.student_dw_id = lps.fle_student_dw_id
                                                  WHERE NVL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON')

SELECT distinct dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_alias                                                        AS school_adek_id,
                UPPER(dsc.school_country_name)                                          AS school_country_name,
                UPPER(dsc.school_city_name)                                             AS school_city_name,
                dsc.school_label,
                dsc.school_composition,
                dsc.school_organisation                                                 AS organisation_name,
                dsc.school_cx_cluster,
                cts.class_dw_id,
                cts.class_total_students,
                cts.class_title,
                cts.class_gen_subject,
                cts.class_section_dw_id                                                 as section_dw_id,
                cts.class_section_name                                                  as section_name,
                cts.curr_grade_name,
                cts.grade_name,
                cts.curr_subject_name,
                dip_dlo.lo_code,
                cip.caa_course_id,
                dip_dlo.lo_title,
                cip.caa_activity_dw_id                                                  AS lo_to_finish,
                lp.lo_attempted,
                lp.lo_status,
                lp.lesson_progress_date,
                nvl(lp.fle_score)                                                       AS fle_score,
                lp.student_dw_id,
                ds.student_id,
                lp.local_date,
                lp.academic_year_start_date,
                lp.academic_year_end_date,
                date_part_year(cts.academic_year_start_date) || '-' ||
                date_part_year(cts.academic_year_end_date)                              AS academic_year,
                dd.calendar_week_number                                                 AS week_number,
                dd.calendar_week_of                                                     AS week_start_date,
                DATEADD('day', 6, dd.calendar_week_of)::DATE                            AS week_end_date,
                cip.caa_activity_pacing,
                cip.caa_activity_is_optional,
                cip.caa_activity_type,
                NVL(dtrm.actp_teaching_period_order, 1)                                 AS org_term,
                NVL(dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date) AS term_start_date,
                NVL(dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date)     AS term_end_date,
                nvl(lp.session_time, 0)                                                 AS session_time,
                lp.grade_k12grade,
                cts.teacher_ids
FROM class_total_students_civil_defense cts
         JOIN Civil_lo cip
              ON MD5(cts.class_material_id) = MD5(cip.caa_course_id)
         JOIN bi_alefdw.bi_all_schools_dim_mv dsc
              ON cts.school_dw_id = dsc.school_dw_id
                  AND cts.class_academic_year_id = dsc.academic_year_id
         JOIN alefdw.dim_academic_calendar dac
              ON dsc.organisation_dw_id = dac.academic_calendar_organization_dw_id
                  AND dac.academic_calendar_academic_year_dw_id = dsc.academic_year_dw_id
         JOIN alefdw.dim_academic_calendar_teaching_period dtrm
              ON dac.academic_calendar_id = dtrm.actp_academic_calendar_id
                  AND dtrm.actp_status = 1
         JOIN Learning_Objective dip_dlo
              ON cip.caa_activity_dw_id = dip_dlo.lo_dw_id
         LEFT JOIN students_learning_progress_civil_defense lp
                   ON cts.class_dw_id = lp.fle_class_dw_id
                       AND cts.class_section_dw_id = lp.student_section_dw_id
                       AND dip_dlo.lo_dw_id = lp.lo_attempted
         LEFT JOIN alefdw.dim_student ds
                   ON ds.student_dw_id = lp.student_dw_id
         LEFT JOIN alefdw.dim_date dd
                   ON dd.full_date = lp.local_date
where dsc.tenant_name in ('MOE', 'Private')
with no schema binding;