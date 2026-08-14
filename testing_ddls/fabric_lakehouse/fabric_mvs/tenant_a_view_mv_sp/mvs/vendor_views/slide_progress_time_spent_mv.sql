-------- ====== SUB SET FOR LESSON LEVEL INSIGHTS =======
CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.slide_progress_time_spent_mv
AS
WITH daily_time_spent_per_slide AS (
    SELECT
        sl.local_date                     AS local_date,
        sl.fle_lo_dw_id,
        sl.fle_student_dw_id,
        sl.class_dw_id,
        sl.school_dw_id,
        sl.grade_id,
        sl.grade_name,
        sl.tenant_dw_id,
        sl.slide_id,
        sl.rnk,
        sl.widget_id,
        COALESCE(sl.total_time_spent,  0) AS total_time_spent,
        COALESCE(sl.active_time_spent, 0) AS active_time_spent,
        COALESCE(sl.idle_time_spent,   0) AS idle_time_spent
    FROM {{rs_bi_coredw}}.fact_slide_progress AS sl
    -- WHERE sl.rnk = 1
),

daily_time_spent_per_student_per_activity AS (
    SELECT
        local_date,
        school_dw_id,
        class_dw_id,
        fle_student_dw_id,
        fle_lo_dw_id,
        grade_name,
        grade_id,
        tenant_dw_id,
        SUM(total_time_spent)  AS aggregated_total_timespent,
        SUM(active_time_spent) AS aggregated_active_timespent,
        SUM(idle_time_spent)   AS aggregated_idle_timespent
    FROM daily_time_spent_per_slide
    GROUP BY
        school_dw_id,
        class_dw_id,
        fle_student_dw_id,
        fle_lo_dw_id,
        grade_name,
        grade_id,
        tenant_dw_id,
        local_date
),

slides_completed_per_stud_per_lo AS (
    SELECT
        MAX(fsl.local_date)          AS local_date,
        fsl.fle_lo_dw_id,
        fsl.fle_student_dw_id,
        fsl.class_dw_id,
        fsl.school_dw_id,
        COUNT(DISTINCT fsl.slide_id) AS slides_completed_per_student
    FROM {{rs_bi_coredw}}.fact_slide_progress AS fsl
    JOIN {{rs_coredw}}.dim_content_slide AS dcl
        ON dcl.id = fsl.slide_id
       AND dcl.status = 1
    GROUP BY
        fsl.fle_lo_dw_id,
        fsl.class_dw_id,
        fsl.fle_student_dw_id,
        fsl.school_dw_id
),

slides_assigned_per_lo AS (
    SELECT
        activity_dw_id,
        COUNT(DISTINCT slide_id) AS num_slides_per_lo
    FROM {{rs_bi_coredw}}.lo_structure_components
    GROUP BY
        activity_dw_id
),

student_progress_per_lo AS (
    SELECT DISTINCT
        pss.local_date,
        pss.fle_lo_dw_id,
        pss.fle_student_dw_id,
        pss.class_dw_id,
        pss.school_dw_id,
        COALESCE(
            CASE
                WHEN MAX(pss.slides_completed_per_student)
                     = MAX(spl.num_slides_per_lo)
                    THEN 'Completed'
                WHEN MAX(pss.slides_completed_per_student) > 0
                 AND MAX(pss.slides_completed_per_student)
                     < MAX(spl.num_slides_per_lo)
                    THEN 'In-Progress'
            END,
            'NA'
        ) AS lesson_completion_status
    FROM slides_completed_per_stud_per_lo AS pss
    JOIN slides_assigned_per_lo AS spl
        ON spl.activity_dw_id = pss.fle_lo_dw_id
    GROUP BY
        pss.fle_lo_dw_id,
        pss.fle_student_dw_id,
        pss.class_dw_id,
        pss.school_dw_id,
        pss.local_date
),

unique_students_finished_lo AS (
    SELECT
        pss.school_dw_id,
        COALESCE(
            COUNT(DISTINCT CASE
                WHEN pss.slides_completed_per_student = spl.num_slides_per_lo
                    THEN pss.fle_student_dw_id
            END),
            0
        ) AS unique_students_finished
    FROM slides_completed_per_stud_per_lo AS pss
    JOIN slides_assigned_per_lo AS spl
        ON spl.activity_dw_id = pss.fle_lo_dw_id
    GROUP BY
        pss.school_dw_id
)

SELECT
    wts.local_date,
    wts.fle_lo_dw_id,
    wts.fle_student_dw_id,
    wts.school_dw_id,
    wts.class_dw_id,
    wts.grade_id,
    wts.grade_name,
    wts.tenant_dw_id,
    wts.aggregated_active_timespent,
    wts.aggregated_idle_timespent,
    wts.aggregated_total_timespent,
    MAX(sapl.num_slides_per_lo)                AS num_slides_per_lesson,
    MAX(scs.slides_completed_per_student)      AS slide_completed_by_student,
    sppl.lesson_completion_status,
    MAX(fle.unique_students_finished)          AS unique_students_completed_at_least_1_lo
FROM daily_time_spent_per_student_per_activity AS wts
JOIN slides_assigned_per_lo AS sapl
    ON sapl.activity_dw_id = wts.fle_lo_dw_id
JOIN slides_completed_per_stud_per_lo AS scs
    ON scs.fle_student_dw_id = wts.fle_student_dw_id
   AND scs.fle_lo_dw_id      = wts.fle_lo_dw_id
   AND scs.class_dw_id       = wts.class_dw_id
INNER JOIN student_progress_per_lo AS sppl
    ON sppl.fle_student_dw_id = wts.fle_student_dw_id
   AND sppl.fle_lo_dw_id      = wts.fle_lo_dw_id
   AND sppl.local_date        = wts.local_date
LEFT JOIN unique_students_finished_lo AS fle
    ON fle.school_dw_id = wts.school_dw_id
GROUP BY
    wts.local_date,
    wts.fle_lo_dw_id,
    wts.fle_student_dw_id,
    wts.school_dw_id,
    wts.class_dw_id,
    wts.grade_id,
    wts.grade_name,
    wts.tenant_dw_id,
    sppl.lesson_completion_status,
    wts.aggregated_active_timespent,
    wts.aggregated_total_timespent,
    wts.aggregated_idle_timespent;