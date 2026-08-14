IF OBJECT_ID('${schema}.fact_lessons_perf', 'U') IS NULL
BEGIN
CREATE TABLE ${schema}.fact_lessons_perf(
 school_dw_id bigint ,
 school_id varchar(36) ,
 school_name varchar(384) ,
 organisation_name varchar(50) ,
 class_dw_id bigint ,
 class_students_assigned_per_mlo int ,
 class_title varchar(255) ,
 class_gen_subject varchar(382) ,
 section_dw_id bigint  ,
 section_name varchar(384) ,
 class_section_name varchar(2048) ,
 grade_name varchar(250) ,
 school_grade_uid varchar(286)  ,
 instructional_plan_curriculum_id bigint ,
 lo_title varchar(750) ,
 lo_to_finish bigint ,
 week_start_date date ,
 week_end_date date ,
 term_academic_period_order int  ,
 term_start_date date ,
 term_end_date date ,
 teacher_ids varchar(max) ,
 total_completed_students int ,
 below_completed_students int ,
 approaching_completed_students int ,
 meets_completed_students int ,
 average_score decimal(38, 6) ,
 total_inprogress_students int ,
 max_local_date datetime2(6) 
);
END;