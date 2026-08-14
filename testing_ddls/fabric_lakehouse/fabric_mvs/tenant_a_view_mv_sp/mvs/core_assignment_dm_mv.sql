CREATE OR REPLACE MATERIALIZED LAKE VIEW {{os_bi_coredw}}.core_assignment_dm_mv
AS
WITH core_assignment AS ( -- published distinct core assignments
    SELECT *
    FROM (
        SELECT assignment_dw_id,
               assignment_id,
               md5(assignment_id)                               AS assignment_id_hash,
               assignment_title,
               assignment_max_score,
               assignment_language,
               assignment_is_gradeable,
               assignment_attachment_required,
               assignment_comment_required,
               assignment_metadata_difficulty_level,
               assignment_metadata_resource_type,
               assignment_metadata_knowledge_dimensions,
               ROW_NUMBER() OVER (
                   PARTITION BY assignment_id ORDER BY assignment_created_time
               )                                                AS rank
        FROM {{rs_coredw}}.dim_assignment
        WHERE assignment_type = 'CORE_ASSIGNMENT'
          AND assignment_assignment_status = 'PUBLISHED'
          AND assignment_status = 1
    ) t
    WHERE rank = 1
),

step_instance AS ( -- reflects assignments attribution to lessons
    SELECT DISTINCT
        step_instance_id,
        md5(step_instance_id)        AS step_instance_id_hash,
        step_instance_lo_id,
        md5(step_instance_lo_id)     AS step_instance_lo_id_hash,
        step_instance_step_uuid,
        md5(step_instance_step_uuid) AS step_instance_step_uuid_hash
    FROM {{rs_coredw}}.dim_step_instance
    WHERE step_instance_type = 4
      AND step_instance_status = 1
      AND step_instance_attach_status = 1
),

active_student_in_class AS (
    SELECT DISTINCT
        d_cu.class_user_user_dw_id,
        d_cu.class_user_class_dw_id,
        dc.class_id,
        md5(dc.class_id)    AS class_id_hash,
        d_s.student_id,
        md5(d_s.student_id) AS student_id_hash,
        d_s.student_dw_id
    FROM (
        SELECT class_user_user_dw_id,
               class_user_class_dw_id,
               class_user_attach_status,
               class_user_status,
               class_user_role_dw_id
        FROM {{rs_coredw}}.dim_class_user
        WHERE class_user_attach_status = 1
          AND class_user_status = 1
          AND class_user_role_dw_id = 2
    ) AS d_cu
    INNER JOIN (
        SELECT class_dw_id,
               class_id,
               class_course_status,
               class_status
        FROM {{rs_coredw}}.dim_class
        WHERE class_course_status = 'ACTIVE'
          AND class_status = 1
    ) AS dc
        ON dc.class_dw_id = d_cu.class_user_class_dw_id
    INNER JOIN (
        SELECT student_id,
               student_dw_id,
               student_status
        FROM {{rs_bi_coredw}}.bi_student_dim
        WHERE student_status = 1
    ) AS d_s
        ON d_s.student_dw_id = d_cu.class_user_user_dw_id
),

