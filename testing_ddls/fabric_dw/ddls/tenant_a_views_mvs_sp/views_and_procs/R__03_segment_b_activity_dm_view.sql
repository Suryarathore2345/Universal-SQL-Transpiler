CREATE OR ALTER VIEW ${os_bi_coredw}.pathway_activity_dm_view AS
WITH fact_levels_recommended_last AS (
    SELECT 
        fpta_created_time       AS flr_created_time,
        fpta_pathway_dw_id      AS flr_course_dw_id,
        fpta_class_dw_id        AS flr_class_dw_id,
        fpta_student_dw_id      AS flr_student_dw_id,
        fpta_level_dw_id        AS flr_course_activity_container_dw_id,
        fpta_activity_dw_id     AS caa_activity_dw_id,
        fpta_activity_type      AS caa_activity_type,
        99                      AS flr_recommendation_type
    FROM (
        SELECT
            fpta.fpta_created_time,
            fpta.fpta_pathway_dw_id,
            fpta.fpta_class_dw_id,
            fpta.fpta_student_dw_id,
            fpta.fpta_level_dw_id,
            fpta.fpta_activity_dw_id,
            fpta.fpta_activity_type,
            fpta.fpta_action_name,
            ROW_NUMBER() OVER (
                PARTITION BY fpta_student_dw_id, fpta_activity_dw_id
                ORDER BY fpta_created_time DESC
            ) AS rank
        FROM ${rs_coredw}.fact_pathway_teacher_activity fpta
    ) fpta
    WHERE fpta.rank = 1
      AND fpta_action_name = 1

    UNION ALL

    SELECT
        flr_created_time,
        flr_course_dw_id,
        flr_class_dw_id,
        flr_student_dw_id,
        flr_course_activity_container_dw_id,
        caa_activity_dw_id,
        caa_activity_type,
        flr_recommendation_type
    FROM (
        SELECT
            flr.flr_created_time,
            flr.flr_student_dw_id,
            flr.flr_class_dw_id,
            flr.flr_course_activity_container_dw_id,
            flr.flr_course_dw_id,
            flr.flr_recommendation_type,
            flr.flr_status,
            dccaa.caa_activity_dw_id,
            dccaa.caa_activity_type,
            ROW_NUMBER() OVER (
                PARTITION BY flr.flr_student_dw_id, dccaa.caa_activity_dw_id
                ORDER BY flr.flr_created_time ASC
            ) AS rank
        FROM ${rs_coredw}.fact_levels_recommended flr
        INNER JOIN ${rs_coredw}.dim_course_activity_association dccaa
            ON dccaa.caa_container_dw_id = flr.flr_course_activity_container_dw_id
           AND dccaa.caa_status = 1
        WHERE flr_status = 1
    ) flrdplaa
    WHERE flrdplaa.rank = 1
),

fact_pathway_activity_completed_last AS (
    SELECT
        fpac_learning_session_id,
        fpac_activity_dw_id,
        fpac_student_dw_id,
        fpac_created_time,
        fpac_score,
        fpac_attempt,
        fpac_course_activity_container_dw_id
    FROM (
        SELECT
            fpac.fpac_learning_session_id,
            fpac.fpac_activity_dw_id,
            fpac.fpac_student_dw_id,
            fpac.fpac_created_time,
            fpac.fpac_score,
            fpac.fpac_attempt,
            fpac.fpac_course_activity_container_dw_id,
            ROW_NUMBER() OVER (
                PARTITION BY fpac_learning_session_id
                ORDER BY fpac_attempt DESC , fpac_created_time DESC
            ) AS rank
        FROM ${rs_coredw}.fact_pathway_activity_completed fpac
        INNER JOIN ${rs_coredw}.dim_course_activity_association dccaa
            ON dccaa.caa_activity_dw_id = fpac.fpac_activity_dw_id
           AND dccaa.caa_status = 1
    ) fpac
    WHERE rank = 1
),

