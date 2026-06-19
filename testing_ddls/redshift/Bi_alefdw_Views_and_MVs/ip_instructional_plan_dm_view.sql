CREATE OR REPLACE VIEW bi_alefdw_dev.ip_instructional_plan_dm_view AS
SELECT DISTINCT dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_alias                     AS school_adek_id,
                dsc.school_country_name,
                dsc.school_city_name,
                dsc.school_label,
                dsc.school_organisation              AS organisation_name,
                dsc.school_cx_cluster,
                cts.class_dw_id,
                cts.class_total_students,
                cts.class_title,
                cts.class_gen_subject,
                999999 AS course_subject_id,
                cts.section_dw_id,
                cts.section_name,
                cts.class_section_name,
                cts.curr_grade_name,
                cts.grade_name,
                cts.curr_subject_name,
                dip.instructional_plan_curriculum_id,
                dip_dlo.lo_title,
                dip.instructional_plan_item_lo_dw_id AS lo_to_finish,
                lp.lo_attempted,
                lp.lo_status,
                lp.fle_score,
                lp.student_dw_id,
                ds.student_id,
                lp.student_tags,
                lp.student_special_needs,
                lp.local_date,
                lp.academic_year_start_date,
                lp.academic_year_end_date,
                dw.week_number,
                dw.week_start_date,
                dw.week_end_date,
                cts.content_academic_year_name,
                dip.instructional_plan_name,
                dip.instructional_plan_id,
                dip.instructional_plan_item_order,
                dip.instructional_plan_item_optional,
                dtrm.term_academic_period_order,
                dtrm.term_start_date,
                dtrm.term_end_date,
                '' AS pacing,
                lp.session_time,
                lp.fle_source,
                lp.grade_k12grade,
                cts.teacher_ids,
                'IP' as course_type
FROM bi_alefdw.ip_class_total_students_mv cts
         JOIN alefdw.dim_instructional_plan dip ON MD5(cts.instructional_plan_id) = MD5(dip.instructional_plan_id)
    AND dip.instructional_plan_status = 1
    AND instructional_plan_item_optional IS FALSE
         JOIN alefdw.dim_week dw ON dip.instructional_plan_item_week_dw_id = dw.week_dw_id
         JOIN alefdw.dim_term dtrm ON md5(dw.week_term_id) = md5(dtrm.term_id)
         JOIN bi_alefdw.bi_active_schools_dim_mv dsc ON cts.school_dw_id = dsc.school_dw_id
         JOIN alefdw.dim_learning_objective dip_dlo ON dip.instructional_plan_item_lo_dw_id = dip_dlo.lo_dw_id
              AND dip_dlo.lo_status=1
    AND nvl(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
         LEFT JOIN bi_alefdw.ip_students_lesson_progress_mv lp
                   ON cts.class_dw_id = lp.fle_class_dw_id
                       AND cts.section_dw_id = lp.student_section_dw_id
                       AND md5(cts.class_curriculum_id) = md5(lp.term_curriculum_id)
                       AND dip.instructional_plan_item_lo_dw_id = lp.lo_attempted
         LEFT JOIN bi_alefdw.bi_student_dim_mv ds ON ds.student_dw_id = lp.student_dw_id
WITH NO SCHEMA BINDING;