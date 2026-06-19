CREATE OR REPLACE VIEW bi_alefdw_dev.alain_adt_aggregated_view AS
With max_ay  AS (select max (academicyear) as max_ay_adt FROM bi_alefdw_dev.adt_student_report_detail_dm_view )
SELECT       tenant_name,
             school_organisation,
             school_name,
             school_dw_id,
             class_gen_subject,
             grade::varchar,
             academicyear,
             test_order,
             fasr_student_dw_id,
             fasr_final_grade,
             fasr_created_date,
             fasr_total_time_spent,
             (academic_year - 1) ::varchar || ' - ' || academic_year::varchar AS formatted_ay
      FROM bi_alefdw_dev.adt_student_report_detail_dm_view sr
      JOIN max_ay m ON 1=1
      WHERE sr.academicyear IN (m.max_ay_adt, m.max_ay_adt - 1)
      and test_order is not null
        AND school_city_name = 'Al Ain'
WITH NO SCHEMA BINDING;