activities_by_class AS ( -- activities_by_class_current_academic_year
    SELECT DISTINCT
        dcr.course_id,
        dcr.course_dw_id,
        dcr.course_name,
        dcaa.caa_activity_is_optional,
        dcaa.caa_activity_dw_id,
        lo.lo_id,
        md5(lo.lo_id)         AS lo_id_hash,
        lo.lo_title,
        d_sch.school_organisation  AS organisation_name,
        d_class.class_gen_subject  AS curr_subject_name,
        dg.grade_name              AS curr_grade_name,
        d_sch.academic_year_start_date,
        d_sch.academic_year_end_date,
        d_sch.academic_year_id,
        d_sch.school_id,
        d_sch.school_name,
        d_sch.tenant_id,
        d_sch.organisation_dw_id,
        d_sch.tenant_name,
        d_class.class_id,
        md5(d_class.class_id) AS class_id_hash,
        d_class.class_dw_id,
        d_class.class_section_id,
        d_class.class_course_status
    FROM (
        SELECT class_id,
               class_dw_id,
               class_section_id,
               class_course_status,
               class_school_id,
               class_material_id,
               class_grade_id,
               class_gen_subject
        FROM {{rs_coredw}}.dim_class
        WHERE class_course_status = 'ACTIVE'
          AND class_status = 1
    ) AS d_class
    INNER JOIN {{rs_bi_coredw}}.bi_active_schools_dim d_sch
        ON d_sch.school_id = d_class.class_school_id
    INNER JOIN {{rs_coredw}}.dim_grade dg
        ON dg.grade_id = d_class.class_grade_id
    INNER JOIN (
        SELECT course_id,
               course_dw_id,
               course_name
        FROM {{rs_coredw}}.dim_course
        WHERE course_status = 1
          AND course_type = 'CORE'
    ) AS dcr
        ON d_class.class_material_id = dcr.course_id
    INNER JOIN (
        SELECT caa_course_dw_id,
               caa_activity_is_optional,
               caa_activity_dw_id
        FROM {{rs_coredw}}.dim_course_activity_association
        WHERE caa_activity_type = 1
          AND caa_status = 1
          AND caa_attach_status = 1
          AND caa_activity_dw_id IS NOT NULL
    ) AS dcaa
        ON dcaa.caa_course_dw_id = dcr.course_dw_id
    INNER JOIN (
        SELECT lo_id,
               lo_dw_id,
               lo_title
        FROM {{rs_coredw}}.dim_learning_objective
        WHERE lo_status = 1
    ) AS lo
        ON lo.lo_dw_id = dcaa.caa_activity_dw_id
),

fact_assignment_submission AS ( -- getting student's same assignment submission last status
    SELECT *
    FROM (
        SELECT assignment_submission_id,
               assignment_submission_assignment_id,
               md5(assignment_submission_assignment_id)       AS assignment_submission_assignment_id_hash,
               assignment_submission_type,
               assignment_submission_submitted_on,
               assignment_submission_status,
               assignment_submission_teacher_score,
               assignment_submission_referrer_id,
               md5(assignment_submission_referrer_id)         AS assignment_submission_referrer_id_hash,
               cast(assignment_submission_student_dw_id AS bigint) AS assignment_submission_student_dw_id,
               assignment_submission_resubmission_count,
               ROW_NUMBER() OVER (
                   PARTITION BY assignment_submission_assignment_id, assignment_submission_student_dw_id
                   ORDER BY assignment_submission_created_time DESC , assignment_submission_submitted_on DESC , assignment_submission_dw_id
               ) AS rn
        FROM {{rs_coredw}}.fact_assignment_submission
    ) t
    WHERE rn = 1
),

content_student_association AS (
    SELECT
        md5(content_student_association_step_id)    AS content_student_association_step_id_hash,
        md5(content_student_association_class_id)   AS content_student_association_class_id_hash,
        md5(content_student_association_lo_id)      AS content_student_association_lo_id_hash,
        md5(content_student_association_student_id) AS content_student_association_student_id_hash,
        CASE
            WHEN content_student_association_assign_status = 0 THEN true
            ELSE false
        END                                              AS is_locked
    FROM {{rs_coredw}}.dim_content_student_association
    WHERE content_student_association_status = 1
      AND year(cast(content_student_association_created_time AS date)) >= 2024
)

