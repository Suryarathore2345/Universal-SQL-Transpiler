CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.fact_learning_experience_silver_mv
AS
WITH date_references AS (
    SELECT
        date_sub(current_date(), 1)                                              AS curent_date,
        add_months(date_sub(current_date(), 1), -12)                             AS last_year_date,
        add_months(date_sub(current_date(), 1), -24)                             AS two_years_ago_date,
        CAST(date_trunc('year', date_sub(current_date(), 1)) AS DATE)            AS current_year_start,
        CAST(date_trunc('year', add_months(date_sub(current_date(), 1), -12)) AS DATE) AS last_year_start,
        CAST(date_trunc('year', add_months(date_sub(current_date(), 1), -24)) AS DATE) AS two_years_ago_start,
        datediff(
            date_sub(current_date(), 1),
            date_trunc('year', date_sub(current_date(), 1))
        ) + 1                                                                    AS days_ytd
),
date_flags AS (
    SELECT
        dd.full_date,
        dr.curent_date,
        -- current period flags
        CASE WHEN dd.full_date BETWEEN dr.curent_date - INTERVAL 6 DAYS AND dr.curent_date THEN 1 ELSE 0 END AS is_last_7_days,
        CASE WHEN dd.full_date BETWEEN dr.curent_date - INTERVAL 13 DAYS AND dr.curent_date THEN 1 ELSE 0 END AS is_last_14_days,
        CASE WHEN dd.full_date BETWEEN dr.curent_date - INTERVAL 29 DAYS AND dr.curent_date THEN 1 ELSE 0 END AS is_last_30_days,
        CASE WHEN dd.full_date BETWEEN dr.curent_date - INTERVAL 89 DAYS AND dr.curent_date THEN 1 ELSE 0 END AS is_last_90_days,
        CASE WHEN dd.full_date BETWEEN dr.current_year_start AND dr.curent_date THEN 1 ELSE 0 END             AS is_ytd,
        -- previous period flags
        CASE WHEN dd.full_date BETWEEN dr.curent_date - INTERVAL 13 DAYS AND dr.curent_date - INTERVAL 7 DAYS  THEN 1 ELSE 0 END AS is_last_7_days_pp,
        CASE WHEN dd.full_date BETWEEN dr.curent_date - INTERVAL 27 DAYS AND dr.curent_date - INTERVAL 14 DAYS THEN 1 ELSE 0 END AS is_last_14_days_pp,
        CASE WHEN dd.full_date BETWEEN dr.curent_date - INTERVAL 59 DAYS AND dr.curent_date - INTERVAL 30 DAYS THEN 1 ELSE 0 END AS is_last_30_days_pp,
        CASE WHEN dd.full_date BETWEEN dr.curent_date - INTERVAL 179 DAYS AND dr.curent_date - INTERVAL 90 DAYS THEN 1 ELSE 0 END AS is_last_90_days_pp,
        CASE WHEN dd.full_date BETWEEN dr.current_year_start - dr.days_ytd AND dr.current_year_start - INTERVAL 1 DAY THEN 1 ELSE 0 END AS is_ytd_pp,
        -- last year flags
        CASE WHEN dd.full_date BETWEEN dr.last_year_date - INTERVAL 6 DAYS AND dr.last_year_date THEN 1 ELSE 0 END   AS is_last_7_days_ly,
        CASE WHEN dd.full_date BETWEEN dr.last_year_date - INTERVAL 13 DAYS AND dr.last_year_date THEN 1 ELSE 0 END  AS is_last_14_days_ly,
        CASE WHEN dd.full_date BETWEEN dr.last_year_date - INTERVAL 29 DAYS AND dr.last_year_date THEN 1 ELSE 0 END  AS is_last_30_days_ly,
        CASE WHEN dd.full_date BETWEEN dr.last_year_date - INTERVAL 89 DAYS AND dr.last_year_date THEN 1 ELSE 0 END  AS is_last_90_days_ly,
        CASE WHEN dd.full_date BETWEEN dr.last_year_start AND dr.last_year_date THEN 1 ELSE 0 END                    AS is_ytd_ly,
        -- 2 years ago flags
        CASE WHEN dd.full_date BETWEEN dr.two_years_ago_date - INTERVAL 6 DAYS AND dr.two_years_ago_date THEN 1 ELSE 0 END   AS is_last_7_days_2ya,
        CASE WHEN dd.full_date BETWEEN dr.two_years_ago_date - INTERVAL 13 DAYS AND dr.two_years_ago_date THEN 1 ELSE 0 END  AS is_last_14_days_2ya,
        CASE WHEN dd.full_date BETWEEN dr.two_years_ago_date - INTERVAL 29 DAYS AND dr.two_years_ago_date THEN 1 ELSE 0 END  AS is_last_30_days_2ya,
        CASE WHEN dd.full_date BETWEEN dr.two_years_ago_date - INTERVAL 89 DAYS AND dr.two_years_ago_date THEN 1 ELSE 0 END  AS is_last_90_days_2ya,
        CASE WHEN dd.full_date BETWEEN dr.two_years_ago_start AND dr.two_years_ago_date THEN 1 ELSE 0 END                    AS is_ytd_2ya
    FROM {{rs_coredw}}.dim_date AS dd
    CROSS JOIN date_references AS dr
    WHERE dd.full_date >= dr.two_years_ago_start
      AND dd.full_date <= dr.curent_date
)
SELECT
    CAST(from_utc_timestamp(fle.fle_created_time, sch.tenant_timezone) AS DATE) AS local_date,
    sch.tenant_name,
    sch.school_organisation,
    sch.school_name,
    sch.school_id,
    sch.school_dw_id,
    sch.school_country_name,
    sch.school_city_name,
    sch.school_label,
    sch.school_status,
    cont.grade_name,
    fle.fle_student_dw_id,
    CASE
        WHEN grouping(cont.class_gen_subject) = 1 THEN 'All'
        ELSE cont.class_gen_subject
    END AS class_gen_subject,
    MAX(df.curent_date)              AS curent_date,
    MAX(df.is_last_7_days)           AS is_last_7_days,
    MAX(df.is_last_7_days_pp)        AS is_last_7_days_pp,
    MAX(df.is_last_7_days_ly)        AS is_last_7_days_ly,
    MAX(df.is_last_7_days_2ya)       AS is_last_7_days_2ya,
    MAX(df.is_last_14_days)          AS is_last_14_days,
    MAX(df.is_last_14_days_pp)       AS is_last_14_days_pp,
    MAX(df.is_last_14_days_ly)       AS is_last_14_days_ly,
    MAX(df.is_last_14_days_2ya)      AS is_last_14_days_2ya,
    MAX(df.is_last_30_days)          AS is_last_30_days,
    MAX(df.is_last_30_days_pp)       AS is_last_30_days_pp,
    MAX(df.is_last_30_days_ly)       AS is_last_30_days_ly,
    MAX(df.is_last_30_days_2ya)      AS is_last_30_days_2ya,
    MAX(df.is_last_90_days)          AS is_last_90_days,
    MAX(df.is_last_90_days_pp)       AS is_last_90_days_pp,
    MAX(df.is_last_90_days_ly)       AS is_last_90_days_ly,
    MAX(df.is_last_90_days_2ya)      AS is_last_90_days_2ya,
    MAX(df.is_ytd)                   AS is_ytd,
    MAX(df.is_ytd_pp)                AS is_ytd_pp,
    MAX(df.is_ytd_ly)                AS is_ytd_ly,
    MAX(df.is_ytd_2ya)               AS is_ytd_2ya,
    COUNT(DISTINCT fle.fle_lo_dw_id) AS total_lessons_learned,
    COUNT(DISTINCT CASE
        WHEN fle.fle_completion_node IS TRUE
            THEN fle.fle_lo_dw_id
    END)                             AS total_completed_lessons,
    COUNT(DISTINCT CASE
        WHEN fle.fle_completion_node IS TRUE
         AND lo.lo_max_stars > 0
            THEN lo.lo_dw_id
    END)                             AS total_completed_lessons_score,
    SUM(CASE
        WHEN fle.fle_completion_node IS TRUE
         AND lo.lo_max_stars > 0
         AND fle.fle_is_retry IS FALSE
         AND fle.fle_is_activity_completed IS FALSE
            THEN fle.fle_total_score
    END)                             AS fle_score,
    SUM(CASE
        WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
        WHEN fle.fle_total_time > 900  THEN 900
        ELSE 0
    END)                             AS session_time
