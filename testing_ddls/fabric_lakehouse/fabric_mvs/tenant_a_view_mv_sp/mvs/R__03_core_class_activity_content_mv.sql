CREATE or Replace MATERIALIZED LAKE VIEW {{os_bi_coredw}}.core_class_activity_content_mv
AS
WITH ip_base AS (
    SELECT
        course_dw_id,
        course_id,
        activity_dw_id,
        created_time,
        active_until,
        activity_is_hidden,
        event_type
    FROM {{rs_coredw}}.dim_course_activity_ip_association
    WHERE event_type = 'InstructionalPlanPublishedEvent'
),
ip_ranked AS (
    SELECT
        ip2.course_dw_id,
        ip2.activity_dw_id,
        ip2.activity_is_hidden,
        sch2.academic_year_id,
        sch2.academic_year_start_date,
        ROW_NUMBER() OVER (
            PARTITION BY ip2.course_dw_id, ip2.activity_dw_id, sch2.academic_year_id
            ORDER BY ip2.created_time DESC
        ) AS rn
    FROM ip_base AS ip2
    JOIN {{rs_coredw}}.dim_class AS dc2
        ON ip2.course_id = dc2.class_material_id
       AND dc2.class_status = 1
    JOIN {{rs_coredw}}.dim_grade AS g
        ON g.grade_id = dc2.class_grade_id
    JOIN {{rs_bi_coredw}}.bi_all_schools_dim AS sch2
        ON dc2.class_school_id = sch2.school_id
       AND g.academic_year_id = sch2.academic_year_id
       AND sch2.academic_year_end_date   >= DATE(ip2.created_time)
       AND sch2.academic_year_start_date <= COALESCE(DATE(ip2.active_until), DATE('9999-12-01'))
),
ip AS (
    SELECT
        course_dw_id,
        activity_dw_id,
        academic_year_id,
        activity_is_hidden
    FROM ip_ranked
    WHERE rn = 1
),
ip_course_check AS (
    SELECT DISTINCT
        course_dw_id,
        created_time,
        active_until
    FROM ip_base
),
ip_activity_check AS (
    SELECT DISTINCT
        course_dw_id,
        activity_dw_id,
        created_time,
        active_until
    FROM ip_base
)
SELECT DISTINCT
    dcr.course_id,
    dcr.course_name,
    dc.class_dw_id,
    dc.class_id,
    UPPER(dc.class_title)                                                   AS class_title,
    UPPER(dc.class_gen_subject)                                             AS class_gen_subject,
    dc.class_grade_id,
    g.grade_k12grade                                                        AS grade_name,
    sch.school_id,
    sch.school_dw_id,
    sch.school_name,
    sch.school_alias,
    sch.school_label,
    sch.school_cx_cluster,
    sch.school_city_name,
    sch.school_country_name,
    sch.tenant_name,
    sch.school_organisation,
    dcaa.caa_activity_dw_id                                                 AS activity_dw_id,
    dip_dlo.lo_title,
    dcsa.cs_subject_id                                                      AS course_subject_id,
    COALESCE(dpg.pacing_activity_order, 1)                                  AS instructional_plan_item_order,
    COALESCE(
        dpg.pacing_interval_start_date,
        dtrm.actp_teaching_period_start_date,
        sch.academic_year_start_date
    )                                                                        AS week_start_date,
    COALESCE(
        dpg.pacing_interval_end_date,
        dtrm.actp_teaching_period_end_date,
        sch.academic_year_end_date
    )                                                                        AS week_end_date,
    COALESCE(dtrm.actp_teaching_period_order, 1)                            AS term_academic_period_order,
    COALESCE(
        dtrm.actp_teaching_period_start_date,
        sch.academic_year_start_date
    )                                                                        AS term_start_date,
    COALESCE(
        dtrm.actp_teaching_period_end_date,
        sch.academic_year_end_date
    )                                                                        AS term_end_date,
    CASE
        WHEN dpg.pacing_interval_start_date IS NULL
         AND dtrm.actp_teaching_period_start_date IS NULL
            THEN 'AY'
        WHEN dpg.pacing_interval_start_date IS NULL
         AND dtrm.actp_teaching_period_start_date IS NOT NULL
            THEN 'TERM'
        ELSE dpg.pacing_interval_type
    END                                                                      AS pacing,
    sch.academic_year_start_date,
    sch.academic_year_end_date,
    sch.academic_year_id,
    CONCAT(
        CAST(YEAR(sch.academic_year_start_date) AS STRING),
        ' - ',
        CAST(YEAR(sch.academic_year_end_date) AS STRING)
    )                                                                        AS academic_year
FROM {{rs_coredw}}.dim_course AS dcr
INNER JOIN {{rs_coredw}}.dim_class AS dc
    ON dcr.course_id = dc.class_material_id
   AND dc.class_status = 1
INNER JOIN {{rs_coredw}}.dim_grade AS g
    ON dc.class_grade_id = g.grade_id
INNER JOIN {{rs_bi_coredw}}.bi_all_schools_dim AS sch
    ON dc.class_school_id   = sch.school_id
   AND g.academic_year_id   = sch.academic_year_id
   AND YEAR(sch.academic_year_start_date) >= 2022