fact_learning_experience_last AS (
    SELECT
        fle_student_dw_id,
        fle_lo_dw_id,
        fle_created_time,
        fle_total_time,
        fle_total_score,
        fle_exp_id,
        fle_abbreviation,
        fle_attempt,
        calc_fle_total_time
    FROM (
        SELECT
            fle.fle_student_dw_id,
            fle.fle_lo_dw_id,
            fle.fle_created_time,
            fle.fle_total_time,
            fle.fle_total_score,
            fle.fle_exp_id,
            fle.fle_abbreviation,
            fle.fle_attempt,
            fle.fle_lesson_category,
            SUM(
                CASE 
                    WHEN fle_lesson_category = 'INTERIM_CHECKPOINT' THEN
                        CASE 
                            WHEN fle.fle_total_time BETWEEN 0 AND 1200 THEN fle.fle_total_time
                            WHEN fle.fle_total_time > 1200 THEN 1200
                            ELSE 0
                        END
                    WHEN fle_lesson_category = 'INSTRUCTIONAL_LESSON' THEN
                        CASE 
                            WHEN fle.fle_total_time BETWEEN 0 AND 900 THEN fle.fle_total_time
                            WHEN fle.fle_total_time > 900 THEN 900
                            ELSE 0
                        END
                END
            ) OVER (
                PARTITION BY CONVERT(DATE, fle_created_time), fle_student_dw_id, fle_lo_dw_id
            ) AS calc_fle_total_time,
            ROW_NUMBER() OVER (
                PARTITION BY fle_ls_id
                ORDER BY fle_created_time DESC, fle_attempt DESC
            ) AS rank
        FROM ${rs_coredw}.fact_learning_experience fle
        WHERE fle_material_type = 'PATHWAY'
          AND fle_abbreviation <> 'NA'
          AND fle_lesson_category <> 'DIAGNOSTIC_TEST'
    ) fle
    WHERE rank = 1
),

pathway_adt_students AS (
    SELECT DISTINCT 
        fle.fle_student_dw_id AS adt_student_dw_id,
        CASE 
            WHEN dcsa.cs_subject_dw_id = 129 THEN 'Arabits'
            ELSE dc.class_gen_subject
        END AS class_gen_subject
    FROM ${rs_coredw}.fact_learning_experience fle
    INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
        ON ds.student_dw_id = fle.fle_student_dw_id
    INNER JOIN ${rs_coredw}.dim_class dc
        ON fle.fle_class_dw_id = dc.class_dw_id
    LEFT JOIN ${rs_coredw}.dim_course_subject_association dcsa
        ON dcsa.cs_course_id = dc.class_material_id
       AND dcsa.cs_status = 1
       AND dcsa.cs_subject_dw_id = 129
    WHERE fle_lesson_category = 'DIAGNOSTIC_TEST'
      AND fle_is_activity_completed = 1
      AND fle_exp_id = 'n/a'
),

pathway_class_total_students AS (
    SELECT
        dsc.school_dw_id,
        dsc.school_name,
        dsc.tenant_id,
        dsc.tenant_name,
        dsc.organisation_dw_id,
        dsc.school_organisation,
        dsc.school_composition,
        dsc.school_label,
        dsc.windows_timezone,
        dsc.academic_year_start_date,
        dcu.class_user_user_dw_id                   AS pathway_student_dw_id,
        ds.student_grade_dw_id,
        ds.student_special_needs,
        dg.grade_name,
        dg.grade_id,
        CASE 
            WHEN dcsa.cs_subject_dw_id = 129 THEN 'Arabits'
            ELSE dc.class_gen_subject
        END                                        AS curr_subject_name,
        dc.class_curriculum_subject_id             AS curr_subject_id,
        dc.class_material_id,
        CONVERT(FLOAT(53), YEAR(dsc.academic_year_end_date)) AS academic_year_end_year
    FROM ${rs_coredw}.dim_class dc
    INNER JOIN ${rs_coredw}.dim_class_user dcu
        ON dcu.class_user_class_dw_id = dc.class_dw_id
    INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dc.class_school_id = dsc.school_id

    INNER JOIN ${rs_bi_coredw}.bi_student_dim ds
        ON dcu.class_user_user_dw_id = ds.student_dw_id
       AND dsc.school_dw_id = ds.student_school_dw_id
       AND ds.student_status = 1
    INNER JOIN ${rs_coredw}.dim_grade dg
        ON dg.grade_dw_id = ds.student_grade_dw_id
       AND dsc.academic_year_id = dg.academic_year_id
       AND dg.grade_status = 1
    LEFT JOIN ${rs_coredw}.dim_course_subject_association dcsa
        ON dcsa.cs_course_id = dc.class_material_id
       AND dcsa.cs_status = 1
       AND dcsa.cs_subject_dw_id = 129
    WHERE dcu.class_user_status = 1
      AND dcu.class_user_role_dw_id = 2
      AND dcu.class_user_attach_status = 1
      AND dc.class_course_status = 'ACTIVE'
      AND dc.class_material_type = 'PATHWAY'
      AND dc.class_status = 1
)

