CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.fact_lessons_perf AS
WITH total_completed_students AS (
    SELECT
        lo_attempted,
        fle_class_dw_id,
        student_section_dw_id,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' THEN student_dw_id END) AS total_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN student_dw_id END) AS total_completed_students_wth_score,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score >= 70 THEN student_dw_id END) AS meets_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score >= 50 AND fle_score < 70 THEN student_dw_id END) AS approaching_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score < 50 AND fle_score >= 0 THEN student_dw_id END) AS below_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'In-Progress' THEN student_dw_id END) AS total_inprogress_students,
        SUM(CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN CONVERT(decimal(10,2), fle_score) END) AS total_score,
        MAX(local_date) AS max_local_date
    FROM ${RS_BI_COREDW}.students_lesson_progress
    GROUP BY lo_attempted, fle_class_dw_id, student_section_dw_id
)

SELECT
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    cts.class_gen_subject,
    cts.grade_name,
    (CONVERT(varchar(200), dsc.school_id) + CONVERT(varchar(200), cts.grade_name)) AS school_grade_uid,
    LTRIM(RTRIM(dip_dlo.lo_title)) AS lo_title,
    dcaa.caa_activity_dw_id AS lo_to_finish,
    COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date) AS week_start_date,
    COALESCE(dpg.pacing_interval_end_date, dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date) AS week_end_date,
    CONVERT(varchar(64), HASHBYTES('MD5',
        CONVERT(varchar(200), dsc.school_dw_id) + '-' +
        CONVERT(varchar(200), cts.grade_name) + '-' +
        ISNULL(cts.class_gen_subject,'') + '-' +
        CONVERT(varchar(10), COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date), 23) + '-' +
        CONVERT(varchar(10), COALESCE(dpg.pacing_interval_end_date, dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date), 23)
    ), 2) AS index_column,
    MAX(ISNULL(tcs.max_local_date, dpg.pacing_interval_start_date)) AS max_local_date,
    SUM(tcs.total_completed_students) AS total_completed_students,
    SUM(tcs.total_completed_students_wth_score) AS total_completed_students_wth_score,
    SUM(tcs.below_completed_students) AS below_completed_students,
    SUM(tcs.approaching_completed_students) AS approaching_completed_students,
    SUM(tcs.meets_completed_students) AS meets_completed_students,
    SUM(tcs.total_score) AS total_score
FROM ${RS_BI_COREDW}.class_total_students cts
JOIN ${RS_COREDW}.dim_course dcr
    ON cts.instructional_plan_id  = dcr.course_id 
   AND dcr.course_status = 1
   AND dcr.course_type = 'CORE'
JOIN ${RS_COREDW}.dim_course_activity_association dcaa
    ON dcr.course_dw_id = dcaa.caa_course_dw_id
   AND dcaa.caa_activity_is_optional = 0
   AND dcaa.caa_activity_type = 1
   AND dcaa.caa_attach_status = 1
JOIN ${RS_COREDW}.dim_learning_objective dip_dlo
    ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
   AND ISNULL(dip_dlo.lo_type,'NA') <> 'EXPERIENTIAL_LESSON'
   AND ISNULL(dip_dlo.lo_template_uuid,'NA') <> '235229fa-4707-4286-8ec2-85f70347096a'
   AND dip_dlo.lo_status = 1
LEFT JOIN ${RS_COREDW}.dim_pacing_guide dpg
    ON cts.class_dw_id = dpg.pacing_class_dw_id
   AND dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
   AND dpg.pacing_status = 1
LEFT JOIN (
    SELECT DISTINCT pacing_class_dw_id FROM ${RS_COREDW}.dim_pacing_guide WHERE pacing_status = 1
) cp
    ON cp.pacing_class_dw_id = cts.class_dw_id
LEFT JOIN ${RS_COREDW}.dim_academic_calendar_teaching_period dtrm
    ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
   AND dtrm.actp_status = 1
JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
    ON cts.school_dw_id = dsc.school_dw_id
LEFT JOIN total_completed_students tcs
    ON cts.class_dw_id = tcs.fle_class_dw_id
   AND dcaa.caa_activity_dw_id = tcs.lo_attempted
   AND cts.section_dw_id = tcs.student_section_dw_id
WHERE cts.class_title NOT LIKE '%power skills%'
  AND cts.class_title NOT LIKE '%extra resources%'
  AND cts.class_gen_subject <> 'core stars'
  AND cts.content_academic_year_name > 2021
  AND dpg.pacing_interval_start_date <= DATEADD(day, -1, CONVERT(date, GETDATE()))
  AND (cp.pacing_class_dw_id IS NULL OR dpg.pacing_activity_dw_id IS NOT NULL)
GROUP BY
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    cts.class_gen_subject,
    cts.grade_name,
    (CONVERT(varchar(200), dsc.school_id) + CONVERT(varchar(200), cts.grade_name)),
    LTRIM(RTRIM(dip_dlo.lo_title)),
    dcaa.caa_activity_dw_id,
    COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date),
    COALESCE(dpg.pacing_interval_end_date, dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date),
    (CONVERT(varchar(200), dsc.school_dw_id) + '-' +
     CONVERT(varchar(200), cts.grade_name) + '-' +
     ISNULL(cts.class_gen_subject,'') + '-' +
        CONVERT(varchar(10), COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date), 23) + '-' +
        CONVERT(varchar(10), COALESCE(dpg.pacing_interval_end_date, dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date), 23)
    );
