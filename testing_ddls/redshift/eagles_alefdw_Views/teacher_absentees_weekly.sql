CREATE OR REPLACE VIEW eagles_alefdw_dev.teacher_absentees_noholiday_weekly as
WITH total_teachers as (
    SELECT DISTINCT ds.*,
                    full_date                                                     AS local_date,
                    DATE_TRUNC('week',full_date)                                  AS week_start_date,
                    DATE_PART(dow, full_date)                                     AS weekend,
                    dt.teacher_dw_id                                              AS available_teacher_dw_id,
                    dt.teacher_id,
                    first_value(trunc(teacher_created_time))
                    OVER (PARTITION BY teacher_dw_id
                        ORDER BY teacher_created_time
                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_first_created_date,
                    first_value(teacher_status)
                    OVER (PARTITION BY teacher_dw_id
                        ORDER BY teacher_created_time DESC, teacher_status ASC
                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_current_status
    FROM bi_alefdw.bi_active_schools_dim_mv ds
             CROSS JOIN (SELECT DISTINCT full_date
                         FROM alefdw.dim_date dt
                         WHERE dt.full_date between trunc(sysdate) - 360 and trunc(sysdate)-1
                          ) dse
             LEFT JOIN (select distinct cast(holiday_date as date) as holiday_date, holiday_organisation_dw_id
                        from alefdw.dim_holiday) dh
                       on dh.holiday_date = dse.full_date and dh.holiday_organisation_dw_id = ds.organisation_dw_id
             INNER JOIN alefdw.dim_teacher dt
                        ON dt.teacher_school_dw_id = ds.school_dw_id
                         AND   ((teacher_status = 2
                                AND full_date >= trunc(convert_timezone('UTC', ds.tenant_timezone,teacher_created_time))
                                AND full_date < trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_active_until)))
                                OR teacher_status = 1 AND full_date >= trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time)))
                         AND teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
    WHERE dh.holiday_date is null
    AND  date_part(dow, full_date)  between 1 and 5
    AND full_date >= ds.academic_year_start_date
    AND full_date <= ds.academic_year_end_date
),
    active_teachers AS (
                SELECT DISTINCT trunc(login_local_date_time) as login_date,
                               tl.school_dw_id,
                               tl.teacher_dw_id             AS active_teacher_dw_id
               FROM bi_alefdw.teacher_login tl
               INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                   ON tl.school_dw_id = ds.school_dw_id
               INNER JOIN alefdw.dim_teacher dt
                   ON dt.teacher_school_dw_id = tl.school_dw_id
                   AND dt.teacher_dw_id = tl.teacher_dw_id
                   AND trunc(login_local_date_time) >= trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))
                   AND (trunc(login_local_date_time) < trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_active_until))
                        OR teacher_status = 1)
               WHERE trunc(login_local_date_time) between trunc(sysdate) - 360 and trunc(sysdate)
    )
SELECT tt.week_start_date,
       listagg(CASE WHEN at.active_teacher_dw_id IS NULL THEN local_date END, '|')  within group (order by local_date)AS absent_days,
       count(CASE WHEN at.active_teacher_dw_id IS NULL THEN local_date END)  AS total_absent_days,
       tt.tenant_name,
       tt.school_name,
       tt.school_id,
       tt.school_dw_id,
       tt.available_teacher_dw_id,
       tt.teacher_id,
       tt.teacher_first_created_date,
       tt.teacher_current_status,
       date_part(year, tt.academic_year_start_date) || '-' ||
        date_part(year, tt.academic_year_end_date)                  AS academic_year,
       tt.academic_year_start_date,
       tt.academic_year_end_date
FROM total_teachers tt
         LEFT JOIN active_teachers at
             ON tt.school_dw_id = at.school_dw_id
             AND tt.local_date = at.login_date
             AND tt.available_teacher_dw_id = at.active_teacher_dw_id
GROUP BY tt.week_start_date,
                tt.tenant_name,
                tt.school_name,
                tt.school_id,
                tt.school_dw_id,
                tt.available_teacher_dw_id,
                tt.teacher_id,
                tt.teacher_first_created_date,
                tt.teacher_current_status,
                date_part(year, tt.academic_year_start_date) || '-' ||
                date_part(year, tt.academic_year_end_date),
                tt.academic_year_start_date,
                tt.academic_year_end_date
with no schema binding;

grant delete, insert, references, select, trigger, update on eagles_alefdw.teacher_absentees_noholiday_weekly to group business_intelligence;

grant delete, insert, references, select, trigger, update on eagles_alefdw.teacher_absentees_noholiday_weekly to group datascience;

grant delete, insert, references, select, trigger, update on eagles_alefdw.teacher_absentees_noholiday_weekly to group tdc;

grant select on eagles_alefdw.teacher_absentees_noholiday_weekly to group ro_users;