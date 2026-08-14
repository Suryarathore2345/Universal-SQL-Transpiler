CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.pathway_class_agg_dm_view AS
WITH fact_pathway_activity_completed_last AS (  -- to take latest attempt of completed activity
    SELECT
        CONVERT(DATE, t.fpac_created_time) AS activity_date,
        t.fpac_course_dw_id,
        t.fpac_student_dw_id,
        COUNT(DISTINCT CASE WHEN t.fpac_activity_type = 1 THEN t.fpac_activity_dw_id END) AS activity_completed_count
    FROM (
        SELECT
            fpac.fpac_created_time,
            fpac.fpac_course_dw_id,
            fpac.fpac_student_dw_id,
            fpac.fpac_activity_type,
            fpac.fpac_activity_dw_id,
            fpac.fpac_attempt,
            ROW_NUMBER() OVER (
                PARTITION BY fpac.fpac_student_dw_id, fpac.fpac_activity_dw_id
                ORDER BY fpac.fpac_attempt DESC
            ) AS rank
        FROM ${RS_COREDW}.fact_pathway_activity_completed fpac
        INNER JOIN ${RS_COREDW}.dim_course_activity_association dccaa
            ON dccaa.caa_activity_dw_id = fpac.fpac_activity_dw_id
           AND dccaa.caa_status = 1
    ) t
    WHERE t.rank = 1
    GROUP BY
        CONVERT(DATE, t.fpac_created_time),
        t.fpac_course_dw_id,
        t.fpac_student_dw_id
),

level_test_score AS (
    SELECT
        t.fpac_student_dw_id,
        t.fpac_course_activity_container_dw_id,
        SUM(CASE WHEN t.fpac_activity_type = 2 AND t.fpac_score > 60 THEN t.fpac_score END) AS fpac_score
    FROM (
        SELECT
            fpac.fpac_student_dw_id,
            fpac.fpac_course_activity_container_dw_id,
            fpac.fpac_activity_type,
            fpac.fpac_score,
            fpac.fpac_activity_dw_id,
            fpac.fpac_attempt,
            ROW_NUMBER() OVER (
                PARTITION BY fpac.fpac_student_dw_id, fpac.fpac_activity_dw_id
                ORDER BY fpac.fpac_attempt DESC
            ) AS rank
        FROM ${RS_COREDW}.fact_pathway_activity_completed fpac
        INNER JOIN ${RS_COREDW}.dim_course_activity_association dccaa
            ON dccaa.caa_activity_dw_id = fpac.fpac_activity_dw_id
           AND dccaa.caa_status = 1
    ) t
    WHERE t.rank = 1
    GROUP BY
        t.fpac_student_dw_id,
        t.fpac_course_activity_container_dw_id
),

fact_pathway_levels_completed_last AS (
    SELECT
        CONVERT(DATE, flcl.flc_created_time) AS activity_date,
        flcl.flc_course_dw_id,
        flcl.flc_student_dw_id,
        COUNT(DISTINCT flcl.flc_course_activity_container_dw_id) AS level_completed_count,
        COUNT(DISTINCT CASE WHEN flcl.flc_score IS NOT NULL THEN flcl.flc_course_activity_container_dw_id END)
            AS level_completed_count_ic,
        SUM(lts.fpac_score) AS total_score
    FROM (
        SELECT
            flc.flc_created_time,
            flc.flc_course_dw_id,
            flc.flc_student_dw_id,
            flc.flc_course_activity_container_dw_id,
            flc.flc_score,
            ROW_NUMBER() OVER (
                PARTITION BY flc.flc_student_dw_id, flc.flc_course_activity_container_dw_id
                ORDER BY flc.flc_created_time DESC
            ) AS rank
        FROM ${RS_COREDW}.fact_level_completed flc
    ) flcl
    LEFT JOIN level_test_score lts
        ON flcl.flc_student_dw_id = lts.fpac_student_dw_id
       AND flcl.flc_course_activity_container_dw_id = lts.fpac_course_activity_container_dw_id
    WHERE flcl.rank = 1
    GROUP BY
        CONVERT(DATE, flcl.flc_created_time),
        flcl.flc_course_dw_id,
        flcl.flc_student_dw_id
),

