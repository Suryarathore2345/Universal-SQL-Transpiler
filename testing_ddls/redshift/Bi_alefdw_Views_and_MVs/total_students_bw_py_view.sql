CREATE OR REPLACE VIEW bi_alefdw_dev.total_students_bw_py_view AS
WITH date_dimension as
         (SELECT DISTINCT full_date                 as local_date,
                          calendar_week_number      as week_num,
                          uae_week_number           as uae_week_num,
                          calendar_year_week_number as wy_num,
                          uae_year_week_number      as uae_wy_num,
                          calendar_year_month_number as year_month
    FROM alefdw.dim_date dt
    WHERE dt.full_date between (trunc(sysdate) - 15) and (trunc(sysdate) - 1) -- Date can be changed based on requirement
),

    holidays_dimension as
    (SELECT DISTINCT cast(holiday_date AS date) AS holiday_date,
    holiday_organisation_dw_id
    FROM alefdw.dim_holiday
)

SELECT DISTINCT local_date,
                tenant_name,
                school_dw_id,
                school_name,
                school_city_name,
                school_organisation,
                school_country_name,
                school_composition,
                school_latitude,
                school_longitude,
                school_alias                               AS adek_id,
                school_label,
                school_created_time,
                school_cx_cluster,
                date_part(year, dsc.academic_year_start_date) || '-' ||
                    date_part(year, dsc.academic_year_end_date) AS academic_year,
                grade_k12grade                             AS grade,
                ''                                         AS class,
                section_dw_id,
                initcap(section_alias)                     AS section,
                student_tags,
                student_special_needs,
                week_num                                   AS week_number,
                DENSE_RANK() OVER (PARTITION BY wy_num,academic_year_start_date,dse.section_dw_id,student_tags,student_special_needs ORDER BY student_dw_id ASC ) +
                    DENSE_RANK() OVER (PARTITION BY wy_num,academic_year_start_date,dse.section_dw_id,student_tags,student_special_needs ORDER BY student_dw_id DESC) - 1
                                                           AS weekly_total_students,
                DENSE_RANK() OVER (PARTITION BY local_date,academic_year_start_date,dse.section_dw_id,student_tags,student_special_needs ORDER BY student_dw_id ASC ) +
                    DENSE_RANK() OVER (PARTITION BY local_date,academic_year_start_date,dse.section_dw_id,student_tags,student_special_needs ORDER BY student_dw_id DESC) - 1
                                                           AS total_students,
                DENSE_RANK() OVER (PARTITION BY year_month,academic_year_start_date,dse.section_dw_id,student_tags,student_special_needs ORDER BY student_dw_id ASC ) +
                DENSE_RANK() OVER (PARTITION BY year_month,academic_year_start_date,dse.section_dw_id,student_tags,student_special_needs ORDER BY student_dw_id DESC) - 1
                                                           as monthly_total_students,
                dsc.school_id                              as school_id,
                dsc.organisation_dw_id                     as org_dw_id,
                null AS org_term,
                null AS term_start_date,
                null AS term_end_date,
                CASE
                    WHEN holiday_date IS NULL THEN FALSE
                    ELSE TRUE
                    END                                    AS holiday_flag,
                dse.year_month                             AS month_year_number,
                dse.wy_num                                 AS week_year_number
FROM (SELECT section_alias, section_dw_id, grade_id, school_id, tenant_id, dd.*
    FROM alefdw.dim_section
    CROSS JOIN date_dimension dd
    where school_id is not null) dse
    INNER JOIN bi_alefdw.bi_all_schools_dim_mv dsc
        ON MD5(dsc.school_id) = MD5(dse.school_id)
        AND ((school_status > 1 AND
                              local_date >= trunc(convert_timezone('UTC', dsc.tenant_timezone, dsc.school_created_time))
                            AND local_date <= trunc(convert_timezone('UTC', dsc.tenant_timezone, dsc.school_updated_time)))
                            OR (school_status = 1 AND local_date >=
                                                       trunc(convert_timezone('UTC', dsc.tenant_timezone, dsc.school_created_time))))
        AND (local_date >= dsc.academic_year_start_date and local_date <= dsc.academic_year_end_date)
    INNER JOIN bi_alefdw.bi_student_dim_mv ds
        ON ds.student_section_dw_id = dse.section_dw_id
        AND ((student_status = 2 AND local_date >= trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))
            AND local_date < trunc(convert_timezone('UTC', dsc.tenant_timezone, student_active_until)))
            OR (student_status = 1 AND local_date >= trunc(convert_timezone('UTC', dsc.tenant_timezone, student_created_time))))
    INNER JOIN alefdw.dim_grade dg
        ON dse.grade_id = dg.grade_id
        AND dg.grade_dw_id = ds.student_grade_dw_id
        AND dg.academic_year_id = dsc.academic_year_id
    LEFT JOIN holidays_dimension dh
        ON dh.holiday_date = dse.local_date and dh.holiday_organisation_dw_id = dsc.organisation_dw_id
WITH NO SCHEMA BINDING;