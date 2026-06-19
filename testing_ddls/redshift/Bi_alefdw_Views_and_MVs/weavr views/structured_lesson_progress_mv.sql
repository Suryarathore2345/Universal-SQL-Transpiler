-------- ====== SET FOR LESSON LEVEL INSIGHTS =======
create materialized view bi_alefdw_dev.structured_lesson_progress_mv
as (
   WITH class_lesson_association AS (SELECT dlo.activity_dw_id       AS assigned_lo_dw_id,
                                            dlo.activity_title       AS lesson_title,
                                            dlo.activity_id          AS lesson_id,
                                            dc.class_dw_id,
                                            dc.class_title,
                                            dg.grade_k12grade        AS grade_name,
                                            dg.grade_id,
                                            dsc.school_name,
                                            dsc.school_dw_id,
                                            dsc.school_organisation,
                                            dsc.tenant_name,
                                            dsc.tenant_timezone,
                                            dsc.academic_year_start_date,
                                            dsc.academic_year_end_date,
                                            dc.class_gen_subject     AS subject,
                                            max(cts.class_total_students) as class_total_students,
                                            count(DISTINCT slide_id) AS num_slides_assigned
                                     FROM bi_alefdw.lo_structure_components_mv AS dlo
                                              INNER JOIN alefdw.dim_course_activity_association dcaa
                                                         ON dcaa.caa_activity_dw_id = dlo.activity_dw_id
                                              INNER JOIN alefdw.dim_course dcr
                                                         ON dcr.course_id = dcaa.caa_course_id
                                              INNER JOIN alefdw.dim_class dc ON dc.class_material_id = dcr.course_id
                                              INNER JOIN bi_alefdw.class_total_students_mv cts
                                                         ON cts.class_dw_id = dc.class_dw_id
                                              INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                                         ON dc.class_school_id = dsc.school_id
                                              INNER JOIN alefdw.dim_grade dg ON dg.grade_id = dc.class_grade_id
                                         AND dg.school_id = dsc.school_id
                                     WHERE dcaa.caa_activity_type = 1
                                       AND dcaa.caa_status = 1
                                       AND dcaa.caa_attach_status = 1
                                       AND course_status = 1
                                       AND dg.grade_status = 1
                                       AND dc.class_status = 1
                                       AND dcr.course_type = 'CORE'
                                       AND dc.class_course_status = 'ACTIVE'
                                     GROUP BY dlo.activity_dw_id,
                                              dlo.activity_title,
                                              dlo.activity_id,
                                              dcaa.caa_course_id,
                                              dc.class_dw_id,
                                              dc.class_title,
                                              dsc.school_name,
                                              dsc.school_dw_id,
                                              dsc.school_organisation,
                                              dsc.tenant_name,
                                              dsc.tenant_timezone,
                                              dsc.academic_year_start_date,
                                              dsc.academic_year_end_date,
                                              dc.class_gen_subject,
                                              dg.grade_k12grade,
                                              dg.grade_id
                                              )

   SELECT DISTINCT trunc(aspm.local_date)     as local_date
                 , clm.assigned_lo_dw_id
                 , clm.class_dw_id
                 , clm.class_title
                 , clm.num_slides_assigned
                 , clm.lesson_id
                 , clm.lesson_title
                 , clm.school_name
                 , clm.school_dw_id
                 , clm.school_organisation
                 , clm.tenant_name
                 , clm.grade_name
                 , clm.grade_id
                 , clm.subject
                 , clm.class_total_students
                 , aspm.fle_lo_dw_id          AS attempted_lo_dw_id
                 , aspm.fle_student_dw_id
                 , aspm.aggregated_idle_timespent
                 , aspm.aggregated_active_timespent
                 , aspm.aggregated_total_timespent
                 , aspm.unique_students_completed_at_least_1_lo
                 , aspm.tenant_dw_id
                 , aspm.num_slides_per_lesson AS total_slides_per_lesson
                 , aspm.slide_completed_by_student
                 , NVL(aspm.lesson_completion_status, 'Not-Started') AS lesson_completion_status
   FROM class_lesson_association clm
            LEFT JOIN bi_alefdw.slide_progress_time_spent_mv aspm
                      ON aspm.class_dw_id = clm.class_dw_id
                          AND aspm.fle_lo_dw_id = clm.assigned_lo_dw_id
                          AND aspm.school_dw_id = clm.school_dw_id
);