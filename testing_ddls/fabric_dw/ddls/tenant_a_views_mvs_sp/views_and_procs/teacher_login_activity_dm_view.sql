CREATE OR ALTER VIEW ${os_bi_coredw}.teacher_login_activity_dm_view AS
WITH provisoned_teachers AS (
    SELECT
        teacher_created_date,
        teacher_school_dw_id,
        COUNT(DISTINCT teacher_dw_id) AS school_provisoned_teachers
    FROM (
        SELECT DISTINCT
            dt.teacher_dw_id,
            dt.teacher_school_dw_id,
            FIRST_VALUE(CONVERT(DATE, dt.teacher_created_time)) OVER (
                PARTITION BY dt.teacher_dw_id
                ORDER BY dt.teacher_created_time ASC
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            ) AS teacher_created_date
        FROM ${rs_coredw}.dim_teacher dt
        WHERE NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = dt.teacher_id)  -- OPT-8
    ) t
    GROUP BY
        teacher_created_date,
        teacher_school_dw_id
)
SELECT DISTINCT
    tt.local_date,
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_created_time,
    dsc.school_status,
    tt.adek_id,
    dsc.school_city_name,
    dsc.school_organisation,
    dsc.school_country_name,
    dsc.school_composition,
    dsc.school_latitude,
    dsc.school_longitude,
    dsc.school_label,
    pv.school_provisoned_teachers,
    tt.week_number,
    tt.week_year_number,
    tt.month_year_number,
    log.daily_active_teachers   AS active_teachers,
    log.weekly_active_teachers,
    log.monthly_active_teachers,
    tt.total_teachers,
    tt.weekly_total_teachers,
    tt.monthly_total_teachers,
    tt.academic_year,
    tt.org_dw_id,
    tt.holiday_flag,
    CASE 
        WHEN TRIM(tt.school_cx_cluster) = '' THEN NULL
        ELSE tt.school_cx_cluster
    END AS school_cx_cluster,
    CASE WHEN st.school_dw_id IS NULL THEN 'NO' ELSE 'YES' END AS school_with_students
FROM ${rs_bi_coredw}.total_teachers tt
INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim dsc
    ON tt.school_dw_id = dsc.school_dw_id
   AND tt.local_date >= dsc.academic_year_start_date
   AND tt.local_date >= dsc.academic_year_start_date
LEFT JOIN ${rs_bi_coredw}.teacher_login_aggregated log
    ON tt.school_dw_id = log.school_dw_id
   AND tt.local_date  = log.local_date
LEFT JOIN ${rs_bi_coredw}.total_students st
    ON tt.school_dw_id = st.school_dw_id
   AND tt.local_date   = st.local_date
LEFT JOIN provisoned_teachers pv
    ON tt.school_dw_id = pv.teacher_school_dw_id
   AND tt.local_date   = pv.teacher_created_date
WHERE tt.local_date BETWEEN
          CONVERT(DATE, DATEADD(MONTH, -36, DATETRUNC(MONTH, CONVERT(DATE, GETDATE()))))
      AND CONVERT(DATE, GETDATE());