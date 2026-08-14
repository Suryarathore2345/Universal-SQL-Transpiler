CREATE OR ALTER VIEW ${os_bi_coredw}.pathway_nlf_activity_dm_view
AS
WITH pathway_student_details AS (
    SELECT DISTINCT
        pathway_student_dw_id,
        fpp_student_dw_id,
        adt_student_dw_id,
        CASE
            WHEN fpp_placement_type = 4 THEN fpp_student_dw_id
        END AS adt_placed_student_dw_id,
        course_dw_id,
        school_name,
        school_dw_id,
        organisation_dw_id,
        school_organisation,
        tenant_id,
        tenant_name,
        grade_name,
        curr_subject_name,
        academic_year
    FROM ${rs_bi_coredw}.pathway_adaptive_practice
),

/* ---------------------------------------------------
   EXACT Redshift-style "latest attempt" logic
--------------------------------------------------- */
adaptive_practice AS (
    SELECT
        pap.student_dw_id,
        pap.course_dw_id,
        pap.pathway_activity_date,
        pap.academic_year,
        COUNT(DISTINCT pap.question_id) AS questions
    FROM ${rs_bi_coredw}.pathway_adaptive_practice pap
    INNER JOIN (
        SELECT
            student_dw_id,
            course_dw_id,
            academic_year,
            level_dw_id,
            question_id,
            MAX(session_attempt) AS max_session_attempt
        FROM ${rs_bi_coredw}.pathway_adaptive_practice
        GROUP BY
            student_dw_id,
            course_dw_id,
            academic_year,
            level_dw_id,
            question_id
    ) mx
        ON pap.student_dw_id     = mx.student_dw_id
       AND pap.course_dw_id      = mx.course_dw_id
       AND pap.academic_year     = mx.academic_year
       AND pap.level_dw_id       = mx.level_dw_id
       AND pap.question_id       = mx.question_id
       AND pap.session_attempt   = mx.max_session_attempt
    GROUP BY
        pap.student_dw_id,
        pap.course_dw_id,
        pap.pathway_activity_date,
        pap.academic_year
),

/* ---------------------------------------------------
   Skill learning aggregation (same as Redshift)
--------------------------------------------------- */
skill_learning AS (
    SELECT
        skill_learning_student_dw_id,
        material_dw_id,
        CONVERT(DATE, skill_learning_date_time) AS skill_learning_date,
        academic_year,
        COUNT(DISTINCT CASE
            WHEN is_component_completed = 1 THEN skill_component_id
        END) AS components_completed,
        COUNT(DISTINCT CASE
            WHEN is_skill_learning_completed = 1 THEN skill_learning_dw_id
        END) AS skills_completed
    FROM ${rs_bi_coredw}.pathway_skill_learning_dm_view
    GROUP BY
        skill_learning_student_dw_id,
        material_dw_id,
        CONVERT(DATE, skill_learning_date_time),
        academic_year
),

/* ---------------------------------------------------
   UNION (NOT UNION ALL) â€” matches Redshift
--------------------------------------------------- */
nlf_joined AS (
    SELECT DISTINCT
        student_dw_id,
        course_dw_id,
        pathway_activity_date AS activity_date,
        academic_year,
        CASE WHEN questions > 0 THEN 1 ELSE 0 END AS onboarded_flag,
        CASE WHEN questions > 0 THEN 1 ELSE 0 END AS active_flag,
        CONVERT(INT, NULL)                         AS actively_engaged_flag,
        questions,
        CONVERT(INT, NULL)                         AS skills
    FROM adaptive_practice

    UNION

    SELECT DISTINCT
        skill_learning_student_dw_id,
        material_dw_id,
        skill_learning_date AS activity_date,
        academic_year,
        1                                        AS onboarded_flag,
        CASE WHEN components_completed > 0 THEN 1 ELSE 0 END AS active_flag,
        CASE WHEN skills_completed > 0 THEN 1 ELSE 0 END     AS actively_engaged_flag,
        CONVERT(INT, NULL)                         AS questions,
        skills_completed                         AS skills
    FROM skill_learning
)

/* ---------------------------------------------------
   Final aggregation â€” BOOL_OR equivalent
--------------------------------------------------- */
SELECT
    psd.pathway_student_dw_id      AS nlf_pathway_student_dw_id,
    psd.course_dw_id               AS nlf_course_dw_id,
    psd.academic_year              AS nlf_academic_year,
    psd.curr_subject_name          AS nlf_curr_subject_name,
    psd.grade_name                 AS nlf_grade_name,
    psd.tenant_name                AS nlf_tenant_name,
    psd.school_name                AS nlf_school_name,
    psd.school_organisation        AS nlf_school_organisation,
    psd.tenant_id                  AS nlf_tenant_id,
    psd.school_dw_id               AS nlf_school_dw_id,
    psd.organisation_dw_id         AS nlf_organisation_dw_id,
    nlf.student_dw_id              AS nlf_student_dw_id,
    nlf.activity_date              AS nlf_activity_date,

    /* BOOL_OR equivalents */
    CONVERT(BIT, MAX(CASE WHEN nlf.onboarded_flag = 1 THEN 1 ELSE 0 END)) AS nlf_is_onboarded,
    CONVERT(BIT, MAX(CASE WHEN nlf.active_flag = 1 THEN 1 ELSE 0 END)) AS nlf_is_active,
    CONVERT(BIT, MAX(CASE WHEN nlf.actively_engaged_flag = 1 THEN 1 ELSE 0 END)) AS nlf_is_actively_engaged,

    MAX(nlf.questions) AS nlf_questions_submitted,
    MAX(nlf.skills)    AS nlf_skills_learned

FROM pathway_student_details psd
LEFT JOIN nlf_joined nlf
    ON nlf.student_dw_id = psd.pathway_student_dw_id
   AND nlf.course_dw_id  = psd.course_dw_id
   AND nlf.academic_year = psd.academic_year
GROUP BY
    psd.pathway_student_dw_id,
    psd.course_dw_id,
    psd.academic_year,
    psd.curr_subject_name,
    psd.grade_name,
    psd.tenant_name,
    psd.school_name,
    psd.school_organisation,
    psd.tenant_id,
    psd.school_dw_id,
    psd.organisation_dw_id,
    nlf.student_dw_id,
    nlf.activity_date;
