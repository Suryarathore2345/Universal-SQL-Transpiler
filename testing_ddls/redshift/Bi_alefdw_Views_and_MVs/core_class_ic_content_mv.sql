CREATE MATERIALIZED VIEW bi_alefdw_dev.core_class_ic_content_mv AS
WITH ip_base AS (
    SELECT course_dw_id,
           course_id,
           activity_dw_id,
           created_time,
           active_until,
           activity_is_hidden,
           event_type
    FROM alefdw.dim_course_activity_ip_association
    WHERE event_type = 'InstructionalPlanPublishedEvent'
),
ip_ranked AS (
    SELECT course_dw_id,
           activity_dw_id,
           activity_is_hidden,
           sch2.academic_year_id,
           sch2.academic_year_start_date,
           ROW_NUMBER() OVER (
               PARTITION BY course_dw_id, activity_dw_id, sch2.academic_year_id
               ORDER BY ip2.created_time DESC
           ) AS rn
    FROM ip_base ip2
    JOIN alefdw.dim_class dc2 ON ip2.course_id = dc2.class_material_id AND dc2.class_status = 1
    JOIN alefdw.dim_grade g ON g.grade_id = dc2.class_grade_id
    JOIN bi_alefdw.bi_all_schools_dim_mv sch2
        ON dc2.class_school_id = sch2.school_id
        AND g.academic_year_id = sch2.academic_year_id
        AND sch2.academic_year_end_date >= DATE(ip2.created_time)
        AND sch2.academic_year_start_date <= COALESCE(DATE(ip2.active_until), '9999-12-01')
),
ip AS (
    SELECT course_dw_id,
           activity_dw_id,
           academic_year_id,
           activity_is_hidden
    FROM ip_ranked
    WHERE rn = 1
),
ip_course_check AS (
    SELECT DISTINCT course_dw_id, created_time, active_until
    FROM ip_base
),
ip_activity_check AS (
    SELECT DISTINCT course_dw_id, activity_dw_id, created_time, active_until
    FROM ip_base
)
SELECT DISTINCT dcr.course_id,
                dcr.course_name,
             dc.class_dw_id,
             dc.class_id,
             dc.class_title,
             dc.class_gen_subject,
             dc.class_grade_id,
             g.grade_k12grade                                                       AS grade_name,
             sch.school_id,
             sch.school_dw_id,
             sch.school_name,
             sch.school_city_name,
             sch.school_country_name,
             sch.school_status,
             sch.tenant_name,
             sch.school_organisation,
             dcaa.caa_activity_dw_id                                                 AS activity_dw_id,
             ic.ic_title,
             icr.ic_num_questions,
             DENSE_RANK() OVER (PARTITION BY dc.class_dw_id, dc.class_material_id, dc.class_gen_subject
                 ORDER BY dpg.pacing_activity_order) AS ic_order,
             dcsa.cs_subject_id AS course_subject_id,
             COALESCE(dpg.pacing_activity_order, 1)                                  AS instructional_plan_item_order,
             COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date,
                 sch.academic_year_start_date)                                       AS week_start_date,
             COALESCE(dpg.pacing_interval_end_date, dtrm.actp_teaching_period_end_date,
                 sch.academic_year_end_date)                                         AS week_end_date,
             COALESCE(dtrm.actp_teaching_period_order, 1)                            AS term_academic_period_order,
             COALESCE(dtrm.actp_teaching_period_start_date,
                 sch.academic_year_start_date)                                       AS term_start_date,
             COALESCE(dtrm.actp_teaching_period_end_date, sch.academic_year_end_date) AS term_end_date,
             CASE
                    WHEN dpg.pacing_interval_start_date IS NULL AND dtrm.actp_teaching_period_start_date IS NULL
                        THEN 'AY'
                    WHEN dpg.pacing_interval_start_date IS NULL AND dtrm.actp_teaching_period_start_date IS NOT NULL
                        THEN 'TERM'
                    ELSE dpg.pacing_interval_type END                                 AS pacing,
             sch.academic_year_start_date,
             sch.academic_year_end_date,
             DATE_PART_YEAR(sch.academic_year_start_date) || ' - ' ||
                DATE_PART_YEAR (sch.academic_year_end_date)                           AS academic_year
