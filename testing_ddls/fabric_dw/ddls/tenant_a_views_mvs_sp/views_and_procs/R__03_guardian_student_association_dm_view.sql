CREATE OR ALTER VIEW ${os_bi_coredw}.guardian_student_association_dm_view AS

SELECT DISTINCT
    dg.guardian_dw_id,
    dg.guardian_student_dw_id,
    ds.student_id,
    ds.student_adek_id,
    dsc.school_dw_id,
    dsc.school_id,
    dsc.school_name,
    dsc.school_city_name,
    dsc.school_country_name,
    dsc.school_composition,
    dsc.school_organisation,
    dsc.organisation_dw_id,
    dsc.tenant_name,
    dtn.tenant_dw_id,
    ds.grade_k12grade,
    ds.grade_dw_id,
    ds.section_dw_id,
    ds.section_name,
    ds.student_special_needs,
    ds.student_tags,
    dsc.school_label,
    ts.total_students,
    dgu.guardian_association_date,
    FIRST_VALUE(dg.guardian_created_time) OVER (
        PARTITION BY dg.guardian_dw_id
        ORDER BY dg.guardian_created_time
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS guardian_registered_date
FROM ${rs_coredw}.dim_guardian dg
INNER JOIN (
    SELECT DISTINCT
        bst.student_dw_id,
        bst.student_id,
        bst.student_username AS student_adek_id,
        bst.student_school_dw_id,
        bst.student_special_needs,
        bst.student_tags,
        grd.grade_dw_id,
        grd.grade_k12grade,
        dse.section_dw_id,
        dse.section_name
    FROM ${rs_bi_coredw}.bi_student_dim bst
    JOIN ${rs_coredw}.dim_grade grd
        ON bst.student_grade_dw_id = grd.grade_dw_id
    INNER JOIN ${rs_coredw}.dim_section dse
        ON bst.student_section_dw_id = dse.section_dw_id
       AND grd.grade_id = dse.grade_id
    WHERE bst.student_status = 1
) ds
    ON ds.student_dw_id = dg.guardian_student_dw_id
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
    ON dsc.school_dw_id = ds.student_school_dw_id
INNER JOIN (
    SELECT DISTINCT
        school_dw_id,
        SUM(total_students) AS total_students
    FROM ${rs_bi_coredw}.total_students
    WHERE local_date = CONVERT(DATE, DATEADD(day, -1, GETDATE()))
    GROUP BY school_dw_id
) ts
    ON ds.student_school_dw_id = ts.school_dw_id
INNER JOIN (
    SELECT DISTINCT
        guardian_dw_id,
        guardian_student_dw_id,
        FIRST_VALUE(guardian_created_time) OVER (
            PARTITION BY guardian_dw_id, guardian_student_dw_id
            ORDER BY guardian_created_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS guardian_association_date
    FROM ${rs_coredw}.dim_guardian
    WHERE guardian_invitation_status = 2
      AND guardian_student_dw_id IS NOT NULL
) dgu
    ON dgu.guardian_dw_id = dg.guardian_dw_id
   AND dgu.guardian_student_dw_id = dg.guardian_student_dw_id
INNER JOIN ${rs_coredw}.dim_tenant dtn
    ON dtn.tenant_id = dsc.tenant_id
WHERE dg.guardian_status = 1;