SELECT DISTINCT 
    pcts.tenant_id,
    pcts.tenant_name,
    pcts.organisation_dw_id,
    pcts.school_organisation,
    pcts.school_composition,
    pcts.school_dw_id,
    pcts.school_name,
    pcts.school_label,
    pcts.student_grade_dw_id,
    pcts.grade_name,
    pcts.pathway_student_dw_id,
    pcts.student_special_needs,
    pcts.academic_year_start_date,
    pcts.academic_year_end_year,
    fle.fle_student_dw_id                                              AS active_student_dw_id,
    dcr.course_dw_id                                                   AS pathway_dw_id,
    dcr.course_name                                                    AS pathway_name,
    dcr.course_lang_code                                               AS pathway_lang_code,
    pcts.curr_subject_name,
    dcac.course_activity_container_dw_id                               AS pathway_level_dw_id,
    flr.flr_class_dw_id,
    flr.caa_activity_dw_id                                             AS plaa_activity_dw_id,
    flr.flr_student_dw_id,
    pnadt.adt_student_dw_id,
    CONVERT(
    DATETIME2,
    flr.flr_created_time
        AT TIME ZONE 'UTC'
        AT TIME ZONE ISNULL(pcts.windows_timezone, 'UTC')
    ) AS flr_created_time,
    flc.flc_course_activity_container_dw_id                            AS level_dw_id_completed,
    CONVERT(
    DATETIME2,
    flc.flc_created_time
        AT TIME ZONE 'UTC'
        AT TIME ZONE ISNULL(pcts.windows_timezone, 'UTC')
    ) AS level_completed_time,
    fpac.fpac_learning_session_id,
    fpac.fpac_activity_dw_id,
    fpac.fpac_created_time                                             AS activity_completed_time,
    CONVERT(DATE, fpac.fpac_created_time)                               AS activity_date,
    CONVERT(
    DATETIME2,
    fpac.fpac_created_time
        AT TIME ZONE 'UTC'
        AT TIME ZONE ISNULL(pcts.windows_timezone, 'UTC')
    ) AS activity_completed_time_local,
    fpac.fpac_student_dw_id,
    fpac.fpac_score,
    fpac.fpac_attempt,
    fle.calc_fle_total_time                                            AS fle_total_time,
    fle.fle_total_score,
    fle.fle_exp_id,
    CONVERT(DATE, fle.fle_created_time)                                 AS fle_activity_date,
    CONVERT(
    DATETIME2,
    fle.fle_created_time
        AT TIME ZONE 'UTC'
        AT TIME ZONE ISNULL(pcts.windows_timezone, 'UTC')
    ) AS fle_activity_time_local,
    fle.fle_abbreviation,
    fle.fle_attempt,
    CASE flr.caa_activity_type
        WHEN 1 THEN 'ACTVITY'
        WHEN 2 THEN 'INTERIM_CHECKPOINT'
    END                                                                AS activity_type,
    flr.flr_recommendation_type,
    (6.0 - flf.lesson_feedback_rating)                                 AS lesson_feedback_rate
FROM pathway_class_total_students pcts
LEFT JOIN ${rs_coredw}.dim_course dcr
    ON pcts.class_material_id = dcr.course_id
   AND dcr.course_status = 1
   AND dcr.course_type = 'PATHWAY'

LEFT JOIN fact_levels_recommended_last flr
    ON pcts.pathway_student_dw_id = flr.flr_student_dw_id
   AND dcr.course_dw_id = flr.flr_course_dw_id
LEFT JOIN ${rs_coredw}.dim_course_activity_container dcac
    ON dcac.course_activity_container_course_id = dcr.course_id
   AND dcac.course_activity_container_dw_id = flr.flr_course_activity_container_dw_id
   AND dcac.course_activity_container_status = 1
   AND dcac.course_activity_container_attach_status = 1
LEFT JOIN ${rs_coredw}.fact_level_completed flc
    ON flc.flc_course_activity_container_dw_id = flr.flr_course_activity_container_dw_id
   AND flc.flc_student_dw_id = flr.flr_student_dw_id
LEFT JOIN fact_pathway_activity_completed_last fpac
    ON fpac.fpac_student_dw_id = flr.flr_student_dw_id
   AND fpac.fpac_activity_dw_id = flr.caa_activity_dw_id
LEFT JOIN fact_learning_experience_last fle
    ON fle.fle_student_dw_id = flr.flr_student_dw_id
   AND fle.fle_lo_dw_id = flr.caa_activity_dw_id
   AND fle.fle_created_time >= CONVERT(DATETIME2, pcts.academic_year_start_date)  -- OPT-7: SARGable rewrite
   AND fle.fle_created_time < CONVERT(DATETIME2, CONVERT(DATE, GETDATE()))  -- OPT-7: SARGable rewrite
LEFT JOIN ${rs_coredw}.fact_lesson_feedback flf
    ON flf.lesson_feedback_lo_dw_id = fpac.fpac_activity_dw_id
   AND flf.lesson_feedback_student_dw_id = fpac.fpac_student_dw_id
   AND flf.lesson_feedback_rating > 0
LEFT JOIN pathway_adt_students pnadt
    ON pcts.pathway_student_dw_id = pnadt.adt_student_dw_id
   AND pcts.curr_subject_name = pnadt.class_gen_subject;
