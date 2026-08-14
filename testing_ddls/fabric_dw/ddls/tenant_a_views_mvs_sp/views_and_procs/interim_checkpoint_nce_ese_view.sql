CREATE OR ALTER VIEW ${os_bi_coredw}.interim_checkpoint_nce_ese_view
AS
WITH class_db AS (
    SELECT
        class_dw_id,
        UPPER(class_gen_subject) AS class_gen_subject,
        class_status,
        ROW_NUMBER() OVER (
            PARTITION BY class_dw_id
            ORDER BY
                class_created_time DESC
        ) AS id
    FROM ${rs_coredw}.dim_class
    WHERE class_status = 1
),

school_grade_cnt AS (
    SELECT
        school_dw_id,
        grade AS grade_k12grade,
        MAX(school_name)         AS school_name,
        MAX(school_organisation) AS organisation_name,
        MAX(school_composition)  AS school_composition,
        MAX(org_dw_id)           AS organisation_dw_id,
        SUM(total_students)      AS total_student
    FROM ${rs_bi_coredw}.total_students
    WHERE local_date = DATEADD(day, -1, CONVERT(date, GETDATE()))
      AND org_dw_id = 17
    GROUP BY school_dw_id, grade
),

db AS (
    SELECT
        fle_student_dw_id,
        school_dw_id,
        class_gen_subject,
        ISNULL(dtrm.actp_teaching_period_order, 1) AS term_academic_period_order,
        grade_k12grade,
        AVG(fle_score) AS fle_score,
        CONVERT(VARCHAR(4), DATEPART(year, dsc.academic_year_start_date)) + '-' +
        CONVERT(VARCHAR(4), DATEPART(year, dsc.academic_year_end_date)) AS academic_year
    FROM ${rs_coredw}.fact_learning_experience fle
    INNER JOIN ${rs_bi_coredw}.bi_student_dim s
        ON fle.fle_student_dw_id = s.student_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON s.student_school_dw_id = dsc.school_dw_id
    INNER JOIN ${rs_coredw}.dim_grade g
        ON s.student_grade_dw_id = g.grade_dw_id
       AND dsc.academic_year_id = g.academic_year_id
    INNER JOIN class_db c
        ON fle.fle_class_dw_id = c.class_dw_id
       AND c.id = 1
    LEFT JOIN ${rs_coredw}.dim_pacing_guide dpg
        ON c.class_dw_id = dpg.pacing_class_dw_id
       AND fle.fle_lo_dw_id = dpg.pacing_activity_dw_id
       AND dpg.pacing_status = 1
    LEFT JOIN ${rs_coredw}.dim_academic_calendar_teaching_period dtrm
        ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
       AND dtrm.actp_status = 1
    WHERE s.student_status = 1
      AND dsc.organisation_dw_id = 17 -- NCE org code
      AND fle.fle_lesson_category = 'INTERIM_CHECKPOINT'
      AND g.grade_status = 1
      AND fle.fle_lesson_type = 'SA'
    GROUP BY
        fle_student_dw_id,
        school_dw_id,
        class_gen_subject,
        ISNULL(dtrm.actp_teaching_period_order, 1),
        grade_k12grade,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date
),

db_1 AS (
    SELECT
        db.fle_student_dw_id,
        db.grade_k12grade,
        db.class_gen_subject,
        sgc.school_name,
        sgc.school_composition,
        sgc.organisation_name,
        db.term_academic_period_order,
        db.fle_score,
        db.academic_year,
        sgc.total_student
    FROM db
    INNER JOIN school_grade_cnt sgc
        ON db.school_dw_id = sgc.school_dw_id
       AND db.grade_k12grade = sgc.grade_k12grade
)

SELECT
    fle_student_dw_id,
    grade_k12grade,
    class_gen_subject,
    school_name,
    school_composition,
    organisation_name,
    term_academic_period_order,
    fle_score,
    academic_year,
    total_student
FROM db_1

UNION ALL

SELECT
    fle_student_dw_id,
    grade_k12grade,
    UPPER(class_gen_subject) AS class_gen_subject,
    school_name,
    school_composition,
    organisation_name,
    term_academic_period_order,
    fle_score,
    academic_year,
    total_student
FROM ${rs_bi_coredw}.interim_checkpint_test_nce_ese_prev_year;