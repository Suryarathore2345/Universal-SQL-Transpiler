IF OBJECT_ID('${schema}.students_lesson_progress', 'U') IS NULL
BEGIN
CREATE TABLE ${schema}.students_lesson_progress
(
	local_date date ,
	fle_class_dw_id bigint ,
	lo_attempted bigint ,
	fle_lesson_category varchar(40) ,
	fle_dw_id bigint ,
	fle_source varchar(10) ,
	student_dw_id bigint ,
	student_section_dw_id bigint ,
	fle_academic_year_dw_id bigint ,
	student_tags varchar(256) ,
	student_special_needs varchar(3) ,
	grade_k12grade int ,
	session_time float ,
	fle_session_time float ,
	academic_year_start_date date ,
	academic_year_end_date date ,
	fle_score decimal(10,4) ,
	lo_status varchar(11) 
);
END;