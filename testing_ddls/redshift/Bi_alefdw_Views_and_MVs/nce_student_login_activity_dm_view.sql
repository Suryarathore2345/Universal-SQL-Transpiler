CREATE OR REPLACE VIEW bi_alefdw_dev.nce_student_login_activity_dm_view AS
WITH total_students AS -- Section Level
         (SELECT DISTINCT full_date                                                                 AS local_date,
                          tenant_name,
                          dsc.school_dw_id,
                          school_name,
                          school_city_name,
                          school_organisation,
                          school_longitude,
                          school_latitude,
                          organisation_dw_id,
                          date_part(year, dsc.academic_year_start_date) || '-' ||
                          date_part(year, dsc.academic_year_end_date)                                AS academic_year,
                          dsc.academic_year_start_date,
                          dsc.academic_year_end_date,
                          grade_k12grade                                                            AS grade,
                          dc.class_title                                                            AS class,
                          section_dw_id,
                          section_name                                                              AS section,
                          student_tags,
                          student_special_needs                                                     AS special_needs,
                          ds.student_dw_id                                                          AS available_student_dw_id,
                          ds.student_id,
                          dc.class_dw_id,
                          dc.class_gen_subject,
                          first_value(student_status)
                                      OVER (PARTITION BY student_dw_id
                                          ORDER BY student_created_time DESC
                                          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS student_current_status,
                          school_label
--                           dsc.school_cx_cluster
          FROM (SELECT full_date, section_name, section_dw_id, grade_id, school_id, tenant_id, section_id
                FROM alefdw.dim_section
                         CROSS JOIN (SELECT distinct full_date
                                     FROM alefdw.dim_date dt
                                     WHERE dt.full_date between trunc(sysdate) - 365 and trunc(sysdate))
                WHERE school_id is not null) dse
                   INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                              ON dsc.school_id = dse.school_id
                              AND (full_date >= dsc.academic_year_start_date and full_date <= dsc.academic_year_end_date)
                   INNER JOIN bi_alefdw.bi_student_dim_mv ds
                              ON ds.student_section_dw_id = dse.section_dw_id
                                  AND ((student_status = 2 AND
                                        full_date >= trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))
                                      AND full_date < trunc(convert_timezone('UTC', dsc.tenant_timezone, student_active_until)))
                                      OR (student_status = 1 AND full_date >= trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))))
                   INNER JOIN alefdw.dim_class_user dcu
                              ON dcu.class_user_user_dw_id = ds.student_dw_id
                   INNER JOIN alefdw.dim_class dc
                              ON dcu.class_user_class_dw_id = dc.class_dw_id
                                  AND class_user_status = 1
                                  AND class_user_attach_status = 1
                   INNER JOIN alefdw.dim_grade dg
                              ON dse.grade_id = dg.grade_id
                              AND dg.grade_dw_id = ds.student_grade_dw_id
                              AND MD5(dsc.academic_year_id) = MD5(dg.academic_year_id)
          WHERE organisation_dw_id = 17 -- NCE organization dw id code
         ),

     active_students AS -- Section Level
         (SELECT DISTINCT login_date,
                          student_section_dw_id,
                          student_tags,
                          special_needs,
                          active_student_dw_id
          FROM (SELECT DISTINCT Trunc(login_local_date_time) AS login_date,
                                student_section_dw_id,
                                student_tags,
                                student_special_needs        AS special_needs,
                                sl.student_dw_id             AS active_student_dw_id
                FROM bi_alefdw.student_login sl
                         INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                    ON dsc.school_dw_id = sl.school_dw_id
                         INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                    ON ds.student_dw_id = sl.student_dw_id
                                        AND ((student_status = 2 AND trunc(login_local_date_time) >= trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))
                                            AND trunc(login_local_date_time) <trunc(convert_timezone('UTC', dsc.tenant_timezone, student_active_until)))
                                            OR (student_status = 1 AND trunc(login_local_date_time) >= trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))))
                WHERE trunc(login_local_date_time) >= trunc(convert_timezone('UTC', dsc.tenant_timezone, sysdate)) - 365
                  AND trunc(login_local_date_time) <= trunc(convert_timezone('UTC', dsc.tenant_timezone, sysdate))
                  AND organisation_dw_id = 17 -- NCE organization code TBD
               )),
     holidays_dimension as
         (SELECT DISTINCT cast(holiday_date AS date) AS holiday_date,
                          holiday_organisation_dw_id
          FROM alefdw.dim_holiday)

SELECT DISTINCT local_date,
                ts.academic_year,
                ts.tenant_name,
                ts.school_dw_id,
                ts.school_name,
                ts.school_city_name,
                ts.school_organisation,
                ts.school_latitude,
                ts.school_longitude,
                ts.school_label,
                ts.grade,
                initcap(ts.class)                                       AS class,
                initcap(ts.section)                                     AS section,
                ts.student_tags,
                ts.special_needs,
                ts.available_student_dw_id,
                active_student_dw_id,
                student_id,
                student_current_status,
                ts.academic_year_start_date,
                ts.academic_year_end_date,
                ts.section_dw_id,
                case when holiday_date is null then FALSE ELSE TRUE END as holiday_flag,
                ts.class_gen_subject,
                ts.class_dw_id
FROM total_students ts
         LEFT JOIN active_students ast
                   ON ts.section_dw_id = ast.student_section_dw_id
                       AND ts.local_date = ast.login_date
                       AND ts.student_tags = ast.student_tags
                       AND ts.special_needs = ast.special_needs
                       AND ts.available_student_dw_id = ast.active_student_dw_id
         LEFT JOIN holidays_dimension dh
                   on dh.holiday_date = ts.local_date and dh.holiday_organisation_dw_id = ts.organisation_dw_id
                       AND organisation_dw_id = 17
        WITH NO SCHEMA BINDING;