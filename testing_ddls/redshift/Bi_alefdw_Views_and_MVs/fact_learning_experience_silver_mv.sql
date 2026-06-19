CREATE MATERIALIZED VIEW bi_alefdw_dev.fact_learning_experience_silver_mv AS
WITH date_references AS (
    SELECT
        CURRENT_DATE - 1  AS curent_date,
        (CURRENT_DATE - 1 - INTERVAL '1 year')::DATE AS last_year_date,
        (CURRENT_DATE - 1 - INTERVAL '2 year')::DATE AS two_years_ago_date,
        DATE_TRUNC('year', CURRENT_DATE - 1)::DATE AS current_year_start,
        DATE_TRUNC('year', CURRENT_DATE - 1 - INTERVAL '1 year')::DATE AS last_year_start,
        DATE_TRUNC('year', CURRENT_DATE - 1 - INTERVAL '2 year')::DATE AS two_years_ago_start,
        DATEDIFF('day', DATE_TRUNC('year', CURRENT_DATE - 1), CURRENT_DATE - 1)+1 AS days_ytd
),
    date_flags AS (
 SELECT full_date,
        curent_date,
        -- current period flags
        CASE WHEN full_date BETWEEN dr.curent_date - 6 AND dr.curent_date THEN 1 ELSE 0 END AS is_last_7_days,
        CASE WHEN full_date BETWEEN dr.curent_date - 13 AND dr.curent_date THEN 1 ELSE 0 END AS is_last_14_days,
        CASE WHEN full_date BETWEEN dr.curent_date - 29 AND dr.curent_date THEN 1 ELSE 0 END AS is_last_30_days,
        CASE WHEN full_date BETWEEN dr.curent_date - 89 AND dr.curent_date THEN 1 ELSE 0 END AS is_last_90_days,
        CASE WHEN full_date BETWEEN dr.current_year_start AND dr.curent_date THEN 1 ELSE 0 END AS is_ytd,
        -- previous period flags
        CASE WHEN full_date BETWEEN dr.curent_date - 13 AND dr.curent_date - 7 THEN 1 ELSE 0 END AS is_last_7_days_pp,
        CASE WHEN full_date BETWEEN dr.curent_date - 27 AND dr.curent_date - 14 THEN 1 ELSE 0 END AS is_last_14_days_pp,
        CASE WHEN full_date BETWEEN dr.curent_date - 59 AND dr.curent_date - 30 THEN 1 ELSE 0 END AS is_last_30_days_pp,
        CASE WHEN full_date BETWEEN dr.curent_date - 179 AND dr.curent_date - 90 THEN 1 ELSE 0 END AS is_last_90_days_pp,
        CASE WHEN full_date BETWEEN dr.current_year_start-days_ytd AND dr.current_year_start-1 THEN 1 ELSE 0 END AS is_ytd_pp,
        -- last year flags
        CASE WHEN full_date BETWEEN dr.last_year_date - 6 AND dr.last_year_date THEN 1 ELSE 0 END AS is_last_7_days_ly,
        CASE WHEN full_date BETWEEN dr.last_year_date - 13 AND dr.last_year_date THEN 1 ELSE 0 END AS is_last_14_days_ly,
        CASE WHEN full_date BETWEEN dr.last_year_date - 29 AND dr.last_year_date THEN 1 ELSE 0 END AS is_last_30_days_ly,
        CASE WHEN full_date BETWEEN dr.last_year_date - 89 AND dr.last_year_date THEN 1 ELSE 0 END AS is_last_90_days_ly,
        CASE WHEN full_date BETWEEN dr.last_year_start AND dr.last_year_date THEN 1 ELSE 0 END AS is_ytd_ly,
        -- 2 years ago flags
        CASE WHEN full_date BETWEEN dr.two_years_ago_date - 6 AND dr.two_years_ago_date THEN 1 ELSE 0 END AS is_last_7_days_2ya,
        CASE WHEN full_date BETWEEN dr.two_years_ago_date - 13 AND dr.two_years_ago_date THEN 1 ELSE 0 END AS is_last_14_days_2ya,
        CASE WHEN full_date BETWEEN dr.two_years_ago_date - 29 AND dr.two_years_ago_date THEN 1 ELSE 0 END AS is_last_30_days_2ya,
        CASE WHEN full_date BETWEEN dr.two_years_ago_date - 89 AND dr.two_years_ago_date THEN 1 ELSE 0 END AS is_last_90_days_2ya,
        CASE WHEN full_date BETWEEN dr.two_years_ago_start AND dr.two_years_ago_date THEN 1 ELSE 0 END AS is_ytd_2ya
FROM alefdw.dim_date dd
     CROSS JOIN date_references dr
WHERE dd.full_date >= dr.two_years_ago_start
        AND dd.full_date <= dr.curent_date
)
SELECT date (CONVERT_TIMEZONE('UTC', tenant_timezone, fle_created_time)) AS local_date,
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
       CASE WHEN GROUPING(cont.class_gen_subject) = 1 THEN 'All' ELSE cont.class_gen_subject END AS class_gen_subject,
       MAX(curent_date) AS curent_date,
       MAX(df.is_last_7_days) AS is_last_7_days,
       MAX(df.is_last_7_days_pp) AS is_last_7_days_pp,
       MAX(df.is_last_7_days_ly) AS is_last_7_days_ly,
       MAX(df.is_last_7_days_2ya) AS is_last_7_days_2ya,
       MAX(df.is_last_14_days) AS is_last_14_days,
       MAX(df.is_last_14_days_pp) AS is_last_14_days_pp,
       MAX(df.is_last_14_days_ly) AS is_last_14_days_ly,
       MAX(df.is_last_14_days_2ya) AS is_last_14_days_2ya,
       MAX(df.is_last_30_days) AS is_last_30_days,
       MAX(df.is_last_30_days_pp) AS is_last_30_days_pp,
       MAX(df.is_last_30_days_ly) AS is_last_30_days_ly,
       MAX(df.is_last_30_days_2ya) AS is_last_30_days_2ya,
       MAX(df.is_last_90_days) AS is_last_90_days,
       MAX(df.is_last_90_days_pp) AS is_last_90_days_pp,
       MAX(df.is_last_90_days_ly) AS is_last_90_days_ly,
       MAX(df.is_last_90_days_2ya) AS is_last_90_days_2ya,
       MAX(df.is_ytd) AS is_ytd,
       MAX(df.is_ytd_pp) AS is_ytd_pp,
       MAX(df.is_ytd_ly) AS is_ytd_ly,
       MAX(df.is_ytd_2ya) AS is_ytd_2ya,
       COUNT(DISTINCT fle_lo_dw_id) AS total_lessons_learned,
       COUNT(DISTINCT CASE
                          WHEN fle_completion_node IS TRUE
                              THEN fle_lo_dw_id END)  AS total_completed_lessons,
       COUNT(DISTINCT CASE
                          WHEN fle_completion_node IS TRUE AND lo.lo_max_stars > 0
                              THEN lo_dw_id END)      AS total_completed_lessons_score,
       SUM(CASE
               WHEN fle_completion_node IS TRUE AND lo.lo_max_stars > 0 AND fle_is_retry IS FALSE AND fle_is_activity_completed IS FALSE
                   THEN fle_total_score END)   AS fle_score,
       SUM(CASE
               WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
               WHEN fle.fle_total_time > 900 THEN 900
               ELSE 0 END)                      AS session_time
