CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.slide_type_completion_progress_mv
AS
WITH fact_progress_per_slide AS (
    SELECT
        date_trunc('week', local_date) AS local_week,
        class_dw_id,
        school_dw_id,
        grade_name,
        tenant_dw_id,
        fle_lo_dw_id,
        fle_student_dw_id,
        slide_id,
        widget_id,
        MAX(idle_time_spent)      AS idle_time_per_slide,
        MAX(active_time_spent)    AS active_time_per_slide,
        MAX(total_time_spent)     AS total_time_per_slide,
        MAX(class_total_students) AS class_total_students
    FROM {{rs_bi_coredw}}.fact_slide_progress
    GROUP BY
        class_dw_id,
        school_dw_id,
        grade_name,
        tenant_dw_id,
        fle_lo_dw_id,
        fle_student_dw_id,
        slide_id,
        widget_id,
        date_trunc('week', local_date)
),
student_progress_per_slide AS (
    SELECT
        local_week,
        class_dw_id,
        school_dw_id,
        tenant_dw_id,
        widget_id,
        slide_id,
        grade_name,
        SUM(idle_time_per_slide)                                 AS sum_idle_time_per_slide,
        SUM(active_time_per_slide)                               AS sum_active_time_per_slide,
        SUM(total_time_per_slide)                                AS sum_total_time_per_slide,
        COUNT(DISTINCT fle_student_dw_id)                        AS total_students_per_slide,
        SUM(idle_time_per_slide)  / COUNT(DISTINCT fle_student_dw_id) AS avg_idle_time_per_slide,
        SUM(active_time_per_slide) / COUNT(DISTINCT fle_student_dw_id) AS avg_active_time_per_slide,
        SUM(total_time_per_slide) / COUNT(DISTINCT fle_student_dw_id)  AS avg_total_time_per_slide
    FROM fact_progress_per_slide
    GROUP BY
        class_dw_id,
        widget_id,
        grade_name,
        school_dw_id,
        tenant_dw_id,
        slide_id,
        local_week
),
unique_attempts_per_widget_type AS (
    SELECT
        date_trunc('week', local_date)              AS local_week,
        fsl.school_dw_id,
        fsl.class_dw_id,
        fsl.tenant_dw_id,
        fsl.grade_name,
        fsl.class_gen_subject,
        fsl.class_title,
        fsl.widget_id,
        COUNT(DISTINCT concat(slide_id, student_id)) AS slide_student_attempts
    FROM {{rs_bi_coredw}}.fact_slide_progress AS fsl
    GROUP BY
        date_trunc('week', local_date),
        fsl.school_dw_id,
        fsl.class_dw_id,
        fsl.class_title,
        fsl.class_gen_subject,
        fsl.tenant_dw_id,
        fsl.grade_name,
        fsl.class_gen_subject,
        fsl.class_title,
        fsl.widget_id
),
time_spent_per_slide AS (
    SELECT
        local_week,
        class_dw_id,
        school_dw_id,
        tenant_dw_id,
        grade_name,
        widget_id,
        SUM(sum_idle_time_per_slide)   AS total_idle_time_per_slide,
        SUM(sum_active_time_per_slide) AS total_active_time_per_slide,
        SUM(sum_total_time_per_slide)  AS total_total_time_per_slide,
        COUNT(DISTINCT slide_id)       AS total_slides_used_per_slide_type,
        AVG(avg_idle_time_per_slide)   AS avg_idle_time_per_slide,
        AVG(avg_active_time_per_slide) AS avg_active_time_per_slide,
        AVG(avg_total_time_per_slide)  AS avg_total_time_per_slide
    FROM student_progress_per_slide AS spps
    GROUP BY
        class_dw_id,
        school_dw_id,
        tenant_dw_id,
        widget_id,
        grade_name,
        local_week
)
SELECT
    CAST(tsps.local_week AS DATE) AS local_week,
    dsc.tenant_name,
    dsc.school_organisation,
    dsc.school_name,
    tsps.tenant_dw_id,
    tsps.school_dw_id,
    tsps.class_dw_id,
    tsps.widget_id,
    tsps.grade_name,
    dc.class_gen_subject          AS class_subject,
    dc.class_title,
    tsps.total_slides_used_per_slide_type,
    tsps.total_total_time_per_slide,
    tsps.total_idle_time_per_slide,
    tsps.total_active_time_per_slide,
    tsps.avg_total_time_per_slide,
    tsps.avg_idle_time_per_slide,
    tsps.avg_active_time_per_slide,
    ust.slide_student_attempts
FROM time_spent_per_slide AS tsps
JOIN {{rs_bi_coredw}}.bi_active_schools_dim AS dsc
    ON dsc.school_dw_id = tsps.school_dw_id
JOIN {{rs_coredw}}.dim_class AS dc
    ON dc.class_dw_id = tsps.class_dw_id
   AND dc.class_status = 1
JOIN unique_attempts_per_widget_type AS ust
    ON ust.grade_name   = tsps.grade_name
   AND ust.school_dw_id = tsps.school_dw_id
   AND ust.tenant_dw_id = tsps.tenant_dw_id
   AND ust.widget_id    = tsps.widget_id
   AND ust.class_dw_id  = tsps.class_dw_id
   AND ust.local_week   = tsps.local_week;