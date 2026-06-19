CREATE OR REPLACE VIEW bi_alefdw_dev.teacher_login_activity_dm_view AS
WITH provisoned_teachers AS
         (SELECT teacher_created_date,
                 teacher_school_dw_id,
                 count(DISTINCT teacher_dw_id) as school_provisoned_teachers
          FROM (SELECT DISTINCT teacher_dw_id,
                                teacher_school_dw_id,
                                first_value(trunc(teacher_created_time))
                                over (partition by teacher_dw_id order by teacher_created_time asc
                                    rows between unbounded preceding and unbounded following) as teacher_created_date
                FROM alefdw.dim_teacher dt
                WHERE dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id))
          GROUP BY 1, 2)
SELECT DISTINCT tt.local_date,
                dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_created_time,
                dsc.school_status,
                tt.adek_id,
                dsc.school_city_name,
                dsc.school_organisation,
                dsc.school_country_name,
                dsc.school_composition,
                dsc.school_latitude,
                dsc.school_longitude,
                dsc.school_label,
                pv.school_provisoned_teachers,
                tt.week_number,
                tt.week_year_number,
                tt.month_year_number,
                log.daily_active_teachers AS active_teachers,
                log.weekly_active_teachers,
                log.monthly_active_teachers,
                tt.total_teachers,
                tt.weekly_total_teachers,
                tt.monthly_total_teachers,
                tt.academic_year,
                tt.org_dw_id,
                tt.holiday_flag,
                tt.school_cx_cluster,
                CASE WHEN st.school_dw_id IS NULL THEN 'NO' ELSE 'YES' END AS school_with_students
FROM bi_alefdw.total_teachers tt
         INNER JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                   ON tt.school_dw_id = dsc.school_dw_id
                   AND tt.local_date >= dsc.academic_year_start_date
                   AND tt.local_date >= dsc.academic_year_start_date
         LEFT JOIN  bi_alefdw.teacher_login_aggregated_mv log
                   ON tt.school_dw_id = log.school_dw_id
                   AND tt.local_date  = log.local_date
         LEFT JOIN bi_alefdw.total_students st
                   ON tt.school_dw_id = st.school_dw_id
                   AND tt.local_date= st.local_date
         LEFT JOIN provisoned_teachers pv
                   ON tt.school_dw_id = pv.teacher_school_dw_id
                       AND tt.local_date = pv.teacher_created_date
WHERE tt.local_date BETWEEN DATE(DATEADD('month',-36,DATE_TRUNC('month',current_date))) AND current_date
WITH NO SCHEMA BINDING;
