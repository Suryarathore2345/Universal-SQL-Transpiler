CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.pathway_activity_principal_dm_view AS
WITH fact_levels_recommended_last AS (
    SELECT
        fpta_created_time AS flr_created_time,
        fpta_course_dw_id AS flr_course_dw_id,
        fpta_class_dw_id AS flr_class_dw_id,
        fpta_student_dw_id AS flr_student_dw_id,
        fpta_course_activity_container_dw_id AS flr_course_activity_container_dw_id,
        fpta_activity_dw_id AS caa_activity_dw_id,
        fpta_activity_type AS caa_activity_type,
        CONVERT(bit, 0) AS caa_activity_is_optional,
        99 AS flr_recommendation_type
    FROM (
        SELECT
            fpta_created_time,
            fpta_course_dw_id,
            fpta_class_dw_id,
            fpta_student_dw_id,
            fpta_course_activity_container_dw_id,
            fpta_activity_dw_id,
            fpta_activity_type,
            fpta_action_name,
            ROW_NUMBER() OVER (
                PARTITION BY fpta_student_dw_id, fpta_activity_dw_id
                ORDER BY fpta_created_time DESC
            ) AS rn
        FROM ${RS_COREDW}.fact_pathway_teacher_activity
    ) fpta
    WHERE rn = 1
      AND fpta_action_name = 1
      AND NOT EXISTS (
          SELECT 1
          FROM ${RS_COREDW}.fact_levels_recommended flr2
          WHERE flr2.flr_course_activity_container_dw_id = fpta.fpta_course_activity_container_dw_id
            AND flr2.flr_student_dw_id = fpta.fpta_student_dw_id
      )

    UNION ALL

    SELECT
        flr_created_time,
        flr_course_dw_id,
        flr_class_dw_id,
        flr_student_dw_id,
        flr_course_activity_container_dw_id,
        caa_activity_dw_id,
        caa_activity_type,
        caa_activity_is_optional,
        flr_recommendation_type
    FROM (
        SELECT
            flr.flr_created_time,
            flr.flr_course_dw_id,
            flr.flr_class_dw_id,
            flr.flr_student_dw_id,
            flr.flr_course_activity_container_dw_id,
            flr.flr_recommendation_type,
            flr.flr_status,
            dccaa.caa_activity_dw_id,
            dccaa.caa_activity_type,
            dccaa.caa_activity_is_optional,
            ROW_NUMBER() OVER (
                PARTITION BY flr_student_dw_id, caa_activity_dw_id
                ORDER BY flr_created_time ASC
            ) AS rn
        FROM ${RS_COREDW}.fact_levels_recommended flr
        INNER JOIN ${RS_COREDW}.dim_course_activity_association dccaa
            ON dccaa.caa_container_dw_id = flr.flr_course_activity_container_dw_id
           AND dccaa.caa_status = 1
        WHERE flr_status = 1
    ) x
    WHERE rn = 1
),

fact_pathway_activity_completed_last AS (
    SELECT
        t.fpac_student_dw_id,
        t.fpac_activity_dw_id,
        t.fpac_course_dw_id,
        t.fpac_created_time,
        t.fpac_attempt
    FROM (
        SELECT
            fpac.fpac_student_dw_id,
            fpac.fpac_activity_dw_id,
            fpac.fpac_course_dw_id,
            fpac.fpac_created_time,
            fpac.fpac_attempt,
            ROW_NUMBER() OVER (
                PARTITION BY fpac_student_dw_id, fpac_activity_dw_id
                ORDER BY fpac_attempt DESC
            ) AS rn
        FROM ${RS_COREDW}.fact_pathway_activity_completed fpac
        INNER JOIN ${RS_COREDW}.dim_course_activity_association dccaa
            ON dccaa.caa_activity_dw_id = fpac.fpac_activity_dw_id
           AND dccaa.caa_status = 1
    ) t
    WHERE rn = 1
),

