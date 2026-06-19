CREATE OR REPLACE VIEW bi_alefdw_dev.alain_time_spent_view AS
With max_ay AS (select max(academicyear) max_ay_adt FROM bi_alefdw.adt_student_report_detail_dm_view),
     core_courses AS (SELECT fes.local_date,
                             fes.school_dw_id,
                             fes.school_name,
                             fes.school_city_name,
                             fes.tenant_name,
                             fes.school_organisation,
                             fes.grade_name,
                             UPPER(fes.class_gen_subject) AS class_gen_subject,
                             DATE_PART_YEAR(sch.academic_year_start_date) || ' - ' ||
                             DATE_PART_YEAR(sch.academic_year_end_date) AS academic_year,
                             DATE_PART_YEAR(sch.academic_year_end_date)    ay_name,
                             fes.fle_student_dw_id                      AS student_dw_id,
                             fes.session_time -- already capped at 900 in silver MV
                      FROM bi_alefdw.fact_learning_experience_silver_mv fes
                               JOIN bi_alefdw.bi_all_schools_dim_mv sch
                                    ON fes.school_dw_id = sch.school_dw_id
                                        AND fes.local_date >= sch.academic_year_start_date
                                        AND fes.local_date <= sch.academic_year_end_date
                      WHERE fes.class_gen_subject IS NOT NULL
                        AND fes.class_gen_subject <> 'All'
                        AND lower(fes.school_city_name) = 'al ain'),
     interim_checkpoints
         AS (SELECT TRUNC(CONVERT_TIMEZONE('UTC', sch.tenant_timezone, fle.fle_created_time)) AS local_date,
                    sch.school_dw_id,
                    sch.school_name,
                    sch.school_city_name,
                    sch.tenant_name,
                    sch.school_organisation,
                    dg.grade_k12grade                                                         AS grade_name,
                    UPPER(dc.class_gen_subject)                                               AS class_gen_subject,
                    DATE_PART_YEAR(sch.academic_year_start_date) || ' - ' ||
                    DATE_PART_YEAR(sch.academic_year_end_date)                                AS academic_year,
                    DATE_PART_YEAR(sch.academic_year_end_date)                                   ay_name,
                    fle.fle_student_dw_id                                                     AS student_dw_id,
                    SUM(CASE
                            WHEN fle.fle_total_time <= 1200 THEN fle.fle_total_time
                            WHEN fle.fle_total_time > 1200 THEN 1200
                            ELSE 0
                        END)                                                                  AS session_time
             FROM alefdw.fact_learning_experience fle
                      JOIN alefdw.dim_learning_objective lo
                           ON lo.lo_dw_id = fle.fle_lo_dw_id
                               AND lo.lo_status = 1
                      JOIN bi_alefdw.bi_all_schools_dim_mv sch
                           ON fle.fle_school_dw_id = sch.school_dw_id
                               AND date(fle.fle_created_time) >= sch.academic_year_start_date
                               AND date(fle.fle_created_time) <= sch.academic_year_end_date
                      JOIN alefdw.dim_class dc
                           ON fle.fle_class_dw_id = dc.class_dw_id
                      JOIN alefdw.dim_grade dg
                           ON dg.grade_dw_id = fle.fle_grade_dw_id
             WHERE fle.fle_abbreviation <> 'NA'
               AND fle.fle_activity_type = 'INTERIM_CHECKPOINT'
               AND fle.fle_material_type <> 'PATHWAY'
               AND lower(sch.school_city_name) = 'al ain'
               AND fle.fle_ls_id NOT IN (SELECT DISTINCT fle_ls_id
                                         FROM alefdw.fact_learning_experience
                                         WHERE fle_state = 4)
             GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),
     adt_tests AS (SELECT DATE(fa.fasr_created_date)                AS local_date,
                          fa.school_dw_id,
                          fa.school_name,
                          fa.school_city_name,
                          fa.tenant_name,
                          fa.school_organisation,
                          fa.grade                                  AS grade_name,
                          UPPER(fa.class_gen_subject)               AS class_gen_subject,
                          academicyear - 1 || ' - ' || academicyear AS academic_year,
                          academicyear                              AS ay_name,
                          fa.fasr_student_dw_id                     AS student_dw_id,
                          fa.fasr_total_time_spent                  AS session_time -- already capped at 5400 in adt view
                   FROM bi_alefdw.adt_student_report_detail_dm_view fa
                   WHERE fa.fasr_total_time_spent IS NOT NULL
                     AND lower(school_city_name) = 'al ain'),

     all_activities AS (SELECT *
                        FROM core_courses
                        UNION ALL
                        SELECT *
                        FROM interim_checkpoints
                        UNION ALL
                        SELECT *
                        FROM adt_tests)
SELECT DATE_TRUNC('week', aa.local_date)::DATE               AS week_start_date,
       DATE_TRUNC('month', aa.local_date)::DATE              AS month_start_date,
       aa.school_dw_id,
       aa.school_name,
       aa.school_city_name,
       aa.tenant_name,
       aa.school_organisation,
       aa.grade_name,
       aa.class_gen_subject,
       aa.academic_year,
       aa.student_dw_id,
       SUM(aa.session_time)                                  AS session_time,
       COUNT(DISTINCT aa.local_date)                         AS active_days_in_week,
       ROUND(SUM(aa.session_time) / 60.0, 2)::numeric(10, 2) AS session_time_minutes
FROM all_activities aa
         JOIN max_ay m ON 1 = 1
WHERE ay_name IN (m.max_ay_adt - 1, m.max_ay_adt)
GROUP BY DATE_TRUNC('week', aa.local_date)::DATE,
         DATE_TRUNC('month', aa.local_date)::DATE,
         aa.school_dw_id,
         aa.school_name,
         aa.school_city_name,
         aa.tenant_name,
         aa.school_organisation,
         aa.grade_name,
         aa.class_gen_subject,
         aa.academic_year,
         aa.student_dw_id
WITH NO SCHEMA BINDING;