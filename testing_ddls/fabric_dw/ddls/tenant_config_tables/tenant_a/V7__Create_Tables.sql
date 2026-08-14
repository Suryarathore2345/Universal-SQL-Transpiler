IF OBJECT_ID('${schema}.core_class_activity_content', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.core_class_activity_content
(
	course_id varchar(36) ,
	course_name varchar(255) ,
	class_dw_id bigint ,
	class_id varchar(36) ,
	class_title varchar(255) ,
	class_gen_subject varchar(255) ,
	class_grade_id varchar(36) ,
	grade_name int ,
	school_id varchar(36) ,
	school_dw_id bigint ,
	school_name varchar(384) ,
	school_alias varchar(256) ,
	school_label varchar(max) ,
	school_cx_cluster varchar(50) ,
	school_city_name varchar(100) ,
	school_country_name varchar(100) ,
	tenant_name varchar(765) ,
	school_organisation varchar(50) ,
	activity_dw_id bigint ,
	lo_title varchar(750) ,
	course_subject_id bigint ,
	instructional_plan_item_order int ,
	week_start_date date ,
	week_end_date date ,
	term_academic_period_order int ,
	term_start_date date ,
	term_end_date date ,
	pacing varchar(50) ,
	academic_year_start_date date ,
	academic_year_end_date date ,
	academic_year_id varchar(36) ,
	academic_year varchar(25) 
);
END;


IF OBJECT_ID('${schema}.fact_slide_progress', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.fact_slide_progress
(
	local_date date ,
	fle_lo_dw_id bigint ,
	fle_student_dw_id bigint ,
	student_id varchar(36) ,
	grade_id varchar(36) ,
	grade_name int ,
	class_dw_id bigint ,
	class_title varchar(255) ,
	class_gen_subject varchar(255) ,
	school_dw_id bigint ,
	tenant_dw_id bigint ,
	material_id varchar(36) ,
	academic_year_tag varchar(20) ,
	fle_ls_id varchar(36) ,
	content_section_dw_id bigint ,
	content_section_id varchar(36) ,
	slide_id varchar(36) ,
	widget_id varchar(50) ,
	class_total_students bigint ,
	active_time_spent int ,
	idle_time_spent int ,
	total_time_spent int ,
	slide_completion_status varchar(20) ,
	rnk bigint 
);
END;

IF OBJECT_ID('${schema}.civil_defense_report_dm', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.civil_defense_report_dm
(
	program_month date ,
	tenant_name varchar(765) ,
	organisation_name varchar(50) ,
	school_dw_id bigint ,
	school_name varchar(384) ,
	school_country_name varchar(150) ,
	school_city_name varchar(150) ,
	school_composition varchar(20) ,
	grade_name int ,
	academic_year varchar(23) ,
	unified_lesson_id int ,
	unified_lesson_title varchar(750) ,
	class_total_students bigint ,
	local_date date ,
	fle_student_dw_id bigint ,
	lo_status varchar(20) ,
	fle_score decimal(10,4) 
);
END;

IF OBJECT_ID('${schema}.adt_course_lo_student_report_detail', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.adt_course_lo_student_report_detail
(
	tenant_name varchar(765) ,
	school_organisation varchar(50) ,
	school_city_name varchar(100) ,
	school_composition varchar(20) ,
	school_name varchar(2048) ,
	school_id varchar(36) ,
	school_dw_id bigint ,
	school_label varchar(8000)  ,
	class_gen_subject varchar(2040) ,
	test_skill varchar(9)  ,
	test_id varchar(36) ,
	grade int ,
	student_special_needs varchar(3)  ,
	student_tags varchar(256) ,
	student_current_status int ,
	academicyear int ,
	class_total_students int ,
	fasr_dw_id bigint ,
	fasr_student_dw_id bigint ,
	fasr_created_date datetime2(6) ,
	academic_year int ,
	test_order int ,
	previous_score float ,
	fasr_final_score float ,
	fasr_final_result varchar(50) ,
	target_cefr_level varchar(4) ,
	fasr_final_grade int ,
	fasr_total_time_spent float 
);
END;

IF OBJECT_ID('${schema}.core_class_ic_content', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.core_class_ic_content
(
	course_id varchar(36) ,
	course_name varchar(255) ,
	class_dw_id bigint ,
	class_id varchar(36) ,
	class_title varchar(255) ,
	class_gen_subject varchar(255) ,
	class_grade_id varchar(36) ,
	grade_name int ,
	school_id varchar(36) ,
	school_dw_id bigint ,
	school_name varchar(384) ,
	school_city_name varchar(100) ,
	school_country_name varchar(100) ,
	school_status int ,
	tenant_name varchar(765) ,
	school_organisation varchar(50) ,
	activity_dw_id bigint ,
	ic_title varchar(250) ,
	ic_num_questions bigint ,
	ic_order bigint ,
	course_subject_id bigint ,
	instructional_plan_item_order int ,
	week_start_date date ,
	week_end_date date ,
	term_academic_period_order int ,
	term_start_date date ,
	term_end_date date ,
	pacing varchar(50) ,
	academic_year_start_date date ,
	academic_year_end_date date ,
	academic_year varchar(25) 
);
END;


IF OBJECT_ID('${schema}.student_lesson_progress_sport_academy', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.student_lesson_progress_sport_academy
(
	class_user_user_dw_id bigint ,
	class_user_class_dw_id bigint ,
	lo_to_finish bigint ,
	lo_title varchar(750) ,
	lo_id varchar(36) ,
	course_id varchar(36) ,
	course_name varchar(255) ,
	class_dw_id bigint ,
	class_title varchar(382) ,
	class_gen_subject varchar(382) ,
	tenant_name varchar(765) ,
	school_dw_id bigint ,
	school_id varchar(36) ,
	school_name varchar(384) ,
	school_adek_id varchar(256) ,
	school_country_name varchar(100) ,
	school_city_name varchar(100) ,
	school_label varchar(max) ,
	organisation_name varchar(50) ,
	school_cx_cluster varchar(50) ,
	academic_year_start_date date ,
	academic_year_end_date date ,
	week_number float ,
	week_start_date date ,
	week_end_date date ,
	term_academic_period_order int ,
	activity_item_order int ,
	term_start_date date ,
	term_end_date date ,
	pacing varchar(50) ,
	student_tags varchar(256) ,
	student_special_needs varchar(3) ,
	student_id varchar(36) ,
	student_dw_id bigint ,
	grade_k12grade int ,
	lo_attempted bigint ,
	session_time float ,
	fle_academic_year_dw_id bigint ,
	fle_student_dw_id bigint ,
	lo_status varchar(11) ,
	fle_score decimal(14,4) ,
	local_date date 
);
END;


IF OBJECT_ID('${schema}.slide_progress_time_spent', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.slide_progress_time_spent
(
	local_date date ,
	fle_lo_dw_id bigint ,
	fle_student_dw_id bigint ,
	school_dw_id bigint ,
	class_dw_id bigint ,
	grade_id varchar(36) ,
	grade_name int ,
	tenant_dw_id bigint ,
	aggregated_active_timespent bigint ,
	aggregated_idle_timespent bigint ,
	aggregated_total_timespent bigint ,
	num_slides_per_lesson bigint ,
	slide_completed_by_student bigint ,
	lesson_completion_status varchar(11) ,
	unique_students_completed_at_least_1_lo bigint 
);
END;


IF OBJECT_ID('${schema}.slide_type_completion_progress', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.slide_type_completion_progress
(
	local_week date ,
	tenant_name varchar(765) ,
	school_organisation varchar(50) ,
	school_name varchar(384) ,
	tenant_dw_id bigint ,
	school_dw_id bigint ,
	class_dw_id bigint ,
	widget_id varchar(50) ,
	grade_name int ,
	class_subject varchar(255) ,
	class_title varchar(255) ,
	total_slides_used_per_slide_type bigint ,
	total_total_time_per_slide bigint ,
	total_idle_time_per_slide bigint ,
	total_active_time_per_slide bigint ,
	avg_total_time_per_slide bigint ,
	avg_idle_time_per_slide bigint ,
	avg_active_time_per_slide bigint ,
	slide_student_attempts bigint 
);
END;


IF OBJECT_ID('${schema}.fact_learning_experience_silver', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.fact_learning_experience_silver
(
	local_date date ,
	tenant_name varchar(765) ,
	school_organisation varchar(50) ,
	school_name varchar(384) ,
	school_id varchar(36) ,
	school_dw_id bigint ,
	school_country_name varchar(100) ,
	school_city_name varchar(100) ,
	school_label varchar(8000) ,
	school_status int ,
	grade_name int ,
	fle_student_dw_id bigint ,
	class_gen_subject varchar(255) ,
	curent_date date ,
	is_last_7_days int ,
	is_last_7_days_pp int ,
	is_last_7_days_ly int ,
	is_last_7_days_2ya int ,
	is_last_14_days int ,
	is_last_14_days_pp int ,
	is_last_14_days_ly int ,
	is_last_14_days_2ya int ,
	is_last_30_days int ,
	is_last_30_days_pp int ,
	is_last_30_days_ly int ,
	is_last_30_days_2ya int ,
	is_last_90_days int ,
	is_last_90_days_pp int ,
	is_last_90_days_ly int ,
	is_last_90_days_2ya int ,
	is_ytd int ,
	is_ytd_pp int ,
	is_ytd_ly int ,
	is_ytd_2ya int ,
	total_lessons_learned bigint ,
	total_completed_lessons bigint ,
	total_completed_lessons_score bigint ,
	fle_score decimal(38,4) ,
	session_time float 
);
END;


IF OBJECT_ID('${schema}.zoud_financial_report', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.zoud_financial_report
(
	program_month date ,
	tenant_name varchar(765) ,
	organisation_name varchar(50) ,
	school_dw_id bigint ,
	school_name varchar(384) ,
	school_country_name varchar(150) ,
	school_city_name varchar(150) ,
	school_composition varchar(20) ,
	grade_name int ,
	academic_year varchar(23) ,
	unified_lesson_id int ,
	unified_lesson_title varchar(750) ,
	class_total_students bigint ,
	local_date date ,
	fle_student_dw_id bigint ,
	lo_status varchar(20) ,
	fle_score decimal(10,4) 
);
END;


IF OBJECT_ID('${schema}.structured_lesson_progress', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.structured_lesson_progress
(
	local_date date ,
	assigned_lo_dw_id bigint ,
	class_dw_id bigint ,
	class_title varchar(255) ,
	num_slides_assigned bigint ,
	lesson_id varchar(36) ,
	lesson_title varchar(750) ,
	school_name varchar(384) ,
	school_dw_id bigint ,
	school_organisation varchar(50) ,
	tenant_name varchar(765) ,
	grade_name int ,
	grade_id varchar(36) ,
	subject varchar(255) ,
	class_total_students bigint ,
	attempted_lo_dw_id bigint ,
	fle_student_dw_id bigint ,
	aggregated_idle_timespent bigint ,
	aggregated_active_timespent bigint ,
	aggregated_total_timespent bigint ,
	unique_students_completed_at_least_1_lo bigint ,
	tenant_dw_id bigint ,
	total_slides_per_lesson bigint ,
	slide_completed_by_student bigint ,
	lesson_completion_status varchar(11) 
);
END;


IF OBJECT_ID('${schema}.structure_components_attempts', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.structure_components_attempts
(
	local_date date ,
	school_dw_id bigint ,
	class_dw_id bigint ,
	tenant_dw_id bigint ,
	fle_lo_dw_id bigint ,
	tenant_name varchar(765) ,
	school_organisation varchar(50) ,
	school_name varchar(384) ,
	grade_name int ,
	class_gen_subject varchar(255) ,
	class_title varchar(255) ,
	widget_id varchar(50) ,
	slide_student_attempts bigint 
);
END;


IF OBJECT_ID('${schema}.indonesia_student_login', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.indonesia_student_login
(
	calendar_month_start_date date ,
	calendar_month_end_date date ,
	school_name varchar(384) ,
	school_dw_id bigint ,
	tenant_dw_id bigint ,
	tenant_name varchar(765) ,
	org_dw_id bigint ,
	organization_name varchar(50) ,
	school_city_name varchar(100) ,
	school_label varchar(max) ,
	school_country_name varchar(100) ,
	academic_year_id varchar(36) ,
	academic_year_start_date date ,
	academic_year_end_date date ,
	academic_year varchar(23) ,
	student_dw_id bigint ,
	student_id varchar(36) ,
	student_status int ,
	grade_dw_id bigint ,
	grade_name varchar(250) ,
	grade_id varchar(36) ,
	is_registered int ,
	is_onboarded int ,
	is_active int ,
	is_active_next_month int 
);
END;