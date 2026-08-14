IF OBJECT_ID('${schema}.student_hourly_activity_dm', 'U') IS  NULL
BEGIN
CREATE TABLE ${schema}.student_hourly_activity_dm(
	local_date date ,
	day_hour float ,
	student_tags varchar(256) ,
	special_needs varchar(3) ,
	academic_year varchar(9) ,
	section_dw_id bigint ,
	section varchar(2048) ,
	grade varchar(96) ,
	tenant_name varchar(765) ,
	school_dw_id bigint ,
	school_id varchar(36) ,
	school_city_name varchar(100) ,
	school_name varchar(384) ,
	school_organisation varchar(50) ,
	school_country_name varchar(100) ,
	school_composition varchar(20) ,
	school_latitude decimal(10, 6) ,
	school_longitude decimal(10, 6) ,
	adek_id varchar(256) ,
	school_label varchar(30) ,
	total_students bigint ,
	active_students int 
);
END;

IF OBJECT_ID('${schema}.agg_student_learning_progress', 'U') IS  NULL
BEGIN
CREATE TABLE ${schema}.agg_student_learning_progress(
	local_date date ,
	student_dw_id bigint ,
	school_id varchar(36) ,
	school_dw_id bigint ,
	school_name varchar(384) ,
	school_label varchar(30)  ,
	school_city_name varchar(100) ,
	tenant_name varchar(765) ,
	school_organisation varchar(50) ,
	school_country_name varchar(100) ,
	grade_name varchar(250) ,
	section_name varchar(50) ,
	student_tags varchar(256) ,
	student_special_needs varchar(3)  ,
	class_gen_subject varchar(255) ,
	content_academic_year_name varchar(10) ,
	total_score decimal(38, 2) ,
	completed_lessons int ,
	session_time float ,
	fle_session_time float 
);
END;