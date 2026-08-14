CREATE OR ALTER  VIEW ${os_bi_coredw}.mhs_achievers_list_dm_view AS

WITH cte_term_dimension AS (
    SELECT DISTINCT
        sch.school_dw_id,
        sch.school_id,
        sch.school_organisation                                                   AS organisation_name,
        sch.organisation_dw_id,
        ISNULL(dtrm.actp_teaching_period_order, 1)                              AS org_term,
        ISNULL(dtrm.actp_teaching_period_start_date, sch.academic_year_start_date)
                                                                                  AS term_start_date,
        ISNULL(dtrm.actp_teaching_period_end_date, sch.academic_year_end_date)
                                                                                  AS term_end_date,
        DATEDIFF(DAY,
                 ISNULL(dtrm.actp_teaching_period_start_date, sch.academic_year_start_date),
                 ISNULL(dtrm.actp_teaching_period_end_date, sch.academic_year_end_date)
        )                                                                          AS term_duration
    FROM ${rs_bi_coredw}.bi_active_schools_dim sch
    LEFT JOIN ${rs_coredw}.dim_academic_calendar dac
        ON sch.organisation_dw_id = dac.academic_calendar_organization_dw_id
       AND dac.academic_calendar_status = 1
    LEFT JOIN ${rs_coredw}.dim_academic_calendar_teaching_period dtrm
        ON dac.academic_calendar_id = dtrm.actp_academic_calendar_id
       AND dtrm.actp_status = 1
    WHERE sch.school_organisation = 'MHS'
),

cte_guardian_login_activity AS (
    SELECT
        ga.fgaa_student_dw_id,
        ctd.org_term,
        ctd.term_start_date,
        ctd.term_end_date,
        dd.calendar_week_of                                         AS week_start,
        DATEADD(DAY, 6, dd.calendar_week_of)                         AS week_end,
        MAX(ctd.term_duration)                                       AS term_duration,
        COUNT(DISTINCT CONVERT(DATE, ga.fgaa_created_time))           AS guaridans_active_days
    FROM ${rs_coredw}.fact_guardian_app_activities ga
    INNER JOIN cte_term_dimension ctd
        ON ga.fgaa_school_dw_id = ctd.school_dw_id
       AND CONVERT(DATE, ga.fgaa_created_time)
           BETWEEN ctd.term_start_date AND ctd.term_end_date
    INNER JOIN ${rs_coredw}.dim_date dd
        ON ga.fgaa_created_time >= CONVERT(DATETIME2, dd.full_date) AND ga.fgaa_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, dd.full_date))  -- OPT-15: SARGable rewrite
    GROUP BY
        ga.fgaa_student_dw_id,
        ctd.org_term,
        ctd.term_start_date,
        ctd.term_end_date,
        dd.calendar_week_of
),

cte_instruction_plan AS (
    SELECT
        student_dw_id,
        student_id,
        section_dw_id,
        section_name,
        grade_name,
        class_gen_subject                                               AS subject,
        school_name,
        academic_year_start_date,
        academic_year_end_date,
        CONVERT(VARCHAR(10), DATEPART(YEAR, academic_year_start_date))
            + '-' +
        CONVERT(VARCHAR(10), DATEPART(YEAR, academic_year_end_date))     AS academic_year,
        content_academic_year_name,
        term_academic_period_order                                      AS org_term,
        term_start_date,
        term_end_date,
        week_start_date,
        week_number,
        DATEADD(DAY, 2, week_end_date)                                  AS week_end_date,
        COUNT(DISTINCT lo_dw_id)                                        AS total_lessons,
        COUNT(DISTINCT CASE
                           WHEN lo_status = 'Completed'
                           THEN lo_dw_id
                       END)                                             AS completed_lessons,
        ISNULL(
            SUM(CASE
                    WHEN lo_status = 'Completed'
                     AND fle_score > 0
                    THEN fle_score
                END),
            0
        )                                                               AS sum_score_completed_lessons
    FROM ${rs_bi_coredw}.student_progress_ip_mscl_view ip
    WHERE school_organisation = 'MHS'
    GROUP BY
        student_dw_id, student_id, section_dw_id, section_name,
        grade_name, class_gen_subject, school_name,
        academic_year_start_date, academic_year_end_date,
        content_academic_year_name, term_academic_period_order,
        term_start_date, term_end_date,
        week_start_date, week_number, week_end_date
),

