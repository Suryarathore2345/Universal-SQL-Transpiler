CREATE OR ALTER VIEW ${os_bi_coredw}.student_activity_hourly_log_dm_view AS

WITH active_years AS (
    SELECT DISTINCT CONVERT(VARCHAR(100), academic_year_id) AS academic_year_id
    FROM ${rs_bi_coredw}.bi_active_schools_dim
),

current_ay_grade AS (
    SELECT DISTINCT
        g.grade_k12grade,
        g.grade_dw_id
    FROM ${rs_coredw}.dim_grade g
    INNER JOIN active_years ay
        ON g.academic_year_id = ay.academic_year_id
),

tenant_tz AS (
    
    SELECT DISTINCT
        tenant_dw_id,
        ISNULL(windows_timezone, 'UTC') AS windows_timezone
    FROM ${rs_coredw}.dim_tenant
),


grade_filtered_fsta AS (
    SELECT
        fsta.fsta_school_dw_id,
        fsta.fsta_student_dw_id,
        fsta.fsta_tenant_dw_id,
        fsta.fsta_grade_dw_id,
        fsta.fsta_created_time,
        gr.grade_k12grade
    FROM ${rs_coredw}.fact_student_activities fsta
    INNER JOIN current_ay_grade gr
        ON fsta.fsta_grade_dw_id = gr.grade_dw_id
),


converted_fsta AS (
    SELECT
        fsta.fsta_school_dw_id,
        fsta.fsta_student_dw_id,
        fsta.grade_k12grade,
        fsta.fsta_created_time
            AT TIME ZONE 'UTC'
            AT TIME ZONE t.windows_timezone    AS local_created_time
    FROM grade_filtered_fsta fsta
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim sch_filter
        ON fsta.fsta_school_dw_id = sch_filter.school_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_student_dim st
        ON fsta.fsta_student_dw_id = st.student_dw_id
       AND st.student_status = 1
    INNER JOIN tenant_tz t
        ON t.tenant_dw_id = fsta.fsta_tenant_dw_id
)

SELECT
    local_date,
    hour,
    dow,
    school_dw_id,
    school_name,
    tenant_name,
    school_organisation,
    school_label,
    school_country_name,
    school_city_name,
    school_composition,
    grade_k12grade,
    student_tags,
    student_special_needs,
    COUNT_BIG(1) AS activities
FROM (
    SELECT
        CONVERT(DATE, fsta.local_created_time)          AS local_date,
        DATEPART(HOUR, fsta.local_created_time)         AS hour,
        CONVERT(FLOAT(53),DATEPART(WEEKDAY, fsta.local_created_time) - 1)  AS dow,
        sch.school_dw_id,
        sch.school_name,
        sch.tenant_name,
        sch.school_organisation,
        sch.school_label,
        sch.school_country_name,
        sch.school_city_name,
        sch.school_composition,
        fsta.grade_k12grade,
        st.student_tags,
        st.student_special_needs
    FROM converted_fsta fsta
    
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
        ON fsta.fsta_school_dw_id = sch.school_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_student_dim st
        ON fsta.fsta_student_dw_id = st.student_dw_id
       AND st.student_status = 1
) grouped_data
GROUP BY
    local_date, hour, dow,
    school_dw_id, school_name, tenant_name,
    school_organisation, school_label,
    school_country_name, school_city_name,
    school_composition, grade_k12grade,
    student_tags, student_special_needs;