CREATE OR ALTER VIEW ${os_bi_coredw}.teacher_activity_rolling_period_view
AS
WITH active_teacher_period AS (
    SELECT
        tl.teacher_dw_id,
        tl.school_dw_id,

        COUNT(DISTINCT CASE
            WHEN CONVERT(date, tl.login_local_date_time)
                 BETWEEN DATEADD(day, -7, CONVERT(date, GETDATE()))
                     AND DATEADD(day, -1, CONVERT(date, GETDATE()))
            THEN CONVERT(date, tl.login_local_date_time)
        END) AS active_days_last7d,

        COUNT(DISTINCT CASE
            WHEN CONVERT(date, tl.login_local_date_time)
                 BETWEEN DATEADD(day, -14, CONVERT(date, GETDATE()))
                     AND DATEADD(day, -8, CONVERT(date, GETDATE()))
            THEN CONVERT(date, tl.login_local_date_time)
        END) AS active_days_prev7d,

        COUNT(DISTINCT CASE
            WHEN CONVERT(date, tl.login_local_date_time)
                 BETWEEN DATEADD(day, -30, CONVERT(date, GETDATE()))
                     AND DATEADD(day, -1, CONVERT(date, GETDATE()))
            THEN CONVERT(date, tl.login_local_date_time)
        END) AS active_days_last30d,

        COUNT(DISTINCT CASE
            WHEN CONVERT(date, tl.login_local_date_time)
                 BETWEEN DATEADD(day, -60, CONVERT(date, GETDATE()))
                     AND DATEADD(day, -31, CONVERT(date, GETDATE()))
            THEN CONVERT(date, tl.login_local_date_time)
        END) AS active_days_prev30d
    FROM ${rs_bi_coredw}.teacher_login tl
    GROUP BY
        tl.teacher_dw_id,
        tl.school_dw_id
),

teacher_onboarding AS (
    SELECT DISTINCT
        tl.teacher_dw_id,
        tl.school_dw_id,

        FIRST_VALUE(tl.login_local_date_time) OVER (
            PARTITION BY tl.teacher_dw_id, tl.school_dw_id
            ORDER BY tl.login_local_date_time ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_first_login_date,

        FIRST_VALUE(tl.login_local_date_time) OVER (
            PARTITION BY tl.teacher_dw_id, tl.school_dw_id
            ORDER BY tl.login_local_date_time DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS teacher_last_login_date

    FROM ${rs_bi_coredw}.teacher_login tl
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
        ON ds.school_dw_id = tl.school_dw_id
       AND CONVERT(date, tl.login_local_date_time) >= ds.academic_year_start_date
)

SELECT DISTINCT
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_alias AS adek_id,
    dsc.school_city_name,
    dsc.school_organisation,
    dsc.organisation_dw_id,

    dt.teacher_dw_id,
    dt.teacher_id,

    FIRST_VALUE(CONVERT(date, dt.teacher_created_time)) OVER (
        PARTITION BY dt.teacher_dw_id
        ORDER BY dt.teacher_created_time
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS teacher_first_created_date,

    ton.teacher_first_login_date,
    ton.teacher_last_login_date,

    CONVERT(varchar(4), YEAR(dsc.academic_year_start_date)) + '-' +
    CONVERT(varchar(4), YEAR(dsc.academic_year_end_date)) AS academic_year,

    ISNULL(atp.active_days_last7d, 0)  AS active_days_last7d,
    ISNULL(atp.active_days_prev7d, 0)  AS active_days_prev7d,
    ISNULL(atp.active_days_last30d, 0) AS active_days_last30d,
    ISNULL(atp.active_days_prev30d, 0) AS active_days_prev30d

FROM ${rs_coredw}.dim_teacher dt
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
    ON dsc.school_dw_id = dt.teacher_school_dw_id

LEFT JOIN active_teacher_period atp
    ON atp.teacher_dw_id = dt.teacher_dw_id
   AND atp.school_dw_id  = dt.teacher_school_dw_id

LEFT JOIN teacher_onboarding ton
    ON ton.teacher_dw_id = dt.teacher_dw_id
   AND ton.school_dw_id  = dt.teacher_school_dw_id

WHERE dt.teacher_status = 1;
