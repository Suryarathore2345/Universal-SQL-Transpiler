CREATE OR REPLACE VIEW bi_alefdw_dev.teacher_lo_lock_unlock_dm_view AS

SELECT DISTINCT sch.tenant_name,
                sch.school_dw_id,
                sch.school_id,
                sch.school_name,
                sch.school_alias AS school_adek_id,
                sch.school_country_name,
                sch.school_city_name,
                sch.school_label,
                sch.school_organisation AS organisation_name,
                sch.school_cx_cluster,
                cts.curr_grade_dw_id,
                cts.grade_name,
                cts.curr_grade_name,
                cts.section_dw_id,
                cts.section_name,
                cts.curr_subject_dw_id,
                cts.curr_subject_name,
                cts.class_gen_subject,
                cts.class_dw_id,
                cts.class_title,
                dlo.lo_dw_id, 
				dlo.lo_title,
				coalesce(dlo.lo_framework_code, 'Flexible Framework') AS lo_framework_code,
				sdm.student_dw_id,
				dcsa.content_student_association_student_id AS student_id,
				dcsa.content_student_association_class_id AS class_id,
				dcsa.content_student_association_assigned_by AS teacher_id,
				dcsa.content_student_association_assign_status AS content_status,
				trunc(convert_timezone('UTC', sch.tenant_timezone, dcsa.content_student_association_created_time)) local_date,
				date_part(YEAR, ay.academic_year_start_date) || '-' || date_part(YEAR, ay.academic_year_end_date) AS academic_year
FROM alefdw.dim_content_student_association dcsa
JOIN bi_alefdw.bi_student_dim_mv sdm ON MD5(sdm.student_id) = MD5(dcsa.content_student_association_student_id)
JOIN bi_alefdw.bi_active_schools_dim_mv sch ON sch.school_dw_id = sdm.student_school_dw_id
JOIN alefdw.dim_class dc ON MD5(dc.class_id) = MD5(dcsa.content_student_association_class_id)
JOIN alefdw.dim_academic_year ay ON MD5(ay.academic_year_school_id) = MD5(sch.school_id)
JOIN bi_alefdw.class_total_students_mv cts ON cts.class_dw_id = dc.class_dw_id
JOIN alefdw.dim_learning_objective dlo ON MD5(dlo.lo_id) = MD5(dcsa.content_student_association_lo_id)
WHERE dcsa.content_student_association_status = 1
  AND sdm.student_status = 1
  AND dc.class_status = 1
  AND dlo.lo_status = 1
  AND dc.class_course_status = 'ACTIVE'
  AND ay.academic_year_status = 1
  AND ay.academic_year_is_roll_over_completed IS FALSE 
 
WITH NO SCHEMA BINDING;
