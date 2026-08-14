CREATE OR REPLACE MATERIALIZED LAKE VIEW ${OS_EAGLES_COREDW}.active_teachers_week_mv AS
WITH
teacher AS (
    SELECT
        teacher_dw_id,
        teacher_id,
        teacher_school_dw_id,
        MAX(teacher_created_time) AS teacher_created_time
    FROM ${RS_COREDW}.dim_teacher
    WHERE teacher_status = 1
    GROUP BY teacher_dw_id, teacher_id, teacher_school_dw_id
),

active_teacher AS (
    SELECT
        DATE_TRUNC('week', CAST(tl.login_local_date_time AS TIMESTAMP)) AS login_week,
        tl.teacher_dw_id AS active_teacher_dw_id,
        COUNT(DISTINCT CAST(tl.login_local_date_time AS DATE)) AS active_days
    FROM ${RS_BI_COREDW}.teacher_login tl
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = tl.school_dw_id
    INNER JOIN teacher dt
        ON tl.teacher_dw_id = dt.teacher_dw_id
       AND CAST(tl.login_local_date_time AS DATE) >= CAST(
               from_utc_timestamp(dt.teacher_created_time, COALESCE(dsc.tenant_timezone, 'UTC'))
           AS DATE)
    LEFT JOIN (
        SELECT DISTINCT
            CAST(holiday_date AS DATE) AS holiday_date,
            holiday_organisation_dw_id
        FROM ${RS_COREDW}.dim_holiday
    ) dh
        ON dh.holiday_date = CAST(tl.login_local_date_time AS DATE)
       AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
    WHERE CAST(tl.login_local_date_time AS DATE) >= dsc.academic_year_start_date
      AND CAST(tl.login_local_date_time AS DATE) <= dsc.academic_year_end_date
      AND dh.holiday_date IS NULL
      AND DAYOFWEEK(CAST(tl.login_local_date_time AS DATE)) BETWEEN 2 AND 6
      AND CAST(tl.login_local_date_time AS DATE) <= DATE_ADD(CURRENT_DATE(), -1)
    GROUP BY
        DATE_TRUNC('week', CAST(tl.login_local_date_time AS TIMESTAMP)),
        tl.teacher_dw_id
),

dim_teacher AS (
    SELECT
        dsc.tenant_name,
        dsc.organisation_dw_id,
        dsc.school_dw_id,
        dsc.school_id,
        dsc.school_name,
        dt.teacher_dw_id,
        dt.teacher_id,
        DATE_TRUNC('week', CAST(d.full_date AS TIMESTAMP)) AS week,
        COUNT(d.full_date) AS week_days
    FROM ${RS_COREDW}.dim_date d
    CROSS JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
    INNER JOIN teacher dt
        ON dsc.school_dw_id = dt.teacher_school_dw_id
       AND CAST(d.full_date AS DATE) >= CAST(
               from_utc_timestamp(dt.teacher_created_time, COALESCE(dsc.tenant_timezone, 'UTC'))
           AS DATE)
    LEFT JOIN (
        SELECT DISTINCT
            CAST(holiday_date AS DATE) AS holiday_date,
            holiday_organisation_dw_id
        FROM ${RS_COREDW}.dim_holiday
    ) dh
        ON dh.holiday_date = d.full_date
       AND dh.holiday_organisation_dw_id = dsc.organisation_dw_id
    WHERE d.full_date >= dsc.academic_year_start_date
      AND d.full_date <= DATE_ADD(CURRENT_DATE(), -1)
      AND dh.holiday_date IS NULL
      AND DAYOFWEEK(d.full_date) BETWEEN 2 AND 6
    GROUP BY
        dsc.tenant_name,
        dsc.organisation_dw_id,
        dsc.school_dw_id,
        dsc.school_id,
        dsc.school_name,
        dt.teacher_dw_id,
        dt.teacher_id,
        DATE_TRUNC('week', CAST(d.full_date AS TIMESTAMP))
),

