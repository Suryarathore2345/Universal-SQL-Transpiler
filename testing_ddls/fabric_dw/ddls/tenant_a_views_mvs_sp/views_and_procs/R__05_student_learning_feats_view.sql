-- CREATING THIS VIEW TO REPLACE A CUSTOM DATA SOURCE FOR NCE OVERVIEW REPORT.
CREATE OR ALTER VIEW ${os_bi_coredw}.student_learning_feats_view AS

WITH class_db AS (
    SELECT 
        class_dw_id,
        class_gen_subject,
        class_status,
        ROW_NUMBER() OVER (PARTITION BY class_dw_id ORDER BY class_created_time DESC) AS id
    FROM ${rs_coredw}.dim_class
),

db AS (
    SELECT 
        -- fact_learning_experience columns
        fle.fle_student_dw_id,
        fle.fle_lo_dw_id,
        fle.fle_class_dw_id,
        fle.fle_date_dw_id,
        fle.fle_lesson_category,
        fle.fle_lesson_type,
        fle.fle_material_type,
        fle.fle_score,
        -- dim_student columns
        ds.student_dw_id,
        ds.student_status,
        ds.student_school_dw_id,
        ds.student_grade_dw_id,
        -- bi_active_schools_dim columns
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.school_composition,
        dsc.school_city_name,
        dsc.organisation_dw_id,
        -- dim_grade columns
        dg.grade_dw_id,
        dg.grade_k12grade,
        dg.grade_status,
        -- class_db columns
        cdb.class_gen_subject,
        cdb.class_status,
        -- dim_interim_checkpoint columns
        dic.ic_title
    FROM ${rs_coredw}.fact_learning_experience fle
    JOIN ${rs_coredw}.dim_student ds 
        ON fle.fle_student_dw_id = ds.student_dw_id
    JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc 
        ON ds.student_school_dw_id = dsc.school_dw_id
    JOIN ${rs_coredw}.dim_grade dg 
        ON ds.student_grade_dw_id = dg.grade_dw_id
    JOIN class_db cdb 
        ON fle.fle_class_dw_id = cdb.class_dw_id 
        AND cdb.id = 1
    LEFT JOIN ${rs_coredw}.dim_interim_checkpoint dic 
        ON fle.fle_lo_dw_id = dic.ic_dw_id
    WHERE fle.fle_date_dw_id >= 20220901
        AND ds.student_status = 1
        AND dg.grade_status = 1
        AND cdb.class_status = 1
        AND fle.fle_lesson_category IN ('INSTRUCTIONAL_LESSON', 'INTERIM_CHECKPOINT')
        AND dsc.organisation_dw_id IN (17)
        AND fle.fle_material_type <> 'PATHWAY'
)

SELECT 
    fle_student_dw_id,
    class_gen_subject,
    grade_k12grade,
    MAX(school_name) AS school_name,
    MAX(school_organisation) AS school_organization,
    MAX(school_composition) AS school_composition,
    MAX(school_city_name) AS school_city_name,
    COUNT(DISTINCT ic_title) AS no_interim,
    COUNT(DISTINCT fle_lo_dw_id) AS no_mlo_completed,
    AVG(CASE WHEN fle_lesson_category = 'INTERIM_CHECKPOINT' THEN fle_score END) AS interim_score,
    AVG(CASE WHEN fle_lesson_category = 'INSTRUCTIONAL_LESSON' THEN fle_score END) AS formative_score
FROM db
WHERE fle_lesson_type = 'SA'
GROUP BY 
    fle_student_dw_id,
    grade_k12grade,
    class_gen_subject;