cte_fle_stars_earned AS (
    SELECT
        fle_student_dw_id,
        class_gen_subject,
        week_start_date,
        week_end_date,
        term_academic_period_order,
        SUM(et_stars) AS et_stars
    FROM (
        SELECT
            fle1.fle_lo_dw_id,
            fle1.fle_student_dw_id,
            dc.class_gen_subject,
            dpg.pacing_interval_start_date                               AS week_start_date,
            DATEADD(DAY, 2, dpg.pacing_interval_end_date)                AS week_end_date,
            ISNULL(dtrm.actp_teaching_period_order, 1)                 AS term_academic_period_order,
            MAX(CONVERT(DATE, fle1.fle_created_time))                     AS created_date,
            MAX(fle1.fle_star_earned)                                    AS et_stars
        FROM ${rs_coredw}.fact_learning_experience fle1
        INNER JOIN (
            SELECT DISTINCT class_dw_id, class_gen_subject, class_school_id
            FROM ${rs_coredw}.dim_class
        ) dc
            ON fle1.fle_class_dw_id = dc.class_dw_id
        INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim sch
            ON dc.class_school_id = sch.school_id
           AND fle1.fle_created_time >= CONVERT(DATETIME2, sch.academic_year_start_date)  -- OPT-7: SARGable rewrite
               AND fle1.fle_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, sch.academic_year_end_date))
        LEFT JOIN ${rs_coredw}.dim_pacing_guide dpg
            ON dc.class_dw_id = dpg.pacing_class_dw_id
           AND fle1.fle_lo_dw_id = dpg.pacing_activity_dw_id
           AND dpg.pacing_status = 1
        LEFT JOIN ${rs_coredw}.dim_academic_calendar_teaching_period dtrm
            ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
           AND dtrm.actp_status = 1
        WHERE fle1.fle_material_type <> 'PATHWAY'
          AND fle1.fle_completion_node = 1
          AND fle1.fle_star_earned > 0
          AND sch.school_organisation = 'MHS'
        GROUP BY
            fle1.fle_lo_dw_id,
            fle1.fle_student_dw_id,
            dc.class_gen_subject,
            dpg.pacing_interval_start_date,
            dpg.pacing_interval_end_date,
            dtrm.actp_teaching_period_order
    ) fle
    GROUP BY
        fle_student_dw_id,
        class_gen_subject,
        week_start_date,
        week_end_date,
        term_academic_period_order
),

cte_certificates_awarded AS (
    SELECT
        cert.fsca_student_dw_id,
        ctd.org_term,
        dc.class_gen_subject,
        dd.calendar_week_of                              AS week_start_date,
        DATEADD(DAY, 6, dd.calendar_week_of)             AS week_end_date,
        COUNT(DISTINCT cert.fsca_dw_id)                  AS certificates_earned
    FROM ${rs_bi_coredw}.student_certificate_awarded_dm_view cert
    INNER JOIN (
        SELECT DISTINCT class_dw_id, class_gen_subject, class_school_id
        FROM ${rs_coredw}.dim_class
    ) dc
        ON cert.fsca_class_dw_id = dc.class_dw_id
    INNER JOIN cte_term_dimension ctd
        ON cert.school_dw_id = ctd.school_dw_id
       AND cert.local_date BETWEEN ctd.term_start_date AND ctd.term_end_date
    INNER JOIN ${rs_coredw}.dim_date dd
        ON cert.week_year_number = dd.calendar_year_week_number
    GROUP BY
        cert.fsca_student_dw_id,
        ctd.org_term,
        dc.class_gen_subject,
        dd.calendar_week_of
),

cte_student_info AS (
    SELECT DISTINCT
        student_dw_id,
        student_id,
        school_name,
        section_dw_id,
        section_name,
        grade_name,
        subject,
        org_term,
        term_start_date,
        term_end_date,
        academic_year_start_date,
        academic_year_end_date,
        academic_year,
        content_academic_year_name
    FROM cte_instruction_plan
),

cte_ip_missing_stars AS (
    SELECT
        star.fle_student_dw_id      AS student_dw_id,
        star.class_gen_subject      AS subject,
        star.term_academic_period_order AS org_term,
        star.week_start_date,
        star.week_end_date,
        star.et_stars,
        0                           AS certificates_earned,
        0                           AS guaridans_active_days
    FROM cte_fle_stars_earned star
    WHERE NOT EXISTS (
        SELECT 1
        FROM cte_instruction_plan cip
        WHERE cip.student_dw_id = star.fle_student_dw_id
          AND cip.subject = star.class_gen_subject
          AND cip.week_start_date = star.week_start_date
          AND cip.week_end_date = star.week_end_date
          AND cip.org_term = star.term_academic_period_order
    )
),

