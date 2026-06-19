CREATE OR REPLACE VIEW bi_alefdw_dev.nce_teacher_login_activity_dm_view as
WITH total_teachers AS (SELECT DISTINCT ds.*,
                                        full_date                                                                 AS local_date,
                                        dt.teacher_dw_id                                                          AS available_teacher_dw_id,
                                        dt.teacher_id,
                                        initcap(NVL(dc.class_gen_subject, 'NA'))                                  AS class_gen_subject,
                                        initcap(NVL(dc.class_title, 'NA'))                                        AS class,
                                        initcap(NVL(dg.grade_k12grade, 0))                                        AS grade_k12grade,
                                        first_value(trunc(teacher_created_time))
                                                    OVER (PARTITION BY teacher_dw_id
                                                        ORDER BY teacher_created_time
                                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_first_created_date,
                                        first_value(teacher_status)
                                                    OVER (PARTITION BY teacher_dw_id
                                                        ORDER BY teacher_created_time DESC
                                                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS teacher_current_status
                        FROM bi_alefdw.bi_active_schools_dim_mv ds
                                 CROSS JOIN (SELECT DISTINCT full_date
                                             FROM alefdw.dim_date dt
                                             WHERE dt.full_date BETWEEN TRUNC(SYSDATE) - 365 AND TRUNC(SYSDATE))
                                 INNER JOIN alefdw.dim_teacher dt
                                            ON dt.teacher_school_dw_id = ds.school_dw_id
                                                AND ((
                                                         teacher_status = 2
                                                             AND full_date >=
                                                                 TRUNC(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))
                                                             AND full_date <
                                                                 TRUNC(convert_timezone('UTC', ds.tenant_timezone, teacher_active_until))
                                                         )
                                                    OR (teacher_status = 1 AND full_date >= trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time)))
                                                   )
                                 LEFT JOIN alefdw.dim_class_user dcu on dt.teacher_dw_id = dcu.class_user_user_dw_id
                            AND class_user_role_dw_id = 1
                            AND class_user_status = 1
                            AND class_user_attach_status = 1
                                 LEFT JOIN alefdw.dim_class dc on dcu.class_user_class_dw_id = dc.class_dw_id
                            AND class_status = 1
                            AND class_course_status = 'ACTIVE'
                                 left join alefdw.dim_grade dg on dc.class_grade_id = dg.grade_id
                        WHERE dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
                           AND (full_date >= ds.academic_year_start_date AND full_date <= ds.academic_year_end_date)
                          AND organisation_dw_id = 17 -- NCE content repository code TBD
),
     active_teachers AS (SELECT DISTINCT TRUNC(login_local_date_time) AS login_date,
                                         tl.school_dw_id,
                                         tl.teacher_dw_id             AS active_teacher_dw_id
                         FROM bi_alefdw.teacher_login tl
                                  INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds
                                             ON tl.school_dw_id = ds.school_dw_id
                                  INNER JOIN alefdw.dim_teacher dt
                                             ON dt.teacher_school_dw_id = tl.school_dw_id
                                                 AND dt.teacher_dw_id = tl.teacher_dw_id
                                                 AND ((teacher_status = 2
                                                     AND TRUNC(login_local_date_time) >=
                                                         TRUNC(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time))
                                                     AND TRUNC(login_local_date_time) <
                                                         TRUNC(convert_timezone('UTC', ds.tenant_timezone, teacher_active_until))
                                                          )
                                                     OR (teacher_status = 1 AND login_local_date_time >= trunc(convert_timezone('UTC', ds.tenant_timezone, teacher_created_time)))
                                                    )
                         WHERE TRUNC(login_local_date_time) between TRUNC(SYSDATE) - 365 AND TRUNC(SYSDATE)
                           AND dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
                           AND organisation_dw_id = 17 -- NCE content repository code TBD
     ),
     holidays_dimension AS (SELECT DISTINCT CAST(holiday_date AS DATE) AS holiday_date,
                                            holiday_organisation_dw_id
                            FROM alefdw.dim_holiday)

SELECT DISTINCT local_date,
                tenant_name,
                tt.school_dw_id,
                school_name,
                school_created_time,
                school_alias                                            AS adek_id,
                tt.school_city_name,
                tt.school_organisation,
                tt.school_country_name,
                tt.school_composition,
                tt.school_id,
                school_label,
                available_teacher_dw_id,
                active_teacher_dw_id,
                tt.teacher_id,
                tt.class_gen_subject,
                tt.class,
                tt.grade_k12grade,
                tt.teacher_first_created_date,
                tt.teacher_current_status,
                date_part(year, tt.academic_year_start_date) || '-' ||
                date_part(year, tt.academic_year_end_date)              AS academic_year,
                tt.academic_year_start_date,
                tt.academic_year_end_date,
                CASE WHEN holiday_date IS NULL THEN FALSE ELSE TRUE END AS holiday_flag,
                tt.school_cx_cluster
FROM total_teachers tt
         LEFT JOIN active_teachers at
                   ON tt.school_dw_id = at.school_dw_id
                       AND tt.local_date = at.login_date
                       AND tt.available_teacher_dw_id = at.active_teacher_dw_id
         LEFT JOIN holidays_dimension dh
                   ON dh.holiday_date = tt.local_date AND dh.holiday_organisation_dw_id = tt.organisation_dw_id
WITH NO SCHEMA BINDING;