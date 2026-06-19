CREATE MATERIALIZED VIEW bi_alefdw_dev.alain_students_login_mv AS(
WITH calendar_year AS (
SELECT
    a.*,
        -- 🗓️ Calendar Year
    DATE_TRUNC('year', week_start_date)::date AS calendar_year_start_date,
    (DATEADD(day, -1, DATEADD(year, 1, DATE_TRUNC('year', week_start_date))))::date AS calendar_year_end_date,
    DATE_TRUNC('month', week_start_date)::date AS calendar_month_start_date,
    (DATEADD(day, -1, DATEADD(month, 1, DATE_TRUNC('month', week_start_date))))::date AS calendar_month_end_date
FROM (
   SELECT DISTINCT
    DATE_TRUNC('week', full_date)::date AS week_start_date,
    date(DATE_TRUNC('week', full_date) + INTERVAL '6 day')  AS week_end_date
FROM alefdw.dim_date
WHERE week_start_date <=  CURRENT_DATE
  AND calendar_year_start_date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '2 year')a
),
prev_academic_year AS
 ( SELECT DATEADD(year, -1, DATE_TRUNC('year', MAX(academic_year_start_date)))::date as prev_AY
                     FROM bi_alefdw.bi_all_schools_dim_mv
                     where lower(school_city_name) = 'al ain'),
login_data AS (
    SELECT
           DATE_TRUNC('month', login_local_date_time)  as cy_month,
           DATE_TRUNC('week', login_local_date_time) as cy_week_start,
           DATE_TRUNC('week', login_local_date_time) + INTERVAL '6 day' as cy_week_end,
           date(login_local_date_time) as login_date,
           ay.tenant_dw_id,
           ay.tenant_name_alias as tenant_name,
           ay.organisation_dw_id as content_repository_dw_id,
           ay.school_organisation as content_repository_name,
           ay.academic_year_start_date,
           ay.academic_year_end_date,
           sl.student_dw_id,
           sl.school_dw_id,
           sec.section_name,
           sec.section_dw_id
    FROM bi_alefdw.student_login sl
             INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                     ON ds.student_dw_id = sl.student_dw_id
                          INNER JOIN alefdw.dim_grade dg
                                     ON dg.grade_dw_id = ds.student_grade_dw_id
                          INNER JOIN alefdw.dim_section sec
                                     ON ds.student_section_dw_id = sec.section_dw_id
             INNER JOIN  bi_alefdw.bi_all_schools_dim_mv ay
             ON ay.academic_year_id = dg.academic_year_id
             AND ay.school_id = dg.school_id
             AND sl.school_dw_id = ay.school_dw_id
             CROSS JOIN prev_academic_year
             WHERE
                 date(sl.login_local_date_time) BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
                AND (date(login_local_date_time) >= date(ds.student_created_time)
                            AND (date(login_local_date_time) <= date(ds.student_active_until)
                                OR (ds.student_active_until is null and ds.student_status = 1))
                                )
                AND lower(school_city_name) = 'al ain'
                AND login_date >=  prev_AY
),
onboarding_data AS (
    SELECT
           tenant_dw_id,
           tenant_name,
           content_repository_dw_id,
           content_repository_name,
           academic_year_start_date,
           academic_year_end_date,
           student_dw_id,
           school_dw_id,
           min(login_date) as first_login_date
    FROM login_data
    GROUP BY 1,2,3,4,5,6,7,8
)
SELECT reg.*,
       CURRENT_TIMESTAMP::timestamp AS inserted_at
FROM (SELECT cy.calendar_year_end_date,
             cy.calendar_month_end_date,
             cy.calendar_month_start_date,
             week_start_date,
             week_end_date,
             ay.tenant_dw_id,
             ay.tenant_name_alias                                          AS tenant_name,
             ay.organisation_dw_id                                         AS content_repository_dw_id,
             ay.school_organisation                                        AS content_repository_name,
             sch.school_city_name,
             sch.school_country_name,
             ay.academic_year_start_date,
             ay.academic_year_end_date,
             cast((extract(year from ay.academic_year_start_date)::varchar || ' - ' || extract(year from  ay.academic_year_end_date)::varchar) as varchar) as AY,
             ds.student_dw_id,
             sch.school_dw_id,
             sch.school_name,
             g.grade_name,
             sec.section_dw_id,
             sec.section_name,
             first_login_date,
             CASE WHEN COUNT(sl.student_dw_id) > 0 THEN 1 ELSE 0 END       AS is_active,
             count(distinct date(login_date)) as active_days
      FROM alefdw.dim_student ds
               CROSS JOIN calendar_year cy
               CROSS JOIN prev_academic_year pv
               INNER JOIN alefdw.dim_grade g on ds.student_grade_dw_id = g.grade_dw_id
               INNER JOIN alefdw.dim_section sec
                        ON ds.student_section_dw_id = sec.section_dw_id
               INNER JOIN alefdw.dim_school sch
                          on sch.school_id = g.school_id and ds.student_school_dw_id = sch.school_dw_id
               INNER JOIN bi_alefdw.bi_all_schools_dim_mv ay
                          ON ay.academic_year_id = g.academic_year_id
                              AND ay.school_id = g.school_id
                              AND ds.student_school_dw_id = ay.school_dw_id
                              AND lower(ay.school_city_name) = 'al ain'
               LEFT JOIN login_data sl ON sl.student_dw_id = ds.student_dw_id
          AND sl.school_dw_id = ds.student_school_dw_id
          AND week_start_date = sl.cy_week_start
          AND sl.academic_year_start_date = ay.academic_year_start_date
          AND sl.academic_year_end_date = ay.academic_year_end_date
               LEFT JOIN onboarding_data onb ON onb.student_dw_id = ds.student_dw_id
          AND onb.school_dw_id = ds.student_school_dw_id
          AND onb.academic_year_start_date = ay.academic_year_start_date
          AND onb.academic_year_end_date = ay.academic_year_end_date

      WHERE (
          cy.week_start_date = DATE_TRUNC('week', ds.student_created_time)
              OR cy.week_start_date = ds.student_active_until
              OR (cy.week_start_date >=  DATE_TRUNC('week', ds.student_created_time)
              AND cy.week_end_date <=   DATE_TRUNC('week', ds.student_active_until)
              OR (ds.student_status = 1 AND ds.student_active_until IS NULL AND
                  cy.week_start_date >=  DATE_TRUNC('week', ds.student_created_time)
                  )
          ))
        AND cy.week_start_date BETWEEN
          DATE_TRUNC('week', ay.academic_year_start_date) AND DATE_TRUNC('week', ay.academic_year_end_date)
        AND ay.academic_year_start_date >= pv.prev_AY
        --AND ds.student_status in (1, 2)
      GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,16,17,18,19,20,21) reg)
