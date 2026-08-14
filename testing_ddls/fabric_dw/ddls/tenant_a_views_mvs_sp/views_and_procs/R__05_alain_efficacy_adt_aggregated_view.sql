CREATE OR ALTER VIEW ${os_bi_coredw}.alain_efficacy_adt_aggregated_view
AS
WITH max_ay AS (
    SELECT MAX(academicyear) AS max_ay_adt
    FROM ${rs_bi_coredw}.adt_student_report_detail_dm_view
)
SELECT
    tenant_name,
    school_organisation,
    school_name,
    school_dw_id,
    class_gen_subject,
    CONVERT(VARCHAR(50), grade) AS grade,
    academicyear,
    test_order,
    fasr_student_dw_id,
    fasr_final_grade,
    fasr_created_date,
    fasr_total_time_spent,
    CONVERT(VARCHAR(4), academic_year - 1) + ' - ' + CONVERT(VARCHAR(4), academic_year) AS formatted_ay
FROM ${rs_bi_coredw}.adt_student_report_detail_dm_view sr
JOIN max_ay m ON 1=1
WHERE sr.academicyear IN (m.max_ay_adt, m.max_ay_adt - 1)
  AND test_order IS NOT NULL
  AND school_city_name = 'Al Ain';