FROM alefdw.fact_learning_experience fle
         JOIN alefdw.dim_learning_objective lo
              ON lo.lo_dw_id = fle.fle_lo_dw_id
                  AND lo.lo_status = 1
         JOIN bi_alefdw.bi_all_schools_dim_mv sch
              ON sch.school_dw_id = fle.fle_school_dw_id
                  AND date(fle_created_time) >= sch.academic_year_start_date
                  AND date(fle_created_time) <= sch.academic_year_end_date
         JOIN (SELECT class_dw_id,
                      MAX(grade_name) as grade_name,
                      MAX(CASE WHEN course_subject_id IS NULL THEN class_gen_subject ELSE 'Arabits' END) AS class_gen_subject -- subject logic for Arabits
               FROM bi_alefdw.core_class_activity_content_mv GROUP BY 1) cont
              ON fle.fle_class_dw_id  = cont.class_dw_id
         JOIN date_flags df
              ON date (CONVERT_TIMEZONE('UTC', tenant_timezone, fle_created_time))  = full_date
WHERE fle_abbreviation <> 'NA'
  AND fle_activity_type NOT IN ('INTERIM_CHECKPOINT', 'DIAGNOSTIC_TEST')
  AND fle_material_type <> 'PATHWAY'
  AND fle_is_additional_resource <> TRUE
  AND NVL(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON'
  AND fle_ls_id NOT IN (SELECT DISTINCT fle_ls_id FROM alefdw.fact_learning_experience WHERE fle_state = 4)
  AND EXISTS (SELECT 1 FROM bi_alefdw.core_class_activity_content_mv cont2
              WHERE fle.fle_lo_dw_id = cont2.activity_dw_id AND fle.fle_class_dw_id = cont2.class_dw_id) -- having only actively assigned to course and mandatory lessons
GROUP BY GROUPING SETS (
        (date (CONVERT_TIMEZONE('UTC', tenant_timezone, fle_created_time)), sch.tenant_name, sch.school_organisation, sch.school_name, sch.school_id, sch.school_dw_id, sch.school_country_name, sch.school_city_name, sch.school_label, sch.school_status, cont.grade_name, fle.fle_student_dw_id, cont.class_gen_subject ),  -- grouping set 1: all including subject
        (date (CONVERT_TIMEZONE('UTC', tenant_timezone, fle_created_time)), sch.tenant_name, sch.school_organisation, sch.school_name, sch.school_id, sch.school_dw_id, sch.school_country_name, sch.school_city_name, sch.school_label, sch.school_status, cont.grade_name, fle.fle_student_dw_id)
    )