combined_fact_metrics AS (
    SELECT
        activity_date,
        fpac_course_dw_id AS course_dw_id,
        fpac_student_dw_id AS student_dw_id,
        activity_completed_count,
        NULL AS level_completed_count,
        NULL AS level_completed_count_ic,
        NULL AS total_score
    FROM fact_pathway_activity_completed_last

    UNION ALL

    SELECT
        activity_date,
        flc_course_dw_id AS course_dw_id,
        flc_student_dw_id AS student_dw_id,
        NULL AS activity_completed_count,
        level_completed_count,
        level_completed_count_ic,
        total_score
    FROM fact_pathway_levels_completed_last
),

pathway_class_total_students AS (
    SELECT
        dsc.school_dw_id,
        dsc.school_id,
        dsc.school_name,
        dsc.tenant_id,
        dsc.tenant_name,
        dsc.organisation_dw_id,
        dsc.school_organisation,
        dsc.school_composition,
        dsc.windows_timezone,
        dsc.academic_year_start_date,
        dcu.class_user_user_dw_id AS pathway_student_dw_id,
        dc.class_dw_id,
        dc.class_title,
        CASE
            WHEN dsec.section_name IS NULL THEN 'NA'
            ELSE UPPER(dsec.section_name)
        END AS class_section_name,
        ds.student_grade_dw_id,
        ds.student_special_needs,
        ds.student_id,
        dg.grade_name,
        dc.class_material_id,
        CASE
            WHEN dcsa.cs_subject_dw_id = 129 THEN 'Arabits'
            ELSE dc.class_gen_subject
        END AS curr_subject_name,
        DATEPART(year, dsc.academic_year_end_date) AS academic_year_end_year
    FROM ${RS_COREDW}.dim_class dc
    INNER JOIN ${RS_COREDW}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dc.class_school_id = dsc.school_id
    INNER JOIN ${RS_BI_COREDW}.bi_student_dim ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
       AND dsc.school_dw_id = ds.student_school_dw_id
       AND ds.student_status = 1
    INNER JOIN ${RS_COREDW}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
       AND dg.academic_year_id = dsc.academic_year_id
       AND dg.grade_status = 1
    LEFT JOIN ${RS_COREDW}.dim_course_subject_association dcsa
        ON dcsa.cs_course_id = dc.class_material_id
       AND dcsa.cs_status = 1
       AND dcsa.cs_subject_dw_id = 129
    LEFT JOIN ${RS_COREDW}.dim_section dsec
        ON dsec.section_id = dc.class_section_id
    WHERE dcu.class_user_status = 1
      AND dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND dc.class_course_status = 'ACTIVE'
      AND dc.class_material_type = 'PATHWAY'
      AND dc.class_status = 1
)

SELECT
    pcts.school_id,
    pcts.school_name,
    pcts.grade_name,
    pcts.class_dw_id,
    pcts.class_title,
    pcts.class_section_name,
    pcts.curr_subject_name,
    cfm.activity_date,
    SUM(cfm.activity_completed_count) AS activity_completed_count,
    SUM(cfm.total_score) AS total_score,
    SUM(cfm.level_completed_count) AS level_completed_count,
    SUM(cfm.level_completed_count) AS level_completed_count_ic
FROM pathway_class_total_students pcts
LEFT JOIN ${RS_COREDW}.dim_course dcr
    ON pcts.class_material_id = dcr.course_id
   AND dcr.course_status = 1
   AND dcr.course_type = 'PATHWAY'
LEFT JOIN combined_fact_metrics cfm
    ON cfm.student_dw_id = pcts.pathway_student_dw_id
   AND cfm.course_dw_id = dcr.course_dw_id
   AND cfm.activity_date >= pcts.academic_year_start_date
   AND cfm.activity_date < CONVERT(DATE, GETDATE())
GROUP BY
    pcts.school_id,
    pcts.school_name,
    pcts.grade_name,
    pcts.class_dw_id,
    pcts.class_title,
    pcts.class_section_name,
    pcts.curr_subject_name,
    cfm.activity_date;