FROM {{rs_coredw}}.fact_learning_experience AS fle
JOIN {{rs_coredw}}.dim_learning_objective AS lo
    ON lo.lo_dw_id  = fle.fle_lo_dw_id
   AND lo.lo_status = 1
JOIN {{rs_bi_coredw}}.bi_all_schools_dim AS sch
    ON sch.school_dw_id = fle.fle_school_dw_id
   AND DATE(fle.fle_created_time) >= sch.academic_year_start_date
   AND DATE(fle.fle_created_time) <= sch.academic_year_end_date
JOIN (
    SELECT
        class_dw_id,
        MAX(grade_name) AS grade_name,
        MAX(
            CASE
                WHEN course_subject_id IS NULL THEN class_gen_subject
                ELSE 'Arabits'
            END
        ) AS class_gen_subject
    FROM {{rs_bi_coredw}}.core_class_activity_content
    GROUP BY class_dw_id
) AS cont
    ON fle.fle_class_dw_id = cont.class_dw_id
JOIN date_flags AS df
    ON CAST(from_utc_timestamp(fle.fle_created_time, sch.tenant_timezone) AS DATE) = df.full_date
WHERE fle.fle_abbreviation <> 'NA'
  AND fle.fle_activity_type NOT IN ('INTERIM_CHECKPOINT', 'DIAGNOSTIC_TEST')
  AND fle.fle_material_type <> 'PATHWAY'
  AND fle.fle_is_additional_resource <> TRUE
  AND COALESCE(fle.fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON'
  AND fle.fle_ls_id NOT IN (
        SELECT DISTINCT fle_ls_id
        FROM {{rs_coredw}}.fact_learning_experience
        WHERE fle_state = 4
  )
  AND EXISTS (
        SELECT 1
        FROM {{rs_bi_coredw}}.core_class_activity_content AS cont2
        WHERE fle.fle_lo_dw_id   = cont2.activity_dw_id
          AND fle.fle_class_dw_id = cont2.class_dw_id
  )
GROUP BY GROUPING SETS (
    (
        CAST(from_utc_timestamp(fle.fle_created_time, sch.tenant_timezone) AS DATE),
        sch.tenant_name,
        sch.school_organisation,
        sch.school_name,
        sch.school_id,
        sch.school_dw_id,
        sch.school_country_name,
        sch.school_city_name,
        sch.school_label,
        sch.school_status,
        cont.grade_name,
        fle.fle_student_dw_id,
        cont.class_gen_subject
    ),
    (
        CAST(from_utc_timestamp(fle.fle_created_time, sch.tenant_timezone) AS DATE),
        sch.tenant_name,
        sch.school_organisation,
        sch.school_name,
        sch.school_id,
        sch.school_dw_id,
        sch.school_country_name,
        sch.school_city_name,
        sch.school_label,
        sch.school_status,
        cont.grade_name,
        fle.fle_student_dw_id
    )
);
