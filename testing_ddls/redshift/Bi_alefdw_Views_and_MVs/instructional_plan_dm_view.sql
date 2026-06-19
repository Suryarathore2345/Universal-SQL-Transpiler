CREATE OR REPLACE VIEW bi_alefdw_dev.instructional_plan_dm_view AS
SELECT *
from bi_alefdw.ip_instructional_plan_dm_view
UNION ALL
SELECT DISTINCT cont.tenant_name,
                cont.school_dw_id,
                cont.school_id,
                cont.school_name,
                cont.school_alias                                                                                  AS school_adek_id,
                cont.school_country_name,
                cont.school_city_name,
                cont.school_label,
                cont.school_organisation                                                                           AS organisation_name,
                cont.school_cx_cluster,
                cts.class_dw_id,
                cts.class_total_students,
                cts.class_title,
                cts.class_gen_subject,
                cts.course_subject_id,
                cts.section_dw_id,
                cts.section_name,
                cts.class_section_name,
                'NA'                                                                                              AS curr_grade_name,
                cts.grade_name,
                'NA'                                                                                              AS curr_subject_name,
                999999                                                                                            AS instructional_plan_curriculum_id,
                cont.lo_title,
                cont.activity_dw_id                                                                               AS lo_to_finish,
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
                nvl(CASE cont.pacing
                        WHEN 'MONTH' THEN date_part(month, cont.week_start_date)
                        ELSE date_part(week, cont.week_start_date) END,
                    1)                                                                                            AS week_number,
                cont.week_start_date,
                cont.week_end_date,
                cts.content_academic_year_name,
                cont.course_name                                                                                  AS instructional_plan_name,
                cont.course_id                                                                                    AS instructional_plan_id,
                cont.instructional_plan_item_order,
                FALSE                                                                                             AS instructional_plan_item_optional,
                cont.term_academic_period_order,
                cont.term_start_date,
                cont.term_end_date,
                cont.pacing,
                lp.session_time,
                lp.fle_source,
                lp.grade_k12grade,
                cts.teacher_ids,
                'Course'                                                                                          as course_type
FROM bi_alefdw.class_total_students_mv cts
         INNER JOIN bi_alefdw.core_class_activity_content_mv cont
                   ON cont.class_dw_id = cts.class_dw_id
         LEFT JOIN bi_alefdw.students_lesson_progress_mv lp
                   ON cts.class_dw_id = lp.fle_class_dw_id
                       AND cts.section_dw_id = lp.student_section_dw_id
                       AND cont.activity_dw_id = lp.lo_attempted
         LEFT JOIN bi_alefdw.bi_student_dim_mv ds
                   ON ds.student_dw_id = lp.student_dw_id
                   AND student_status = 1
WITH NO SCHEMA BINDING;