FROM alefdw.dim_course dcr
      INNER JOIN alefdw.dim_class dc
           ON dcr.course_id = dc.class_material_id
           AND dc.class_status = 1
      INNER JOIN alefdw.dim_grade g
           ON dc.class_grade_id = g.grade_id
      INNER JOIN bi_alefdw.bi_all_schools_dim_mv sch
           ON dc.class_school_id = sch.school_id
               AND g.academic_year_id = sch.academic_year_id
               AND DATE_PART_YEAR(sch.academic_year_start_date) >= 2022
      INNER JOIN alefdw.dim_course_activity_association dcaa
           ON dcr.course_dw_id = dcaa.caa_course_dw_id
               AND dcaa.caa_activity_is_optional IS FALSE
               AND dcaa.caa_activity_type = 2
               AND dcaa.caa_attach_status = 1
               AND sch.academic_year_end_date >= DATE(dcaa.caa_created_time)
               AND sch.academic_year_end_date <= COALESCE(DATE(dcaa.caa_updated_time),'9999-12-01')
               AND sch.academic_year_start_date <= COALESCE(DATE(dcaa.caa_updated_time),'9999-12-01')
      INNER JOIN alefdw.dim_interim_checkpoint ic
           ON dcaa.caa_activity_dw_id = ic.ic_dw_id
               AND ic.ic_status = 1
      LEFT JOIN (SELECT ic_rule_ic_dw_id,
                        SUM(ic_rule_no_questions) AS ic_num_questions
                 FROM alefdw.dim_interim_checkpoint_rules
                 WHERE ic_rule_status = 1
                 GROUP BY 1) icr
            ON icr.ic_rule_ic_dw_id = ic.ic_dw_id
      LEFT JOIN alefdw.dim_pacing_guide dpg
            ON dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
                AND dc.class_dw_id = dpg.pacing_class_dw_id
                AND sch.academic_year_end_date >= DATE(dpg.pacing_created_time)
                AND sch.academic_year_end_date <= COALESCE(DATE(dpg.pacing_updated_time),'9999-12-01')
                AND sch.academic_year_start_date <= COALESCE(DATE(dpg.pacing_updated_time),'9999-12-01')
      LEFT JOIN alefdw.dim_academic_calendar_teaching_period dtrm
            ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
                AND sch.academic_year_end_date >= DATE(dtrm.actp_created_time)
                AND sch.academic_year_end_date <= COALESCE(DATE(dtrm.actp_updated_time),'9999-12-01')
                AND sch.academic_year_start_date <= COALESCE(DATE(dtrm.actp_updated_time),'9999-12-01')
      LEFT JOIN alefdw.dim_course_subject_association dcsa
            ON dcsa.cs_course_dw_id=dcr.course_dw_id
                AND dcsa.cs_status=1
                AND dcsa.cs_subject_dw_id IN (129, 503) -- Arabits subject_dw_id , courses can have multiple subjects - with this condition we keep the unique value
      LEFT JOIN ip
            ON dcaa.caa_course_dw_id = ip.course_dw_id
                AND dcaa.caa_activity_dw_id = ip.activity_dw_id
                AND ip.activity_is_hidden IS FALSE
                AND sch.academic_year_id = ip.academic_year_id
      LEFT JOIN ip_course_check
            ON dcr.course_dw_id = ip_course_check.course_dw_id
                AND sch.academic_year_end_date >= DATE(ip_course_check.created_time)
                AND sch.academic_year_start_date <= COALESCE(DATE(ip_course_check.active_until),'9999-12-01')
      LEFT JOIN ip_activity_check
            ON dcr.course_dw_id = ip_activity_check.course_dw_id
                AND dcaa.caa_activity_dw_id = ip_activity_check.activity_dw_id
                AND sch.academic_year_end_date >= DATE(ip_activity_check.created_time)
                AND sch.academic_year_start_date <= COALESCE(DATE(ip_activity_check.active_until),'9999-12-01')
WHERE dcr.course_status = 1
  AND dcr.course_type = 'CORE'
  AND COALESCE(dpg.pacing_interval_start_date, dtrm.actp_teaching_period_start_date, sch.academic_year_start_date) <= sch.academic_year_end_date
  AND (
        (ip_course_check.course_dw_id IS NOT NULL AND ip.activity_dw_id IS NOT NULL AND dpg.pacing_activity_dw_id IS NOT NULL) --  If course exists in ip_course_check, then the specific activity must also have a match in the main 'ip' join and it should be in pacing
        OR (ip_course_check.course_dw_id IS NULL ) -- If course does not exist in ip_course_check, include all its activities
        OR (ip_course_check.course_dw_id IS NOT NULL AND ip_activity_check.activity_dw_id IS NULL)   -- If course exists in ip_course_check, but activity does not exists in IP - include those activities
    )
UNION ALL
SELECT * FROM bi_alefdw.core_ip_class_ic_content_mv;