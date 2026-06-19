CREATE MATERIALIZED VIEW bi_alefdw_dev.teacher_login_aggregated_mv AS
WITH weekly_active_teachers AS (
SELECT date_trunc('week', login_local_date_time) AS local_week,
       tl.school_dw_id,
       COUNT(DISTINCT tl.teacher_dw_id) AS weekly_active_teachers
FROM bi_alefdw.teacher_login tl
         JOIN alefdw.dim_teacher t
              ON tl.teacher_dw_id = t.teacher_dw_id
                  AND tl.school_dw_id = t.teacher_school_dw_id
                  AND ((teacher_status = 2 AND date_trunc('week', login_local_date_time) >= date_trunc('week', teacher_created_time)
                                           AND date_trunc('week', login_local_date_time) < date_trunc('week', teacher_active_until))
                  OR (teacher_status = 1 AND date_trunc('week', login_local_date_time) >= date_trunc('week', teacher_created_time)))
WHERE DATE(login_local_date_time) < current_date
GROUP BY 1, 2
),
monthly_active_teachers AS (
SELECT date_trunc('month', login_local_date_time) AS local_month,
       tl.school_dw_id,
       COUNT(DISTINCT tl.teacher_dw_id) AS monthly_active_teachers
FROM bi_alefdw.teacher_login tl
         JOIN alefdw.dim_teacher t
              ON tl.teacher_dw_id = t.teacher_dw_id
                  AND tl.school_dw_id = t.teacher_school_dw_id
                  AND ((teacher_status = 2 AND date_trunc('month', login_local_date_time) >= date_trunc('month', teacher_created_time)
                                           AND date_trunc('month', login_local_date_time) < date_trunc('month', teacher_active_until))
                  OR (teacher_status = 1 AND date_trunc('month', login_local_date_time) >= date_trunc('month', teacher_created_time)))
WHERE DATE(login_local_date_time) < current_date
GROUP BY 1, 2
),
daily_active_teachers AS (
SELECT date(login_local_date_time) AS local_date,
       tl.school_dw_id,
       COUNT(DISTINCT tl.teacher_dw_id) AS daily_active_teachers
FROM bi_alefdw.teacher_login tl
         JOIN alefdw.dim_teacher t
              ON tl.teacher_dw_id = t.teacher_dw_id
                  AND tl.school_dw_id = t.teacher_school_dw_id
                  AND ((teacher_status = 2 AND date_trunc('day', login_local_date_time) >= date_trunc('day', teacher_created_time)
                                           AND date_trunc('day', login_local_date_time) < date_trunc('day', teacher_active_until))
                  OR (teacher_status = 1 AND date_trunc('day', login_local_date_time) >= date_trunc('day', teacher_created_time)))
GROUP BY 1, 2
)
SELECT dd.full_date     AS local_date,
       COALESCE(wat.local_week, date_trunc('week', dd.full_date)) AS local_week,
       mat.local_month,
       mat.school_dw_id,
       COALESCE(wat.weekly_active_teachers,0) AS weekly_active_teachers,
       mat.monthly_active_teachers,
       COALESCE(daily_active_teachers,0) AS daily_active_teachers
FROM alefdw.dim_date dd
JOIN monthly_active_teachers mat
    ON date_trunc('month', dd.full_date) = mat.local_month
LEFT JOIN  weekly_active_teachers wat
    ON mat.school_dw_id = wat.school_dw_id
    AND date_trunc('week', dd.full_date) = wat.local_week
LEFT JOIN  daily_active_teachers dat
    ON mat.school_dw_id  = dat.school_dw_id
    AND dd.full_date  = dat.local_date
WHERE dd.full_date BETWEEN DATE(DATEADD('month',-36,DATE_TRUNC('month',current_date))) AND current_date;