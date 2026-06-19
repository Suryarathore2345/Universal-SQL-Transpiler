CREATE OR REPLACE VIEW bi_alefdw_dev.dagg_student_login_activity_dm_view AS
WITH date_dimension as
         (SELECT DISTINCT full_date                  as local_date,
                          calendar_week_number       as week_num,
                          uae_week_number            as uae_week_num,
                          calendar_year_week_number  as wy_num,
                          uae_year_week_number       as uae_wy_num,
                          calendar_year_month_number as year_month
          FROM alefdw.dim_date dt
          WHERE dt.full_date >= Trunc(sysdate) - 365
            AND dt.full_date <= Trunc(sysdate) - 1),

     provisioned_students AS -- School Level
         (SELECT DISTINCT student_first_created_date,
                          student_school_dw_id,
                          count(distinct student_dw_id) AS school_provisioned_students
          FROM bi_alefdw.bi_student_dim_mv
          GROUP BY 1, 2),

     daily_active_students AS --Section level
         (
             SELECT DISTINCT local_date,
                             student_section_dw_id,
                             student_tags,
                             student_special_needs                      as special_needs,
                             date_part(year, ay.academic_year_start_date) || '-' ||
                             date_part(year, ay.academic_year_end_date) AS academic_year,
                             DENSE_RANK()
                             OVER (PARTITION BY local_date,academic_year_start_date,ds.student_section_dw_id,student_tags,special_needs ORDER BY sl.student_dw_id ASC )
                                 + DENSE_RANK()
                                   OVER (PARTITION BY local_date,academic_year_start_date,ds.student_section_dw_id,student_tags,special_needs ORDER BY sl.student_dw_id DESC ) -
                             1
                                                                        AS active_students
             FROM bi_alefdw.student_login sl
                      INNER JOIN date_dimension dd
                                 ON trunc(sl.login_local_date_time) = dd.local_date
                      INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                 ON dsc.school_dw_id = sl.school_dw_id
                      INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                 ON ds.student_dw_id = sl.student_dw_id
                                     AND ((student_status = 2 AND
                                           local_date >=
                                           trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))
                                         AND local_date <
                                             trunc(convert_timezone('UTC', dsc.tenant_timezone, student_active_until)))
                                         OR (student_status = 1 AND local_date >=
                                                                    trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))))
                      INNER JOIN alefdw.dim_grade dg
                                 ON dg.grade_dw_id = ds.student_grade_dw_id
                      INNER JOIN alefdw.dim_academic_year ay
                                 ON MD5(ay.academic_year_id) = MD5(dg.academic_year_id)
                                     AND MD5(ay.academic_year_school_id) = MD5(dsc.school_id)
                                     AND (local_date >= ay.academic_year_start_date AND
                                          local_date <= ay.academic_year_end_date)
                                     AND academic_year_status = 1
         )

SELECT DISTINCT ts.local_date,
                ts.academic_year,
                ts.tenant_name,
                ts.school_dw_id,
                ts.school_id,
                ts.school_name,
                ts.school_created_time,
                ts.adek_id,
                ts.school_city_name,
                ts.school_organisation,
                ts.school_country_name,
                ts.school_composition,
                ts.school_latitude,
                ts.school_longitude,
                ts.school_label,
                ts.grade,
                initcap(ts.class)        as class,
                initcap(ts.section)      as section,
                ts.student_tags,
                ts.student_special_needs as special_needs,
                ps.school_provisioned_students,
                ts.week_number,
                ts.week_year_number,
                ts.month_year_number,
                das.active_students,
                ts.total_students,
                ts.section_dw_id,
                ts.org_dw_id,
                ts.org_term,
                ts.term_start_date,
                ts.term_end_date,
                ts.holiday_flag,
                ts.school_cx_cluster
FROM bi_alefdw.total_students ts
         LEFT JOIN daily_active_students das
                   on ts.section_dw_id = das.student_section_dw_id
                       and ts.local_date = das.local_date
                       and ts.student_special_needs = das.special_needs
                       and ts.student_tags = das.student_tags
                       and nvl(ts.academic_year, 'NA') = nvl(das.academic_year, 'NA')
         
         LEFT JOIN provisioned_students ps
                   ON ts.school_dw_id = ps.student_school_dw_id
                       AND ts.local_date = ps.student_first_created_date
WHERE ts.local_date <> '2022-01-03'
WITH NO SCHEMA BINDING;