IF OBJECT_ID('${schema}.dagg_student_login_activity_dm', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.dagg_student_login_activity_dm
    (
        local_date DATE,
        academic_year Varchar(49),
        tenant_name Varchar(765),
        school_dw_id BIGINT,
        school_id Varchar(36),
        school_name Varchar(384),
        school_created_time DATETIME2(6),
        adek_id Varchar(256),
        school_city_name Varchar(100),
        school_organisation Varchar(250),
        school_country_name Varchar(100),
        school_composition Varchar(20),
        school_latitude DECIMAL(10, 6),
        school_longitude DECIMAL(10, 6),
        school_label VARCHAR(MAX),
        grade INT,
        class Varchar(1),
        section Varchar(112),
        student_tags Varchar(256),
        special_needs Varchar(3),
        school_provisioned_students BIGINT,
        week_number DECIMAL(18, 0),
        week_year_number INT,
        month_year_number INT,
        active_students BIGINT,
        weekly_active_students BIGINT,
        monthly_active_students BIGINT,
        hb_active_students BIGINT,
        hb_weekly_active_students BIGINT,
        hb_monthly_active_students BIGINT,
        total_students BIGINT,
        weekly_total_students BIGINT,
        monthly_total_students BIGINT,
        section_dw_id BIGINT,
        org_dw_id BIGINT,
        org_term INT,
        term_start_date DATE,
        term_end_date DATE,
        holiday_flag BIT,
        school_cx_cluster Varchar(50)
    );
END;

IF OBJECT_ID('${schema}.wagg_student_login_activity_dm', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.wagg_student_login_activity_dm
    (
        academic_year Varchar(49),
        tenant_name Varchar(765),
        school_dw_id BIGINT,
        school_id Varchar(36),
        school_name Varchar(384),
        school_created_time DATETIME2(6),
        adek_id Varchar(256),
        school_city_name Varchar(100),
        school_organisation Varchar(250),
        school_country_name Varchar(100),
        school_composition Varchar(20),
        school_label VARCHAR(MAX),
        grade INT,
        class Varchar(1),
        section Varchar(112),
        student_tags Varchar(256),
        special_needs Varchar(3),
        week_number DECIMAL(18, 0),
        week_year_number INT,
        weekly_active_students BIGINT,
        weekly_total_students BIGINT,
        section_dw_id BIGINT,
        org_dw_id BIGINT,
        org_term INT,
        term_start_date DATE,
        term_end_date DATE,
        holiday_flag BIT,
        school_cx_cluster Varchar(50),
        agg_type Varchar(6)
    );
END;

IF OBJECT_ID('${schema}.magg_student_login_activity_dm', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.magg_student_login_activity_dm
    (
        academic_year Varchar(49),
        tenant_name Varchar(765),
        school_dw_id BIGINT,
        school_id Varchar(36),
        school_name Varchar(384),
        school_created_time DATETIME2(6),
        adek_id Varchar(256),
        school_city_name Varchar(100),
        school_organisation Varchar(250),
        school_country_name Varchar(100),
        school_composition Varchar(20),
        school_label VARCHAR(MAX),
        grade INT,
        class Varchar(1),
        section Varchar(112),
        student_tags Varchar(256),
        special_needs Varchar(3),
        month_year_number INT,
        monthly_total_students BIGINT,
        monthly_active_students BIGINT,
        section_dw_id BIGINT,
        org_dw_id BIGINT,
        org_term INT,
        term_start_date DATE,
        term_end_date DATE,
        holiday_flag BIT,
        school_cx_cluster Varchar(50),
        agg_type Varchar(7)
    );
END;

IF OBJECT_ID('${schema}.heartbeat_teacher_login', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.heartbeat_teacher_login
    (
        login_date_dw_id      BIGINT,
        teacher_dw_id         BIGINT,
        tenant_dw_id          BIGINT,
        school_dw_id          BIGINT,
        login_local_date      DATETIME2(6),
        login_local_date_time DATETIME2(6)
    );
END;