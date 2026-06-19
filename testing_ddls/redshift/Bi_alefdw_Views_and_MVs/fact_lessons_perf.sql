CREATE OR REPLACE VIEW bi_alefdw_dev.fact_lessons_perf AS
with total_completed_students as (
    SELECT lo_attempted,
           fle_class_dw_id,
           student_section_dw_id,
            count(distinct case lo_status when 'Completed' then student_dw_id end)                                                    as total_completed_students,
            count(distinct case  when lo_status = 'Completed' and fle_score >= 70 then student_dw_id end)                             as meets_completed_students,
            count(distinct case  when lo_status = 'Completed' and fle_score >= 50 and fle_score < 70 then student_dw_id end)          as approaching_completed_students,
            count(distinct case  when lo_status = 'Completed' and fle_score < 50 and fle_score >= 0 then student_dw_id end)           as below_completed_students,
            count(distinct case lo_status when 'In-Progress' then student_dw_id end)                                                  as total_inprogress_students,
            avg(case  when lo_status = 'Completed' and fle_score >= 0 then cast(fle_score as decimal(10, 2)) end)                     as average_score,
            max(local_date)                                                                                                       as max_local_date
    from bi_alefdw.students_lesson_progress_mv
    group by 1,2,3
)
SELECT DISTINCT dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_organisation                  AS organisation_name,
                cts.class_dw_id,
                cts.class_total_students                 AS class_students_assigned_per_mlo ,
                cts.class_title,
                cts.class_gen_subject,
                cts.section_dw_id,
                cts.section_name,
                cts.class_section_name,
                cts.grade_name,
                concat(dsc.school_id, cts.grade_name) as school_grade_uid,
                cts.class_curriculum_id                AS instructional_plan_curriculum_id,
                trim(dip_dlo.lo_title)                 AS lo_title,
                dcaa.caa_activity_dw_id                AS lo_to_finish,
                nvl(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date) AS week_start_date,
                nvl(dpg.pacing_interval_end_date , dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date)      AS week_end_date,
                nvl(dtrm.actp_teaching_period_order,1)                                      AS term_academic_period_order,
                nvl(dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date)     AS term_start_date,
                nvl(dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date)         AS term_end_date,
                cts.teacher_ids,
                tcs.total_completed_students,
                tcs.below_completed_students,
                tcs.approaching_completed_students,
                tcs.meets_completed_students,
                tcs.average_score,
                tcs.total_inprogress_students,
                nvl(tcs.max_local_date, dpg.pacing_interval_start_date)::timestamp as max_local_date
FROM bi_alefdw.class_total_students_mv cts
         JOIN alefdw.dim_course dcr
             ON MD5(cts.instructional_plan_id) = MD5(dcr.course_id)
                AND dcr.course_status = 1
                AND dcr.course_type = 'CORE'
         JOIN alefdw.dim_course_activity_association dcaa
             ON dcr.course_dw_id = dcaa.caa_course_dw_id
                AND dcaa.caa_activity_is_optional IS FALSE
                AND dcaa.caa_activity_type = 1
         LEFT JOIN alefdw.dim_pacing_guide dpg
             ON cts.class_dw_id = dpg.pacing_class_dw_id
             AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
         LEFT JOIN alefdw.dim_academic_calendar_teaching_period dtrm
             ON md5(dpg.pacing_period_id) = md5(dtrm.actp_teaching_period_id)
         JOIN bi_alefdw.bi_active_schools_dim_mv dsc ON cts.school_dw_id = dsc.school_dw_id
         JOIN alefdw.dim_learning_objective dip_dlo ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
                AND nvl(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
         LEFT JOIN total_completed_students tcs
                   ON  cts.class_dw_id = tcs.fle_class_dw_id
                       AND dcaa.caa_activity_dw_id = tcs.lo_attempted
                       AND cts.section_dw_id = tcs.student_section_dw_id
WHERE lower(cts.class_title) NOT LIKE '%power skills%'
  AND lower(cts.class_title) NOT LIKE '%extra resources%'
  AND lower(cts.class_gen_subject) != 'alef stars'
  AND dpg.pacing_interval_start_date <= trunc(sysdate)-1
WITH NO SCHEMA BINDING;