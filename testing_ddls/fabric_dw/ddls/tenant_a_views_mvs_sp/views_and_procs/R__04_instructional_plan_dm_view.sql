CREATE OR ALTER VIEW ${os_bi_coredw}.instructional_plan_dm_view AS

SELECT
    tenant_name AS tenant_name,
    school_dw_id                               AS school_dw_id,
    school_id AS school_id,
    school_name AS school_name,
    school_adek_id AS school_adek_id,
    school_country_name AS school_country_name,
    school_city_name AS school_city_name,
    school_label AS school_label,
    organisation_name AS organisation_name,
    school_cx_cluster AS school_cx_cluster,
    class_dw_id                                AS class_dw_id,
    class_total_students                       AS class_total_students,
    class_title AS class_title,
    class_gen_subject AS class_gen_subject,
    course_subject_id                          AS course_subject_id,
    section_dw_id                              AS section_dw_id,
    section_name AS section_name,
    class_section_name AS class_section_name,
    curr_grade_name AS curr_grade_name,
    grade_name AS grade_name,
    curr_subject_name AS curr_subject_name,
    instructional_plan_curriculum_id           AS instructional_plan_curriculum_id,
    lo_title AS lo_title,
    lo_to_finish                              AS lo_to_finish,
    lo_attempted                              AS lo_attempted,
    lo_status AS lo_status,
    fle_score                                 AS fle_score,
    student_dw_id                             AS student_dw_id,
    student_id AS student_id,
    student_tags AS student_tags,
    student_special_needs AS student_special_needs,
    local_date                               AS local_date,
    academic_year_start_date                 AS academic_year_start_date,
    academic_year_end_date                   AS academic_year_end_date,
    convert(FLOAT(53),week_number)                              AS week_number,
    week_start_date                          AS week_start_date,
    week_end_date                            AS week_end_date,
    content_academic_year_name AS content_academic_year_name,
    instructional_plan_name AS instructional_plan_name,
    instructional_plan_id AS instructional_plan_id,
    instructional_plan_item_order             AS instructional_plan_item_order,
    instructional_plan_item_optional          AS instructional_plan_item_optional,
    term_academic_period_order                AS term_academic_period_order,
    term_start_date                           AS term_start_date,
    term_end_date                             AS term_end_date,
    pacing AS pacing,
    session_time                             AS session_time,
    fle_source AS fle_source,
    grade_k12grade                            AS grade_k12grade,
    teacher_ids AS teacher_ids,
    course_type AS course_type
FROM ${rs_bi_coredw}.ip_instructional_plan_dm_view

UNION ALL

SELECT DISTINCT
    cont.tenant_name AS tenant_name,
    cont.school_dw_id                           AS school_dw_id,
    cont.school_id AS school_id,
    cont.school_name AS school_name,
    cont.school_alias AS school_adek_id,
    cont.school_country_name AS school_country_name,
    cont.school_city_name AS school_city_name,
    cont.school_label AS school_label,
    cont.school_organisation AS organisation_name,
    cont.school_cx_cluster AS school_cx_cluster,
    cts.class_dw_id                            AS class_dw_id,
    cts.class_total_students                   AS class_total_students,
    cts.class_title AS class_title,
    cts.class_gen_subject AS class_gen_subject,
    cts.course_subject_id                      AS course_subject_id,
    cts.section_dw_id                          AS section_dw_id,
    cts.section_name AS section_name,
    cts.class_section_name AS class_section_name,
    'NA' AS curr_grade_name,
    cts.grade_name AS grade_name,
    'NA' AS curr_subject_name,
    999999                                      AS instructional_plan_curriculum_id,
    cont.lo_title AS lo_title,
    cont.activity_dw_id                         AS lo_to_finish,
    lp.lo_attempted                             AS lo_attempted,
    lp.lo_status AS lo_status,
    lp.fle_score                                AS fle_score,
    lp.student_dw_id                            AS student_dw_id,
    ds.student_id AS student_id,
    lp.student_tags AS student_tags,
    lp.student_special_needs AS student_special_needs,
    lp.local_date                              AS local_date,
    lp.academic_year_start_date                AS academic_year_start_date,
    lp.academic_year_end_date                  AS academic_year_end_date,
    CONVERT(
        FLOAT(53),
        ISNULL(
            CASE cont.pacing
                WHEN 'MONTH' THEN DATEPART(MONTH, cont.week_start_date)
                ELSE DATEPART(ISO_WEEK, cont.week_start_date)
            END,
            1
        )
    ) AS week_number,
    cont.week_start_date                        AS week_start_date,
    cont.week_end_date                          AS week_end_date,
    cts.content_academic_year_name AS content_academic_year_name,
    cont.course_name AS instructional_plan_name,
    cont.course_id AS instructional_plan_id,
    cont.instructional_plan_item_order           AS instructional_plan_item_order,
    CONVERT(BIT, 0)                               AS instructional_plan_item_optional,
    cont.term_academic_period_order              AS term_academic_period_order,
    cont.term_start_date                         AS term_start_date,
    cont.term_end_date                           AS term_end_date,
    cont.pacing AS pacing,
    lp.session_time                             AS session_time,
    lp.fle_source AS fle_source,
    lp.grade_k12grade                           AS grade_k12grade,
    cts.teacher_ids AS teacher_ids,
    'Course' AS course_type
FROM ${rs_bi_coredw}.class_total_students cts
INNER JOIN ${rs_bi_coredw}.core_class_activity_content cont
    ON cont.class_dw_id = cts.class_dw_id
LEFT JOIN ${rs_bi_coredw}.students_lesson_progress lp
    ON cts.class_dw_id = lp.fle_class_dw_id
   AND cts.section_dw_id = lp.student_section_dw_id
   AND cont.activity_dw_id = lp.lo_attempted
LEFT JOIN ${rs_bi_coredw}.bi_student_dim ds
    ON ds.student_dw_id = lp.student_dw_id
   AND ds.student_status = 1;
