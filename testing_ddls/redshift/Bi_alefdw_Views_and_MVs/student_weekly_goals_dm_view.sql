CREATE OR REPLACE VIEW bi_alefdw_dev.student_weekly_goals_dm_view AS

WITH date_dimension AS
         (SELECT DISTINCT full_date                 AS local_date,
                          calendar_week_number      AS week_num,
                          uae_week_number           AS uae_week_num,
                          calendar_year_week_number AS wy_num,
                          uae_year_week_number      AS uae_wy_num
          FROM alefdw.dim_date dt
          WHERE dt.full_date >= Trunc(sysdate) - 365
            AND dt.full_date <= Trunc(sysdate)),

     Combined_Data as (SELECT fwg_id
                            , fwg_dw_id
                            , local_date
                            , fwg_student_dw_id
                            , dsc.tenant_name
                            , dsc.school_organisation
                            , dsc.school_name
                            , dsc.school_dw_id
                            , date_part(year, dsc.academic_year_start_date) || '-' ||
                              date_part(year, dsc.academic_year_end_date) AS academic_year
                            , dsc.academic_year_start_date
                            , dsc.academic_year_end_date
--                             , dcr.curr_name
                            , week_num
                            , fwg_created_time
                            , fwg_class_dw_id
                            , dc.class_title
                            , dse.section_name
                            , dc.class_gen_subject
                            , dg.grade_name
                            , weekly_goal_type_total_activity_count
                            , fwg_star_earned
                            , fwg_action_status
                            , CASE fwg_action_status
                                  WHEN 1 THEN 'Created'
                                  WHEN 2 THEN 'Completed'
                                  WHEN 3 THEN 'Expired'
                                  WHEN 4 THEN 'Deleted'
             END                                                          AS goal_status,
                            dc.class_material_type
                       FROM alefdw.fact_weekly_goal fwg
                                INNER JOIN alefdw.dim_weekly_goal_type dwgt
                                           on dwgt.weekly_goal_type_dw_id = fwg.fwg_type_dw_id
                                INNER JOIN bi_alefdw.bi_student_dim_mv sdm
                                           ON sdm.student_dw_id = fwg.fwg_student_dw_id
                                               AND sdm.student_status = 1
                                               AND sdm.student_active_until IS NULL
                                INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                           ON dsc.school_dw_id = sdm.student_school_dw_id
                                INNER JOIN date_dimension dd ON trunc(fwg.fwg_created_time) = dd.local_date
                                INNER JOIN alefdw.dim_grade dg on dg.grade_dw_id = sdm.student_grade_dw_id
                           and MD5(dsc.academic_year_id) = MD5(dg.academic_year_id)
                                INNER JOIN alefdw.dim_class dc on DC.class_dw_id = fwg.fwg_class_dw_id
                           AND MD5(dsc.academic_year_id) = MD5(dc.class_academic_year_id)
                           AND class_status = 1
                           AND class_course_status = 'ACTIVE'
                                INNER JOIN alefdw.dim_section dse on dse.section_dw_id = sdm.student_section_dw_id
                                INNER JOIN alefdw.dim_class_user dcu
                                           on dcu.class_user_user_dw_id = fwg.fwg_student_dw_id
                                               AND dcu.class_user_class_dw_id = fwg.fwg_class_dw_id
                                               AND class_user_status = 1
                                               AND class_user_attach_status = 1
--                                 INNER JOIN alefdw.dim_curriculum dcr
--                                            on md5(dcr.curr_id) = md5(dc.class_curriculum_id)
     )


SELECT cd.fwg_id,
       cd.fwg_dw_id,
       cd.local_date,
       cd.academic_year,
       cd.academic_year_start_date,
       cd.academic_year_end_date,
--        cd.curr_name,
       cd.fwg_student_dw_id,
       cd.tenant_name,
       cd.school_organisation,
       cd.week_num,
       cd.school_name,
       cd.school_dw_id,
       cd.fwg_created_time,
       cd.fwg_class_dw_id,
       cd.grade_name,
       cd.class_title,
       cd.section_name,
       cd.class_gen_subject,
       goals.end_goal_created_time,
       goals.fwg_star_earned,
       cd.weekly_goal_type_total_activity_count,
       cd.class_material_type,
       nvl(goals.goal_status, 'Ongoing') end_goal_status
FROM Combined_Data cd
         LEFT JOIN
     (SELECT fwg_id, fwg_created_time as end_goal_created_time, fwg_star_earned, goal_status
      FROM Combined_Data
      WHERE fwg_action_status <> 1) goals ON goals.fwg_id = cd.fwg_id
WHERE cd.fwg_action_status = 1
WITH NO SCHEMA BINDING;