total_completed_lessons AS (
    SELECT
        slp.fle_class_dw_id,
        COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, slp.academic_year_start_date) AS week_start_date,
        COALESCE(dpg.pacing_interval_end_date,   dtrm.actp_teaching_period_end_date,   slp.academic_year_end_date)   AS week_end_date,
        SUM(CASE WHEN slp.lo_status = 'Completed' THEN 1 END) AS total_completed_lessons,
        AVG(CASE
                WHEN slp.lo_status = 'Completed'
                 AND fle_score >= 0
                THEN CAST(fle_score AS DECIMAL(10,2))
            END) AS average_score
    FROM ${RS_BI_COREDW}.students_lesson_progress slp
    INNER JOIN ${RS_COREDW}.dim_class dc
        ON slp.fle_class_dw_id = dc.class_dw_id
       AND dc.class_status = 1
       AND dc.class_course_status = 'ACTIVE'
       AND dc.class_material_type <> 'PATHWAY'
       AND dc.class_title NOT LIKE '%power skills%'
       AND dc.class_title NOT LIKE '%extra resources%'
       AND dc.class_gen_subject <> 'core stars'
    INNER JOIN ${RS_COREDW}.dim_course_activity_association dcaa
        ON dc.class_material_id = dcaa.caa_course_id
       AND slp.lo_attempted = dcaa.caa_activity_dw_id
       AND dcaa.caa_attach_status = 1
       AND dcaa.caa_status = 1
       AND dcaa.caa_activity_is_optional = 0
    LEFT JOIN ${RS_COREDW}.dim_pacing_guide dpg
        ON dc.class_dw_id = dpg.pacing_class_dw_id
       AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
       AND dpg.pacing_status = 1
    LEFT JOIN (
        SELECT DISTINCT pacing_class_dw_id
        FROM ${RS_COREDW}.dim_pacing_guide
        WHERE pacing_status = 1
    ) cp
        ON cp.pacing_class_dw_id = dc.class_dw_id
    LEFT JOIN ${RS_COREDW}.dim_academic_calendar_teaching_period dtrm
        ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
       AND dtrm.actp_status = 1
    INNER JOIN ${RS_COREDW}.dim_learning_objective dip_dlo
        ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
       AND COALESCE(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
       AND COALESCE(dip_dlo.lo_template_uuid, 'DISTINCT_VALUE')
           NOT IN ('235229fa-4707-4286-8ec2-85f70347096a', '15295fd1-b5e3-46f9-9045-86ee3b13552b')
    WHERE (cp.pacing_class_dw_id IS NULL        -- if class has pacing >> only keep activities that are in pacing
        OR dpg.pacing_activity_dw_id IS NOT NULL) -- if class has no pacing >> keep all activities
    GROUP BY
        slp.fle_class_dw_id,
        COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, slp.academic_year_start_date),
        COALESCE(dpg.pacing_interval_end_date,   dtrm.actp_teaching_period_end_date,   slp.academic_year_end_date)
),

