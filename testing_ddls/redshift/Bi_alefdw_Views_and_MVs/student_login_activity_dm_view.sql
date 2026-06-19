CREATE OR REPLACE VIEW bi_alefdw_dev.student_login_activity_dm_view AS
WITH provisioned_students AS -- School Level
         (SELECT DISTINCT date(student_first_created_date) AS student_first_created_date,
                          student_school_dw_id,
                          count(distinct student_dw_id) AS school_provisioned_students
          FROM bi_alefdw.bi_student_dim_mv
          GROUP BY 1, 2)
SELECT DISTINCT ts.local_date,
                ts.academic_year,
                dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_status,
                dsc.school_created_time,
                ts.adek_id,
                dsc.school_city_name,
                dsc.school_organisation,
                dsc.school_country_name,
                dsc.school_composition,
                dsc.school_latitude,
                dsc.school_longitude,
                dsc.school_label,
                ts.grade,
                initcap(ts.class)        as class,
                initcap(ts.section)      as section,
                ts.student_tags,
                ts.student_special_needs as special_needs,
                ps.school_provisioned_students,
                ts.week_number,
                ts.week_year_number,
                ts.month_year_number,
                log.daily_active_students as active_students,
                log.weekly_active_students,
                log.monthly_active_students,
                ts.total_students,
                ts.weekly_total_students,
                ts.monthly_total_students,
                ts.section_dw_id,
                ts.org_dw_id,
                ts.holiday_flag,
                ts.school_cx_cluster
FROM bi_alefdw.total_students ts
         INNER JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                   ON ts.school_dw_id = dsc.school_dw_id
                   AND ts.local_date >= dsc.academic_year_start_date
                   AND ts.local_date >= dsc.academic_year_start_date
         LEFT JOIN  bi_alefdw.student_login_aggregated_mv log
                   ON ts.school_dw_id = log.school_dw_id
                   AND ts.local_date  = log.local_date
                   AND ts.section_dw_id = log.student_section_dw_id
                   AND ts.student_special_needs = log.student_special_needs
                   AND ts.student_tags = log.student_tags
         LEFT JOIN provisioned_students ps
                   ON ts.school_dw_id = ps.student_school_dw_id
                       AND ts.local_date = ps.student_first_created_date
WHERE ts.local_date BETWEEN DATE(DATEADD('month',-36,DATE_TRUNC('month',current_date))) AND current_date
WITH NO SCHEMA BINDING;
