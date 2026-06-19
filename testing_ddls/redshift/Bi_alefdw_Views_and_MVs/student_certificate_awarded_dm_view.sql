CREATE OR REPLACE VIEW bi_alefdw_dev.student_certificate_awarded_dm_view AS
WITH date_dimension AS (SELECT DISTINCT full_date                 AS local_date,
                                        calendar_week_number      AS week_num,
                                        calendar_year_week_number AS wy_num
                        FROM alefdw.dim_date as dt
                        WHERE dt.full_date >= TRUNC(SYSDATE) - 365
                          AND dt.full_date <= TRUNC(SYSDATE)),
     cte_students AS (SELECT DISTINCT ts.local_date,
                                      ts.academic_year,
                                      ts.week_year_number,
                                      ts.week_number,
                                      ts.month_year_number,
                                      ts.tenant_name,
                                      ts.school_dw_id,
                                      ts.school_id,
                                      ts.org_dw_id,
                                      ts.school_organisation,
                                      ts.school_city_name,
                                      ts.school_country_name,
                                      ts.school_name,
                                      ts.section_dw_id,
                                      ts.section,
                                      ts.grade,
                                      ts.student_special_needs,
                                      ts.student_tags,
                                      ts.total_students
                      FROM bi_alefdw.total_students as ts
                               JOIN bi_alefdw.bi_active_schools_dim_mv as dsc
                                    ON dsc.school_dw_id = ts.school_dw_id
                                        AND
                                       ts.local_date BETWEEN TRUNC(dsc.academic_year_start_date) AND TRUNC(dsc.academic_year_end_date)
     ),
     cte_teachers AS (SELECT DISTINCT tt.local_date,
                                      tt.academic_year,
                                      tt.week_year_number,
                                      tt.week_number,
                                      tt.month_year_number,
                                      tt.tenant_name,
                                      tt.school_dw_id,
                                      tt.school_id,
                                      tt.org_dw_id,
                                      tt.school_organisation,
                                      tt.school_city_name,
                                      tt.school_country_name,
                                      tt.school_name,
                                      tt.total_teachers
                      FROM bi_alefdw.total_teachers as tt
                               JOIN bi_alefdw.bi_active_schools_dim_mv as dsc
                                    ON dsc.school_dw_id = tt.school_dw_id
                                        AND
                                       tt.local_date BETWEEN TRUNC(dsc.academic_year_start_date) AND TRUNC(dsc.academic_year_end_date)
     ),
     certificates AS (SELECT DISTINCT fsca.*,
                                      dd.local_date,
                                      dst.student_special_needs,
                                      dst.student_tags,
                                      dg.grade_k12grade,
                                      dsc.school_dw_id,
                                      dsc.school_id,
                                      dsc.school_name,
                                      dsc.tenant_name,
                                      dsc.school_organisation,
                                      dsc.organisation_dw_id,
                                      dsc.school_city_name,
                                      dsc.school_country_name,
                                      ds.section_dw_id,
                                      dc.class_title,
                                      dc.class_material_type,
                                      ds.section_name,
                                      dt.teacher_id,
                                      dsc.academic_year_id,
                                      dsc.academic_year_start_date,
                                      dsc.academic_year_end_date,
                                      DATE_PART(year, dsc.academic_year_start_date) || '-' ||
                                      DATE_PART(year, dsc.academic_year_end_date) AS academic_year
                      FROM alefdw.fact_student_certificate_awarded as fsca
                               JOIN bi_alefdw.bi_student_dim_mv as dst
                                    ON dst.student_dw_id = fsca.fsca_student_dw_id
                                        AND dst.student_status = 1
                               JOIN alefdw.dim_grade as dg
                                    ON dg.grade_dw_id = fsca.fsca_grade_dw_id
                                        AND dg.grade_status = 1
                               JOIN bi_alefdw.bi_active_schools_dim_mv as dsc
                                    ON dsc.school_dw_id = dst.student_school_dw_id
                               JOIN alefdw.dim_class as dc
                                    on dc.class_dw_id = fsca.fsca_class_dw_id
                                        AND dc.class_status = 1
                               JOIN alefdw.dim_section as ds
                                    ON dst.student_section_dw_id = ds.section_dw_id
                                        AND ds.section_status = 1
                               JOIN alefdw.dim_teacher as dt
                                    ON fsca.fsca_teacher_dw_id = dt.teacher_dw_id
                                        AND dt.teacher_status = 1
                                        AND dt.teacher_active_until IS NULL
                                        AND dt.teacher_id NOT IN
                                            (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
                               JOIN date_dimension as dd
                                    ON TRUNC(CONVERT_TIMEZONE('UTC', dsc.tenant_timezone, fsca.fsca_created_time)) = dd.local_date
WHERE dd.local_date BETWEEN TRUNC(dsc.academic_year_start_date) AND TRUNC(dsc.academic_year_end_date)
)

SELECT DISTINCT COALESCE(ts.local_date, tt.local_date, fsca.local_date)                   AS local_date,
                COALESCE(ts.month_year_number, tt.month_year_number)                      as month_year_number,
                COALESCE(ts.week_number, tt.week_number)                                  as week_number,
                COALESCE(ts.week_year_number, tt.week_year_number)                        as week_year_number,
                fsca.fsca_dw_id,
                fsca.fsca_certificate_id,
                fsca.fsca_student_dw_id,
                COALESCE(ts.student_special_needs, fsca.student_special_needs)            as student_special_needs,
                COALESCE(ts.student_tags, fsca.student_tags)                              as student_tags,
                fsca.fsca_award_category,
                fsca.fsca_language,
                COALESCE(ts.school_dw_id, tt.school_dw_id, fsca.school_dw_id)             as school_dw_id,
                COALESCE(ts.school_id, tt.school_id, fsca.school_id)                      as school_id,
                COALESCE(ts.school_name, tt.school_name, fsca.school_name)                as school_name,
                COALESCE(ts.tenant_name, tt.tenant_name, fsca.tenant_name)                as tenant_name,
                COALESCE(ts.org_dw_id, tt.org_dw_id, fsca.organisation_dw_id)             as organisation_dw_id,
                COALESCE(ts.school_organisation, tt.school_organisation,
                         fsca.school_organisation)                                        as school_organisation,
                COALESCE(ts.school_city_name, tt.school_city_name, fsca.school_city_name) as school_city_name,
                COALESCE(ts.school_country_name, tt.school_country_name,
                         fsca.school_country_name)                                        as school_country_name,
                COALESCE(ts.grade, fsca.grade_k12grade)                                   as grade_k12grade,
                fsca.fsca_class_dw_id,
                fsca.class_title,
                fsca.class_material_type,
                ts.total_students,
                COALESCE(ts.section_dw_id, fsca.section_dw_id)                            as section_dw_id,
                COALESCE(ts.section, fsca.section_name)                                   as section_name,
                fsca.teacher_id,
                fsca.fsca_teacher_dw_id,
                tt.total_teachers,
                fsca.academic_year_id,
                fsca.academic_year_start_date,
                fsca.academic_year_end_date,
                COALESCE(ts.academic_year, tt.academic_year, fsca.academic_year)          AS academic_year
FROM cte_students as ts FULL JOIN cte_teachers AS tt
    ON ts.local_date = tt.local_date
    AND ts.school_dw_id = tt.school_dw_id
FULL JOIN certificates AS fsca
    ON COALESCE(ts.local_date, tt.local_date) = fsca.local_date
    AND COALESCE(ts.school_dw_id, tt.school_dw_id) = fsca.school_dw_id
    AND ts.section_dw_id = fsca.section_dw_id
    AND ts.student_tags = fsca.student_tags
    AND ts.student_special_needs = fsca.student_special_needs
WITH NO SCHEMA BINDING;
