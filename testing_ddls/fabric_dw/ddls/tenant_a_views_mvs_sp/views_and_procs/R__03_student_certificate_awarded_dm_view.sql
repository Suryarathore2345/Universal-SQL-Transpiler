CREATE OR ALTER VIEW ${os_bi_coredw}.student_certificate_awarded_dm_view
AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date                 AS local_date,
        calendar_week_number      AS week_num,
        calendar_year_week_number AS wy_num
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date >= DATEADD(DAY, -365, CONVERT(DATE, GETDATE()))
      AND dt.full_date <= CONVERT(DATE, GETDATE())
),

cte_students AS (
    SELECT DISTINCT
        ts.local_date,
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
    FROM ${rs_bi_coredw}.total_students ts
    JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = ts.school_dw_id
       AND ts.local_date BETWEEN
           CONVERT(DATE, dsc.academic_year_start_date)
           AND CONVERT(DATE, dsc.academic_year_end_date)
),

cte_teachers AS (
    SELECT DISTINCT
        tt.local_date,
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
    FROM ${rs_bi_coredw}.total_teachers tt
    JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = tt.school_dw_id
       AND tt.local_date BETWEEN
           CONVERT(DATE, dsc.academic_year_start_date)
           AND CONVERT(DATE, dsc.academic_year_end_date)
),

certificates AS (
    SELECT DISTINCT
        fsca.fsca_dw_id,
        fsca.fsca_certificate_id,
        fsca.fsca_student_dw_id,
        fsca.fsca_award_category,
        fsca.fsca_language,
        fsca.fsca_class_dw_id,
        fsca.fsca_teacher_dw_id,
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
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year
    FROM ${rs_coredw}.fact_student_certificate_awarded fsca
    JOIN ${rs_bi_coredw}.bi_student_dim dst
        ON dst.student_dw_id = fsca.fsca_student_dw_id
       AND dst.student_status = 1
    JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = fsca.fsca_grade_dw_id
       AND dg.grade_status = 1
    JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = dst.student_school_dw_id

    JOIN ${rs_coredw}.dim_class dc
        ON dc.class_dw_id = fsca.fsca_class_dw_id
       AND dc.class_status = 1
    JOIN ${rs_coredw}.dim_section ds
        ON dst.student_section_dw_id = ds.section_dw_id
       AND ds.section_status = 1
    JOIN ${rs_coredw}.dim_teacher dt
        ON fsca.fsca_teacher_dw_id = dt.teacher_dw_id
       AND dt.teacher_status = 1
       AND dt.teacher_active_until IS NULL
       AND NOT EXISTS (SELECT 1 FROM ${rs_bi_coredw}.exclude_teacher_id excl WHERE excl.teacher_id = dt.teacher_id)  -- OPT-8
    JOIN date_dimension dd
        ON CONVERT(
            DATE,
            CONVERT(DATETIME2, fsca.fsca_created_time)
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
        ) = dd.local_date
    WHERE dd.local_date BETWEEN
        CONVERT(DATE, dsc.academic_year_start_date)
        AND CONVERT(DATE, dsc.academic_year_end_date)
)

SELECT DISTINCT
    COALESCE(ts.local_date, tt.local_date, fsca.local_date) AS local_date,
    ISNULL(ts.month_year_number, tt.month_year_number)   AS month_year_number,
    ISNULL(ts.week_number, tt.week_number)               AS week_number,
    ISNULL(ts.week_year_number, tt.week_year_number)     AS week_year_number,

    fsca.fsca_dw_id,
    fsca.fsca_certificate_id,
    fsca.fsca_student_dw_id,

    ISNULL(
        ts.student_special_needs,
        fsca.student_special_needs
    ) AS student_special_needs,

    ISNULL(
        ts.student_tags,
        fsca.student_tags
    ) AS student_tags,

    fsca.fsca_award_category,
    fsca.fsca_language,

    COALESCE(ts.school_dw_id, tt.school_dw_id, fsca.school_dw_id) AS school_dw_id,

    COALESCE(
        ts.school_id,
        tt.school_id,
        fsca.school_id
    ) AS school_id,

    COALESCE(
        ts.school_name,
        tt.school_name,
        fsca.school_name
    ) AS school_name,

    COALESCE(
        ts.tenant_name,
        tt.tenant_name,
        fsca.tenant_name
    ) AS tenant_name,

    COALESCE(ts.org_dw_id, tt.org_dw_id, fsca.organisation_dw_id) AS organisation_dw_id,

    COALESCE(
        ts.school_organisation,
        tt.school_organisation,
        fsca.school_organisation
    ) AS school_organisation,

    COALESCE(
        ts.school_city_name,
        tt.school_city_name,
        fsca.school_city_name
    ) AS school_city_name,

    COALESCE(
        ts.school_country_name,
        tt.school_country_name,
        fsca.school_country_name
    ) AS school_country_name,

    ISNULL(ts.grade, fsca.grade_k12grade) AS grade_k12grade,

    fsca.fsca_class_dw_id,
    fsca.class_title,
    fsca.class_material_type,

    ts.total_students,

    ISNULL(ts.section_dw_id, fsca.section_dw_id) AS section_dw_id,

    ISNULL(
        ts.section,
        fsca.section_name
    ) AS section_name,

    fsca.teacher_id,
    fsca.fsca_teacher_dw_id,

    tt.total_teachers,

    fsca.academic_year_id,
    fsca.academic_year_start_date,
    fsca.academic_year_end_date,

    COALESCE(
        ts.academic_year,
        tt.academic_year,
        fsca.academic_year
    ) AS academic_year
FROM cte_students ts
FULL JOIN cte_teachers tt
    ON ts.local_date = tt.local_date
   AND ts.school_dw_id = tt.school_dw_id
FULL JOIN certificates fsca
    ON ISNULL(ts.local_date, tt.local_date) = fsca.local_date
   AND ISNULL(ts.school_dw_id, tt.school_dw_id) = fsca.school_dw_id
   AND ts.section_dw_id = fsca.section_dw_id
   AND ts.student_tags = fsca.student_tags
   AND ts.student_special_needs = fsca.student_special_needs;
