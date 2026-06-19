CREATE OR REPLACE VIEW eagles_alefdw_dev.student_absentees_noholiday_weekly AS
WITH total_students AS -- Section Level
         (SELECT DISTINCT full_date                                                     AS local_date,
                          DATE_TRUNC('week', full_date)                                 AS week_start_date,
                          DATE_PART(DOW, full_date)                                     AS weekend,
                          tenant_name,
                          dsc.school_dw_id,
                          dsc.school_id,
                          school_name,
                          school_city_name,
                          school_organisation,
                          school_country_name,
                          school_composition,
                          school_alias                                                  AS adek_id,
                          school_created_time,
                          DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                            DATE_PART(YEAR, dsc.academic_year_end_date)                 AS academic_year,
                          dsc.academic_year_start_date,
                          dsc.academic_year_end_date,
                          grade_k12grade                                                AS grade,
                          section_dw_id,
                          section_name                                                  AS section,
                          student_tags,
                          student_special_needs                                         AS special_needs,
                          ds.student_dw_id                                              AS available_student_dw_id,
                          ds.student_id,
                          student_username,
                          student_first_created_date,
                          FIRST_VALUE(student_status) OVER (PARTITION BY student_dw_id
                              ORDER BY student_created_time DESC, student_status ASC
                              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS student_current_status,
                          school_label
          FROM (SELECT full_date, section_name, section_dw_id, grade_id, school_id, tenant_id, section_id
                FROM alefdw. dim_section
                         CROSS JOIN (SELECT DISTINCT full_date
                                     FROM alefdw.dim_date dt
                                     WHERE dt.full_date BETWEEN TRUNC(SYSDATE) - 365 AND TRUNC(SYSDATE) - 1)
                WHERE school_id IS NOT NULL) dse
                   INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                              ON dsc. school_id = dse. school_id
                              AND (full_date >= dsc.academic_year_start_date AND full_date <= dsc.academic_year_end_date)
                   INNER JOIN bi_alefdw.bi_student_dim_mv ds
                              ON ds. student_section_dw_id = dse. section_dw_id
                              AND ((student_status = 2
                                      AND full_date >= TRUNC(CONVERT_TIMEZONE('UTC', dsc. tenant_timezone, student_created_time))
                                      AND full_date < TRUNC(CONVERT_TIMEZONE('UTC', dsc. tenant_timezone, student_active_until)))
                                      OR (student_status = 1 AND full_date >= TRUNC(CONVERT_TIMEZONE('UTC', dsc. tenant_timezone, student_created_time))))
                   INNER JOIN alefdw.dim_grade dg
                              ON dse.grade_id = dg.grade_id
                                  AND dg.grade_dw_id = ds.student_grade_dw_id
                                  AND dsc.academic_year_id = dg.academic_year_id
                   LEFT JOIN (SELECT DISTINCT CAST(holiday_date AS date) AS holiday_date, holiday_organisation_dw_id
                              FROM alefdw.dim_holiday) dh
                             ON dh.holiday_date = dse. full_date AND
                                dh.holiday_organisation_dw_id = dsc. organisation_dw_id
          WHERE dsc.academic_year_end_date >= DATE_TRUNC('day', SYSDATE)
            AND holiday_date IS NULL
            AND DATE_PART(DOW, full_date) BETWEEN 1 AND 5),

     active_students AS ( -- Section Level
        SELECT DISTINCT TRUNC(sl.login_local_date_time) AS login_date,
                        student_section_dw_id,
                        sl.student_dw_id                AS active_student_dw_id
        FROM bi_alefdw.student_login sl
        INNER JOIN bi_alefdw. bi_active_schools_dim_mv dsc
            ON dsc.school_dw_id = sl.school_dw_id
        INNER JOIN bi_alefdw. bi_student_dim_mv ds
            ON ds.student_dw_id = sl.student_dw_id
            AND ((student_status = 2
                 AND TRUNC(login_local_date_time) >= TRUNC(CONVERT_TIMEZONE('UTC', dsc. tenant_timezone, student_created_time))
                 AND TRUNC(login_local_date_time) < TRUNC(CONVERT_TIMEZONE('UTC', dsc. tenant_timezone, student_active_until)))
                 OR (student_status = 1 AND TRUNC(login_local_date_time) >= TRUNC(CONVERT_TIMEZONE('UTC', dsc. tenant_timezone, student_created_time))))
        WHERE TRUNC(login_local_date_time) >=TRUNC(CONVERT_TIMEZONE('UTC', dsc. tenant_timezone, SYSDATE)) - 365
          AND TRUNC(login_local_date_time) <= TRUNC(CONVERT_TIMEZONE('UTC', dsc. tenant_timezone, SYSDATE))
    )

SELECT ts.week_start_date,
       LISTAGG(CASE WHEN ast.active_student_dw_id IS NULL THEN local_date END, '|') WITHIN GROUP (ORDER BY local_date) AS absent_days,
       COUNT(CASE WHEN ast.active_student_dw_id IS NULL THEN local_date END) AS total_absent_days,
       ts.academic_year,
       ts.tenant_name,
       ts.school_dw_id,
       ts.school_id,
       ts.school_name,
       ts.adek_id,
       ts.grade,
       INITCAP(ts.section)                                         AS section,
       ts.student_tags,
       ts.special_needs,
       ts.available_student_dw_id,
       ts.student_id,
       ts.student_username,
       ts.student_first_created_date,
       ts.student_current_status,
       ts.academic_year_start_date,
       ts.academic_year_end_date,
       ts.section_dw_id
FROM total_students ts
         LEFT JOIN active_students ast
                   ON ts.section_dw_id = ast.student_section_dw_id
                       AND ts.local_date = ast.login_date
                       AND ts.available_student_dw_id = ast.active_student_dw_id
GROUP BY week_start_date,
         academic_year,
         ts.tenant_name,
         ts.school_dw_id,
         ts.school_id,
         ts.school_name,
         ts.adek_id,
         ts.grade,
         INITCAP(ts.section),
         ts.student_tags,
         ts.special_needs,
         ts.available_student_dw_id,
         student_id,
         student_username,
         student_first_created_date,
         student_current_status,
         ts.academic_year_start_date,
         ts.academic_year_end_date,
         ts.section_dw_id
WITH NO SCHEMA BINDING;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.student_absentees_noholiday_weekly to group business_intelligence;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.student_absentees_noholiday_weekly to group datascience;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.student_absentees_noholiday_weekly to group tdc;

grant select on eagles_alefdw_dev.student_absentees_noholiday_weekly to group ro_users;