CREATE
OR REPLACE VIEW bi_alefdw_dev.aggr_teacher_login_activity_dm_view AS

         with aggr_weekly_total as
                  (select tenant_name,
                          academic_year,
                          local_date,
                          school_dw_id,
                          school_name,
                          week_number,
                          week_year_number,
                          max(weekly_total_teachers) as weekly_total_teachers
                   from bi_alefdw.teacher_login_activity_dm_view
                   group by 1, 2, 3, 4, 5, 6, 7
                  ),

              aggr_weekly_active as
                  (select tenant_name,
                          week_number,
                          academic_year,
                          school_dw_id,
                          max(weekly_active_teachers) as weekly_active_teachers
                   from (select tenant_name,
                                week_number,
                                academic_year,
                                school_dw_id,
                                sum(weekly_active_teachers) as weekly_active_teachers
                         from (select tenant_name,
                                      academic_year,
                                      school_dw_id,
                                      school_name,
                                      week_number,
                                      week_year_number,
                                      max(weekly_active_teachers) as weekly_active_teachers
                               from bi_alefdw.teacher_login_activity_dm_view
                               group by 1, 2, 3, 4, 5, 6
                              )
                         group by 1, 2, 3, 4)
                   group by 1, 2, 3, 4)


select dt.local_date,
       dt.week_number,
       dt.week_year_number,
       dt.month_year_number,
       dt.tenant_name,
       dt.school_dw_id,
       dt.school_name,
       dt.school_organisation,
       dt.school_composition,
       dt.org_term,
       dt.term_end_date,
       dt.term_start_date,
       dt.academic_year,
       dt.holiday_flag,
       sum(awa.weekly_active_teachers) as weekly_active_teachers,
       sum(awt.weekly_total_teachers)  as weekly_total_teachers,
       max(dt.total_teachers)          as total_teachers,
       max(dt.active_teachers)         as active_teachers

from bi_alefdw.teacher_login_activity_dm_view dt
         LEFT JOIN aggr_weekly_total awt
                   on awt.school_dw_id = dt.school_dw_id
                       AND awt.academic_year = dt.academic_year
                       AND awt.week_number = dt.week_number
                       and awt.local_date = dt.local_date
         LEFT JOIN aggr_weekly_active awa
                   on awa.school_dw_id = dt.school_dw_id
                       AND awa.academic_year = dt.academic_year
                       AND awa.week_number = dt.week_number
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
WITH NO SCHEMA BINDING;