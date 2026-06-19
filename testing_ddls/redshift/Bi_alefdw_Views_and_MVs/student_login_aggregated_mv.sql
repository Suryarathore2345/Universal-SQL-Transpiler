CREATE MATERIALIZED VIEW bi_alefdw_dev.student_login_aggregated_mv AS
WITH weekly_active_students AS (
SELECT date_trunc('week', login_local_date_time) AS local_week,
       sl.school_dw_id,
       student_grade_dw_id,
       student_section_dw_id,
       student_special_needs,
       student_tags,
       COUNT(DISTINCT sl.student_dw_id) AS weekly_active_students
FROM bi_alefdw.student_login sl
         JOIN bi_alefdw.bi_student_dim_mv st
              ON sl.student_dw_id = st.student_dw_id
                  AND sl.school_dw_id = st.student_school_dw_id
                  AND ((student_status = 2 AND date_trunc('week', login_local_date_time) >= date_trunc('week', student_created_time)
                                           AND date_trunc('week', login_local_date_time) < date_trunc('week', student_active_until))
                  OR (student_status = 1 AND date_trunc('week', login_local_date_time) >= date_trunc('week', student_created_time)))
WHERE DATE(login_local_date_time) < current_date
GROUP BY 1, 2, 3, 4, 5, 6
),
monthly_active_students AS (
SELECT date_trunc('month', login_local_date_time) AS local_month,
       sl.school_dw_id,
       student_grade_dw_id,
       grade_k12grade AS grade_name,
       student_section_dw_id,
       student_special_needs,
       student_tags,
       COUNT(DISTINCT sl.student_dw_id) AS monthly_active_students
FROM bi_alefdw.student_login sl
         JOIN bi_alefdw.bi_student_dim_mv st
              ON sl.student_dw_id = st.student_dw_id
                  AND sl.school_dw_id = st.student_school_dw_id
                  AND ((student_status = 2 AND date_trunc('month', login_local_date_time) >= date_trunc('month', student_created_time)
                                           AND date_trunc('month', login_local_date_time) < date_trunc('month', student_active_until))
                  OR (student_status = 1 AND date_trunc('month', login_local_date_time) >= date_trunc('month', student_created_time)))
         JOIN alefdw.dim_grade g
              ON st.student_grade_dw_id = g.grade_dw_id
WHERE DATE(login_local_date_time) < current_date
GROUP BY 1, 2, 3, 4, 5, 6, 7
),
daily_active_students AS (
SELECT date(login_local_date_time) AS local_date,
       sl.school_dw_id,
       student_grade_dw_id,
       student_section_dw_id,
       student_special_needs,
       student_tags,
       COUNT(DISTINCT sl.student_dw_id) AS daily_active_students
FROM bi_alefdw.student_login sl
         JOIN bi_alefdw.bi_student_dim_mv st
              ON sl.student_dw_id = st.student_dw_id
                  AND sl.school_dw_id = st.student_school_dw_id
                  AND ((student_status = 2 AND date_trunc('day', login_local_date_time) >= date_trunc('day', student_created_time)
                                           AND date_trunc('day', login_local_date_time) < date_trunc('day', student_active_until))
                  OR (student_status = 1 AND date_trunc('day', login_local_date_time) >= date_trunc('day', student_created_time)))
GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT dd.full_date     AS local_date,
       was.local_week,
       mas.local_month,
       mas.school_dw_id,
       mas.student_grade_dw_id,
       mas.grade_name,
       mas.student_section_dw_id,
       mas.student_special_needs,
       mas.student_tags,
       COALESCE(was.weekly_active_students,0) AS weekly_active_students,
       mas.monthly_active_students,
       COALESCE(daily_active_students,0) AS daily_active_students
FROM alefdw.dim_date dd
JOIN monthly_active_students mas
    ON date_trunc('month', dd.full_date) = mas.local_month
LEFT JOIN  weekly_active_students was
    ON mas.student_section_dw_id  = was.student_section_dw_id
    AND mas.student_special_needs = was.student_special_needs
    AND mas.student_tags = was.student_tags
    AND date_trunc('week', dd.full_date) = was.local_week
LEFT JOIN  daily_active_students das
    ON mas.student_section_dw_id  = das.student_section_dw_id
    AND mas.student_special_needs = das.student_special_needs
    AND mas.student_tags = das.student_tags
    AND dd.full_date  = das.local_date
WHERE dd.full_date BETWEEN DATE(DATEADD('month',-36,DATE_TRUNC('month',current_date))) AND current_date;
