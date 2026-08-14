CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.fact_lessons_perf_mv AS
WITH total_completed_students AS (
    SELECT
        lo_attempted,
        fle_class_dw_id,
        student_section_dw_id,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' THEN student_dw_id END)                                            AS total_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score >= 70 THEN student_dw_id END)                        AS meets_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score >= 50 AND fle_score < 70 THEN student_dw_id END)     AS approaching_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score < 50  AND fle_score >= 0 THEN student_dw_id END)     AS below_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'In-Progress' THEN student_dw_id END)                                         AS total_inprogress_students,
        AVG(CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN CAST(fle_score AS DECIMAL(10,2)) END)                 AS average_score,
        MAX(local_date)                                                                                                     AS max_local_date
    FROM {{rs_bi_coredw}}.students_lesson_progress
    GROUP BY
        lo_attempted,
        fle_class_dw_id,
        student_section_dw_id
)
SELECT DISTINCT
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_organisation                                                                                                 AS organisation_name,
    cts.class_dw_id,
    cts.class_total_students                                                                                                AS class_students_assigned_per_mlo,
    cts.class_title,
    cts.class_gen_subject,
    cts.section_dw_id,
    cts.section_name,
    cts.class_section_name,
    cts.grade_name,
    CONCAT(dsc.school_id, cts.grade_name)                                                                                   AS school_grade_uid,
    cts.class_curriculum_id                                                                                                 AS instructional_plan_curriculum_id,
    TRIM(dip_dlo.lo_title)                                                                                                  AS lo_title,
    dcaa.caa_activity_dw_id                                                                                                 AS lo_to_finish,
    COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date)           AS week_start_date,
    COALESCE(dpg.pacing_interval_end_date,   dtrm.actp_teaching_period_end_date,   dsc.academic_year_end_date)             AS week_end_date,
    COALESCE(dtrm.actp_teaching_period_order, 1)                                                                            AS term_academic_period_order,
    COALESCE(dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date)                                            AS term_start_date,
    COALESCE(dtrm.actp_teaching_period_end_date,   dsc.academic_year_end_date)                                              AS term_end_date,
    cts.teacher_ids,
    tcs.total_completed_students,
    tcs.below_completed_students,
    tcs.approaching_completed_students,
    tcs.meets_completed_students,
    tcs.average_score,
    tcs.total_inprogress_students,
    CAST(
        COALESCE(tcs.max_local_date, dpg.pacing_interval_start_date)
        AS TIMESTAMP
    )                                                                                                                       AS max_local_date
FROM {{rs_bi_coredw}}.class_total_students                   AS cts
JOIN {{rs_coredw}}.dim_course                                AS dcr
    ON  cts.instructional_plan_id   = dcr.course_id
    AND dcr.course_status           = 1
    AND dcr.course_type             = 'CORE'
JOIN {{rs_coredw}}.dim_course_activity_association           AS dcaa
    ON  dcr.course_dw_id            = dcaa.caa_course_dw_id
    AND dcaa.caa_activity_is_optional = 0
    AND dcaa.caa_activity_type      = 1
LEFT JOIN {{rs_coredw}}.dim_pacing_guide                     AS dpg
    ON  cts.class_dw_id             = dpg.pacing_class_dw_id
    AND dcaa.caa_activity_dw_id     = dpg.pacing_activity_dw_id
LEFT JOIN {{rs_coredw}}.dim_academic_calendar_teaching_period AS dtrm
    ON  dpg.pacing_period_id        = dtrm.actp_teaching_period_id
JOIN {{rs_bi_coredw}}.bi_active_schools_dim                  AS dsc
    ON  cts.school_dw_id            = dsc.school_dw_id
JOIN {{rs_coredw}}.dim_learning_objective                    AS dip_dlo
    ON  dcaa.caa_activity_dw_id     = dip_dlo.lo_dw_id
    AND COALESCE(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
LEFT JOIN total_completed_students                          AS tcs
    ON  cts.class_dw_id             = tcs.fle_class_dw_id
    AND dcaa.caa_activity_dw_id     = tcs.lo_attempted
    AND cts.section_dw_id           = tcs.student_section_dw_id
WHERE cts.class_title       NOT LIKE '%power skills%'
  AND cts.class_title       NOT LIKE '%extra resources%'
  AND cts.class_gen_subject  <> 'core stars'
  AND dpg.pacing_interval_start_date <= DATE_ADD(CURRENT_DATE(), -1);