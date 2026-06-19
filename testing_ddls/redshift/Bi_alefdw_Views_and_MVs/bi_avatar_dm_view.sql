CREATE OR REPLACE VIEW bi_alefdw_dev.marketplace_avatar_dm_view
AS
SELECT DISTINCT
                cast(fit.fit_created_time as date)             as transaction_date,
                cast(fip.fip_created_time as date)             as purchase_date,
                fit.fit_student_dw_id                          as student_dw_id,
                da.avatar_dw_id,
                da.avatar_name,
                da.avatar_type                                 as avatar_type,
                fit.fit_item_type                              as avatar_item_type,
                da.avatar_file_id,
                da.avatar_star_cost                            as avatar_cost,
                fit.fit_available_stars                        as stars_before_buying,
                fit.fit_star_balance                           as stars_after_buying,
                fip.fip_redeemed_stars,
                da.avatar_category,
                da.avatar_app_status,
                da.avatar_description                          as avatar_description,
                fit.fit_item_id                                as avatar_id,
                dg.grade_name,
                fit.fit_grade_dw_id                            as grade_dw_id,
                ac.school_name,
                fit.fit_school_dw_id                           as school_dw_id,
                ac.tenant_name,
                fit.fit_tenant_dw_id                           as tenant_dw_id,
                ac.school_organisation,
                ac.academic_year_start_date,
                ac.academic_year_end_date,
                extract('year' from ac.academic_year_start_date) || '-' ||
                extract('year' from ac.academic_year_end_date) AS academic_year
FROM alefdw.dim_avatar da
         LEFT JOIN alefdw.fact_item_transaction fit
                   ON da.avatar_dw_id = fit.fit_item_dw_id
                       AND da.avatar_status = 1
         LEFT JOIN alefdw.fact_item_purchase fip
                   ON fip.fip_student_dw_id = fit.fit_student_dw_id
                       AND fip.fip_item_dw_id = fit.fit_item_dw_id
         LEFT JOIN alefdw.fact_user_avatar fua
                   ON fit.fit_student_dw_id = fua.fua_user_dw_id
                       AND fit.fit_item_dw_id = fua.fua_avatar_dw_id
         JOIN bi_alefdw.bi_active_schools_dim_mv ac
              ON ac.school_dw_id = fit.fit_school_dw_id
              AND ac.school_dw_id = fip.fip_school_dw_id
              AND (trunc(fit_created_time) >= ac.academic_year_start_date
              AND trunc(fit_created_time) <= ac.academic_year_end_date)
         JOIN bi_alefdw.bi_student_dim_mv dst
              ON fit.fit_student_dw_id = dst.student_dw_id
                  AND dst.student_status <> 4
         JOIN alefdw.dim_grade dg
              ON fit.fit_grade_dw_id = dg.grade_dw_id
                  AND fip.fip_grade_dw_id = dg.grade_dw_id
                  AND dg.academic_year_id = fit.fit_academic_year_id
                  AND dg.grade_status = 1
         WITH NO SCHEMA BINDING;