CREATE OR ALTER VIEW ${os_bi_coredw}.nce_ese_lo_mastery_view AS
WITH class_db AS (
    SELECT
        class_dw_id,
        class_gen_subject,
        class_status,
        ROW_NUMBER() OVER (
            PARTITION BY class_dw_id
            ORDER BY
                class_created_time DESC
        ) AS id
    FROM ${rs_coredw}.dim_class
    WHERE class_status = 1
),

db AS (
    SELECT
        fle.fle_student_dw_id,
        lower(trim(dlo.lo_title))                    AS lo_title,
        dlo.lo_id,
        MAX(dsc.school_name)            AS school_name,
        MAX(dg.grade_k12grade)          AS curr_grade_name,
        MAX(dsc.school_composition)     AS school_composition,
        MAX(class_db.class_gen_subject) AS subject,
        MAX(dsc.school_city_name)       AS school_city_name,
        AVG(fle.fle_score)              AS score,
        MAX(dsc.school_organisation)    AS organisation_name,

        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year
    FROM ${rs_coredw}.fact_learning_experience fle
    INNER JOIN ${rs_bi_coredw}.bi_student_dim sdm
        ON fle.fle_student_dw_id = sdm.student_dw_id
    LEFT JOIN class_db
        ON fle.fle_class_dw_id = class_db.class_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON sdm.student_school_dw_id = dsc.school_dw_id
    INNER JOIN ${rs_coredw}.dim_grade dg
        ON sdm.student_grade_dw_id = dg.grade_dw_id
       AND dsc.academic_year_id = dg.academic_year_id
    LEFT JOIN ${rs_coredw}.dim_learning_objective dlo
        ON fle.fle_lo_dw_id = dlo.lo_dw_id
    WHERE
        fle.fle_lesson_category = 'INSTRUCTIONAL_LESSON'
      AND fle.fle_lesson_type = 'SA'
      AND dsc.organisation_dw_id = 17 -- NCE content repository code
      AND dg.grade_status = 1
      AND sdm.student_status = 1
    group by fle.fle_student_dw_id, lower(trim(dlo.lo_title)), dlo.lo_id, dsc.academic_year_start_date, dsc.academic_year_end_date)

SELECT
    CONVERT(VARCHAR(4000), school_name) AS school_name,
    fle_student_dw_id,
    CONVERT(VARCHAR(50), academic_year) AS academic_year,
    CONVERT(VARCHAR(200), school_composition) AS school_composition,
    CONVERT(VARCHAR(200), school_city_name) AS school_city_name,
    CONVERT(VARCHAR(200), subject) AS subject,
    CONVERT(VARCHAR(4000), lo_title) AS lo_title,
    CONVERT(VARCHAR(200), organisation_name) AS organisation_name,
    CONVERT(VARCHAR(50), curr_grade_name) AS curr_grade_name,
    score AS fle_score
FROM db

UNION ALL

SELECT 
    school_name,
    fle_student_dw_id,
    academic_year,
    school_composition,
    school_city_name,
    subject,
    lo_title,
    organisation_name,
    curr_grade_name,
    fle_score
FROM ${rs_bi_coredw}.nce_ese_lo_mastery_prev_year;