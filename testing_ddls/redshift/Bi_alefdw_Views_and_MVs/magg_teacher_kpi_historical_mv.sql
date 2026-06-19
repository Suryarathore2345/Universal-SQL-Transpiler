CREATE MATERIALIZED VIEW bi_alefdw_dev.magg_teacher_kpi_historical_mv AUTO REFRESH YES AS
WITH reg_data AS (
    SELECT
        calendar_year_end_date,
        calendar_month_end_date,
        calendar_month_start_date,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        academic_year_start_date,
        academic_year_end_date,
        ay,
        school_dw_id,
        school_name,
        COUNT(teacher_dw_id) AS registered_teachers,
        COUNT(CASE WHEN date_trunc('month',first_login_date) = calendar_month_start_date then teacher_dw_id END ) AS onboarded_teachers,
        SUM(is_active) AS teachers_logged_in
    FROM bi_alefdw.teacher_stats_monthly
    GROUP BY
        calendar_year_end_date,
        calendar_month_end_date,
        calendar_month_start_date,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        academic_year_start_date,
        academic_year_end_date,
        ay,
        school_dw_id,
        school_name
),
distinct_teachers AS (
    SELECT DISTINCT
        teacher_dw_id,
        calendar_month_start_date,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        academic_year_start_date,
        academic_year_end_date,
        school_dw_id,
        school_name,
        first_login_date
    FROM bi_alefdw.teacher_stats_monthly
),
cumulative_distinct_teachers AS (
    SELECT
        cm.calendar_month_start_date,
        ds.tenant_dw_id,
        ds.tenant_name,
        ds.content_repository_name,
        ds.content_repository_dw_id,
        ds.academic_year_start_date,
        ds.academic_year_end_date,
        CAST(DATE_PART('year', ds.academic_year_start_date) AS VARCHAR) || '-' ||
        CAST(DATE_PART('year', ds.academic_year_end_date) AS VARCHAR) AS AY,
        school_dw_id,
        school_name,
        COUNT(DISTINCT ds.teacher_dw_id) AS reg_teacher_cumsum,
        COUNT(DISTINCT CASE WHEN first_login_date >= ds.academic_year_start_date AND first_login_date <= last_day(ds.calendar_month_start_date)
                        THEN teacher_dw_id END) AS onb_teacher_cumsum
    FROM (
        SELECT DISTINCT calendar_month_start_date,academic_year_start_date,academic_year_end_date
        FROM bi_alefdw.teacher_stats_monthly
    ) cm
    LEFT JOIN distinct_teachers ds
        ON ds.calendar_month_start_date <= cm.calendar_month_start_date
        AND ds.academic_year_start_date = cm.academic_year_start_date
        AND cm.calendar_month_start_date BETWEEN date_trunc('month',ds.academic_year_start_date)
            AND date_trunc('month',ds.academic_year_end_date)
    GROUP BY
        cm.calendar_month_start_date,
        ds.tenant_dw_id,
        ds.tenant_name,
        ds.content_repository_dw_id,
        ds.content_repository_name,
        ds.academic_year_start_date,
        ds.academic_year_end_date,
        AY,
        ds.school_dw_id,
        ds.school_name
),
CY_stats AS (SELECT
        calendar_year_end_date,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        COUNT(DISTINCT teacher_dw_id) AS registered_teachers_cy,
        COUNT(DISTINCT CASE WHEN (first_login_date BETWEEN academic_year_start_date and academic_year_end_date AND
                                  first_login_date <= calendar_year_end_date AND is_active = 1) THEN teacher_dw_id END) AS onboarded_teachers_cy
    FROM bi_alefdw.teacher_stats_monthly
    GROUP BY 1,2,3,4,5
    ),
AY_stats AS (SELECT
        academic_year_start_date,
        academic_year_end_date,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        school_dw_id,
        school_name,
        COUNT(DISTINCT teacher_dw_id) AS registered_teachers_ay,
        COUNT(DISTINCT CASE WHEN first_login_date BETWEEN academic_year_start_date AND academic_year_end_date
            THEN teacher_dw_id END) AS onboarded_teachers_ay
    FROM bi_alefdw.teacher_stats_monthly
    GROUP BY 1,2,3,4,5,6,7,8),
