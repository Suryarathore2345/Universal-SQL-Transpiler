CREATE OR ALTER VIEW ${os_bi_coredw}.pathway_level_completion_dm_view_py
AS
WITH school_previousay AS (
    SELECT
        school_id,
        academic_year_id,
        academic_year_start_date AS previous_academic_year_start_date,
        academic_year_end_date   AS previous_academic_year_end_date
    FROM (
        SELECT
            ay.*,
            ROW_NUMBER() OVER (
                PARTITION BY school_id
                ORDER BY
                    academic_year_end_date DESC
            ) AS rn
        FROM ${rs_bi_coredw}.bi_all_schools_dim ay
        WHERE academic_year_is_roll_over_completed = 1
    ) x
    WHERE rn = 1
),

fact_levels_recommended_last AS (
    SELECT
        flr_pathway_dw_id,
        flr_student_dw_id,
        flr_course_dw_id,
        flr_course_activity_container_dw_id AS flr_level_dw_id,
        flr_created_time,
        grade_name,
        grade_dw_id,
        class_school_id
    FROM (
        SELECT
            flc.flr_pathway_dw_id,
            flc.flr_student_dw_id,
            flc.flr_course_dw_id,
            flc.flr_course_activity_container_dw_id,
            flc.flr_created_time,
            flc.flr_class_dw_id,
            g.grade_name,
            g.grade_dw_id,
            dc.class_school_id,
            ROW_NUMBER() OVER (
                PARTITION BY flr_student_dw_id, dplaa.caa_activity_dw_id
                ORDER BY
                    flr_created_time DESC
            ) AS rn
        FROM ${rs_coredw}.fact_levels_recommended flc
        INNER JOIN ${rs_coredw}.dim_course_activity_association dplaa
            ON flc.flr_course_activity_container_dw_id = dplaa.caa_container_dw_id
           AND dplaa.caa_status = 1
           AND flc.flr_status = 1
        INNER JOIN ${rs_coredw}.dim_class dc
            ON dc.class_dw_id = flc.flr_class_dw_id
        INNER JOIN ${rs_coredw}.dim_grade g
            ON g.grade_id = dc.class_grade_id
        INNER JOIN school_previousay ay
            ON ay.academic_year_id = g.academic_year_id
    ) y
    WHERE rn = 1
)

SELECT DISTINCT
    sch.school_dw_id,
    flr.grade_name,
    flr.flr_student_dw_id,
    flr.flr_level_dw_id,
    flr.flr_created_time,
    flc.flc_course_activity_container_dw_id AS level_dw_id_completed,
    flc.flc_created_time                    AS level_completed_time
FROM fact_levels_recommended_last flr
INNER JOIN ${rs_coredw}.dim_school sch
    ON flr.class_school_id = sch.school_id
LEFT JOIN ${rs_coredw}.dim_course dcr
    ON flr.flr_course_dw_id = dcr.course_dw_id
   AND dcr.course_status = 1
LEFT JOIN ${rs_coredw}.dim_course_activity_container dcac
    ON dcac.course_activity_container_course_id = dcr.course_id
   AND dcac.course_activity_container_dw_id = flr.flr_level_dw_id
   AND dcac.course_activity_container_status = 1
LEFT JOIN ${rs_coredw}.fact_level_completed flc
    ON flc.flc_course_activity_container_dw_id = flr.flr_level_dw_id
   AND flc.flc_student_dw_id = flr.flr_student_dw_id
WHERE dcr.course_type = 'PATHWAY';
