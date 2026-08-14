CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.interim_checkpoint_student_dm_view AS
SELECT  local_date,
        dip.course_id  AS instructional_plan_id,
        dip.school_id,
        dip.school_dw_id,
        dip.school_name,
        dip.tenant_name,
        dip.school_organisation,
        dip.class_gen_subject,
        ctsm.grade_name  AS grade_k12grade,
        ctsm.class_dw_id,
        ctsm.class_title,
        ctsm.section_dw_id,
        ctsm.section_name,
        dip.term_academic_period_order,
        dip.activity_dw_id     AS icp_dw_id,
        dip.ic_title,
        dip.instructional_plan_item_order AS pacing_activity_order,
        dip.ic_order,
        ctsm.class_total_students,
        fle.fle_total_score    AS total_score,
        fle.student_dw_id AS fle_student_dw_id,
        fle.fle_lo_dw_id AS completed_lo_dw_id,
        dip.week_start_date,
        dip.week_end_date
FROM ${RS_BI_COREDW}.core_class_ic_content AS dip
         INNER JOIN ${RS_BI_COREDW}.class_total_students AS ctsm
                        ON dip.class_dw_id = ctsm.class_dw_id
         LEFT JOIN ${RS_BI_COREDW}.students_ic_progress fle
                     ON fle.fle_class_dw_id = dip.class_dw_id
                       AND fle.fle_lo_dw_id = dip.activity_dw_id
                       AND fle.student_section_dw_id = ctsm.section_dw_id;
