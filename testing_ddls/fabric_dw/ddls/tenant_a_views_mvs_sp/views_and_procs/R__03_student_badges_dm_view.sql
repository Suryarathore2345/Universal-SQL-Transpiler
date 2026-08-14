CREATE OR ALTER VIEW ${os_bi_coredw}.student_badges_dm_view
AS
WITH section_total_students AS ( -- to take section total students
    SELECT
        sc.school_dw_id,
        dg.grade_k12grade,
        dg.grade_dw_id,
        ISNULL(dse.section_dw_id, '10001') AS section_dw_id,
        UPPER(ISNULL(dse.section_name, 'NA')) AS section_name,
        dg.grade_name,
        COUNT(DISTINCT ds.student_dw_id) AS section_total_students
    FROM ${rs_coredw}.dim_section AS dse
    JOIN ${rs_bi_coredw}.bi_active_schools_dim AS sc
        ON dse.school_id = sc.school_id
    JOIN ${rs_bi_coredw}.bi_student_dim AS ds
        ON sc.school_dw_id = ds.student_school_dw_id
       AND ds.student_section_dw_id = dse.section_dw_id
    JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
    WHERE ds.student_status = 1
      AND dse.section_status = 1
    GROUP BY
        sc.school_dw_id,
        dg.grade_k12grade,
        dg.grade_dw_id,
        ISNULL(dse.section_dw_id, '10001'),
        ISNULL(dse.section_name, 'NA'),
        dg.grade_name
),
earned_badges AS ( -- to take latest attempt of earned badge activity
        SELECT
            dd.full_date AS local_date,
            fba_dw_id,
            fba_id,
            fba_badge_dw_id,
            fba_student_dw_id,
            fba_school_dw_id,
            fba_grade_dw_id,
            fba_section_dw_id,
            fba_tenant_dw_id,
            fba_academic_year_dw_id,
            fba_content_repository_dw_id,
            fba_organization_dw_id,
            fba_date_dw_id
        FROM ${rs_coredw}.fact_badge_awarded AS fba
        JOIN ${rs_coredw}.dim_date AS dd
            ON fba.fba_date_dw_id = dd.date_id
        JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
            ON fba.fba_school_dw_id = dsc.school_dw_id
           AND fba.fba_created_time >= CONVERT(DATETIME2, dsc.academic_year_start_date)
           AND fba.fba_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, dsc.academic_year_end_date)) 
)
SELECT DISTINCT
    eb.local_date,
    db.bdg_dw_id,
    db.bdg_id,
    db.bdg_grade,
    db.bdg_title,
    db.bdg_tier,
    db.bdg_type,
    db.bdg_category,
    db.bdg_tenant_dw_id,
    db.bdg_threshold,
    eb.fba_student_dw_id,
    dst.student_id,
    dsc.tenant_name,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_alias AS school_adek_id,
    dsc.school_country_name,
    dsc.school_city_name,
    dsc.school_label,
    dsc.school_organisation AS organisation_name,
    dsc.school_latitude,
    dsc.school_longitude,
    dg.grade_k12grade AS grade,
    dg.grade_dw_id,
    dst.student_section_dw_id,
    sts.section_total_students,
    sts.section_name,
    dsc.academic_year_start_date,
    dsc.academic_year_end_date,
    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_start_date)) + '-' +
    CONVERT(VARCHAR(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year
FROM earned_badges AS eb
INNER JOIN ${rs_coredw}.dim_badge AS db
    ON db.bdg_dw_id = eb.fba_badge_dw_id
   AND db.bdg_status IN (1,2)
INNER JOIN ${rs_bi_coredw}.bi_student_dim AS dst
    ON dst.student_dw_id = eb.fba_student_dw_id
   AND dst.student_status = 1
   AND dst.student_active_until IS NULL
INNER JOIN section_total_students AS sts
    ON sts.school_dw_id = dst.student_school_dw_id
   AND sts.grade_dw_id = dst.student_grade_dw_id
   AND sts.section_dw_id = ISNULL(dst.student_section_dw_id, '10001')
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
    ON dsc.school_dw_id        = eb.fba_school_dw_id
   AND dsc.academic_year_dw_id = eb.fba_academic_year_dw_id
   AND dst.student_school_dw_id = dsc.school_dw_id
INNER JOIN ${rs_coredw}.dim_grade AS dg
    ON dg.grade_dw_id  = eb.fba_grade_dw_id
   AND dg.grade_status = 1
   AND dg.school_id = dsc.school_id;