class_teacher AS (
    SELECT
        dc.class_gen_subject,
        g.grade_k12grade AS grade,
        dc.class_dw_id,
        COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date) AS week_start_date,
        COALESCE(dpg.pacing_interval_end_date,   dtrm.actp_teaching_period_end_date,   dsc.academic_year_end_date)   AS week_end_date,
        dt.teacher_id,
        SUM(cts.class_total_students) AS class_total_students
    FROM ${RS_COREDW}.dim_class dc
    JOIN ${RS_COREDW}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    JOIN teacher dt
        ON dcu.class_user_user_dw_id = dt.teacher_dw_id
       AND dt.teacher_id NOT IN (
           SELECT DISTINCT teacher_id
           FROM ${RS_BI_COREDW}.exclude_teacher_id
       )
    JOIN ${RS_COREDW}.dim_grade g
        ON g.grade_id = dc.class_grade_id
    INNER JOIN ${RS_COREDW}.dim_course_activity_association dcaa
        ON dc.class_material_id = dcaa.caa_course_id
       AND dcaa.caa_attach_status = 1
       AND dcaa.caa_status = 1
       AND dcaa.caa_activity_type = 1
       AND dcaa.caa_activity_is_optional = 0
    LEFT JOIN ${RS_COREDW}.dim_pacing_guide dpg
        ON dc.class_dw_id = dpg.pacing_class_dw_id
       AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
       AND dpg.pacing_status = 1
    LEFT JOIN (
        SELECT DISTINCT pacing_class_dw_id
        FROM ${RS_COREDW}.dim_pacing_guide
        WHERE pacing_status = 1
    ) cp
        ON cp.pacing_class_dw_id = dc.class_dw_id
    LEFT JOIN ${RS_COREDW}.dim_academic_calendar_teaching_period dtrm
        ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
       AND dtrm.actp_status = 1
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dc.class_school_id = dsc.school_id
    INNER JOIN ${RS_COREDW}.dim_learning_objective dip_dlo
        ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
       AND COALESCE(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
       AND COALESCE(dip_dlo.lo_template_uuid, 'DISTINCT_VALUE')
           NOT IN ('235229fa-4707-4286-8ec2-85f70347096a', '15295fd1-b5e3-46f9-9045-86ee3b13552b')
    INNER JOIN ${RS_BI_COREDW}.class_total_students cts
        ON cts.class_dw_id = dc.class_dw_id
    WHERE dc.class_status = 1
      AND dcu.class_user_role_dw_id = 1
      AND dc.class_course_status = 'ACTIVE'
      AND dcu.class_user_status = 1
      AND dc.class_material_type <> 'PATHWAY'
      AND dcu.class_user_attach_status = 1
      AND dc.class_title NOT LIKE '%power skills%'
      AND dc.class_title NOT LIKE '%extra resources%'
      AND dc.class_gen_subject <> 'core stars'
      AND (cp.pacing_class_dw_id IS NULL        -- if class has pacing >> only keep activities that are in pacing
        OR dpg.pacing_activity_dw_id IS NOT NULL) -- if class has no pacing >> keep all activities
    GROUP BY
        dc.class_gen_subject,
        g.grade_k12grade,
        dc.class_dw_id,
        COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date),
        COALESCE(dpg.pacing_interval_end_date,   dtrm.actp_teaching_period_end_date,   dsc.academic_year_end_date),
        dt.teacher_id
)

SELECT
    dt.school_dw_id,
    dt.school_id,
    dt.school_name,
    dt.tenant_name,
    dt.organisation_dw_id,
    dt.teacher_dw_id,
    dt.teacher_id,
    ct.class_gen_subject,
    ct.grade,
    dt.week,
    COALESCE(act.active_days, 0) AS active_days,
    dt.week_days,
    SUM(ct.class_total_students) AS class_total_students,
    SUM(tcl.total_completed_lessons) AS completed_lessons,
    AVG(tcl.average_score) AS average_score
FROM dim_teacher dt
LEFT JOIN active_teacher act
    ON dt.teacher_dw_id = act.active_teacher_dw_id
   AND dt.week = act.login_week
INNER JOIN class_teacher ct
    ON dt.teacher_id = ct.teacher_id
   AND dt.week BETWEEN ct.week_start_date AND ct.week_end_date
LEFT JOIN total_completed_lessons tcl
    ON ct.class_dw_id = tcl.fle_class_dw_id
   AND dt.week BETWEEN tcl.week_start_date AND tcl.week_end_date
GROUP BY
    dt.school_dw_id,
    dt.school_id,
    dt.school_name,
    dt.tenant_name,
    dt.organisation_dw_id,
    dt.teacher_dw_id,
    dt.teacher_id,
    ct.class_gen_subject,
    ct.grade,
    dt.week,
    COALESCE(act.active_days, 0),
    dt.week_days;