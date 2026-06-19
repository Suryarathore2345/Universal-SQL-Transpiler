create or replace view bi_alefdw_dev.assignment_dm_view as
with _teachers as
         (select distinct teacher_dw_id, teacher_id
          from alefdw.dim_teacher
          where teacher_status = 1
            and teacher_active_until is null),
     fact_assignment_submission AS ( -- getting student' same assignment submission last status
         SELECT *
         FROM (SELECT *,
                      ROW_NUMBER() OVER (
                          PARTITION BY assignment_submission_assignment_id, assignment_submission_student_dw_id
                          ORDER BY assignment_submission_created_time desc, assignment_submission_submitted_on desc,
                          assignment_submission_dw_id desc
                          ) AS rank
               FROM alefdw.fact_assignment_submission) sub
         WHERE sub.rank = 1)

select distinct da.assignment_id           -- total assignments
              , da.assignment_created_time
              , da.assignment_title
              , da.assignment_language
              , da.assignment_type         -- assignment type: teacher assignment only
              , da.assignment_assignment_status
              , da.assignment_status
              , da.assignment_max_score
              , da.assignment_is_gradeable
              , da.assignment_attachment_required
              , da.assignment_comment_required
              , dai.assignment_instance_id -- total assignments assigned
              , dai.assignment_instance_lo_dw_id
              , lo.lo_title
              , fas.assignment_submission_id
              , fas.assignment_submission_assignment_id
              , fas.assignment_submission_type
              , fas.assignment_submission_submitted_on
              , fas.assignment_submission_status
              , fas.assignment_submission_teacher_score
              , fas.assignment_submission_resubmission_count
              , da.assignment_school_dw_id
              , da.assignment_tenant_dw_id
              , dsc.tenant_name
              , dsc.school_organisation
              , dsc.school_city_name
              , dsc.school_country_name
              , dsc.school_name
              , dc.class_school_id
              , dc.class_grade_id
              , dg.grade_name
              , dc.class_id
              , dc.class_title
              , dc.class_dw_id
              , dcsa.cs_subject_id              AS curr_subject_id
              , dc.class_gen_subject            AS curr_subject_name
              , dt.teacher_id
              , ds.student_dw_id
              , ds.student_id
              , nvl(dtrm.actp_teaching_period_order,1)  AS term_academic_period_order
              , nvl(dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date) AS term_start_date
              , nvl(dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date) AS term_end_date
FROM alefdw.dim_assignment da
         LEFT JOIN alefdw.dim_assignment_instance dai
                   ON dai.assignment_instance_assignment_dw_id = da.assignment_dw_id
         LEFT JOIN alefdw.dim_assignment_instance_student dais
                   ON dais.ais_instance_dw_id = dai.assignment_instance_dw_id
         LEFT JOIN fact_assignment_submission fas
                   ON md5(fas.assignment_submission_assignment_instance_id) =
                      md5(dai.assignment_instance_id)
                       AND fas.assignment_submission_student_dw_id = dais.ais_student_dw_id
                       and da.assignment_id = fas.assignment_submission_assignment_id
         INNER JOIN alefdw.dim_learning_objective lo
                    ON lo.lo_dw_id = dai.assignment_instance_lo_dw_id
         INNER JOIN alefdw.dim_class as dc
                    on dc.class_dw_id = dai.assignment_instance_class_dw_id
                        and dc.class_status = 1
         INNER JOIN alefdw.dim_course dcr
                    ON md5(dcr.course_id)=md5(dc.class_material_id)
                        AND dcr.course_status = 1
        INNER JOIN alefdw.dim_course_subject_association dcsa
                    ON md5(dcsa.cs_course_id) = md5(dcr.course_id)
         INNER JOIN bi_alefdw.bi_student_dim_mv as ds
                    ON dais.ais_student_dw_id = ds.student_dw_id
                        and ds.student_status = 1
                        and ds.student_active_until is null
         INNER JOIN _teachers as dt
                    on dt.teacher_dw_id = dai.assignment_instance_teacher_dw_id
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv as dsc
                    on dsc.school_dw_id = da.assignment_school_dw_id
                    AND (trunc(assignment_created_time) >= dsc.academic_year_start_date and
                             trunc(assignment_created_time) <= dsc.academic_year_end_date)
         INNER JOIN alefdw.dim_grade as dg
                    on dg.grade_dw_id = dai.assignment_instance_grade_dw_id
                    and MD5(dsc.academic_year_id) = MD5(dg.academic_year_id)
         LEFT JOIN alefdw.dim_academic_calendar_teaching_period dtrm
                    ON md5(dtrm.actp_teaching_period_id)  = md5(dai.assignment_instance_trimester_id)
WITH NO SCHEMA BINDING;