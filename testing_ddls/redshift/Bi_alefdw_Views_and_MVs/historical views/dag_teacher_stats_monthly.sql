CREATE OR REPLACE VIEW bi_alefdw_dev.dag_teacher_stats_monthly AS
    WITH calendar_year AS (
    SELECT DISTINCT
        calendar_year_start_date,
        calendar_year_end_date,
        calendar_month_start_date,
        calendar_month_end_date
    FROM alefdw.dim_date
    WHERE calendar_month_start_date = date_trunc('month', sysdate - interval '1' day)
),
login_data AS (
                    SELECT date_trunc('month', login_local_date_time)  as cy_month,
                           date(login_local_date_time) as login_date,
                           ay.tenant_dw_id,
                           ay.tenant_name_alias as tenant_name,
                           ay.academic_year_end_date,
                           ay.academic_year_start_date,
                           ay.organisation_dw_id as content_repository_dw_id,
                           ay.school_organisation as content_repository_name,
                           tl.school_dw_id,
                           tl.teacher_dw_id
                    FROM bi_alefdw.teacher_login tl
                             JOIN alefdw.dim_teacher dt
                                  ON dt.teacher_school_dw_id = tl.school_dw_id
                                      AND dt.teacher_dw_id = tl.teacher_dw_id
                             JOIN alefdw.dim_school sch
                                  on sch.school_dw_id = dt.teacher_school_dw_id
                             JOIN bi_alefdw.bi_all_schools_dim_mv ay
                                  ON ay.school_id = sch.school_id
                                      AND dt.teacher_school_dw_id = ay.school_dw_id
                                      AND (date(tl.login_local_date_time) BETWEEN ay.academic_year_start_date
                                          AND ay.academic_year_end_date)
                    WHERE dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
                    AND date_trunc('month',login_local_date_time) >= date_trunc('month', sysdate - interval '365' day)
),
onboarding_data AS (
    SELECT
           tenant_dw_id,
           tenant_name,
           content_repository_dw_id,
           content_repository_name,
           academic_year_start_date,
           academic_year_end_date,
           teacher_dw_id,
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
             ay.academic_year_start_date,
             ay.academic_year_end_date,
             CAST(DATE_PART('year', ay.academic_year_start_date) AS VARCHAR) || '-' ||
             CAST(DATE_PART('year', ay.academic_year_end_date) AS VARCHAR) AS AY,
             dt.teacher_dw_id,
             sch.school_dw_id,
             sch.school_name,
             sch.school_city_name,
             sch.school_country_name,
             first_login_date,
             CASE WHEN COUNT(sl.teacher_dw_id) > 0 THEN 1 ELSE 0 END       AS is_active
      FROM alefdw.dim_teacher dt
               CROSS JOIN calendar_year cy
               INNER JOIN alefdw.dim_school sch ON dt.teacher_school_dw_id = sch.school_dw_id
               INNER JOIN bi_alefdw.bi_all_schools_dim_mv ay
                          ON ay.school_id = sch.school_id
                              AND dt.teacher_school_dw_id = ay.school_dw_id
                LEFT JOIN login_data sl ON sl.teacher_dw_id = dt.teacher_dw_id
                  AND sl.school_dw_id = dt.teacher_school_dw_id
                  AND calendar_month_start_date = sl.cy_month
                  AND sl.academic_year_start_date = ay.academic_year_start_date
                  AND sl.academic_year_end_date = ay.academic_year_end_date
                       LEFT JOIN onboarding_data onb ON onb.teacher_dw_id = dt.teacher_dw_id
                  AND onb.school_dw_id = dt.teacher_school_dw_id
                  AND onb.academic_year_start_date = ay.academic_year_start_date
                  AND onb.academic_year_end_date = ay.academic_year_end_date

      WHERE (
           calendar_month_start_date = DATE_TRUNC('month', dt.teacher_created_time)
              OR calendar_month_end_date = DATE_TRUNC('month', dt.teacher_active_until)
              OR (
              calendar_month_start_date >= DATE_TRUNC('month', dt.teacher_created_time)
                  AND  calendar_month_end_date <= DATE_TRUNC('month', dt.teacher_active_until)
              )
              OR
          (dt.teacher_active_until is null and teacher_status = 1 and
           calendar_year_end_date >= DATE_TRUNC('month', teacher_created_time))
          )
        AND (sch.school_status = 1
          OR DATE_TRUNC('month', sch.school_updated_time) >=  calendar_month_start_date
          )
        AND cy.calendar_month_start_date BETWEEN
          DATE_TRUNC('month', ay.academic_year_start_date)
          AND DATE_TRUNC('month', ay.academic_year_end_date)
      GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,15,16
      ) reg
WITH NO SCHEMA BINDING