INNER JOIN {{rs_coredw}}.dim_course_activity_association AS dcaa
    ON dcr.course_dw_id = dcaa.caa_course_dw_id
   AND dcaa.caa_activity_is_optional = FALSE
   AND dcaa.caa_activity_type        = 1
   AND dcaa.caa_attach_status        = 1
   AND sch.academic_year_end_date    >= DATE(dcaa.caa_created_time)
   AND sch.academic_year_end_date    <= COALESCE(DATE(dcaa.caa_updated_time), DATE('9999-12-01'))
   AND sch.academic_year_start_date  <= COALESCE(DATE(dcaa.caa_updated_time), DATE('9999-12-01'))
INNER JOIN {{rs_coredw}}.dim_learning_objective AS dip_dlo
    ON dcaa.caa_activity_dw_id = dip_dlo.lo_dw_id
   AND COALESCE(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
   AND COALESCE(dip_dlo.lo_template_uuid, 'NA')
       NOT IN (
           '235229fa-4707-4286-8ec2-85f70347096a',
           '15295fd1-b5e3-46f9-9045-86ee3b13552b'
       )
   AND dip_dlo.lo_status = 1
LEFT JOIN {{rs_coredw}}.dim_pacing_guide AS dpg
    ON dcaa.caa_activity_dw_id = dpg.pacing_activity_dw_id
   AND dc.class_dw_id          = dpg.pacing_class_dw_id
   AND sch.academic_year_end_date   >= DATE(dpg.pacing_created_time)
   AND sch.academic_year_end_date   <= COALESCE(DATE(dpg.pacing_updated_time), DATE('9999-12-01'))
   AND sch.academic_year_start_date <= COALESCE(DATE(dpg.pacing_updated_time), DATE('9999-12-01'))
LEFT JOIN {{rs_coredw}}.dim_academic_calendar_teaching_period AS dtrm
    ON dpg.pacing_period_id = dtrm.actp_teaching_period_id
   AND sch.academic_year_end_date   >= DATE(dtrm.actp_created_time)
   AND sch.academic_year_end_date   <= COALESCE(DATE(dtrm.actp_updated_time), DATE('9999-12-01'))
   AND sch.academic_year_start_date <= COALESCE(DATE(dtrm.actp_updated_time), DATE('9999-12-01'))
LEFT JOIN {{rs_coredw}}.dim_course_subject_association AS dcsa
    ON dcsa.cs_course_dw_id  = dcr.course_dw_id
   AND dcsa.cs_status        = 1
   AND dcsa.cs_subject_dw_id IN (129, 503)  -- Arabits subject_dw_id
LEFT JOIN ip
    ON dcaa.caa_course_dw_id   = ip.course_dw_id
   AND dcaa.caa_activity_dw_id = ip.activity_dw_id
   AND ip.activity_is_hidden   IS FALSE
   AND sch.academic_year_id    = ip.academic_year_id
LEFT JOIN ip_course_check
    ON dcr.course_dw_id            = ip_course_check.course_dw_id
   AND sch.academic_year_end_date  >= DATE(ip_course_check.created_time)
   AND sch.academic_year_start_date<= COALESCE(DATE(ip_course_check.active_until), DATE('9999-12-01'))
LEFT JOIN ip_activity_check
    ON dcr.course_dw_id            = ip_activity_check.course_dw_id
   AND dcaa.caa_activity_dw_id     = ip_activity_check.activity_dw_id
   AND sch.academic_year_end_date  >= DATE(ip_activity_check.created_time)
   AND sch.academic_year_start_date<= COALESCE(DATE(ip_activity_check.active_until), DATE('9999-12-01'))
WHERE dcr.course_status = 1
  AND dcr.course_type   = 'CORE'
  AND COALESCE(
        dpg.pacing_interval_start_date,
        dtrm.actp_teaching_period_start_date,
        sch.academic_year_start_date
      ) <= sch.academic_year_end_date
  AND (
        -- If course exists in ip_course_check, then the specific activity
        -- must also have a match in 'ip' and it should be in pacing
        (ip_course_check.course_dw_id IS NOT NULL
         AND ip.activity_dw_id        IS NOT NULL
         AND dpg.pacing_activity_dw_id IS NOT NULL)
        -- If course does not exist in ip_course_check, include all its activities
        OR (ip_course_check.course_dw_id IS NULL)
        -- If course exists in ip_course_check, but activity does not exist in IP – include those activities
        OR (ip_course_check.course_dw_id IS NOT NULL
            AND ip_activity_check.activity_dw_id IS NULL)
      )

UNION ALL
SELECT 
    course_id,
    course_name,
    class_dw_id,
    class_id,
    class_title,
    class_gen_subject,
    class_grade_id,
    grade_name,
    school_id,
    school_dw_id,
    school_name,
    school_alias,
    school_label,
    school_cx_cluster,
    school_city_name,
    school_country_name,
    tenant_name,
    school_organisation,
    activity_dw_id,
    lo_title,
    course_subject_id,
    instructional_plan_item_order,
    week_start_date,
    week_end_date,
    term_academic_period_order,
    term_start_date,
    term_end_date,
    pacing,
    academic_year_start_date,
    academic_year_end_date,
    academic_year_id,
    academic_year
FROM {{rs_bi_coredw}}.core_ip_class_activity_content;