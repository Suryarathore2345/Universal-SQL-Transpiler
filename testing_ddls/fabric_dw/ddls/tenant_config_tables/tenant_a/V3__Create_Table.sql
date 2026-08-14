IF OBJECT_ID('${schema}.adt_attempt1_percentile', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.adt_attempt1_percentile (
        grade INT,
        percentile INT,
        attempt_1_min FLOAT(53),
        attempt_1_max FLOAT(53)
    );
END;

IF OBJECT_ID('${schema}.adt_attempt2_percentile', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.adt_attempt2_percentile (
        grade INT,
        percentile INT,
        attempt_2_min FLOAT(53),
        attempt_2_max FLOAT(53)
    );
END;

IF OBJECT_ID('${schema}.adt_attempt3_percentile', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.adt_attempt3_percentile (
        grade INT,
        percentile INT,
        attempt_3_min FLOAT(53),
        attempt_3_max FLOAT(53)
    );
END;

IF OBJECT_ID('${schema}.ese_school', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.ese_school (
        school_dw_id BIGINT,
        school_alias VARCHAR(256),
        school_id VARCHAR(36),
        school_name VARCHAR(384)
    );
END;

IF OBJECT_ID('${schema}.exclude_teacher_id', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.exclude_teacher_id (
        teacher_id VARCHAR(36) NOT NULL
    );
END;

IF OBJECT_ID('${schema}.historical_data_reload_audit', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.historical_data_reload_audit (
        user_type VARCHAR(36),
        date_time_created DATETIME2(6),
        num_records_loaded BIGINT,
        from_date DATETIME2(6),
        to_date DATETIME2(6)
    );
END;

IF OBJECT_ID('${schema}.interim_checkpint_test_nce_ese_prev_year', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.interim_checkpint_test_nce_ese_prev_year (
        fle_student_dw_id BIGINT,
        grade_k12grade INT,
        class_gen_subject VARCHAR(255),
        school_name VARCHAR(384),
        school_composition VARCHAR(20),
        organisation_name VARCHAR(50),
        term_academic_period_order INT,
        fle_score BIGINT,
        academic_year VARCHAR(49),
        total_student BIGINT
    );
END;

IF OBJECT_ID('${schema}.login_activity_full_load_audit', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.login_activity_full_load_audit (
        user_type VARCHAR(36),
        date_time_created DATETIME2(6),
        num_records_loaded BIGINT,
        from_date DATETIME2(6),
        to_date DATETIME2(6)
    );
END;

IF OBJECT_ID('${schema}.login_activity_reload_audit', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.login_activity_reload_audit (
        user_type VARCHAR(36),
        date_time_created DATETIME2(6),
        num_records_loaded BIGINT,
        from_date DATETIME2(6),
        to_date DATETIME2(6)
    );
END;

IF OBJECT_ID('${schema}.map_polygons', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.map_polygons (
        [geometry] VARCHAR(MAX),
        gid_0 VARCHAR(256),
        name_0 VARCHAR(256),
        gid_1 VARCHAR(256),
        name_1 VARCHAR(256),
        nl_name_1 VARCHAR(256),
        gid_2 VARCHAR(256),
        name_2 VARCHAR(256),
        nl_name_2 VARCHAR(256),
        gid_3 VARCHAR(256),
        name_3 VARCHAR(256),
        varname_3 VARCHAR(256),
        nl_name_3 VARCHAR(256),
        type_3 VARCHAR(256),
        engtype_3 VARCHAR(256),
        cc_3 VARCHAR(256),
        hasc_3 VARCHAR(256),
        is_valid_polygon VARCHAR(256)
    );
END;

IF OBJECT_ID('${schema}.nce_ese_lo_mastery_prev_year', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.nce_ese_lo_mastery_prev_year (
        school_name VARCHAR(384),
        fle_student_dw_id BIGINT,
        academic_year VARCHAR(49),
        school_composition VARCHAR(20),
        school_city_name VARCHAR(100),
        subject VARCHAR(255),
        lo_title VARCHAR(750),
        organisation_name VARCHAR(50),
        curr_grade_name INT,
        fle_score BIGINT
    );
END;

IF OBJECT_ID('${schema}.principal_login', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.principal_login (
        login_date_dw_id BIGINT,
        principal_dw_id BIGINT,
        tenant_dw_id BIGINT,
        school_dw_id BIGINT,
        outside_school_flag BIT,
        login_local_date_time DATETIME2(6),
        login_date_time DATETIME2(6)
    );
END;

IF OBJECT_ID('${schema}.scaffold', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.scaffold (
        [key] INT
    );
END;

IF OBJECT_ID('${schema}.school_district_mapping', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.school_district_mapping (
        [school name] VARCHAR(256),
        [school dw id] INT,
        district VARCHAR(256),
        [name 3 in shape file] VARCHAR(256),
        [district latitude] FLOAT(53),
        [district longitude] FLOAT(53),
        [school latitude] FLOAT(53),
        [school longitude] FLOAT(53)
    );
END;

IF OBJECT_ID('${schema}.student_adek_info', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.student_adek_info (
        student_adek_id VARCHAR(50),
        school_adek_id VARCHAR(50),
        grade VARCHAR(50),
        load_date DATE
    );
END;

IF OBJECT_ID('${schema}.student_login', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.student_login (
        login_date_dw_id BIGINT,
        student_dw_id BIGINT,
        tenant_dw_id BIGINT,
        school_dw_id BIGINT,
        outside_school_flag BIT,
        login_local_date_time DATETIME2(6),
        login_date_time DATETIME2(6)
    );
END;

IF OBJECT_ID('${schema}.student_login_backup_17oct25', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.student_login_backup_17oct25 (
        login_date_dw_id BIGINT,
        student_dw_id BIGINT,
        tenant_dw_id BIGINT,
        school_dw_id BIGINT,
        outside_school_flag BIT,
        login_local_date_time DATETIME2(6),
        login_date_time DATETIME2(6)
    );
END;

IF OBJECT_ID('${schema}.student_login_military', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.student_login_military (
        login_date_dw_id BIGINT,
        student_dw_id BIGINT,
        school_dw_id BIGINT,
        tenant_dw_id BIGINT,
        login_local_date_time DATETIME2(6),
        login_date_time DATETIME2(6)
    );
END;

IF OBJECT_ID('${schema}.teacher_login', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.teacher_login (
        login_date_dw_id BIGINT,
        teacher_dw_id BIGINT,
        tenant_dw_id BIGINT,
        school_dw_id BIGINT,
        outside_school_flag BIT,
        login_local_date_time DATETIME2(6),
        login_date_time DATETIME2(6)
    );
END;

IF OBJECT_ID('${schema}.teacher_nps', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.teacher_nps (
        month DATE NOT NULL,
        teacher_nps INT
    );
END;

IF OBJECT_ID('${schema}.teacher_score_idn_school', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.teacher_score_idn_school (
        school_name VARCHAR(256),
        school_dw_id INT
    );
END;

IF OBJECT_ID('${schema}.total_students', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.total_students (
        local_date DATE,
        tenant_name VARCHAR(765),
        school_dw_id BIGINT,
        school_name VARCHAR(384),
        school_city_name VARCHAR(100),
        school_organisation VARCHAR(250),
        school_country_name VARCHAR(100),
        school_composition VARCHAR(20),
        school_latitude DECIMAL(10,6),
        school_longitude DECIMAL(10,6),
        adek_id VARCHAR(256),
        school_label VARCHAR(MAX),
        school_created_time DATETIME2(6),
        school_cx_cluster VARCHAR(50),
        academic_year VARCHAR(49),
        grade INT,
        class VARCHAR(1),
        section_dw_id BIGINT,
        section VARCHAR(75),
        student_tags VARCHAR(256),
        student_special_needs VARCHAR(3),
        week_number DECIMAL(18,0),
        weekly_total_students BIGINT,
        total_students BIGINT,
        monthly_total_students BIGINT,
        school_id VARCHAR(36),
        org_dw_id BIGINT,
        org_term INT,
        term_start_date DATE,
        term_end_date DATE,
        holiday_flag BIT,
        month_year_number INT,
        week_year_number INT
    );
END;

IF OBJECT_ID('${schema}.total_teachers', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.total_teachers (
        local_date DATE,
        tenant_name VARCHAR(765),
        school_dw_id BIGINT,
        school_name VARCHAR(384),
        adek_id VARCHAR(256),
        school_city_name VARCHAR(100),
        school_organisation VARCHAR(250),
        school_country_name VARCHAR(100),
        school_composition VARCHAR(20),
        school_latitude DECIMAL(10,6),
        school_longitude DECIMAL(10,6),
        school_label VARCHAR(MAX),
        school_cx_cluster VARCHAR(50),
        school_created_time DATETIME2(6),
        week_number DECIMAL(18,0),
        week_year_number DECIMAL(18,0),
        weekly_total_teachers BIGINT,
        total_teachers BIGINT,
        monthly_total_teachers BIGINT,
        academic_year VARCHAR(23),
        school_id VARCHAR(36),
        org_dw_id BIGINT,
        org_term INT,
        term_start_date DATE,
        term_end_date DATE,
        holiday_flag BIT,
        month_year_number INT
    );
END;

IF OBJECT_ID('${schema}.total_users_reload_audit', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.total_users_reload_audit (
        user_type VARCHAR(36),
        date_time_created DATETIME2(6),
        num_records_loaded BIGINT,
        from_date DATETIME2(6),
        to_date DATETIME2(6)
    );
END;
