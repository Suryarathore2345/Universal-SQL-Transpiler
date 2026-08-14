CREATE OR ALTER VIEW ${os_bi_coredw}.core_course_classlearning_agg_view AS
WITH class_total_students AS (
    SELECT
        ISNULL(cts.class_dw_id, cts_prev.class_dw_id) AS class_dw_id,
        ISNULL(cts.section_dw_id, cts_prev.class_section_dw_id) AS section_dw_id,
        ISNULL(cts.section_name, cts_prev.class_section_name) AS section_name,
        ISNULL(cts.class_total_students, cts_prev.class_total_students) AS class_total_students
    FROM
        ${rs_bi_coredw}.class_total_students cts
    FULL OUTER JOIN ${rs_bi_coredw}.class_total_students_prev_ay cts_prev
        ON cts.class_dw_id = cts_prev.class_dw_id
),

core_course_learning_experience AS (
    SELECT
        fle_class_dw_id,
        student_section_dw_id AS fle_section_dw_id,
        lo_attempted AS fle_lo_dw_id,
        ISNULL(fle_source, 'NA') AS fle_source,
        COUNT(student_dw_id)                                                              AS total_students_fact,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' THEN student_dw_id END)          AS total_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN student_dw_id END) AS total_completed_students_score,
        SUM(CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN fle_score END)     AS fle_score,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score >= 70 THEN student_dw_id END) AS meets_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score >= 50 AND fle_score < 70 THEN student_dw_id END) AS approaching_completed_students,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' AND fle_score < 50 AND fle_score >= 0 THEN student_dw_id END)  AS below_completed_students,
        SUM(session_time)                                                                 AS session_time
    FROM ${rs_bi_coredw}.students_lesson_progress
    GROUP BY
        fle_class_dw_id,
        student_section_dw_id,
        lo_attempted,
        ISNULL(fle_source, 'NA')

    UNION ALL

    SELECT
        ccfle.fle_class_dw_id,
        ccfle.fle_section_dw_id,
        ccfle.fle_lo_dw_id,
        ccfle.fle_source,
        ccfle.total_students_fact,
        ccfle.total_completed_students,
        ccfle.total_completed_students_score,
        ccfle.fle_score,
        ccfle.meets_completed_students,
        ccfle.approaching_completed_students,
        ccfle.below_completed_students,
        ccfle.session_time
    FROM ${rs_bi_coredw}.core_course_learning_experience ccfle
    WHERE NOT EXISTS (
        SELECT 1
        FROM ${rs_bi_coredw}.students_lesson_progress slp
        WHERE ccfle.fle_class_dw_id = slp.fle_class_dw_id
    )
)

SELECT
    cont.course_id,
    cont.course_name,
    cont.class_dw_id,
    cont.class_id,
    cont.class_title,
    cont.class_gen_subject,
    cont.class_grade_id,
    cont.grade_name,
    cont.school_id,
    cont.school_dw_id,
    cont.school_name,
    cont.school_alias,
    cont.school_label,
    cont.school_cx_cluster,
    cont.school_city_name,
    cont.school_country_name,
    cont.tenant_name,
    cont.school_organisation,
    cont.activity_dw_id,
    cont.lo_title,
    cont.course_subject_id,
    cont.instructional_plan_item_order,
    cont.week_start_date,
    cont.week_end_date,
    cont.term_academic_period_order,
    cont.term_start_date,
    cont.term_end_date,
    cont.pacing,
    cont.academic_year_start_date,
    cont.academic_year_end_date,
    cont.academic_year_id,
    cont.academic_year,
    cts.section_dw_id,
    cts.section_name,
    cts.class_total_students,
    fact.fle_source,
    fact.total_students_fact,
    fact.total_completed_students,
    fact.total_completed_students_score,
    fact.total_students_fact - fact.total_completed_students AS total_inprogress_students,
    fact.fle_score,
    fact.meets_completed_students,
    fact.approaching_completed_students,
    fact.below_completed_students,
    CASE
        WHEN fact.total_completed_students IS NULL OR fact.total_completed_students = 0 THEN NULL
        ELSE fact.fle_score / CONVERT(FLOAT, fact.total_completed_students)
    END AS avg_score,
    fact.session_time
FROM ${rs_bi_coredw}.core_class_activity_content cont
INNER JOIN class_total_students cts
    ON cts.class_dw_id = cont.class_dw_id
LEFT JOIN core_course_learning_experience fact
    ON fact.fle_class_dw_id = cont.class_dw_id
   AND fact.fle_lo_dw_id = cont.activity_dw_id
   AND fact.fle_section_dw_id = cts.section_dw_id;
