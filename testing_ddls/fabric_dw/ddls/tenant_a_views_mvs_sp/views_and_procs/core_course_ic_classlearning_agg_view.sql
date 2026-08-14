CREATE OR ALTER VIEW ${os_bi_coredw}.core_course_ic_classlearning_agg_view AS
WITH class_total_students AS (
    SELECT
        ISNULL(cts.class_dw_id, cts_prev.class_dw_id)                   AS class_dw_id,
        ISNULL(cts.section_dw_id, cts_prev.class_section_dw_id)         AS section_dw_id,
        ISNULL(cts.section_name, cts_prev.class_section_name)           AS section_name,
        ISNULL(cts.class_total_students, cts_prev.class_total_students) AS class_total_students
    FROM ${rs_bi_coredw}.class_total_students cts
    FULL OUTER JOIN ${rs_bi_coredw}.class_total_students_prev_ay cts_prev
        ON cts.class_dw_id = cts_prev.class_dw_id
),

core_course_ic_experience AS (
    /* === primary aggregation from students_ic_progress === */
    SELECT
        fle_class_dw_id,
        student_section_dw_id AS fle_section_dw_id,
        fle_lo_dw_id,
        COUNT(DISTINCT student_dw_id) AS total_students_fact,
        COUNT(DISTINCT CASE
            WHEN ic_status = 'Completed'
            THEN student_dw_id
        END) AS total_completed_students,
        COUNT(DISTINCT CASE
            WHEN fle_total_score >= 70
            THEN student_dw_id
        END) AS meets_completed_students,
        COUNT(DISTINCT CASE
            WHEN fle_total_score >= 50 AND fle_total_score < 70
            THEN student_dw_id
        END) AS approaching_completed_students,
        COUNT(DISTINCT CASE
            WHEN fle_total_score < 50 AND fle_total_score >= 0
            THEN student_dw_id
        END) AS below_completed_students,
        SUM(fle_total_score) AS fle_score,
        SUM(session_time)    AS session_time
    FROM ${rs_bi_coredw}.students_ic_progress
    GROUP BY
        fle_class_dw_id,
        student_section_dw_id,
        fle_lo_dw_id

    UNION ALL

    /* === fallback rows when no IC progress exists === */
    SELECT
        ccfle.fle_class_dw_id,
        ccfle.fle_section_dw_id,
        ccfle.fle_lo_dw_id,
        ccfle.total_students_fact,
        ccfle.total_completed_students, 
        ccfle.meets_completed_students,
        ccfle.approaching_completed_students,
        ccfle.below_completed_students,
        ccfle.fle_score,
        ccfle.session_time
    FROM ${rs_bi_coredw}.core_course_ic_experience ccfle
    WHERE NOT EXISTS (
        SELECT 1
        FROM ${rs_bi_coredw}.students_ic_progress slp
        WHERE slp.fle_class_dw_id = ccfle.fle_class_dw_id
    )
)

SELECT
    cont.*,
    cts.section_dw_id,
    cts.section_name,
    cts.class_total_students,
    fact.total_students_fact,
    fact.total_completed_students,
    fact.total_students_fact - fact.total_completed_students AS total_inprogress_students,
    fact.meets_completed_students,
    fact.approaching_completed_students,
    fact.below_completed_students,
    fact.fle_score,
    fact.fle_score / CONVERT(FLOAT, fact.total_completed_students) AS avg_score,
    fact.session_time
FROM ${rs_bi_coredw}.core_class_ic_content cont
INNER JOIN class_total_students cts
    ON cts.class_dw_id = cont.class_dw_id
LEFT JOIN core_course_ic_experience fact
    ON fact.fle_class_dw_id  = cont.class_dw_id
   AND fact.fle_lo_dw_id     = cont.activity_dw_id
   AND fact.fle_section_dw_id = cts.section_dw_id;