fact_learning_experience_last AS (
    SELECT
        z.fle_student_dw_id,
        z.fle_lo_dw_id,
        z.fle_created_time,
        z.fle_attempt,
        z.fle_total_score,
        z.calc_fle_total_time
    FROM (
        SELECT
            fle.fle_student_dw_id,
            fle.fle_lo_dw_id,
            fle.fle_created_time,
            fle.fle_attempt,
            fle.fle_total_score,
            fle.fle_total_time,
            fle.fle_lesson_category,
            SUM(
                CASE
                    WHEN fle_lesson_category = 'INTERIM_CHECKPOINT' THEN
                        CASE
                            WHEN fle_total_time <= 1200 THEN fle_total_time
                            WHEN fle_total_time > 1200 THEN 1200
                            ELSE 0
                        END
                    WHEN fle_lesson_category = 'INSTRUCTIONAL_LESSON' THEN
                        CASE
                            WHEN fle_total_time <= 900 THEN fle_total_time
                            WHEN fle_total_time > 900 THEN 900
                            ELSE 0
                        END
                END
            ) OVER (
                PARTITION BY CONVERT(date, fle_created_time),
                             fle_student_dw_id,
                             fle_lo_dw_id
            ) AS calc_fle_total_time,
            ROW_NUMBER() OVER (
                PARTITION BY fle_student_dw_id, fle_lo_dw_id
                ORDER BY fle_created_time DESC, fle_attempt DESC
            ) AS rn
        FROM ${RS_COREDW}.fact_learning_experience fle
        WHERE fle_material_type = 'PATHWAY'
          AND fle_lesson_category <> 'DIAGNOSTIC_TEST'
          AND fle_abbreviation <> 'NA'
    ) z
    WHERE rn = 1
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
        dsc.academic_year_end_date,
        dcu.class_user_user_dw_id AS pathway_student_dw_id,
        dc.class_dw_id,
        dc.class_title,
        UPPER(ISNULL(dsec.section_name, 'NA')) AS class_section_name,
        ds.student_grade_dw_id,
        ds.student_special_needs,
        ds.student_id,
        dg.grade_name,
        dc.class_material_id,
        CASE WHEN dcsa.cs_subject_dw_id = 129 THEN 'Arabits'
             ELSE dc.class_gen_subject END AS curr_subject_name,
        DATEPART(year, dsc.academic_year_end_date) AS academic_year_end_year
    FROM ${RS_COREDW}.dim_class dc
    INNER JOIN ${RS_COREDW}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim dsc
        ON dc.class_school_id = dsc.school_id
    INNER JOIN ${RS_BI_COREDW}.bi_student_dim ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
       AND ds.student_school_dw_id = dsc.school_dw_id
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
    pcts.tenant_id,
    pcts.tenant_name,
    pcts.organisation_dw_id,
    pcts.school_organisation,
    pcts.school_composition,
    pcts.school_dw_id,
    pcts.school_id,
    pcts.school_name,
    pcts.student_grade_dw_id,
    pcts.grade_name,
    pcts.class_dw_id,
    pcts.class_title,
    pcts.class_section_name,
    pcts.curr_subject_name,
    pcts.pathway_student_dw_id,
    pcts.student_id,
    pcts.student_special_needs,
    pcts.academic_year_start_date,
    pcts.academic_year_end_year,
    fle.fle_student_dw_id AS active_student_dw_id,
    dcr.course_dw_id AS pathway_dw_id,
    dcr.course_name AS pathway_name,
    dcr.course_lang_code AS pathway_lang_code,
    dcac.course_activity_container_dw_id AS pathway_level_dw_id,
    dcac.course_activity_container_domain AS pathway_level_domain,
    cacga.cacga_grade AS pathway_level_grade,
    flr.flr_class_dw_id,
    flr.caa_activity_dw_id AS plaa_activity_dw_id,
    flr.caa_activity_is_optional AS plaa_activity_is_optional,
    flr.flr_student_dw_id,
    flr.flr_created_time,
    flc.flc_course_activity_container_dw_id AS level_dw_id_completed,
    flc.flc_created_time AS level_completed_time,
    fle.calc_fle_total_time AS fle_total_time,
    fle.fle_total_score,
    CONVERT(date, fle.fle_created_time) AS fle_activity_date,
    CONVERT(datetime2, fle.fle_created_time AT TIME ZONE 'UTC'
        AT TIME ZONE ISNULL(pcts.windows_timezone, 'UTC')) AS fle_activity_time_local,
    CONVERT(date, fpac.fpac_created_time AT TIME ZONE 'UTC'
        AT TIME ZONE ISNULL(pcts.windows_timezone, 'UTC')) AS complted_activity_date_local,
    fpac.fpac_activity_dw_id,
    fle.fle_attempt,
    CASE flr.caa_activity_type
        WHEN 1 THEN 'ACTVITY'
        WHEN 2 THEN 'INTERIM_CHECKPOINT'
    END AS activity_type,
    flr.flr_recommendation_type
FROM pathway_class_total_students pcts
LEFT JOIN ${RS_COREDW}.dim_course dcr
    ON pcts.class_material_id = dcr.course_id
   AND dcr.course_status = 1
   AND dcr.course_type = 'PATHWAY'
LEFT JOIN fact_levels_recommended_last flr
    ON pcts.pathway_student_dw_id = flr.flr_student_dw_id
   AND dcr.course_dw_id = flr.flr_course_dw_id
LEFT JOIN ${RS_COREDW}.dim_course_activity_container dcac
    ON dcac.course_activity_container_course_id = dcr.course_id
   AND dcac.course_activity_container_dw_id = flr.flr_course_activity_container_dw_id
   AND dcac.course_activity_container_status = 1
LEFT JOIN ${RS_COREDW}.dim_course_activity_container_grade_association cacga
    ON cacga.cacga_container_dw_id = dcac.course_activity_container_dw_id
   AND cacga_status = 1
LEFT JOIN ${RS_COREDW}.fact_level_completed flc
    ON flc.flc_course_activity_container_dw_id = flr.flr_course_activity_container_dw_id
   AND flc.flc_student_dw_id = flr.flr_student_dw_id
LEFT JOIN fact_learning_experience_last fle
    ON fle.fle_student_dw_id = flr.flr_student_dw_id
   AND fle.fle_lo_dw_id = flr.caa_activity_dw_id
   AND CONVERT(date, fle.fle_created_time) >= pcts.academic_year_start_date
   AND CONVERT(date, fle.fle_created_time) < CONVERT(date, GETDATE())
LEFT JOIN fact_pathway_activity_completed_last fpac
    ON fpac.fpac_student_dw_id = flr.flr_student_dw_id
   AND fpac.fpac_activity_dw_id = flr.caa_activity_dw_id
   AND CONVERT(date, fpac.fpac_created_time) >= pcts.academic_year_start_date
   AND CONVERT(date, fpac.fpac_created_time) < CONVERT(date, GETDATE());