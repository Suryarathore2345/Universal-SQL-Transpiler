CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.student_lesson_progress_sport_academy_mv
AS
WITH TOTAL_LESSONS_ASSIGNED AS (
    SELECT DISTINCT 
        d_cu.class_user_user_dw_id,
        d_cu.class_user_class_dw_id,
        cac.activity_dw_id AS lo_to_finish,
        dlo.lo_title,
        dlo.lo_id,
        cac.course_id,
        cac.course_name,
        cac.class_dw_id,
        UPPER(cac.class_title) AS class_title,
        UPPER(cac.class_gen_subject) AS class_gen_subject,
        cac.tenant_name,
        cac.school_dw_id,
        cac.school_id,
        cac.school_name,
        cac.school_alias AS school_adek_id,
        cac.school_country_name,
        cac.school_city_name,
        cac.school_label,
        cac.school_organisation AS organisation_name,
        cac.school_cx_cluster,
        cac.academic_year_start_date,
        cac.academic_year_end_date,
        COALESCE(
            CASE
                WHEN cac.pacing = 'MONTH' THEN MONTH(cac.week_start_date)
                ELSE WEEKOFYEAR(cac.week_start_date)
            END, 
            1
        ) AS week_number,
        COALESCE(cac.week_start_date, cac.academic_year_start_date) AS week_start_date,
        COALESCE(cac.week_end_date, cac.academic_year_end_date) AS week_end_date,
        COALESCE(cac.term_academic_period_order, 1) AS term_academic_period_order,
        COALESCE(cac.instructional_plan_item_order, 1) AS activity_item_order,
        COALESCE(cac.term_start_date, cac.academic_year_start_date) AS term_start_date,
        COALESCE(cac.term_end_date, cac.academic_year_end_date) AS term_end_date,
        cac.pacing
    FROM {{rs_coredw}}.dim_class_user d_cu
    INNER JOIN {{rs_bi_coredw}}.core_class_activity_content cac
        ON cac.class_dw_id = d_cu.class_user_class_dw_id
    INNER JOIN {{rs_coredw}}.dim_class dc
        ON dc.class_dw_id = d_cu.class_user_class_dw_id
    INNER JOIN {{rs_coredw}}.dim_course dcr
        ON dcr.course_id = class_material_id
    INNER JOIN {{rs_coredw}}.dim_learning_objective dlo
        ON dlo.lo_dw_id = cac.activity_dw_id
        AND dlo.lo_status = 1
        AND COALESCE(dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
    WHERE d_cu.class_user_attach_status = 1
        AND d_cu.class_user_status = 1
        AND d_cu.class_user_role_dw_id = 2
        AND cac.school_dw_id = 132766
        AND dcr.course_type = 'CORE'
),

COMPLETED_LESSONS AS (
    SELECT
        local_date,
        fle_ls_id,
        fle_lo_dw_id,
        fle_student_dw_id,
        fle_attempt,
        fle_dw_id,
        fle_score
    FROM (
        SELECT 
            CAST(FROM_UTC_TIMESTAMP(fle.fle_created_time, dsc.tenant_timezone) AS DATE) AS local_date,
            fle.fle_ls_id,
            fle.fle_lo_dw_id,
            fle.fle_student_dw_id,
            fle.fle_attempt,
            fle.fle_dw_id,
            CASE WHEN lo.lo_max_stars > 0 THEN fle.fle_total_score END AS fle_score,
            ROW_NUMBER() OVER (PARTITION BY fle.fle_ls_id ORDER BY fle.fle_created_time DESC) AS rnk
        FROM {{rs_coredw}}.fact_learning_experience fle
        JOIN {{rs_coredw}}.dim_learning_objective lo
            ON lo.lo_dw_id = fle.fle_lo_dw_id
            AND lo.lo_status = 1
        JOIN {{rs_bi_coredw}}.bi_active_schools_dim dsc
            ON fle.fle_school_dw_id = dsc.school_dw_id
            AND CAST(fle.fle_created_time AS DATE) >= dsc.academic_year_start_date
            AND CAST(fle.fle_created_time AS DATE) <= dsc.academic_year_end_date
        WHERE fle.fle_completion_node = TRUE
            AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
            AND fle.fle_material_type <> 'PATHWAY'
            AND dsc.school_dw_id = 132766
            AND fle.fle_is_additional_resource <> TRUE
    ) completed_lessons
    WHERE rnk = 1
),

LESSON_PROGRESS AS (
    SELECT DISTINCT 
        local_date,
        fle_ls_id,
        fle_dw_id,
        fle_lo_dw_id,
        fle_student_dw_id,
        fle_attempt,
        0 AS fle_score,
        'In-Progress' AS lo_status
    FROM (
        SELECT 
            CAST(FROM_UTC_TIMESTAMP(fle.fle_created_time, dsc.tenant_timezone) AS DATE) AS local_date,
            fle.fle_ls_id,
            fle.fle_lo_dw_id,
            fle.fle_student_dw_id,
            fle.fle_attempt,
            MAX(fle.fle_dw_id) AS fle_dw_id
        FROM {{rs_coredw}}.fact_learning_experience fle
        JOIN {{rs_bi_coredw}}.bi_active_schools_dim dsc
            ON fle.fle_school_dw_id = dsc.school_dw_id
            AND CAST(fle.fle_created_time AS DATE) >= dsc.academic_year_start_date
            AND CAST(fle.fle_created_time AS DATE) <= dsc.academic_year_end_date
        WHERE fle.fle_ls_id NOT IN (SELECT fle_ls_id FROM COMPLETED_LESSONS)
            AND fle.fle_attempt = 1
            AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
            AND fle.fle_material_type <> 'PATHWAY'
            AND fle.fle_is_additional_resource <> TRUE
            AND fle.fle_abbreviation <> 'NA'
            AND dsc.school_dw_id = 132766
        GROUP BY 
            CAST(FROM_UTC_TIMESTAMP(fle.fle_created_time, dsc.tenant_timezone) AS DATE),
            fle.fle_ls_id,
            fle.fle_lo_dw_id,
            fle.fle_student_dw_id,
            fle.fle_attempt
    ) in_progress

    UNION ALL

    SELECT DISTINCT 
        local_date, 
        fle_ls_id, 
        fle_dw_id, 
        fle_lo_dw_id, 
        fle_student_dw_id, 
        fle_attempt, 
        fle_score, 
        'Completed' AS lo_status
    FROM COMPLETED_LESSONS
),

STUDENT_LESSON_PROGRESS AS (
    SELECT 
        fle.fle_student_dw_id,
        fle.fle_class_dw_id,
        fle.fle_lo_dw_id,
        fle.fle_lesson_category,
        lp.fle_score,
        lp.local_date,
        COALESCE(lp.lo_status, 'Not Started') AS lo_status,
        lp.fle_dw_id,
        lp.fle_ls_id,
        fle.fle_academic_year_dw_id,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date,
        dsc.school_name,
        dsc.school_dw_id,
        SUM(
            CASE
                WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                WHEN fle.fle_total_time > 900 THEN 900
                ELSE 0
            END
        ) OVER (
            PARTITION BY fle.fle_academic_year_dw_id, fle.fle_student_dw_id, fle.fle_lo_dw_id
        ) AS session_time
    FROM {{rs_coredw}}.fact_learning_experience fle
    JOIN LESSON_PROGRESS lp
        ON lp.fle_ls_id = fle.fle_ls_id
        AND lp.fle_lo_dw_id = fle.fle_lo_dw_id
        AND fle.fle_attempt = 1
    JOIN {{rs_bi_coredw}}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = fle.fle_school_dw_id
        AND CAST(fle.fle_created_time AS DATE) <= dsc.academic_year_end_date
        AND dsc.school_dw_id = 132766
    WHERE COALESCE(fle.fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON'
        AND fle.fle_abbreviation <> 'NA'
        AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
        AND fle.fle_material_type <> 'PATHWAY'
        AND fle.fle_is_additional_resource <> TRUE
        AND fle.fle_ls_id NOT IN (
            SELECT DISTINCT fle_ls_id
            FROM {{rs_coredw}}.fact_learning_experience
            WHERE fle_state = 4
        )
)

SELECT DISTINCT
    sla.class_user_user_dw_id,
    sla.class_user_class_dw_id,
    sla.lo_to_finish,
    sla.lo_title,
    sla.lo_id,
    sla.course_id,
    sla.course_name,
    sla.class_dw_id,
    sla.class_title,
    sla.class_gen_subject,
    sla.tenant_name,
    sla.school_dw_id,
    sla.school_id,
    sla.school_name,
    sla.school_adek_id,
    sla.school_country_name,
    sla.school_city_name,
    sla.school_label,
    sla.organisation_name,
    sla.school_cx_cluster,
    sla.academic_year_start_date,
    sla.academic_year_end_date,
    sla.week_number,
    sla.week_start_date,
    sla.week_end_date,
    sla.term_academic_period_order,
    sla.activity_item_order,
    sla.term_start_date,
    sla.term_end_date,
    sla.pacing,

    dst.student_tags,
    dst.student_special_needs,
    dst.student_id,
    dst.student_dw_id,
    dg.grade_k12grade,
    lps.fle_lo_dw_id AS lo_attempted,
    lps.session_time,
    lps.fle_academic_year_dw_id,
    lps.fle_student_dw_id,
    COALESCE(lps.lo_status, 'Not Started') AS lo_status,
    lps.fle_score,
    lps.local_date
FROM TOTAL_LESSONS_ASSIGNED sla
JOIN {{rs_bi_coredw}}.bi_student_dim dst 
    ON dst.student_dw_id = sla.class_user_user_dw_id
JOIN {{rs_coredw}}.dim_grade dg 
    ON dg.grade_dw_id = dst.student_grade_dw_id
LEFT JOIN STUDENT_LESSON_PROGRESS lps 
    ON sla.lo_to_finish = lps.fle_lo_dw_id
    AND sla.class_user_user_dw_id = lps.fle_student_dw_id;