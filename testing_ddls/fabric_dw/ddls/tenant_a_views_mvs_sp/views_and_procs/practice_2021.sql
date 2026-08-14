CREATE OR ALTER VIEW ${os_bi_coredw}.practice_2021
AS
SELECT DISTINCT
    dsc.school_name,
    dsc.school_composition,
    dsc.school_alias,
    dsc.school_dw_id,
    dg.grade_k12grade,
    dc.section_name,
    dc.section_dw_id,
    dsc.academic_year_start_date,
    dsc.academic_year_end_date,
    lo.lo_title,
    lo.lo_dw_id,
    dd.date_id,

    -- INITCAP replacement
    UPPER(ISNULL(dcs.class_gen_subject, dsb.subject_gen_subject))
        AS subject,

    UPPER(ISNULL(dcs.class_title, dc.section_name))
        AS class,

    fp.practice_student_dw_id,
    dst.student_tags,
    fp.practice_id,
    fp.practice_dw_created_time,
    fp.practice_created_time,
    ps.practice_session_start_time,
    ps.practice_session_end_time,
    ps.practice_session_score,
    ps.practice_session_time_spent,
    dsc.school_label,
    dsc.school_country_name,
    dsc.school_city_name,
    dsc.school_organisation,
    dsc.tenant_name,
    ISNULL(ps.practice_status, 'Un-Attempted') AS practice_status,
    dsc.school_id
FROM ${rs_coredw}.fact_practice fp

JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
    ON dsc.school_dw_id = fp.practice_school_dw_id
   AND CONVERT(date, fp.practice_created_time)
       BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date

JOIN ${rs_bi_coredw}.bi_student_dim dst
    ON dst.student_dw_id = fp.practice_student_dw_id
   AND (
        (dst.student_status = 2
         AND fp.practice_created_time >= dst.student_created_time
         AND fp.practice_created_time < dst.student_active_until)
        OR
        (dst.student_status = 1
         AND fp.practice_created_time >= dst.student_created_time)
       )

JOIN ${rs_coredw}.dim_grade dg
    ON dst.student_grade_dw_id = dg.grade_dw_id
   AND dg.grade_status <> 4

JOIN ${rs_coredw}.dim_tenant dte
    ON dte.tenant_id = dsc.tenant_id

JOIN ${rs_coredw}.dim_date dd
    ON dd.date_id = FORMAT(CONVERT(date, fp.practice_created_time), 'yyyyMMdd')

JOIN ${rs_coredw}.dim_learning_objective lo
    ON fp.practice_lo_dw_id = lo.lo_dw_id

LEFT JOIN ${rs_coredw}.dim_section dc
    ON dc.section_dw_id = fp.practice_section_dw_id
   AND dc.section_status <> 4

LEFT JOIN ${rs_coredw}.dim_class dcs
    ON fp.practice_class_dw_id = dcs.class_dw_id
   AND dcs.class_status = 1

LEFT JOIN ${rs_coredw}.dim_subject dsb
    ON fp.practice_subject_dw_id = dsb.subject_dw_id

LEFT JOIN (
    SELECT
        dda.date_id,
        fps.practice_session_id,
        fps.practice_session_is_start,
        fps.practice_session_start_time,
        fps.practice_session_end_time,
        fps.practice_session_score,
        fps.practice_session_time_spent,
        CASE
            WHEN fps.practice_session_is_start = 0 THEN 'Completed'
            WHEN fps.practice_session_is_start = 1 THEN 'In-Progress'
            ELSE 'Un-Attempted'
        END AS practice_status,
        ROW_NUMBER() OVER (
            PARTITION BY fps.practice_session_id
            ORDER BY fps.practice_session_dw_created_time DESC
        ) AS rn
    FROM ${rs_coredw}.fact_practice_session fps
    JOIN ${rs_coredw}.dim_date dda
        ON dda.date_id = FORMAT(CONVERT(date, fps.practice_session_dw_created_time),'yyyyMMdd')
    WHERE fps.practice_session_event_type = 1
) ps
    ON fp.practice_id = ps.practice_session_id
WHERE ps.rn = 1 OR ps.rn IS NULL;
