CREATE OR REPLACE VIEW bi_alefdw_dev.student_activity_hourly_log_dm_view AS
WITH current_ay_grade AS (SELECT grade_k12grade, grade_dw_id
                          FROM alefdw.dim_grade
                          WHERE academic_year_id IN (SELECT academic_year_id
                                                     FROM bi_alefdw.bi_active_schools_dim_mv)
),
     converted_fsta
         AS (SELECT fsta.fsta_created_time,
                    fsta.fsta_tenant_dw_id,
                    fsta.fsta_school_dw_id,
                    fsta.fsta_student_dw_id,
                    fsta.fsta_grade_dw_id,
                    gr.grade_k12grade,
                    CONVERT_TIMEZONE('UTC', t.tenant_timezone, fsta.fsta_created_time) AS local_created_time
             FROM alefdw.fact_student_activities fsta
                      INNER JOIN alefdw.dim_tenant t
                                 ON t.tenant_dw_id = fsta.fsta_tenant_dw_id
                      INNER JOIN current_ay_grade gr
                                 ON fsta.fsta_grade_dw_id = gr.grade_dw_id)
SELECT TRUNC(fsta.local_created_time)             AS local_date,
       EXTRACT(HOUR FROM fsta.local_created_time) AS hour,
       DATE_PART(DOW, fsta.local_created_time)    AS dow,
       sch.school_dw_id,
       sch.school_name,
       sch.tenant_name,
       sch.school_organisation,
       sch.school_label,
       sch.school_country_name,
       sch.school_city_name,
       sch.school_composition,
       fsta.grade_k12grade,
       st.student_tags,
       st.student_special_needs,
       COUNT(1)                                   AS activities
FROM converted_fsta fsta
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv sch
                    ON fsta.fsta_school_dw_id = sch.school_dw_id
         INNER JOIN bi_alefdw.bi_student_dim_mv st
                    ON fsta.fsta_student_dw_id = st.student_dw_id
                        AND student_status = 1
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
WITH
NO SCHEMA BINDING;
