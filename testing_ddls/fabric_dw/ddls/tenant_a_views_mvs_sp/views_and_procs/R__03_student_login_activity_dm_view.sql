CREATE OR ALTER VIEW ${os_bi_coredw}.student_login_activity_dm_view AS
WITH provisioned_students AS -- School Level
(
    SELECT 
        CONVERT(DATE, student_first_created_date) AS student_first_created_date,
        student_school_dw_id,
        COUNT(DISTINCT student_dw_id) AS school_provisioned_students
    FROM ${rs_bi_coredw}.bi_student_dim
    GROUP BY 
        CONVERT(DATE, student_first_created_date),
        student_school_dw_id
)
SELECT DISTINCT 
    ts.local_date,
    ts.academic_year,
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_status,
    dsc.school_created_time,
    ts.adek_id,
    dsc.school_city_name,
    dsc.school_organisation,
    dsc.school_country_name,
    dsc.school_composition,
    dsc.school_latitude,
    dsc.school_longitude,
    dsc.school_label,
    ts.grade,
    UPPER(ts.class)       AS class,
    UPPER(ts.section)     AS section,
    ts.student_tags,
    ts.student_special_needs AS special_needs,
    ps.school_provisioned_students,
    ts.week_number,
    ts.week_year_number,
    ts.month_year_number,
    log.daily_active_students      AS active_students,
    log.weekly_active_students,
    log.monthly_active_students,
    ts.total_students,
    ts.weekly_total_students,
    ts.monthly_total_students,
    ts.section_dw_id,
    ts.org_dw_id,
    ts.holiday_flag,
    CASE 
        WHEN TRIM(ts.school_cx_cluster) = '' THEN NULL
        ELSE ts.school_cx_cluster
    END AS school_cx_cluster
FROM ${rs_bi_coredw}.total_students ts
INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim dsc
    ON ts.school_dw_id = dsc.school_dw_id
   AND ts.local_date >= dsc.academic_year_start_date
   AND ts.local_date >= dsc.academic_year_start_date
LEFT JOIN ${rs_bi_coredw}.student_login_aggregated log
    ON ts.school_dw_id    = log.school_dw_id
   AND ts.local_date      = log.local_date
   AND ts.section_dw_id   = log.student_section_dw_id
   AND ts.student_special_needs 
       = log.student_special_needs
   AND ts.student_tags
       = log.student_tags
LEFT JOIN provisioned_students ps
    ON ts.school_dw_id   = ps.student_school_dw_id
   AND ts.local_date     = ps.student_first_created_date
WHERE ts.local_date BETWEEN 
          CONVERT(
              DATE,
              DATEADD(MONTH, -36, DATETRUNC(month, CONVERT(DATE, GETDATE())))
          )
      AND CONVERT(DATE, GETDATE());
    