CREATE OR REPLACE VIEW bi_alefdw_dev.stars_awarded_dm_view AS
SELECT DISTINCT trunc(convert_timezone('UTC', dsc.tenant_timezone, fsa.fsa_created_time))                             AS local_date,
                dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_organisation,
                dsc.school_country_name,
                dsc.school_city_name,
                dg.grade_k12grade                                                                                     AS grade,
                initcap(COALESCE(dsu.subject_gen_subject, dc.class_gen_subject))                                      AS subject,
                ac.award_category_level_en                                                                            AS award_category,
                ds.student_tags,
                ds.student_special_needs,
                dsc.school_label,
                date_part(year, dsc.academic_year_start_date) || '-' ||
                date_part(year, dsc.academic_year_end_date)                                                          AS academic_year,
                count(distinct fsa.fsa_id)                                                                            AS stars_awarded
FROM alefdw.fact_star_awarded fsa
         JOIN bi_alefdw.bi_active_schools_dim_mv dsc
             ON dsc.school_dw_id = fsa.fsa_school_dw_id
             AND trunc(fsa.fsa_created_time) >= dsc.academic_year_start_date
             AND trunc(fsa.fsa_created_time) <= dsc.academic_year_end_date
         JOIN alefdw.dim_grade dg ON dg.grade_dw_id = fsa.fsa_grade_dw_id
    AND dg.grade_status <> 4
         JOIN bi_alefdw.bi_student_dim_mv ds ON ds.student_dw_id = fsa.fsa_student_dw_id
    AND ds.student_status <> 4
         JOIN alefdw.dim_award_category ac ON ac.award_category_dw_id = fsa.fsa_award_category_dw_id
         LEFT JOIN alefdw.dim_class dc ON dc.class_dw_id = fsa.fsa_class_dw_id
         LEFT JOIN alefdw.dim_subject dsu ON dsu.subject_dw_id = fsa.fsa_subject_dw_id
where class_status = 1
  and grade_status = 1
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
WITH NO SCHEMA BINDING;