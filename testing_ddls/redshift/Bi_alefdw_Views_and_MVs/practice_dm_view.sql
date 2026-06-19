CREATE OR REPLACE VIEW bi_alefdw_dev.practice_dm_view
AS
SELECT distinct dsc.school_name,
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
                initcap(COALESCE(dcs.class_gen_subject, dsb.subject_gen_subject)) AS subject,
                initcap(COALESCE(dcs.class_title, dc.section_name))               AS "class",
                fp.practice_student_dw_id,
                dst.student_tags,
                fp.practice_id,
                fp.practice_dw_created_time,
                NVL(practice_session.practice_status, 'Un-Attempted')             AS practice_status,
                dsc.school_label,
                dsc.school_country_name,
                dsc.school_city_name,
                dsc.school_id
FROM alefdw.fact_practice fp
         JOIN bi_alefdw.bi_active_schools_dim_mv dsc ON dsc.school_dw_id = fp.practice_school_dw_id
         JOIN alefdw.dim_grade dg ON fp.practice_grade_dw_id = dg.grade_dw_id AND dg.grade_status <> 4
         JOIN bi_alefdw.bi_student_dim_mv dst
              ON dst.student_dw_id = fp.practice_student_dw_id AND dst.student_status <> 4
         JOIN alefdw.dim_tenant dte ON dte.tenant_dw_id = fp.practice_tenant_dw_id
         JOIN alefdw.dim_date dd ON dd.date_id = to_char(
        convert_timezone('UTC', dte.tenant_timezone, fp.practice_created_time), 'YYYYMMDD')
    AND full_date between trunc(sysdate) - 365 and trunc(sysdate)
         JOIN alefdw.dim_learning_objective lo ON fp.practice_lo_dw_id = lo.lo_dw_id
         LEFT JOIN alefdw.dim_academic_year ay ON ay.academic_year_dw_id = fp.practice_academic_year_dw_id
         LEFT JOIN alefdw.dim_section dc
                   ON dc.section_dw_id = fp.practice_section_dw_id AND dc.section_status <> 4
         LEFT JOIN alefdw.dim_class dcs ON fp.practice_class_dw_id = dcs.class_dw_id AND dcs.class_status = 1
         LEFT JOIN alefdw.dim_subject dsb ON fp.practice_subject_dw_id = dsb.subject_dw_id
         LEFT JOIN (SELECT dda.date_id,
                           fps.practice_session_id,
                           fps.practice_session_is_start,
                           CASE
                               WHEN practice_session_is_start = false THEN 'Completed'
                               WHEN practice_session_is_start = true THEN 'In-Progress'
                               ELSE 'Un-Attempted'
                               END                                                 AS practice_status,
                           rank()
                           OVER (
                               PARTITION BY fps.practice_session_id
                               ORDER BY fps.practice_session_dw_created_time DESC) AS rank
                    FROM alefdw.fact_practice_session fps
                             JOIN alefdw.dim_tenant dten ON dten.tenant_dw_id = fps.practice_session_tenant_dw_id
                             JOIN alefdw.dim_date dda ON dda.date_id = to_char(
                            convert_timezone('UTC', dten.tenant_timezone,
                                             fps.practice_session_dw_created_time), 'YYYYMMDD')
                    WHERE fps.practice_session_event_type = 1) practice_session
                   ON fp.practice_id = practice_session.practice_session_id
WHERE practice_session.rank = 1
   OR practice_session.rank IS NULL
WITH NO SCHEMA BINDING;