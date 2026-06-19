create or replace view bi_alefdw_dev.learning_experience_dm_view
AS
SELECT DISTINCT trunc(convert_timezone('UTC', dsc.tenant_timezone, fle.fle_created_time)) AS local_date,
                fle.fle_dw_created_time,
                fle.fle_created_time,
                fle.fle_dw_id,
                fle.fle_ls_id,
                fle.fle_exp_id,
                fle.fle_lesson_type,
                fle.fle_start_time,
                fle.fle_end_time,
                fle.fle_total_time,
                fle.fle_score,
                fle.fle_outside_of_school,
                fle.fle_attempt,
                fle.fle_academic_period_order,
                initcap(ds.section_name)                                                  AS section_name,
                initcap(dc.class_title)                                                   AS class,
                initcap(dg.grade_k12grade)                                                AS grade_k12grade,
                dcu.curr_name,
                dcs.curr_subject_name,
                dlo.lo_title,
                dlo.lo_code,
                dlp.learning_path_name,
                dlp.learning_path_experiential_learning,
                dsc.tenant_name,
                dsc.school_dw_id,
                initcap(dsc.school_name)                                                  AS school_name,
                dsc.school_alias                                                          AS school_adek_id,
                dsc.school_organisation,
                dsc.school_city_name,
                dsc.school_country_name,
                dsc.school_composition,
                dst.student_id,
                dst.student_dw_id,
                dst.student_username,
                dst.student_special_needs,
                dst.student_tags,
                initcap(COALESCE(dsu.subject_gen_subject, dc.class_gen_subject))          AS subject_gen_subject,
                dsu.subject_online,
                lessontypepivoted.lessontypes,
                dip.instructional_plan_item_optional                                      AS optional_mlo,
                CASE
                    WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                    WHEN fle.fle_total_time > 900 THEN 900
                    ELSE 0
                END                                                                   AS session_time,
                (date_part('year', ay.academic_year_start_date) || '-') ||
                date_part('year', ay.academic_year_end_date)                              AS academic_year,
                dsc.school_label,
                dsc.school_id
FROM alefdw.fact_learning_experience fle
         JOIN bi_alefdw.bi_active_schools_dim_mv dsc
              ON dsc.school_dw_id = fle.fle_school_dw_id
         JOIN alefdw.dim_grade dg
              ON dg.grade_dw_id = fle.fle_grade_dw_id AND dg.grade_status <> 4
         JOIN alefdw.dim_section ds
              ON fle.fle_section_dw_id = ds.section_dw_id AND ds.section_status <> 4
         JOIN alefdw.dim_learning_objective dlo
              ON dlo.lo_dw_id = fle.fle_lo_dw_id
         JOIN bi_alefdw.bi_student_dim_mv dst
              ON fle.fle_student_dw_id = dst.student_dw_id
                  AND dst.student_section_dw_id = ds.section_dw_id AND dst.student_status <> 4
         JOIN alefdw.dim_academic_year ay ON ay.academic_year_dw_id = fle.fle_academic_year_dw_id
         JOIN alefdw.dim_instructional_plan dip
              ON dip.instructional_plan_id = fle.fle_instructional_plan_id AND
                 fle.fle_lo_dw_id = dip.instructional_plan_item_lo_dw_id
         JOIN (SELECT fle2.fle_ls_id,
                      listagg(fle2.fle_lesson_type, ',') WITHIN GROUP (
                          ORDER BY fle2.fle_dw_id DESC) AS lessontypes
               FROM alefdw.fact_learning_experience fle2
               WHERE fle2.fle_activity_type <> 'INTERIM_CHECKPOINT'
               GROUP BY fle2.fle_ls_id) lessontypepivoted ON lessontypepivoted.fle_ls_id = fle.fle_ls_id
         LEFT JOIN alefdw.dim_class dc ON dc.class_dw_id = fle.fle_class_dw_id
         LEFT JOIN alefdw.dim_subject dsu ON dsu.subject_dw_id = fle.fle_subject_dw_id
         LEFT JOIN alefdw.dim_term dtr ON fle.fle_term_dw_id = dtr.term_dw_id
         LEFT JOIN alefdw.dim_curriculum dcu ON dtr.term_curriculum_id = dcu.curr_id
         LEFT JOIN alefdw.dim_curriculum_grade dcg ON fle.fle_curr_grade_dw_id = dcg.curr_grade_dw_id
         LEFT JOIN alefdw.dim_curriculum_subject dcs ON fle.fle_curr_subject_dw_id = dcs.curr_subject_dw_id
         LEFT JOIN alefdw.dim_learning_path dlp ON fle.fle_lp_dw_id = dlp.learning_path_dw_id
WHERE trunc(convert_timezone('UTC', dsc.tenant_timezone, fle.fle_created_time)) >= academic_year_start_date
  AND trunc(convert_timezone('UTC', dsc.tenant_timezone, fle.fle_created_time)) <= academic_year_end_date
  AND date_part_year(academic_year_start_date) >= Extract(year FROM sysdate) - 1
AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
  with no schema binding ;
