CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.students_lesson_progress_mv AS
WITH COMPLETED_LESSONS AS (
    SELECT fle_ls_id, fle_dw_id, fle_score
    FROM (
        SELECT 
            fle_ls_id,
            fle_dw_id,
            CASE WHEN lo.lo_max_stars > 0 THEN fle_total_score END as fle_score,
            ROW_NUMBER() OVER (PARTITION BY fle_ls_id ORDER BY fle_created_time DESC) AS rnk
        FROM {{rs_coredw}}.fact_learning_experience
        JOIN {{rs_coredw}}.dim_learning_objective lo
            ON lo.lo_dw_id = fle_lo_dw_id
            AND lo.lo_status = 1
        JOIN {{rs_bi_coredw}}.bi_active_schools_dim dsc
            ON fle_school_dw_id = dsc.school_dw_id
            AND TO_DATE(fle_created_time) >= dsc.academic_year_start_date
            AND TO_DATE(fle_created_time) <= dsc.academic_year_end_date
        WHERE fle_completion_node = true
          AND fact_learning_experience.fle_activity_type <> 'INTERIM_CHECKPOINT'
          AND fle_material_type <> 'PATHWAY'
          AND fle_is_additional_resource <> TRUE
    ) subq -- get latest completed record for a student lesson
    WHERE rnk = 1
),

LESSON_PROGRESS AS (
    SELECT fle_dw_id, 0 as fle_score, 'In-Progress' AS lo_status
    FROM (
        SELECT 
            fle_ls_id,
            MAX(fle_dw_id) AS fle_dw_id
        FROM {{rs_coredw}}.fact_learning_experience
        JOIN {{rs_bi_coredw}}.bi_active_schools_dim dsc
            ON fle_school_dw_id = dsc.school_dw_id
            AND TO_DATE(fle_created_time) >= dsc.academic_year_start_date
            AND TO_DATE(fle_created_time) <= dsc.academic_year_end_date
        WHERE fle_ls_id NOT IN (SELECT fle_ls_id FROM COMPLETED_LESSONS)
          AND fle_attempt = 1
          AND fact_learning_experience.fle_activity_type <> 'INTERIM_CHECKPOINT'
          AND fle_material_type <> 'PATHWAY'
          AND fle_is_additional_resource <> TRUE
          AND fle_abbreviation <> 'NA'
        GROUP BY fle_ls_id
    ) subq -- get any in-progress record for the student lesson

    UNION ALL

    SELECT fle_dw_id, fle_score, 'Completed' AS lo_status
    FROM COMPLETED_LESSONS
),

student_lessons_assigned AS (
    -- lesson level learning plan for each student
    SELECT DISTINCT 
        d_cu.class_user_user_dw_id,
        d_cu.class_user_class_dw_id,
        dcaa.caa_activity_dw_id AS lo_dw_id
    FROM {{rs_coredw}}.dim_class_user d_cu
    INNER JOIN {{rs_coredw}}.dim_class dc
        ON dc.class_dw_id = d_cu.class_user_class_dw_id
    INNER JOIN {{rs_coredw}}.dim_course dcr
        ON dcr.course_id = dc.class_material_id
    INNER JOIN {{rs_coredw}}.dim_course_activity_association dcaa
        ON dcaa.caa_course_id = dcr.course_id
    WHERE d_cu.class_user_attach_status = 1
      AND d_cu.class_user_status = 1
      AND d_cu.class_user_role_dw_id = 2
      AND dc.class_course_status = 'ACTIVE'
      AND dcr.course_status = 1
      AND dcr.course_type = 'CORE'
      AND dcaa.caa_status = 1
      AND dcaa.caa_attach_status = 1
      AND dc.class_status = 1
)

SELECT 
    fl.local_date,
    fl.fle_class_dw_id,
    fl.lo_attempted,
    fl.fle_lesson_category,
    fl.fle_dw_id,
    fl.fle_source,
    fl.student_dw_id,
    fl.student_section_dw_id,
    fl.fle_academic_year_dw_id,
    fl.student_tags,
    fl.student_special_needs,
    fl.grade_k12grade,
    fl.session_time,
    fl.fle_session_time,
    fl.academic_year_start_date,
    fl.academic_year_end_date,
    lps.fle_score,
    lps.lo_status
FROM (
    SELECT DISTINCT 
        TO_DATE(FROM_UTC_TIMESTAMP(fle.fle_created_time, dsc.tenant_timezone)) AS local_date,
        dcu.class_user_class_dw_id AS fle_class_dw_id,
        fle_lo_dw_id AS lo_attempted,
        fle_lesson_category,
        fle_dw_id,
        fle_source,
        dst.student_dw_id,
        dst.student_section_dw_id,
        fle_academic_year_dw_id,
        dst.student_tags,
        dst.student_special_needs,
        dg.grade_k12grade,
        SUM(
            CASE
                WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                WHEN fle.fle_total_time > 900 THEN 900
                ELSE 0
            END
        ) OVER (
            PARTITION BY 
                TO_DATE(FROM_UTC_TIMESTAMP(fle.fle_created_time, dsc.tenant_timezone)),
                dst.student_dw_id,
                fle_lo_dw_id
        ) AS session_time,
        SUM(
            CASE
                WHEN fle.fle_total_time <= 900 THEN fle.fle_total_time
                WHEN fle.fle_total_time > 900 THEN 900
                ELSE 0
            END
        ) OVER (
            PARTITION BY 
                TO_DATE(FROM_UTC_TIMESTAMP(fle.fle_created_time, dsc.tenant_timezone)),
                dst.student_dw_id,
                fle_lo_dw_id
        ) AS fle_session_time,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date
    FROM {{rs_coredw}}.fact_learning_experience fle
    JOIN {{rs_bi_coredw}}.bi_student_dim dst
        ON fle.fle_student_dw_id = dst.student_dw_id 
        AND student_status = 1
    JOIN {{rs_coredw}}.dim_grade dg 
        ON dg.grade_dw_id = fle.fle_grade_dw_id
    JOIN student_lessons_assigned dcu
        ON fle_student_dw_id = dcu.class_user_user_dw_id
        AND fle_lo_dw_id = dcu.lo_dw_id
    JOIN {{rs_bi_coredw}}.bi_active_schools_dim dsc
        ON fle.fle_school_dw_id = dsc.school_dw_id
        AND TO_DATE(fle_created_time) >= dsc.academic_year_start_date
        AND TO_DATE(fle_created_time) <= dsc.academic_year_end_date
    WHERE fle_abbreviation <> 'NA'
      AND fle.fle_activity_type <> 'INTERIM_CHECKPOINT'
      AND fle_material_type <> 'PATHWAY'
      AND fle_is_additional_resource <> TRUE
      AND fle.fle_ls_id NOT IN (
          SELECT DISTINCT fle_ls_id 
          FROM {{rs_coredw}}.fact_learning_experience 
          WHERE fle_state = 4
      )
) fl
JOIN LESSON_PROGRESS lps 
    ON fl.fle_dw_id = lps.fle_dw_id
WHERE COALESCE(fle_lesson_category, 'NA') <> 'EXPERIENTIAL_LESSON';
