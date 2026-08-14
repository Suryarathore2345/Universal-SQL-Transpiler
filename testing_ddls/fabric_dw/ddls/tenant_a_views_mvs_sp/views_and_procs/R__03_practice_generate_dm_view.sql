CREATE OR ALTER VIEW ${os_bi_coredw}.practice_generate_dm_view AS
WITH lesson_wth_practice1 AS (  -- lessons with practice prerequisite
    SELECT DISTINCT 
        lo.lo_dw_id,
        lo.lo_id,
        lo.lo_title,
        lo.lo_curriculum_subject_id
    FROM ${rs_coredw}.dim_learning_objective lo
    INNER JOIN ${rs_coredw}.dim_step_instance dsi
        ON lo.lo_id = dsi.step_instance_lo_id
    INNER JOIN ${rs_coredw}.dim_content_association c
        ON dsi.step_instance_id = convert(varchar,c.content_association_content_id)
    INNER JOIN ${rs_coredw}.dim_ccl_skill sk
        ON c.content_association_id = sk.ccl_skill_id
    INNER JOIN ${rs_coredw}.dim_skill_association ska
        ON sk.ccl_skill_id = ska.skill_association_skill_id
    WHERE lo.lo_status = 1
      AND c.content_association_type = 3
      AND c.content_association_status = 1
      AND dsi.step_instance_status = 1
      AND dsi.step_instance_attach_status = 1
      AND sk.ccl_skill_status = 1
      AND ska.skill_association_type = 1
      AND ska.skill_association_attach_status = 1
),
lesson_wth_practice2 AS ( -- lessons with practice prerequisite missing in lesson_wth_practice1
    SELECT DISTINCT 
        lo.lo_dw_id,
        lo.lo_id,
        lo.lo_title,
        lo.lo_curriculum_subject_id
    FROM ${rs_coredw}.dim_learning_objective lo
    INNER JOIN ${rs_coredw}.fact_practice p
        ON lo.lo_dw_id = p.practice_lo_dw_id
),
lesson_wth_practice AS ( -- combined unique lessons with practice prerequisite
    SELECT 
        lo_dw_id,
        lo_id,
        lo_title,
        lo_curriculum_subject_id
    FROM lesson_wth_practice1
    UNION
    SELECT 
        lo_dw_id,
        lo_id,
        lo_title,
        lo_curriculum_subject_id
    FROM lesson_wth_practice2
),
students_failed_et AS ( -- students didn't pass 70 in lesson exit ticket
    SELECT
        fle_lo_dw_id,
        fle_student_dw_id,
        fle_school_dw_id,
        fle_grade_dw_id,
        fle_instructional_plan_id,
        fle_created_time,
        fle_exit_ticket,
        fle_is_retry,
        fle_total_score
    FROM ${rs_coredw}.fact_learning_experience
    WHERE fle_exit_ticket = 'true'
      AND fle_is_retry = 'false'
      AND fle_total_score < 70
)
SELECT DISTINCT 
    lwp.lo_dw_id,
    lwp.lo_id,
    lwp.lo_title,
    d_ip.instructional_plan_id,
    dtrm.term_academic_period_order,
    cay.content_academic_year_name,
    st_et.fle_student_dw_id,
    st_et.fle_school_dw_id,
    sch.school_name,
    sch.school_dw_id,
    sch.tenant_name,
    sch.tenant_id,
    sch.school_organisation,
    sch.organisation_dw_id,
    sj.curr_subject_dw_id,
    sj.curr_subject_name,
    gr.grade_k12grade AS grade,
    p.practice_id,
    st_et.fle_created_time,
    p.practice_created_time,

    -- practice_gen_time_sec in seconds (float)
    CONVERT(
        FLOAT,
        DATEDIFF(
            millisecond, 
            st_et.fle_created_time, 
            p.practice_created_time
        )
    ) / 1000.0 AS practice_gen_time_sec

FROM lesson_wth_practice lwp
INNER JOIN students_failed_et st_et
    ON lwp.lo_dw_id = st_et.fle_lo_dw_id
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
    ON st_et.fle_school_dw_id = sch.school_dw_id
INNER JOIN ${rs_coredw}.dim_curriculum_subject sj
    ON lwp.lo_curriculum_subject_id = sj.curr_subject_id
INNER JOIN ${rs_coredw}.dim_grade gr
    ON gr.grade_dw_id = st_et.fle_grade_dw_id
INNER JOIN ${rs_coredw}.dim_instructional_plan d_ip
    ON d_ip.instructional_plan_item_lo_dw_id = lwp.lo_dw_id
   AND d_ip.instructional_plan_id = st_et.fle_instructional_plan_id
INNER JOIN ${rs_coredw}.dim_week dw
    ON d_ip.instructional_plan_item_week_dw_id = dw.week_dw_id
INNER JOIN ${rs_coredw}.dim_term dtrm
    ON dw.week_term_id = dtrm.term_id
INNER JOIN ${rs_coredw}.dim_content_academic_year cay
    ON cay.content_academic_year_id = d_ip.instructional_plan_content_academic_year_id
LEFT JOIN ${rs_coredw}.fact_practice p
    ON lwp.lo_dw_id = p.practice_lo_dw_id
   AND st_et.fle_student_dw_id = p.practice_student_dw_id;
