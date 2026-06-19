CREATE OR REPLACE VIEW eagles_alefdw_dev.school_dim_week AS
SELECT dsc.organisation_dw_id,
       dsc.school_dw_id,
       dsc.school_id,
       dsc.school_name,
       DATE_TRUNC('week',d.full_date)  AS week,
       COUNT(distinct d.full_date)     AS week_days
FROM alefdw.dim_date d
    CROSS JOIN bi_alefdw.bi_active_schools_dim_mv dsc
    LEFT JOIN (SELECT DISTINCT cast(holiday_date AS DATE) AS holiday_date,
               holiday_organisation_dw_id
               FROM alefdw.dim_holiday) dh
        ON dh.holiday_date = d.full_date
        AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
WHERE d.full_date >= academic_year_start_date
    AND d.full_date <= CURRENT_DATE -1
    AND holiday_date IS NULL
    AND DATE_PART(DOW, full_date) BETWEEN 1 AND 5
GROUP BY 1, 2, 3, 4, 5
WITH NO SCHEMA BINDING;