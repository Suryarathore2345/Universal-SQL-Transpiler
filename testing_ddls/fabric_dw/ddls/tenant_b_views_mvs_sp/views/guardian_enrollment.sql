CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.guardian_enrollment_p AS
SELECT DISTINCT
    ts.school_dw_id,
    ts.school_id,
    ts.school_name,
    ts.school_city_name,
    ts.school_country_name,
    ts.school_composition,
    ts.school_organisation,
    ts.tenant_name,
    ts.school_label,
    ts.grade,
    ts.section,
    ts.total_students,
    gre.guardian_dw_id,
    gre.guardian_student_dw_id,
    gre.student_special_needs,
    gre.student_tags,
    CONVERT(date, gre.guardian_registered_date) AS guardian_registered_date,
    CONVERT(date, gre.guardian_association_date) AS guardian_association_date
FROM (
    SELECT
        tst.local_date,
        tst.school_dw_id,
        tst.school_id,
        tst.school_name,
        tst.tenant_name,
        tst.school_city_name,
        tst.school_country_name,
        tst.school_composition,
        tst.school_organisation,
        tst.school_label,
        tst.grade,
        tst.section,
        tst.section_dw_id,
        SUM(tst.total_students) AS total_students
    FROM ${RS_BI_COREDW}.total_students tst
    WHERE tst.local_date = DATEADD(day, -1, CONVERT(date, GETDATE()))
      AND tst.academic_year <> ''
    GROUP BY
        tst.local_date,
        tst.school_dw_id,
        tst.school_id,
        tst.school_name,
        tst.tenant_name,
        tst.school_city_name,
        tst.school_country_name,
        tst.school_composition,
        tst.school_organisation,
        tst.school_label,
        tst.grade,
        tst.section,
        tst.section_dw_id
) ts
LEFT JOIN (
    SELECT
        dg.guardian_dw_id,
        dg.guardian_student_dw_id,
        dsc.school_dw_id,
        dsc.school_id,
        dsc.school_name,
        dsc.school_city_name,
        dsc.school_country_name,
        dsc.school_composition,
        dsc.school_organisation,
        dsc.tenant_name,
        ds.student_special_needs,
        ds.student_tags,
        ds.student_grade_dw_id,
        dsc.school_label,
        ds.student_section_dw_id,
        dgu.guardian_association_date,
        -- first created time per guardian (registered date)
        FIRST_VALUE(dg.guardian_created_time) OVER (
            PARTITION BY dg.guardian_dw_id
            ORDER BY dg.guardian_created_time ASC
        ) AS guardian_registered_date
    FROM ${RS_COREDW}.dim_guardian dg
    INNER JOIN (
        SELECT DISTINCT
            st.student_dw_id,
            st.student_school_dw_id,
            st.student_special_needs,
            st.student_grade_dw_id,
            st.student_tags,
            st.student_section_dw_id
        FROM ${RS_BI_COREDW}.bi_student_dim st
        WHERE st.student_status = 1
          AND st.student_school_dw_id NOT IN (1283,1287,84,88,360,369,160,152,352,354,132,11,1809,3542)
    ) ds
        ON ds.student_dw_id = dg.guardian_student_dw_id
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = ds.student_school_dw_id
    LEFT JOIN (
        SELECT DISTINCT
            guardian_dw_id,
            guardian_student_dw_id,
            FIRST_VALUE(guardian_created_time) OVER (
                PARTITION BY guardian_dw_id, guardian_student_dw_id
                ORDER BY guardian_created_time ASC
            ) AS guardian_association_date
        FROM ${RS_COREDW}.dim_guardian
        WHERE guardian_invitation_status = 2
          AND guardian_status = 1
          AND guardian_student_dw_id IS NOT NULL
    ) dgu
        ON dgu.guardian_dw_id = dg.guardian_dw_id
       AND dgu.guardian_student_dw_id = dg.guardian_student_dw_id
    WHERE dg.guardian_status = 1
      AND ds.student_school_dw_id NOT IN (1283,1287,84,88,360,369,160,152,352,354,132,11,1809,3542)
) gre
    ON ts.school_dw_id = gre.school_dw_id
   AND ts.section_dw_id = gre.student_section_dw_id;