max_insert_date AS (
    SELECT MAX(inserted_at) as inserted_at  FROM bi_alefdw.teacher_stats_monthly
                              )
SELECT dt.*,
        DENSE_RANK() OVER (
        PARTITION BY calendar_month_start_date,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id
        ORDER BY date_part('year',academic_year_end_date) DESC
    ) AS dense_rank
FROM (SELECT date(coalesce(reg.calendar_year_end_date, DATEADD(day, -1, DATEADD(year, 1,
                                                                                DATE_TRUNC('year', cum_tch.calendar_month_start_date))))) as calendar_year_end_date,
             coalesce(reg.calendar_month_start_date,
                      cum_tch.calendar_month_start_date)                                                                                  as calendar_month_start_date,
             coalesce(reg.calendar_month_end_date,
                      last_day(cum_tch.calendar_month_start_date))                                                                        as calendar_month_end_date,
             coalesce(reg.tenant_dw_id, cum_tch.tenant_dw_id)                                                                             as tenant_dw_id,
             coalesce(reg.tenant_name, cum_tch.tenant_name)                                                                               as tenant_name,
             coalesce(reg.content_repository_dw_id,
                      cum_tch.content_repository_dw_id)                                                                                   as content_repository_dw_id,
             coalesce(reg.content_repository_name,
                      cum_tch.content_repository_name)                                                                                    as content_repository_name,
             coalesce(reg.academic_year_start_date,
                      cum_tch.academic_year_start_date)                                                                                   as academic_year_start_date,
             coalesce(reg.academic_year_end_date, cum_tch.academic_year_end_date)                                                         as academic_year_end_date,
             coalesce(reg.school_dw_id, cum_tch.school_dw_id)                                                                             as school_dw_id,
             coalesce(reg.school_name, cum_tch.school_name)                                                                               as school_name,
             coalesce(reg.ay, cum_tch.ay)                                                                                                 as ay,
             registered_teachers,
             onboarded_teachers,
             teachers_logged_in,
             cum_tch.reg_teacher_cumsum,
             cum_tch.onb_teacher_cumsum,
             registered_teachers_cy,
             onboarded_teachers_cy,
             registered_teachers_ay,
             onboarded_teachers_ay,
             ins.inserted_at
      FROM reg_data reg
               FULL JOIN cumulative_distinct_teachers cum_tch
                         ON reg.calendar_month_start_date = cum_tch.calendar_month_start_date
                             AND reg.tenant_dw_id = cum_tch.tenant_dw_id
                             AND reg.tenant_name = cum_tch.tenant_name
                             AND reg.content_repository_dw_id = cum_tch.content_repository_dw_id
                             AND reg.school_dw_id = cum_tch.school_dw_id
                             AND reg.academic_year_end_date = cum_tch.academic_year_end_date
                             AND reg.academic_year_start_date = cum_tch.academic_year_start_date
               LEFT JOIN CY_stats ON reg.calendar_year_end_date = CY_stats.calendar_year_end_date
          AND reg.tenant_dw_id = CY_stats.tenant_dw_id
          AND reg.tenant_name = CY_stats.tenant_name
          AND reg.content_repository_dw_id = CY_stats.content_repository_dw_id
               LEFT JOIN AY_stats ON reg.academic_year_start_date = AY_stats.academic_year_start_date
          AND reg.academic_year_end_date = AY_stats.academic_year_end_date
          AND reg.tenant_dw_id = AY_stats.tenant_dw_id
          AND reg.tenant_name = AY_stats.tenant_name
          AND reg.content_repository_dw_id = AY_stats.content_repository_dw_id
          AND reg.school_dw_id = AY_stats.school_dw_id
               CROSS JOIN max_insert_date ins) dt
