CREATE OR ALTER VIEW ${os_bi_coredw}.assignment_dm_view AS
WITH _teachers AS (
    SELECT DISTINCT teacher_dw_id, teacher_id
    FROM ${rs_coredw}.dim_teacher
    WHERE teacher_status = 1
      AND teacher_active_until IS NULL
),

fact_assignment_submission AS ( -- getting student's latest assignment submission per student+assignment
    SELECT
        assignment_submission_id,
        assignment_submission_assignment_id,
        assignment_submission_assignment_instance_id,
        assignment_submission_student_dw_id,
        assignment_submission_type,
        assignment_submission_submitted_on,
        assignment_submission_status,
        assignment_submission_teacher_score,
        assignment_submission_resubmission_count
    FROM (
        SELECT
            assignment_submission_id,
            assignment_submission_assignment_id,
            assignment_submission_assignment_instance_id,
            assignment_submission_student_dw_id,
            assignment_submission_type,
            assignment_submission_submitted_on,
            assignment_submission_status,
            assignment_submission_teacher_score,
            assignment_submission_resubmission_count,
            assignment_submission_created_time,
               ROW_NUMBER() OVER (
                   PARTITION BY assignment_submission_assignment_id, assignment_submission_student_dw_id
                   ORDER BY assignment_submission_created_time DESC , assignment_submission_submitted_on DESC , 
                   assignment_submission_dw_id desc
               ) AS rank
        FROM ${rs_coredw}.fact_assignment_submission
    ) sub
    WHERE sub.rank = 1
)

SELECT DISTINCT
    da.assignment_id,           -- total assignments
    da.assignment_created_time,
    da.assignment_title,
    da.assignment_language,
    da.assignment_type,         -- assignment type: teacher assignment only
    da.assignment_assignment_status,
    da.assignment_status,
    da.assignment_max_score,
    da.assignment_is_gradeable,
    da.assignment_attachment_required,
    da.assignment_comment_required,
    dai.assignment_instance_id, -- total assignments assigned
    dai.assignment_instance_lo_dw_id,
    lo.lo_title,
    fas.assignment_submission_id,
    fas.assignment_submission_assignment_id,
    fas.assignment_submission_type,
    fas.assignment_submission_submitted_on,
    fas.assignment_submission_status,
    fas.assignment_submission_teacher_score,
    fas.assignment_submission_resubmission_count,
    da.assignment_school_dw_id,
    da.assignment_tenant_dw_id,
    dsc.tenant_name,
    dsc.school_organisation,
    dsc.school_city_name,
    dsc.school_country_name,
    dsc.school_name,
    dc.class_school_id,
    dc.class_grade_id,
    dg.grade_name,
    dc.class_id,
    dc.class_title,
    dc.class_dw_id,
    dcsa.cs_subject_id              AS curr_subject_id,
    dc.class_gen_subject            AS curr_subject_name,
    dt.teacher_id,
    ds.student_dw_id,
    ds.student_id,
    ISNULL(dtrm.actp_teaching_period_order, 1) AS term_academic_period_order,
    ISNULL(dtrm.actp_teaching_period_start_date, dsc.academic_year_start_date) AS term_start_date,
    ISNULL(dtrm.actp_teaching_period_end_date, dsc.academic_year_end_date)   AS term_end_date
FROM ${rs_coredw}.dim_assignment da
LEFT JOIN ${rs_coredw}.dim_assignment_instance dai
    ON dai.assignment_instance_assignment_dw_id = da.assignment_dw_id
LEFT JOIN ${rs_coredw}.dim_assignment_instance_student dais
    ON dais.ais_instance_dw_id = dai.assignment_instance_dw_id
LEFT JOIN fact_assignment_submission fas
    ON fas.assignment_submission_assignment_instance_id = dai.assignment_instance_id
   AND fas.assignment_submission_student_dw_id = dais.ais_student_dw_id
   AND da.assignment_id = fas.assignment_submission_assignment_id
INNER JOIN ${rs_coredw}.dim_learning_objective lo
    ON lo.lo_dw_id = dai.assignment_instance_lo_dw_id
INNER JOIN ${rs_coredw}.dim_class dc
    ON dc.class_dw_id = dai.assignment_instance_class_dw_id
   AND dc.class_status = 1
INNER JOIN ${rs_coredw}.dim_course dcr
    ON dcr.course_id = dc.class_material_id
   AND dcr.course_status = 1
INNER JOIN ${rs_coredw}.dim_course_subject_association dcsa
    ON dcsa.cs_course_id = dcr.course_id
INNER JOIN ${rs_bi_coredw}.bi_student_dim AS ds
    ON dais.ais_student_dw_id = ds.student_dw_id
   AND ds.student_status = 1
   AND ds.student_active_until IS NULL
INNER JOIN _teachers AS dt
    ON dt.teacher_dw_id = dai.assignment_instance_teacher_dw_id
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
    ON dsc.school_dw_id = da.assignment_school_dw_id
   AND da.assignment_created_time >= CONVERT(DATETIME2, dsc.academic_year_start_date)  -- OPT-15: SARGable rewrite
        AND da.assignment_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, dsc.academic_year_end_date))  -- OPT-15: SARGable rewrite
INNER JOIN ${rs_coredw}.dim_grade AS dg
    ON dg.grade_dw_id = dai.assignment_instance_grade_dw_id
   AND dsc.academic_year_id = dg.academic_year_id
LEFT JOIN ${rs_coredw}.dim_academic_calendar_teaching_period dtrm
    ON dtrm.actp_teaching_period_id = dai.assignment_instance_trimester_id;