SELECT DISTINCT
    d_a.assignment_dw_id,
    d_a.assignment_title,
    d_a.assignment_max_score,
    d_a.assignment_language,
    d_a.assignment_is_gradeable,
    d_a.assignment_attachment_required,
    d_a.assignment_comment_required,
    d_a.assignment_metadata_difficulty_level                             AS difficulty_level,
    d_a.assignment_metadata_resource_type                                AS resource_type,
    d_a.assignment_metadata_knowledge_dimensions                         AS knowledge_dimensions,
    student_in_class.student_dw_id,
    activities_by_class.course_dw_id                                     AS instructional_plan_dw_id,
    activities_by_class.course_name                                      AS instructional_plan_name,
    activities_by_class.academic_year_id,
    coalesce(dpg.pacing_dw_id, 100001)                                   AS week_dw_id,
    CASE dpg.pacing_interval_type
        WHEN 'MONTH' THEN coalesce(month(dpg.pacing_interval_start_date), 1)
        ELSE coalesce(weekofyear(dpg.pacing_interval_start_date), 1)
    END                                                                  AS week_number,
    coalesce(dpg.pacing_interval_start_date,
             dtrm.actp_teaching_period_start_date,
             activities_by_class.academic_year_start_date)               AS week_start_date,
    coalesce(dpg.pacing_interval_end_date,
             dtrm.actp_teaching_period_end_date,
             activities_by_class.academic_year_end_date)                 AS week_end_date,
    coalesce(dtrm.actp_teaching_period_order, 1)                         AS term_academic_period_order,
    coalesce(dtrm.actp_teaching_period_start_date,
             activities_by_class.academic_year_start_date)               AS term_start_date,
    coalesce(dtrm.actp_teaching_period_end_date,
             activities_by_class.academic_year_end_date)                 AS term_end_date,
    activities_by_class.caa_activity_dw_id                               AS lo_to_finish,
    activities_by_class.lo_title,
    activities_by_class.caa_activity_is_optional                         AS instructional_plan_item_optional,
    activities_by_class.organisation_dw_id,
    activities_by_class.organisation_name,
    activities_by_class.curr_subject_name,
    activities_by_class.curr_grade_name,
    activities_by_class.academic_year_start_date,
    activities_by_class.academic_year_end_date,
    activities_by_class.school_id,
    activities_by_class.school_name,
    activities_by_class.tenant_name,
    activities_by_class.class_id,
    d_csa.is_locked,
    fas.assignment_submission_id,
    fas.assignment_submission_assignment_id,
    fas.assignment_submission_type,
    fas.assignment_submission_submitted_on,
    fas.assignment_submission_status,
    fas.assignment_submission_teacher_score,
    fas.assignment_submission_resubmission_count
FROM core_assignment d_a
INNER JOIN step_instance d_si
    ON d_si.step_instance_id_hash = d_a.assignment_id_hash
INNER JOIN activities_by_class
    ON activities_by_class.lo_id_hash = d_si.step_instance_lo_id_hash
INNER JOIN active_student_in_class student_in_class
    ON activities_by_class.class_id_hash = student_in_class.class_id_hash
LEFT JOIN {{rs_coredw}}.dim_pacing_guide dpg
    ON dpg.pacing_class_dw_id = activities_by_class.class_dw_id
    AND dpg.pacing_activity_dw_id = activities_by_class.caa_activity_dw_id
LEFT JOIN {{rs_coredw}}.dim_academic_calendar_teaching_period dtrm
    ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
LEFT JOIN content_student_association d_csa
    ON d_csa.content_student_association_step_id_hash = d_si.step_instance_step_uuid_hash   
    AND d_csa.content_student_association_class_id_hash = student_in_class.class_id_hash
    AND d_csa.content_student_association_lo_id_hash = d_si.step_instance_lo_id_hash
    AND d_csa.content_student_association_student_id_hash = student_in_class.student_id_hash
LEFT JOIN fact_assignment_submission fas
    ON fas.assignment_submission_assignment_id_hash = d_a.assignment_id_hash
    AND fas.assignment_submission_student_dw_id = student_in_class.student_dw_id
    AND fas.assignment_submission_referrer_id_hash = activities_by_class.lo_id_hash; 