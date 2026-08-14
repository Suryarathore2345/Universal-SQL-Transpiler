CREATE OR ALTER VIEW ${os_bi_coredw}.student_weekly_goals_dm_view AS

WITH date_dimension AS (
    SELECT 
        full_date AS local_date,
        calendar_week_number AS week_num
    FROM ${rs_coredw}.dim_date
    WHERE full_date BETWEEN DATEADD(DAY, -365, CONVERT(DATE, GETDATE()))
                        AND CONVERT(DATE, GETDATE())
),

base_data AS (
    SELECT 
        fwg.fwg_id,
        fwg.fwg_dw_id,
        CONVERT(DATE, fwg.fwg_created_time) AS local_date,
        fwg.fwg_student_dw_id,
        dsc.tenant_name,
        dsc.school_organisation,
        dsc.school_name,
        dsc.school_dw_id,
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date))
        + '-' +
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        dsc.academic_year_start_date,
        dsc.academic_year_end_date,
        fwg.fwg_created_time,
        fwg.fwg_class_dw_id,
        dc.class_title,
        dse.section_name,
        dc.class_gen_subject,
        dg.grade_name,
        dwgt.weekly_goal_type_total_activity_count,
        fwg.fwg_star_earned,
        fwg.fwg_action_status,
        CASE fwg.fwg_action_status
            WHEN 1 THEN 'Created'
            WHEN 2 THEN 'Completed'
            WHEN 3 THEN 'Expired'
            WHEN 4 THEN 'Deleted'
        END AS goal_status,
        dc.class_material_type
    FROM ${rs_coredw}.fact_weekly_goal fwg
    INNER JOIN ${rs_coredw}.dim_weekly_goal_type dwgt
        ON dwgt.weekly_goal_type_dw_id = fwg.fwg_type_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_student_dim sdm
        ON sdm.student_dw_id = fwg.fwg_student_dw_id
        AND sdm.student_status = 1
        AND sdm.student_active_until IS NULL
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = sdm.student_school_dw_id
    INNER JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = sdm.student_grade_dw_id
        AND dsc.academic_year_id = dg.academic_year_id
    INNER JOIN ${rs_coredw}.dim_class dc
        ON dc.class_dw_id = fwg.fwg_class_dw_id
        AND dsc.academic_year_id = dc.class_academic_year_id
        AND dc.class_status = 1
        AND dc.class_course_status = 'ACTIVE'
    INNER JOIN ${rs_coredw}.dim_section dse
        ON dse.section_dw_id = sdm.student_section_dw_id
    INNER JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_user_dw_id = fwg.fwg_student_dw_id
        AND dcu.class_user_class_dw_id = fwg.fwg_class_dw_id
        AND dcu.class_user_status = 1
        AND dcu.class_user_attach_status = 1
    WHERE fwg.fwg_created_time >= DATEADD(DAY, -365, GETDATE())
),

final_data AS (
    SELECT 
        bd.fwg_id,
        bd.fwg_dw_id,
        bd.local_date,
        bd.fwg_student_dw_id,
        bd.tenant_name,
        bd.school_organisation,
        bd.school_name,
        bd.school_dw_id,
        bd.academic_year,
        bd.academic_year_start_date,
        bd.academic_year_end_date,
        bd.fwg_created_time,
        bd.fwg_class_dw_id,
        bd.class_title,
        bd.section_name,
        bd.class_gen_subject,
        bd.grade_name,
        bd.weekly_goal_type_total_activity_count,
        bd.fwg_star_earned,
        bd.fwg_action_status,
        bd.goal_status,
        bd.class_material_type,
        dd.week_num,

        MAX(CASE WHEN bd.fwg_action_status <> 1 THEN bd.fwg_created_time END)
            OVER (PARTITION BY bd.fwg_id) AS end_goal_created_time,

        MAX(CASE WHEN bd.fwg_action_status <> 1 THEN bd.fwg_star_earned END)
            OVER (PARTITION BY bd.fwg_id) AS end_goal_star,

        MAX(CASE WHEN bd.fwg_action_status <> 1 THEN bd.goal_status END)
            OVER (PARTITION BY bd.fwg_id) AS end_goal_status

    FROM base_data bd
    INNER JOIN date_dimension dd
        ON bd.local_date = dd.local_date
)

SELECT 
    fwg_id,
    fwg_dw_id,
    local_date,
    academic_year,
    academic_year_start_date,
    academic_year_end_date,
    fwg_student_dw_id,
    tenant_name,
    school_organisation,
    week_num,
    school_name,
    school_dw_id,
    fwg_created_time,
    fwg_class_dw_id,
    grade_name,
    class_title,
    section_name,
    class_gen_subject,
    end_goal_created_time,
    end_goal_star AS fwg_star_earned,
    weekly_goal_type_total_activity_count,
    class_material_type,
    ISNULL(end_goal_status, 'Ongoing') AS end_goal_status
FROM final_data
WHERE fwg_action_status = 1;