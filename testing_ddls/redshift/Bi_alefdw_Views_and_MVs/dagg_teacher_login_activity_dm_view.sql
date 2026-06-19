CREATE OR REPLACE VIEW bi_alefdw_dev.dagg_teacher_login_activity_dm_view AS
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

     daily_active_teachers AS (SELECT DISTINCT local_date                                 as login_date,
                                               tl.school_dw_id,
                                               date_part(year, ay.academic_year_start_date) || '-' ||
                                               date_part(year, ay.academic_year_end_date) AS academic_year,
                                               DENSE_RANK()
                                               OVER (PARTITION BY local_date,academic_year_start_date,tl.school_dw_id ORDER BY tl.teacher_dw_id ASC ) +
                                               DENSE_RANK()
                                               OVER (PARTITION BY local_date,academic_year_start_date,tl.school_dw_id ORDER BY tl.teacher_dw_id DESC) -
                                               1                                          as active_teachers
                               FROM bi_alefdw.teacher_login tl
                                        INNER JOIN date_dimension dd
                                                   ON trunc(tl.login_local_date_time) = dd.local_date
                                        INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                                                   ON tl.school_dw_id = ds.school_dw_id
                                        INNER JOIN alefdw.dim_teacher dt
                                                   ON dt.teacher_school_dw_id = tl.school_dw_id
                                                       AND dt.teacher_dw_id = tl.teacher_dw_id
                                                       AND ((teacher_status = 2
                                                           AND
                                                             local_date >=
                                                             trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))
                                                           AND
                                                             local_date <
                                                             trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_active_until)))
                                                           OR (teacher_status = 1
                                                               AND local_date >=
                                                                   trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))))
                                        INNER JOIN alefdw.dim_academic_year ay
                                                   ON MD5(ay.academic_year_school_id) = MD5(ds.school_id)
                                                       AND
                                                      (local_date >= ay.academic_year_start_date AND
                                                       local_date <= ay.academic_year_end_date)
                                                       AND academic_year_status = 1
                               WHERE dt.teacher_id NOT IN
                                     (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)) 

SELECT DISTINCT tt.local_date,
                tt.tenant_name,
                tt.school_dw_id,
                tt.school_id,
                tt.school_name,
                tt.school_created_time,
                tt.adek_id,
                tt.school_city_name,
                tt.school_organisation,
                tt.school_country_name,
                tt.school_composition,
                tt.school_latitude,
                tt.school_longitude,
                tt.school_label, 
                tt.week_number,
                tt.week_year_number,
                dat.active_teachers,
                tt.total_teachers,
                tt.academic_year,
                tt.org_dw_id,
                tt.org_term,
                tt.term_start_date,
                tt.term_end_date,
                tt.holiday_flag,
                tt.school_cx_cluster,
                'Daily' aa_type
FROM bi_alefdw.total_teachers tt 
         LEFT JOIN daily_active_teachers dat
                   ON tt.school_dw_id = dat.school_dw_id
                       AND tt.local_date = dat.login_date
                       AND nvl(tt.academic_year, 'NA') = nvl(dat.academic_year, 'NA')
WHERE tt.academic_year is not null
WITH NO SCHEMA BINDING;