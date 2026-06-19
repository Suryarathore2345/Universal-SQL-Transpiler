CREATE MATERIALIZED VIEW bi_alefdw_dev.magg_student_kpi_historical_mv AUTO REFRESH YES AS
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
        grade_name,
        COUNT(student_dw_id) AS registered_students,
        COUNT(CASE WHEN date_trunc('month',first_login_date) = calendar_month_start_date then student_dw_id END ) AS onboarded_students,
        SUM(is_active) AS students_logged_in
    FROM bi_alefdw.students_stats_monthly
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
        school_name,
        grade_name
),
distinct_students AS (
    SELECT DISTINCT
        student_dw_id,
        calendar_month_start_date,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        academic_year_start_date,
        academic_year_end_date,
        school_dw_id,
        school_name,
        grade_name,
        first_login_date
    FROM bi_alefdw.students_stats_monthly
),
cumulative_distinct_students AS (
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
        grade_name,
        COUNT(DISTINCT ds.school_dw_id) AS reg_school_cumsum,
        COUNT(DISTINCT ds.student_dw_id) AS reg_student_cumsum,
        COUNT(DISTINCT CASE WHEN first_login_date >= ds.academic_year_start_date AND first_login_date <= last_day(ds.calendar_month_start_date)
                        THEN school_dw_id END) AS onb_school_cumsum,
        COUNT(DISTINCT CASE WHEN first_login_date >= ds.academic_year_start_date AND first_login_date <= last_day(ds.calendar_month_start_date)
                        THEN student_dw_id END) AS onb_student_cumsum
    FROM (
        SELECT DISTINCT calendar_month_start_date,academic_year_start_date,academic_year_end_date
        FROM bi_alefdw.students_stats_monthly
    ) cm
    LEFT JOIN distinct_students ds
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
        ds.school_name,
        ds.grade_name
),
CY_stats AS (SELECT
        calendar_year_end_date,
        tenant_dw_id,
        tenant_name,
        content_repository_dw_id,
        content_repository_name,
        COUNT(DISTINCT student_dw_id) AS registered_students_cy,
        COUNT(DISTINCT CASE WHEN (first_login_date between academic_year_start_date and academic_year_end_date AND
                                  first_login_date <= calendar_year_end_date AND is_active = 1) THEN student_dw_id END) AS onboarded_students_cy
    FROM bi_alefdw.students_stats_monthly
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
        grade_name,
        COUNT(DISTINCT student_dw_id) AS registered_students_ay,
        COUNT(DISTINCT CASE WHEN first_login_date BETWEEN academic_year_start_date AND academic_year_end_date
            THEN student_dw_id END) AS onboarded_students_ay
    FROM bi_alefdw.students_stats_monthly
    GROUP BY 1,2,3,4,5,6,7,8,9),
max_insert_date AS (
    SELECT MAX(inserted_at) AS inserted_at  FROM bi_alefdw.students_stats_monthly
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
                                                                                DATE_TRUNC('year', cum_stu.calendar_month_start_date))))) as calendar_year_end_date,
             coalesce(reg.calendar_month_start_date,
                      cum_stu.calendar_month_start_date)                                                                                  as calendar_month_start_date,
             coalesce(reg.calendar_month_end_date,
                      last_day(cum_stu.calendar_month_start_date))                                                                        as calendar_month_end_date,
             coalesce(reg.tenant_dw_id, cum_stu.tenant_dw_id)                                                                             as tenant_dw_id,
             coalesce(reg.tenant_name, cum_stu.tenant_name)                                                                               as tenant_name,
             coalesce(reg.content_repository_dw_id,
                      cum_stu.content_repository_dw_id)                                                                                   as content_repository_dw_id,
             coalesce(reg.content_repository_name,
                      cum_stu.content_repository_name)                                                                                    as content_repository_name,
             coalesce(reg.academic_year_start_date,
                      cum_stu.academic_year_start_date)                                                                                   as academic_year_start_date,
             coalesce(reg.academic_year_end_date, cum_stu.academic_year_end_date)                                                         as academic_year_end_date,
             coalesce(reg.school_dw_id, cum_stu.school_dw_id)                                                                             as school_dw_id,
             coalesce(reg.school_name, cum_stu.school_name)                                                                               as school_name,
             coalesce(reg.grade_name, cum_stu.grade_name)                                                                                 as grade_name,
             coalesce(reg.ay, cum_stu.ay)                                                                                                 as ay,
             registered_students,
             onboarded_students,
             students_logged_in,
             cum_stu.reg_school_cumsum,
             cum_stu.reg_student_cumsum,
             cum_stu.onb_school_cumsum,
             cum_stu.onb_student_cumsum,
             DENSE_RANK() OVER (
                 PARTITION BY reg.academic_year_start_date,
                     reg.academic_year_end_date,
                     reg.tenant_dw_id,
                     reg.tenant_name,
                     reg.content_repository_dw_id
                 ORDER BY reg.calendar_month_start_date asc
                 )                                                                                                                        AS ay_rank,
             registered_students_cy,
             onboarded_students_cy,
             registered_students_ay,
             onboarded_students_ay,
             ins.inserted_at
      FROM reg_data reg
               FULL JOIN cumulative_distinct_students cum_stu
                         ON reg.calendar_month_start_date = cum_stu.calendar_month_start_date
                             AND reg.tenant_dw_id = cum_stu.tenant_dw_id
                             AND reg.tenant_name = cum_stu.tenant_name
                             AND reg.content_repository_dw_id = cum_stu.content_repository_dw_id
                             AND reg.school_dw_id = cum_stu.school_dw_id
                             AND reg.grade_name = cum_stu.grade_name
                             AND reg.academic_year_end_date = cum_stu.academic_year_end_date
                             AND reg.academic_year_start_date = cum_stu.academic_year_start_date
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
          AND reg.grade_name = AY_stats.grade_name
               CROSS JOIN max_insert_date ins) dt