cte_ip_missing_certificates AS (
    SELECT
        cert.fsca_student_dw_id     AS student_dw_id,
        cert.class_gen_subject      AS subject,
        cert.org_term,
        cert.week_start_date,
        cert.week_end_date,
        0                           AS et_stars,
        cert.certificates_earned,
        0                           AS guaridans_active_days
    FROM cte_certificates_awarded cert
    WHERE NOT EXISTS (
        SELECT 1
        FROM cte_instruction_plan cip
        WHERE cip.student_dw_id = cert.fsca_student_dw_id
          AND cip.subject = cert.class_gen_subject
          AND cip.week_start_date = cert.week_start_date
          AND cip.week_end_date = cert.week_end_date
          AND cip.org_term = cert.org_term
    )
),

cte_combined_data AS (
    SELECT
        cip.school_name,
        cip.student_dw_id,
        cip.student_id,
        cip.section_dw_id,
        cip.section_name,
        cip.grade_name,
        cip.subject,
        cip.org_term,
        cip.term_start_date,
        cip.term_end_date,
        cip.week_start_date,
        cip.week_end_date,
        cip.academic_year_start_date,
        cip.academic_year_end_date,
        cip.academic_year,
        cip.content_academic_year_name,
        cip.total_lessons,
        cip.completed_lessons,
        cip.sum_score_completed_lessons,
        ISNULL(star.et_stars, 0)               AS et_stars,
        ISNULL(cert.certificates_earned, 0)   AS certificates_earned,
        ISNULL(guard.guaridans_active_days,0) AS guaridans_active_days
    FROM cte_instruction_plan cip
    LEFT JOIN cte_fle_stars_earned star
        ON star.fle_student_dw_id = cip.student_dw_id
       AND star.term_academic_period_order = cip.org_term
       AND star.class_gen_subject = cip.subject
       AND star.week_start_date = cip.week_start_date
       AND star.week_end_date = cip.week_end_date
    LEFT JOIN cte_certificates_awarded cert
        ON cert.fsca_student_dw_id = cip.student_dw_id
       AND cert.org_term = cip.org_term
       AND cert.class_gen_subject = cip.subject
       AND cert.week_start_date = cip.week_start_date
       AND cert.week_end_date = cip.week_end_date
    LEFT JOIN cte_guardian_login_activity guard
        ON guard.fgaa_student_dw_id = cip.student_dw_id
       AND guard.org_term = cip.org_term
       AND guard.week_start = cip.week_start_date
       AND guard.week_end = cip.week_end_date

    UNION ALL

    SELECT
        si.school_name,
        ms.student_dw_id,
        si.student_id,
        si.section_dw_id,
        si.section_name,
        si.grade_name,
        ms.subject,
        ms.org_term,
        si.term_start_date,
        si.term_end_date,
        ms.week_start_date,
        ms.week_end_date,
        si.academic_year_start_date,
        si.academic_year_end_date,
        si.academic_year,
        si.content_academic_year_name,
        0 AS total_lessons,
        0 AS completed_lessons,
        0 AS sum_score_completed_lessons,
        ms.et_stars,
        ms.certificates_earned,
        ms.guaridans_active_days
    FROM cte_ip_missing_stars ms
    JOIN cte_student_info si
        ON ms.student_dw_id = si.student_dw_id
       AND ms.subject = si.subject
       AND ms.org_term = si.org_term

    UNION ALL

    SELECT
        si.school_name,
        mc.student_dw_id,
        si.student_id,
        si.section_dw_id,
        si.section_name,
        si.grade_name,
        mc.subject,
        mc.org_term,
        si.term_start_date,
        si.term_end_date,
        mc.week_start_date,
        mc.week_end_date,
        si.academic_year_start_date,
        si.academic_year_end_date,
        si.academic_year,
        si.content_academic_year_name,
        0 AS total_lessons,
        0 AS completed_lessons,
        0 AS avg_score_completed_lessons,
        mc.et_stars,
        mc.certificates_earned,
        mc.guaridans_active_days
    FROM cte_ip_missing_certificates mc
    JOIN cte_student_info si
        ON mc.student_dw_id = si.student_dw_id
       AND mc.subject = si.subject
       AND mc.org_term = si.org_term
)

SELECT DISTINCT
    school_name,
    student_dw_id,
    student_id,
    section_dw_id,
    section_name,
    grade_name,
    subject,
    org_term,
    term_start_date,
    term_end_date,
    week_start_date,
    week_end_date,
    academic_year_start_date,
    academic_year_end_date,
    academic_year,
    content_academic_year_name,
    total_lessons,
    completed_lessons,
    sum_score_completed_lessons,
    et_stars,
    certificates_earned,
    guaridans_active_days
FROM cte_combined_data;
