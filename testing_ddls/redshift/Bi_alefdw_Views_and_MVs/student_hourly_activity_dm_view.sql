CREATE OR REPLACE VIEW bi_alefdw_dev.student_hourly_activity_dm_view AS

SELECT DISTINCT trunc(convert_timezone('UTC', dsc.tenant_timezone, sl.ful_created_time)) AS local_date,
                date_part(hour, convert_timezone('UTC', dsc.tenant_timezone, sl.ful_created_time)) AS day_hour,
                ds.student_tags,
                ds.student_special_needs                                                           AS special_needs,
                date_part(year, dsc.academic_year_start_date) || '-' ||
                date_part(year, dsc.academic_year_end_date)                                        AS academic_year,
                dse.section_dw_id,
                INITCAP(dse.section_name)                                                          AS section,
                INITCAP(grade_k12grade)                                                            AS grade,
                dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_city_name,
                dsc.school_name,
                dsc.school_organisation,
                dsc.school_country_name,
                dsc.school_composition,
                dsc.school_latitude,
                dsc.school_longitude,
                dsc.school_alias                                                                   AS adek_id,
                dsc.school_label,
                total_students,
                count(distinct sl.ful_user_dw_id)                                                  AS active_students
FROM alefdw.fact_user_login sl
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                    ON dsc.school_dw_id = sl.ful_school_dw_id
                    AND (trunc(convert_timezone('UTC', dsc.tenant_timezone, sl.ful_created_time)) >=
                            dsc.academic_year_start_date and
                            trunc(convert_timezone('UTC', dsc.tenant_timezone, sl.ful_created_time)) <=
                            dsc.academic_year_end_date)
         INNER JOIN bi_alefdw.bi_student_dim_mv ds
                    ON ds.student_dw_id = sl.ful_user_dw_id
                        AND ((student_status = 2
                            AND
                              trunc(convert_timezone('UTC', dsc.tenant_timezone, sl.ful_created_time)) >=
                              trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))
                            AND
                              trunc(convert_timezone('UTC', dsc.tenant_timezone, sl.ful_created_time)) <
                              trunc(convert_timezone('UTC', dsc.tenant_timezone, student_active_until)))
                            OR
                             (student_status = 1 AND
                              trunc(convert_timezone('UTC', dsc.tenant_timezone, sl.ful_created_time)) >=
                              trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))))
         INNER JOIN alefdw.dim_section dse
                    ON dse.section_dw_id = ds.student_section_dw_id
         INNER JOIN alefdw.dim_grade dg
                    ON dse.grade_id = dg.grade_id
                    AND dg.grade_dw_id = ds.student_grade_dw_id
                    AND MD5(dsc.academic_year_id) = MD5(dg.academic_year_id)
         INNER JOIN bi_alefdw.total_students ts
                    ON ts.section_dw_id = ds.student_section_dw_id
                        AND ts.local_date = trunc(convert_timezone('UTC', dsc.tenant_timezone, sl.ful_created_time))
                        AND ts.student_tags = ds.student_tags
                        AND ts.student_special_needs = ds.student_special_needs
         LEFT JOIN alefdw.dim_tag dtg on dtg.tag_association_id = dsc.school_id
WHERE sl.ful_role_dw_id = 2
  AND trunc(sl.ful_created_time) >= trunc(sysdate) - 90
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21
WITH NO SCHEMA BINDING;
