CREATE OR ALTER VIEW ${os_bi_coredw}.marketplace_avatar_dm_view
AS
SELECT DISTINCT
       CONVERT(DATE, fit.fit_created_time)  AS transaction_date,
       CONVERT(DATE, fip.fip_created_time)  AS purchase_date,
       fit.fit_student_dw_id               AS student_dw_id,
       da.avatar_dw_id,
       da.avatar_name,
       da.avatar_type                      AS avatar_type,
       fit.fit_item_type                   AS avatar_item_type,
       da.avatar_file_id,
       da.avatar_star_cost                 AS avatar_cost,
       fit.fit_available_stars             AS stars_before_buying,
       fit.fit_star_balance                AS stars_after_buying,
       fip.fip_redeemed_stars,
       da.avatar_category,
       da.avatar_app_status,
       da.avatar_description               AS avatar_description,
       fit.fit_item_id                     AS avatar_id,
       dg.grade_name,
       fit.fit_grade_dw_id                 AS grade_dw_id,
       ac.school_name,
       fit.fit_school_dw_id                AS school_dw_id,
       ac.tenant_name,
       fit.fit_tenant_dw_id                AS tenant_dw_id,
       ac.school_organisation,
       ac.academic_year_start_date,
       ac.academic_year_end_date,
       -- academic_year as 'YYYY-YYYY'
       CONVERT(VARCHAR(4), YEAR(ac.academic_year_start_date))
           + '-' +
       CONVERT(VARCHAR(4), YEAR(ac.academic_year_end_date)) AS academic_year
FROM ${rs_coredw}.dim_avatar da
LEFT JOIN ${rs_coredw}.fact_item_transaction fit
       ON da.avatar_dw_id = fit.fit_item_dw_id
      AND da.avatar_status = 1
LEFT JOIN ${rs_coredw}.fact_item_purchase fip
       ON fip.fip_student_dw_id = fit.fit_student_dw_id
      AND fip.fip_item_dw_id    = fit.fit_item_dw_id
LEFT JOIN ${rs_coredw}.fact_user_avatar fua
       ON fit.fit_student_dw_id = fua.fua_user_dw_id
      AND fit.fit_item_dw_id    = fua.fua_avatar_dw_id
JOIN ${rs_bi_coredw}.bi_active_schools_dim ac
     ON ac.school_dw_id = fit.fit_school_dw_id
    AND ac.school_dw_id = fip.fip_school_dw_id
    AND fit.fit_created_time >= CONVERT(DATETIME2, ac.academic_year_start_date)
    AND fit.fit_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, ac.academic_year_end_date))
    JOIN ${rs_bi_coredw}.bi_student_dim dst
     ON fit.fit_student_dw_id = dst.student_dw_id
    AND dst.student_status <> 4
JOIN ${rs_coredw}.dim_grade dg
     ON fit.fit_grade_dw_id = dg.grade_dw_id
    AND fip.fip_grade_dw_id = dg.grade_dw_id
    AND dg.academic_year_id = fit.fit_academic_year_id
    AND dg.grade_status = 1;
