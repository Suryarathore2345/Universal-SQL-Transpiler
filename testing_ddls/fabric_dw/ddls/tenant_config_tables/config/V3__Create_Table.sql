IF OBJECT_ID('${schema}.admin_mapping', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.admin_mapping (
        school_adek_id DECIMAL(18,0),
        school_id VARCHAR(500),
        school_name_en VARCHAR(5000),
        school_name_ar VARCHAR(5000),
        cluster VARCHAR(500),
        school_organization VARCHAR(500),
        tenant_name VARCHAR(500),
        need_report DECIMAL(5,0),
        user_unique_id VARCHAR(500),
        user_name_en VARCHAR(500),
        user_name_ar VARCHAR(500),
        user_email VARCHAR(500),
        user_role VARCHAR(500)
    );
END;


IF OBJECT_ID('${schema}.email_html_fragment', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.email_html_fragment (
        fragment_id DECIMAL(18,0),
        arabic_fragment VARCHAR(5000),
        english_fragment VARCHAR(5000),
        email_subject VARCHAR(250)
    );
END;


IF OBJECT_ID('${schema}.job_details', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.job_details (
        job_id INT,
        job_name VARCHAR(1000),
        email_fragment_id DECIMAL(18,0),
        is_active DECIMAL(18,0),
        report_path VARCHAR(1000),
        report_filter VARCHAR(100),
        report_refresh VARCHAR(100),
        report_export VARCHAR(100),
        start_date DATE,
        end_date DATE,
        report_type VARCHAR(50),
        report_type_id INT,
        user_role VARCHAR(50)
    );
END;


IF OBJECT_ID('${schema}.reporting_progress_status', 'U') IS NULL
BEGIN
    CREATE TABLE ${schema}.reporting_progress_status (
        user_email VARCHAR(300),
        user_role VARCHAR(50),
        job_name VARCHAR(1000),
        school_id VARCHAR(50),
        report_date DATE
    );
END;
