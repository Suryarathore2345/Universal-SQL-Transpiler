CREATE OR REPLACE VIEW eagles_alefdw_dev.interim_checkpoint_student_dm_view AS
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
FROM bi_alefdw.core_class_ic_content_mv AS dip
         INNER JOIN bi_alefdw.class_total_students_mv AS ctsm
                        ON dip.class_dw_id = ctsm.class_dw_id
         LEFT JOIN bi_alefdw.students_ic_progress_mv fle
                     ON fle.fle_class_dw_id = dip.class_dw_id
                       AND fle.fle_lo_dw_id = dip.activity_dw_id
                       AND fle.student_section_dw_id = ctsm.section_dw_id
WITH NO SCHEMA BINDING;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.interim_checkpoint_student_dm_view to group business_intelligence;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.interim_checkpoint_student_dm_view to group datascience;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.interim_checkpoint_student_dm_view to group tdc;

grant select on eagles_alefdw_dev.interim_checkpoint_student_dm_view to group ro_users;