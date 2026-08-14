CREATE OR ALTER VIEW ${os_bi_coredw}.alain_time_spent_view
AS
WITH max_ay AS (
    SELECT MAX(academicyear) AS max_ay_adt
    FROM ${rs_bi_coredw}.adt_student_report_detail_dm_view
),
core_courses AS (
    SELECT
        fes.local_date,
        fes.school_dw_id,
        fes.school_name,
        fes.school_city_name,
        fes.tenant_name,
        fes.school_organisation,
        fes.grade_name,
        fes.class_gen_subject,
        CONVERT(VARCHAR(4), YEAR(sch.academic_year_start_date))
            + ' - ' +
        CONVERT(VARCHAR(4), YEAR(sch.academic_year_end_date)) AS academic_year,
        YEAR(sch.academic_year_end_date) AS ay_name,
        fes.fle_student_dw_id AS student_dw_id,
        fes.session_time
    FROM ${rs_bi_coredw}.fact_learning_experience_silver fes
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim sch
        ON fes.school_dw_id = sch.school_dw_id
       AND fes.local_date >= sch.academic_year_start_date
       AND fes.local_date <= sch.academic_year_end_date
    WHERE fes.class_gen_subject IS NOT NULL
      AND fes.class_gen_subject <> 'All'
      AND LOWER(fes.school_city_name) = 'al ain'
),

interim_checkpoints AS (
    SELECT
        CONVERT(DATE,
            fle.fle_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sch.windows_timezone, 'UTC')
        ) AS local_date,
        sch.school_dw_id,
        sch.school_name,
        sch.school_city_name,
        sch.tenant_name,
        sch.school_organisation,
        dg.grade_k12grade AS grade_name,
        dc.class_gen_subject,
        CONVERT(VARCHAR(4), YEAR(sch.academic_year_start_date))
            + ' - ' +
        CONVERT(VARCHAR(4), YEAR(sch.academic_year_end_date)) AS academic_year,
        YEAR(sch.academic_year_end_date) AS ay_name,
        fle.fle_student_dw_id AS student_dw_id,
        SUM(
            CASE
                WHEN fle.fle_total_time <= 1200 THEN fle.fle_total_time
                WHEN fle.fle_total_time > 1200 THEN 1200
                ELSE 0
            END
        ) AS session_time
    FROM ${rs_coredw}.fact_learning_experience fle
    INNER JOIN ${rs_coredw}.dim_learning_objective lo
        ON lo.lo_dw_id = fle.fle_lo_dw_id
       AND lo.lo_status = 1
    INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim sch
        ON fle.fle_school_dw_id = sch.school_dw_id
       AND CONVERT(DATE, fle.fle_created_time)
           BETWEEN sch.academic_year_start_date
               AND sch.academic_year_end_date
    INNER JOIN ${rs_coredw}.dim_class dc
        ON fle.fle_class_dw_id = dc.class_dw_id
    INNER JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = fle.fle_grade_dw_id
    WHERE fle.fle_abbreviation <> 'NA'
      AND fle.fle_activity_type = 'INTERIM_CHECKPOINT'
      AND fle.fle_material_type <> 'PATHWAY'
      AND LOWER(sch.school_city_name) = 'al ain'
      AND fle.fle_ls_id NOT IN (
            SELECT DISTINCT fle_ls_id
            FROM ${rs_coredw}.fact_learning_experience
            WHERE fle_state = 4
      )
    GROUP BY
        CONVERT(DATE,
            fle.fle_created_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(sch.windows_timezone, 'UTC')
        ),
        sch.school_dw_id,
        sch.school_name,
        sch.school_city_name,
        sch.tenant_name,
        sch.school_organisation,
        dg.grade_k12grade,
        dc.class_gen_subject,
        sch.academic_year_start_date,
        sch.academic_year_end_date,
        fle.fle_student_dw_id
),

adt_tests AS (
    SELECT
        CONVERT(DATE, fa.fasr_created_date) AS local_date,
        fa.school_dw_id,
        fa.school_name,
        fa.school_city_name,
        fa.tenant_name,
        fa.school_organisation,
        fa.grade AS grade_name,
        fa.class_gen_subject,
        CONVERT(VARCHAR(4), fa.academicyear - 1)
            + ' - ' +
        CONVERT(VARCHAR(4), fa.academicyear) AS academic_year,
        fa.academicyear AS ay_name,
        fa.fasr_student_dw_id AS student_dw_id,
        fa.fasr_total_time_spent AS session_time
    FROM ${rs_bi_coredw}.adt_student_report_detail_dm_view fa
    WHERE fa.fasr_total_time_spent IS NOT NULL
      AND LOWER(fa.school_city_name) = 'al ain'
),

all_activities AS (
    SELECT
        local_date,
        school_dw_id,
        school_name,
        school_city_name,
        tenant_name,
        school_organisation,
        grade_name,
        class_gen_subject,
        academic_year,
        ay_name,
        student_dw_id,
        session_time
    FROM core_courses
    UNION ALL
    SELECT
        local_date,
        school_dw_id,
        school_name,
        school_city_name,
        tenant_name,
        school_organisation,
        grade_name,
        class_gen_subject,
        academic_year,
        ay_name,
        student_dw_id,
        session_time
    FROM interim_checkpoints
    UNION ALL
    SELECT
        local_date,
        school_dw_id,
        school_name,
        school_city_name,
        tenant_name,
        school_organisation,
        grade_name,
        class_gen_subject,
        academic_year,
        ay_name,
        student_dw_id,
        session_time
    FROM adt_tests
)

SELECT
    CONVERT(DATE, DATETRUNC(ISO_WEEK, aa.local_date)) AS week_start_date,
    DATETRUNC(MONTH, aa.local_date) AS month_start_date,
    aa.school_dw_id,
    aa.school_name,
    aa.school_city_name,
    aa.tenant_name,
    aa.school_organisation,
    aa.grade_name,
    aa.class_gen_subject,
    aa.academic_year,
    aa.student_dw_id,
    SUM(aa.session_time) AS session_time,
    COUNT(DISTINCT aa.local_date) AS active_days_in_week,
    CONVERT(DECIMAL(10,2), ROUND(SUM(aa.session_time) / 60.0, 2))
        AS session_time_minutes
FROM all_activities aa
CROSS JOIN max_ay m
WHERE aa.ay_name IN (m.max_ay_adt - 1, m.max_ay_adt)
GROUP BY
    CONVERT(DATE, DATETRUNC(ISO_WEEK, aa.local_date)),
    DATETRUNC(MONTH, aa.local_date),
    aa.school_dw_id,
    aa.school_name,
    aa.school_city_name,
    aa.tenant_name,
    aa.school_organisation,
    aa.grade_name,
    aa.class_gen_subject,
    aa.academic_year,
    aa.student_dw_id;
