CREATE OR ALTER VIEW ${os_bi_coredw}.pathway_skill_learning_dm_view
AS
SELECT DISTINCT
    fslp.created_time AS skill_learning_date_time,
    fslp.skill_session_id,

    FIRST_VALUE(fslp.time_spent_on_activity) OVER (
        PARTITION BY fslp.student_dw_id, fslp.skill_dw_id
        ORDER BY fslp.created_time DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS time_spent_on_skill,

    FIRST_VALUE(fslp.time_spent_this_time_on_activity) OVER (
        PARTITION BY fslp.student_dw_id, fslp.skill_dw_id, fslp.component_id
        ORDER BY fslp.created_time DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS time_spent_on_component,

    fslp.component_id                    AS skill_component_id,
    fslp.class_id,
    fslp.class_dw_id                     AS skill_learning_class_dw_id,
    fslp.student_dw_id                   AS skill_learning_student_dw_id,
    fslp.skill_dw_id                     AS skill_learning_dw_id,
    fslp.material_dw_id,
    fslp.material_id,
    fslp.academic_year,
    fslp.skill_completion_percentage,

    CASE
        WHEN fslp.event_type = 'SkillExperienceFinished'
            THEN fslp.is_activity_completed
    END AS is_component_completed,

    CASE
        WHEN submitted.student_dw_id IS NULL
            THEN CONVERT(bit, 0)
        ELSE CONVERT(bit, 1)
    END AS is_skill_learning_completed

FROM ${rs_coredw}.fact_pathway_skill_learning_progress fslp

LEFT JOIN (
    SELECT DISTINCT
        created_time,
        student_dw_id,
        skill_dw_id
    FROM ${rs_coredw}.fact_pathway_skill_learning_progress
    WHERE event_type = 'SkillLearningSessionFinished'
) submitted
    ON fslp.student_dw_id = submitted.student_dw_id
   AND fslp.skill_dw_id   = submitted.skill_dw_id
   AND fslp.created_time  = submitted.created_time

INNER JOIN ${rs_coredw}.dim_course dcr
    ON fslp.material_dw_id = dcr.course_dw_id
   AND dcr.course_status = 1
   AND dcr.course_type = 'PATHWAY'

INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
    ON fslp.school_dw_id = dsc.school_dw_id
   AND fslp.academic_year =
       CONVERT(varchar(4), YEAR(dsc.academic_year_start_date)) + '-' +
       CONVERT(varchar(4), YEAR(dsc.academic_year_end_date))

INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
    ON fslp.student_dw_id = ds.student_dw_id
   AND dsc.school_dw_id   = ds.student_school_dw_id
   AND ds.student_status = 1;
