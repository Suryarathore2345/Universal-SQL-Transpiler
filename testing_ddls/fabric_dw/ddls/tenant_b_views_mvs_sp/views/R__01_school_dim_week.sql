CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.school_dim_week AS
SELECT 
    dsc.organisation_dw_id,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    CONVERT(datetime2(7), DATETRUNC(iso_week, d.full_date)) AS week,
    COUNT(DISTINCT d.full_date) AS week_days
FROM ${RS_COREDW}.dim_date d
CROSS JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
LEFT JOIN (
        SELECT DISTINCT 
            CONVERT(DATE, holiday_date) AS holiday_date,
            holiday_organisation_dw_id
        FROM ${RS_COREDW}.dim_holiday
) dh
    ON dh.holiday_date = d.full_date
    AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
WHERE d.full_date >= dsc.academic_year_start_date
  AND d.full_date <= DATEADD(DAY, -1, CONVERT(DATE, SYSDATETIME()))
  AND dh.holiday_date IS NULL
  AND DATEPART(WEEKDAY, d.full_date) BETWEEN 2 AND 6
GROUP BY 
    dsc.organisation_dw_id,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    CONVERT(datetime2(7), DATETRUNC(iso_week, d.full_date));