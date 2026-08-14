IF OBJECT_ID('${schema}.pathway_level_completion_dm_py', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.pathway_level_completion_dm_py (
    school_dw_id BIGINT,
    grade_name VARCHAR(250),
    flr_student_dw_id BIGINT,
    flr_level_dw_id BIGINT,
    flr_created_time DATETIME2(6),
    level_dw_id_completed BIGINT,
    level_completed_time DATETIME2(6)
);
END;

IF OBJECT_ID('${schema}.instruction_plan_optional_moe_dm', 'U') IS NULL 
BEGIN
CREATE TABLE ${schema}.instruction_plan_optional_moe_dm (
    tenant_name VARCHAR(765),
    school_dw_id BIGINT,
    school_id VARCHAR(36),
    school_name VARCHAR(384),
    school_adek_id VARCHAR(256),
    school_country_name VARCHAR(10),
    school_city_name VARCHAR(100),
    school_label VARCHAR(30),
    school_composition VARCHAR(20),
    organisation_name VARCHAR(50),
    school_cx_cluster VARCHAR(50),
    class_dw_id BIGINT,
    class_total_students BIGINT,
    class_title VARCHAR(255),
    class_gen_subject VARCHAR(255),
    section_dw_id BIGINT,
    section_name VARCHAR(50),
    curr_grade_name VARCHAR(255),
    grade_name VARCHAR(250),
    curr_subject_name VARCHAR(255),
    lo_code VARCHAR(750),
    caa_course_id VARCHAR(36),
    lo_title VARCHAR(750),
    lo_to_finish BIGINT,
    lo_attempted BIGINT,
    lo_status VARCHAR(30),
    lesson_progress_date DATE,
    fle_score INT,
    student_dw_id BIGINT,
    student_id VARCHAR(36),
    local_date DATE,
    academic_year_start_date DATE,
    academic_year_end_date DATE,
    academic_year VARCHAR(15),
    week_number INT,
    week_start_date DATE,
    week_end_date DATE,
    caa_activity_pacing VARCHAR(50),
    caa_activity_is_optional BIT,
    caa_activity_type INT,
    org_term INT,
    term_start_date DATE,
    term_end_date DATE,
    session_time FLOAT,
    grade_k12grade INT,
    teacher_ids VARCHAR(MAX)
);
END;