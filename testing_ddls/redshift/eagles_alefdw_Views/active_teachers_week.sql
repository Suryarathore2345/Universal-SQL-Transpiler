CREATE OR REPLACE VIEW eagles_alefdw_dev.active_teachers_week AS
WITH teacher AS (
SELECT teacher_dw_id,
       teacher_id,
       teacher_school_dw_id,
       MAX(teacher_created_time) AS teacher_created_time
FROM alefdw.dim_teacher
WHERE teacher_status = 1
GROUP BY 1, 2, 3
),
    active_teacher AS(
SELECT DATE_TRUNC('week', tl.login_local_date_time)     AS login_week,
        tl.teacher_dw_id                                AS active_teacher_dw_id,
        COUNT(DISTINCT TRUNC(tl.login_local_date_time)) AS active_days
FROM bi_alefdw.teacher_login tl
    INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
        ON dsc.school_dw_id = tl.school_dw_id
    INNER JOIN teacher dt
        ON tl.teacher_dw_id = dt.teacher_dw_id
        AND TRUNC(login_local_date_time) >= TRUNC(CONVERT_TIMEZONE('UTC', dsc.tenant_timezone, teacher_created_time))
    LEFT JOIN (SELECT DISTINCT CAST(holiday_date AS date) AS holiday_date,
               holiday_organisation_dw_id
                FROM alefdw.dim_holiday) dh
        ON dh.holiday_date = TRUNC(login_local_date_time)
        AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
WHERE TRUNC(login_local_date_time) >= academic_year_start_date
    AND TRUNC(login_local_date_time) <= academic_year_end_date
    AND holiday_date IS NULL
    AND DATE_PART(DOW, TRUNC(login_local_date_time)) BETWEEN 1 AND 5
    AND TRUNC(login_local_date_time) <= CURRENT_DATE - 1
GROUP BY 1, 2
),
dim_teacher AS (
SELECT dsc.tenant_name,
       dsc.organisation_dw_id,
       dsc.school_dw_id,
       dsc.school_id,
       dsc.school_name,
       dt.teacher_dw_id,
       dt.teacher_id,
       DATE_TRUNC('week',d.full_date) AS week,
       COUNT( d.full_date) as week_days
FROM alefdw.dim_date d
       CROSS JOIN bi_alefdw.bi_active_schools_dim_mv dsc
       INNER JOIN teacher dt
                ON dsc.school_dw_id = dt.teacher_school_dw_id
                AND TRUNC(full_date) >= TRUNC(CONVERT_TIMEZONE('UTC', dsc.tenant_timezone, teacher_created_time))
       LEFT JOIN (SELECT DISTINCT CAST(holiday_date AS DATE) AS holiday_date,
                                                           holiday_organisation_dw_id
                  FROM alefdw.dim_holiday) dh
       ON dh.holiday_date = d.full_date
       AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
WHERE d.full_date >= academic_year_start_date
       AND d.full_date <= CURRENT_DATE -1
       AND holiday_date IS NULL
       AND DATE_PART(DOW, full_date) BETWEEN 1 AND 5
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),
total_completed_lessons AS (
SELECT slp.fle_class_dw_id,
       nvl(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date,
            slp.academic_year_start_date)                                                   AS week_start_date,
       nvl(dpg.pacing_interval_end_date, dtrm.actp_teaching_period_end_date,
            slp.academic_year_end_date)                                                     AS week_end_date,
       SUM(CASE WHEN slp.lo_status = 'Completed' THEN 1 END)                                                     AS total_completed_lessons,
       AVG(CASE WHEN slp.lo_status = 'Completed' AND fle_score >= 0 THEN CAST(fle_score AS decimal(10, 2)) END)  AS average_score
FROM bi_alefdw.students_lesson_progress_mv slp
    INNER JOIN alefdw.dim_class dc
        ON slp.fle_class_dw_id = dc.class_dw_id
        AND dc.class_status = 1
        AND dc.class_course_status = 'ACTIVE'
        AND dc.class_material_type <> 'PATHWAY'
        AND LOWER(dc.class_title) NOT LIKE '%power skills%'
        AND LOWER(dc.class_title) NOT LIKE '%extra resources%'
        AND LOWER(dc.class_gen_subject) != 'alef stars'
    INNER JOIN alefdw.dim_course_activity_association dcaa
        ON dc.class_material_id = dcaa.caa_course_id
        AND slp.lo_attempted = dcaa.caa_activity_dw_id
        AND dcaa.caa_attach_status = 1
        AND dcaa.caa_status = 1
        AND dcaa.caa_activity_is_optional IS FALSE
    LEFT JOIN alefdw.dim_pacing_guide dpg
        ON dc.class_dw_id = dpg.pacing_class_dw_id
        AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
        AND dpg.pacing_status = 1
    LEFT JOIN (SELECT DISTINCT pacing_class_dw_id
                 FROM alefdw.dim_pacing_guide
                 WHERE pacing_status = 1) cp
         ON cp.pacing_class_dw_id = dc.class_dw_id
    LEFT JOIN alefdw.dim_academic_calendar_teaching_period dtrm
        ON md5(dpg.pacing_period_id) = md5(dtrm.actp_teaching_period_id)
        AND dtrm.actp_status = 1
    INNER JOIN alefdw.dim_learning_objective dip_dlo
        ON dcaa.caa_activity_dw_id  = dip_dlo.lo_dw_id
        AND nvl(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
        AND COALESCE(lo_template_uuid, 'DISTINCT_VALUE')  NOT IN ('235229fa-4707-4286-8ec2-85f70347096a', '15295fd1-b5e3-46f9-9045-86ee3b13552b')
WHERE (cp.pacing_class_dw_id IS NULL             -- if class has pacing >> only keep activities that are in pacing
    OR dpg.pacing_activity_dw_id IS NOT NULL)  -- if class has no pacing >> keep all activities
GROUP BY 1, 2, 3
),
class_teacher AS (
SELECT  dc.class_gen_subject,
        g.grade_k12grade AS grade,
        dc.class_dw_id,
        nvl(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date,
            dsc.academic_year_start_date)                                                   AS week_start_date,
        nvl(dpg.pacing_interval_end_date, dtrm.actp_teaching_period_end_date,
            dsc.academic_year_end_date)                                                     AS week_end_date,
        dt.teacher_id,
        SUM(cts.class_total_students)                                                       AS class_total_students
FROM alefdw.dim_class dc
    JOIN alefdw.dim_class_user dcu ON dcu.class_user_class_dw_id = dc.class_dw_id
    JOIN teacher dt
        ON dcu.class_user_user_dw_id = dt.teacher_dw_id
        AND teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
    JOIN alefdw.dim_grade g
        ON g.grade_id = dc.class_grade_id
    INNER JOIN alefdw.dim_course_activity_association dcaa
        ON dc.class_material_id = dcaa.caa_course_id
        AND dcaa.caa_attach_status = 1
        AND dcaa.caa_status = 1
        AND dcaa.caa_activity_type = 1
        AND dcaa.caa_activity_is_optional IS FALSE
    LEFT JOIN alefdw.dim_pacing_guide dpg
        ON dc.class_dw_id = dpg.pacing_class_dw_id
        AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
        AND dpg.pacing_status = 1
    LEFT JOIN (SELECT DISTINCT pacing_class_dw_id
                 FROM alefdw.dim_pacing_guide
                 WHERE pacing_status = 1) cp
        ON cp.pacing_class_dw_id = dc.class_dw_id
    LEFT JOIN alefdw.dim_academic_calendar_teaching_period dtrm
        ON md5(dpg.pacing_period_id) = md5(dtrm.actp_teaching_period_id)
        AND dtrm.actp_status = 1
        INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
        ON dc.class_school_id = dsc.school_id
    INNER JOIN alefdw.dim_learning_objective dip_dlo
        ON dcaa.caa_activity_dw_id  = dip_dlo.lo_dw_id
        AND nvl(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
        AND COALESCE(lo_template_uuid, 'DISTINCT_VALUE')  NOT IN ('235229fa-4707-4286-8ec2-85f70347096a', '15295fd1-b5e3-46f9-9045-86ee3b13552b')
    INNER JOIN bi_alefdw.class_total_students_mv cts
        ON cts.class_dw_id = dc.class_dw_id
WHERE dc.class_status = 1
    AND dcu.class_user_role_dw_id = 1
    AND dc.class_course_status = 'ACTIVE'
    AND dcu.class_user_status = 1
    AND dc.class_material_type <> 'PATHWAY'
    AND dcu.class_user_attach_status = 1
    AND LOWER(dc.class_title) NOT LIKE '%power skills%'
    AND LOWER(dc.class_title) NOT LIKE '%extra resources%'
    AND LOWER(dc.class_gen_subject) != 'alef stars'
    AND (cp.pacing_class_dw_id IS NULL             -- if class has pacing >> only keep activities that are in pacing
    OR dpg.pacing_activity_dw_id IS NOT NULL)  -- if class has no pacing >> keep all activities
GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT  dt.school_dw_id,
        dt.school_id,
        dt.school_name,
        dt.tenant_name,
        dt.organisation_dw_id,
        dt.teacher_dw_id,
        dt.teacher_id,
        ct.class_gen_subject,
        ct.grade,
        dt.week,
        COALESCE(act.active_days,0)        AS active_days,
        dt.week_days,
        SUM(ct.class_total_students)       AS class_total_students,
        SUM(tcl.total_completed_lessons)   AS completed_lessons,
        AVG(tcl.average_score)             AS average_score
FROM dim_teacher dt
    LEFT JOIN active_teacher act
        ON dt.teacher_dw_id = act.active_teacher_dw_id
        AND dt.week = act.login_week
    INNER JOIN class_teacher ct
        ON dt.teacher_id = ct.teacher_id
        AND dt.week  BETWEEN ct.week_start_date AND ct.week_end_date
    LEFT JOIN total_completed_lessons tcl
        ON ct.class_dw_id = tcl.fle_class_dw_id
        AND dt.week  BETWEEN tcl.week_start_date AND tcl.week_end_date
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
WITH NO SCHEMA BINDING;