CREATE TABLE bi_alefdw_dev.students_stats_monthly AS
    WITH calendar_year AS (
    SELECT DISTINCT
        calendar_year_start_date,
        calendar_year_end_date,
        calendar_month_start_date,
        calendar_month_end_date
    FROM alefdw.dim_date
    WHERE calendar_month_start_date <= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1' day)
      AND date_part('year', calendar_year_start_date) >= 2018
),
login_data AS (
    SELECT
           date_trunc('month', login_local_date_time)  as cy_month,
           date(login_local_date_time) as login_date,
           ay.tenant_dw_id,
           ay.tenant_name_alias as tenant_name,
           ay.organisation_dw_id as content_repository_dw_id,
           ay.school_organisation as content_repository_name,
           ay.academic_year_start_date,
           ay.academic_year_end_date,
           sl.student_dw_id,
           sl.school_dw_id
    FROM bi_alefdw.student_login sl
             INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                     ON ds.student_dw_id = sl.student_dw_id
                          INNER JOIN alefdw.dim_grade dg
                                     ON dg.grade_dw_id = ds.student_grade_dw_id
             INNER JOIN  bi_alefdw.bi_all_schools_dim_mv ay
             ON ay.academic_year_id = dg.academic_year_id
             AND ay.school_id = dg.school_id
             AND sl.school_dw_id = ay.school_dw_id
             WHERE
                 date(sl.login_local_date_time) BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
                AND (date(login_local_date_time) >= date(ds.student_created_time)
                            AND (date(login_local_date_time) <= date(ds.student_active_until)
                                OR (ds.student_active_until is null and ds.student_status = 1))
                                )
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
             ay.tenant_dw_id,
             ay.tenant_name_alias                                          AS tenant_name,
             ay.organisation_dw_id                                         AS content_repository_dw_id,
             ay.school_organisation                                        AS content_repository_name,
             sch.school_city_name,
             sch.school_country_name,
             ay.academic_year_start_date,
             ay.academic_year_end_date,
             CAST(DATE_PART('year', ay.academic_year_start_date) AS VARCHAR) || '-' ||
             CAST(DATE_PART('year', ay.academic_year_end_date) AS VARCHAR) AS AY,
             ds.student_dw_id,
             sch.school_dw_id,
             sch.school_name,
             g.grade_name,
             first_login_date,
             CASE WHEN COUNT(sl.student_dw_id) > 0 THEN 1 ELSE 0 END       AS is_active
      FROM alefdw.dim_student ds
               CROSS JOIN calendar_year cy
               INNER JOIN alefdw.dim_grade g on ds.student_grade_dw_id = g.grade_dw_id
               INNER JOIN alefdw.dim_school sch
                          on sch.school_id = g.school_id and ds.student_school_dw_id = sch.school_dw_id
               INNER JOIN bi_alefdw.bi_all_schools_dim_mv ay
                          ON ay.academic_year_id = g.academic_year_id
                              AND ay.school_id = g.school_id
                              AND ds.student_school_dw_id = ay.school_dw_id
               LEFT JOIN login_data sl ON sl.student_dw_id = ds.student_dw_id
          AND sl.school_dw_id = ds.student_school_dw_id
          AND calendar_month_start_date = sl.cy_month
          AND sl.academic_year_start_date = ay.academic_year_start_date
          AND sl.academic_year_end_date = ay.academic_year_end_date
               LEFT JOIN onboarding_data onb ON onb.student_dw_id = ds.student_dw_id
          AND onb.school_dw_id = ds.student_school_dw_id
          AND onb.academic_year_start_date = ay.academic_year_start_date
          AND onb.academic_year_end_date = ay.academic_year_end_date

      WHERE (
          cy.calendar_month_start_date = DATE_TRUNC('month', ds.student_created_time)
              OR cy.calendar_month_start_date = ds.student_active_until
              OR (cy.calendar_month_start_date >= DATE_TRUNC('month', ds.student_created_time)
              AND cy.calendar_month_end_date <= DATE_TRUNC('month', ds.student_active_until))
              OR (ds.student_status = 1 AND ds.student_active_until IS NULL AND
                  cy.calendar_month_start_date >= DATE_TRUNC('month', student_created_time))
          )
        AND cy.calendar_month_start_date BETWEEN
          DATE_TRUNC('month', ay.academic_year_start_date)
          AND DATE_TRUNC('month', ay.academic_year_end_date)
        --AND ds.student_status in (1, 2)
      GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,16,17) reg
