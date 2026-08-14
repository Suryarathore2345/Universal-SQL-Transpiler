CREATE OR ALTER VIEW ${os_bi_coredw}.practice_dm_view
AS
WITH practice_session AS (
    SELECT 
        dda.date_id,
        fps.practice_session_id,
        fps.practice_session_is_start,
        CASE
            WHEN fps.practice_session_is_start = 0 THEN 'Completed'
            WHEN fps.practice_session_is_start = 1 THEN 'In-Progress'
            ELSE 'Un-Attempted'
        END AS practice_status,
        RANK() OVER (
            PARTITION BY fps.practice_session_id
            ORDER BY fps.practice_session_dw_created_time DESC
        ) AS rank
    FROM ${rs_coredw}.fact_practice_session fps
    JOIN ${rs_coredw}.dim_tenant dten 
        ON dten.tenant_dw_id = fps.practice_session_tenant_dw_id

    JOIN ${rs_coredw}.dim_date dda 
        ON dda.date_id = CONVERT(
                            VARCHAR(8),
                            CONVERT(
                                DATETIME2,
                                fps.practice_session_dw_created_time
                                    AT TIME ZONE 'UTC'
                                    AT TIME ZONE ISNULL(dten.windows_timezone, 'UTC')
                            ),
                            112
                        )
    WHERE fps.practice_session_event_type = 1
)

SELECT DISTINCT
    dsc.school_name,
    dsc.school_composition,
    dsc.school_alias,
    dsc.school_dw_id,
    dg.grade_k12grade,
    dc.section_name,
    dc.section_dw_id,
    ay.academic_year_start_date,
    ay.academic_year_end_date,
    lo.lo_title,
    lo.lo_dw_id,
    dd.date_id,
    UPPER(ISNULL(dcs.class_gen_subject, dsb.subject_gen_subject)) AS subject,
    UPPER(ISNULL(dcs.class_title, dc.section_name)) AS class,
    fp.practice_student_dw_id,
    dst.student_tags,
    fp.practice_id,
    fp.practice_dw_created_time,
    ISNULL(ps.practice_status, 'Un-Attempted') AS practice_status,
    dsc.school_label,
    dsc.school_country_name,
    dsc.school_city_name,
    dsc.school_id
FROM ${rs_coredw}.fact_practice fp
JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc 
    ON dsc.school_dw_id = fp.practice_school_dw_id
JOIN ${rs_coredw}.dim_grade dg 
    ON fp.practice_grade_dw_id = dg.grade_dw_id 
   AND dg.grade_status <> 4
JOIN (
    SELECT DISTINCT student_dw_id, student_tags
    FROM ${rs_bi_coredw}.bi_student_dim
    WHERE student_status <> 4
) dst
    ON dst.student_dw_id = fp.practice_student_dw_id
JOIN ${rs_coredw}.dim_tenant dte
    ON dte.tenant_dw_id = fp.practice_tenant_dw_id

JOIN ${rs_coredw}.dim_date dd 
    ON dd.date_id = CONVERT(
                        VARCHAR(8),
                        CONVERT(
                            DATETIME2,
                            fp.practice_created_time
                                AT TIME ZONE 'UTC'
                                AT TIME ZONE ISNULL(dte.windows_timezone, 'UTC')
                        ),
                        112
                    )
   AND dd.full_date BETWEEN CONVERT(DATE, DATEADD(DAY, -365, GETDATE()))
                        AND CONVERT(DATE, GETDATE())
JOIN ${rs_coredw}.dim_learning_objective lo 
    ON fp.practice_lo_dw_id = lo.lo_dw_id
LEFT JOIN ${rs_coredw}.dim_academic_year ay 
    ON ay.academic_year_dw_id = fp.practice_academic_year_dw_id
LEFT JOIN ${rs_coredw}.dim_section dc
    ON dc.section_dw_id = fp.practice_section_dw_id 
   AND dc.section_status <> 4
LEFT JOIN ${rs_coredw}.dim_class dcs 
    ON fp.practice_class_dw_id = dcs.class_dw_id 
   AND dcs.class_status = 1
LEFT JOIN ${rs_coredw}.dim_subject dsb 
    ON fp.practice_subject_dw_id = dsb.subject_dw_id
LEFT JOIN practice_session ps
    ON fp.practice_id = ps.practice_session_id
--    AND dd.date_id = ps.date_id
WHERE ps.rank = 1
   OR ps.rank IS NULL;
