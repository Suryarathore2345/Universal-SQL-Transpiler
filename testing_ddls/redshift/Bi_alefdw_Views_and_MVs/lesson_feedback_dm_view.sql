CREATE OR REPLACE VIEW bi_alefdw_dev.lesson_feedback_dm_view AS
SELECT DISTINCT sch.tenant_id,
                sch.tenant_name,
                grade_dw_id,
                grade_name,
                lesson_feedback_subject_dw_id,
                class_gen_subject,
                flf.lesson_feedback_created_time,
                trunc(convert_timezone('UTC', sch.tenant_timezone, flf.lesson_feedback_created_time)) local_date,
                (6.0 - flf.lesson_feedback_rating)                                      AS            rate,
                flf.lesson_feedback_student_dw_id,
                flf.lesson_feedback_rating_text,
                sch.school_dw_id,
                sch.school_organisation,
                sch.organisation_dw_id,
                sch.school_name,
                sch.school_city_name,
                dg.grade_k12grade,
                ds.section_dw_id,
                ds.section_name,
                dc.class_title,
                flf.lesson_feedback_lo_dw_id,
                dlo.lo_title,
                sdm.student_tags,
                sdm.student_special_needs                                               AS            special_needs,
                nvl(dtrm.actp_teaching_period_order, 1)                                 AS            term_academic_period_order,
                nvl(dtrm.actp_teaching_period_start_date, sch.academic_year_start_date) AS            term_start_date,
                nvl(dtrm.actp_teaching_period_end_date, sch.academic_year_end_date)     AS            term_end_date,
                date_part(YEAR, sch.academic_year_start_date) || '-' ||
                date_part(YEAR, sch.academic_year_end_date)                             AS            academic_year
FROM alefdw.fact_lesson_feedback flf
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv sch
                    ON sch.school_dw_id = flf.lesson_feedback_school_dw_id
                        AND trunc(lesson_feedback_created_time) >= sch.academic_year_start_date
                        AND trunc(lesson_feedback_created_time) <= sch.academic_year_end_date
         INNER JOIN alefdw.dim_grade dg
                    ON dg.grade_dw_id = flf.lesson_feedback_grade_dw_id
         INNER JOIN alefdw.dim_section ds
                    ON ds.section_dw_id = flf.lesson_feedback_section_dw_id
         INNER JOIN alefdw.dim_class_user dcu
                    ON dcu.class_user_user_dw_id = flf.lesson_feedback_student_dw_id
         INNER JOIN alefdw.dim_class dc
                    ON dc.class_dw_id = dcu.class_user_class_dw_id
                        AND dc.class_dw_id = flf.lesson_feedback_class_dw_id
         INNER JOIN bi_alefdw.bi_student_dim_mv sdm
                    ON sdm.student_dw_id = flf.lesson_feedback_student_dw_id
         LEFT JOIN alefdw.dim_academic_calendar_teaching_period dtrm
                   ON dtrm.actp_dw_id = flf.lesson_feedback_term_dw_id -- fact table to have a new column - as per new events
                          AND dtrm.actp_status = 1
         INNER JOIN alefdw.dim_learning_objective dlo
                    ON dlo.lo_dw_id = flf.lesson_feedback_lo_dw_id
WHERE flf.lesson_feedback_rating > 0
  AND dg.grade_status = 1
  AND ds.section_status = 1
  AND sdm.student_status = 1
  AND dc.class_status = 1
  AND dcu.class_user_status = 1
  AND dcu.class_user_attach_status = 1
  AND dlo.lo_status = 1
WITH NO SCHEMA BINDING;