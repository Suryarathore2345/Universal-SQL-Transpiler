-- =============================================================================
-- Registered, onboarded and logged-in students on a monthly basis (IDN)
-- Student-level: one row per student per calendar_month_start_date (within AY).
-- Includes student grade. No aggregation.
-- =============================================================================
CREATE MATERIALIZED VIEW bi_alefdw_dev.indonesia_student_login_mv as
(
WITH calendar_year AS (SELECT DISTINCT calendar_year_start_date,
                                       calendar_year_end_date,
                                       calendar_month_start_date,
                                       calendar_month_end_date
                       FROM alefdw.dim_date
                       WHERE calendar_month_start_date <= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1' day)
                         AND date_part('year', calendar_year_start_date) >= 2023),
     login_data AS (SELECT date_trunc('month', login_local_date_time) AS login_month,
                           date(login_local_date_time)                AS login_date,
                           ay.tenant_dw_id,
                           ay.tenant_name_alias                       AS tenant_name,
                           ay.organisation_dw_id                      AS content_repository_dw_id,
                           ay.school_organisation                     AS content_repository_name,
                           ay.academic_year_start_date,
                           ay.academic_year_end_date,
                           sl.student_dw_id,
                           sl.school_dw_id,
                           ds.student_grade_dw_id
                    FROM bi_alefdw.student_login sl
                             INNER JOIN bi_alefdw.bi_student_dim_mv ds
                                        ON ds.student_dw_id = sl.student_dw_id
                             INNER JOIN alefdw.dim_grade dg
                                        ON dg.grade_dw_id = ds.student_grade_dw_id
                             INNER JOIN alefdw.dim_school dsch
                                        ON dsch.school_dw_id = ds.student_school_dw_id
                             INNER JOIN bi_alefdw.bi_all_schools_dim_mv ay
                                        ON dsch.school_dw_id = ay.school_dw_id
                                            AND sl.school_dw_id = ay.school_dw_id
                                            AND sl.tenant_dw_id = ay.tenant_dw_id
                    WHERE lower(ay.tenant_name) = 'idn'
                      AND date_part('year', ay.academic_year_start_date) >= 2023
                      AND date(sl.login_local_date_time) BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date
                      AND (
                        (ds.student_status IN (2, 3, 4)
                            AND trunc(login_local_date_time) >=
                                trunc(convert_timezone('UTC', dsch.school_timezone, ds.student_created_time))
                            AND trunc(login_local_date_time) <
                                trunc(convert_timezone('UTC', dsch.school_timezone, ds.student_active_until)))
                            OR (ds.student_status = 1
                            AND trunc(login_local_date_time) >=
                                trunc(convert_timezone('UTC', dsch.school_timezone, ds.student_created_time)))
                        )),
     student_registrations AS (SELECT DISTINCT str.student_dw_id,
                                               str.student_school_dw_id,
                                               str.academic_year_start_date,
                                               str.academic_year_end_date,
                                               cast((extract(year from str.academic_year_start_date)::varchar || '-' || extract(year from  str.academic_year_end_date)::varchar) as varchar) as
                                               academic_year,
                                               str.student_grade_dw_id,
                                               str.tenant_dw_id,
                                               str.organisation_dw_id,
                                               str.student_status,
                                               trunc(str.student_first_created_date)                          AS student_first_created_date
                               FROM (SELECT dst.student_dw_id,
                                            dst.student_school_dw_id             AS student_school_dw_id,
                                            dsc.academic_year_start_date,
                                            dsc.academic_year_end_date,
                                            dst.student_grade_dw_id,
                                            dsc.tenant_dw_id,
                                            dsc.organisation_dw_id,
                                            max(dst.student_status)              AS student_status,
                                            min(trunc(dst.student_created_time)) AS student_first_created_date
                                     FROM alefdw.dim_student dst
                                              INNER JOIN alefdw.dim_grade dg ON dg.grade_dw_id = dst.student_grade_dw_id
                                              INNER JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                                                         ON dsc.academic_year_id = dg.academic_year_id
                                                             AND dsc.school_id = dg.school_id
                                                             AND dst.student_school_dw_id = dsc.school_dw_id
                                     WHERE date_part('year', dsc.academic_year_start_date) >= 2023
                                       AND lower(dsc.tenant_name) = 'idn'
                                     GROUP BY dst.student_dw_id, dst.student_school_dw_id, dsc.academic_year_start_date,
                                              dsc.academic_year_end_date,
                                              dst.student_grade_dw_id, dsc.organisation_dw_id, dsc.tenant_dw_id) str),

    onboarding_data AS (SELECT date_trunc('month', login_date)::DATE AS onb_month,
                                tenant_dw_id,
                                tenant_name,
                                content_repository_dw_id,
                                content_repository_name,
                                academic_year_start_date,
                                academic_year_end_date,
                                student_dw_id,
                                school_dw_id,
                                student_grade_dw_id,
                                min(login_date)                       AS student_first_login_date
                         FROM login_data
                         GROUP BY date_trunc('month', login_date),
                                  tenant_dw_id,
                                  tenant_name,
                                  content_repository_dw_id,
                                  content_repository_name,
                                  academic_year_start_date,
                                  academic_year_end_date,
                                  student_dw_id,
                                  school_dw_id,
                                  student_grade_dw_id),

-- Spine: one row per student per calendar month (within that student's AY)
     student_month_spine AS (SELECT cy.calendar_month_start_date,
                                    cy.calendar_month_end_date,
                                    str.student_dw_id,
                                    str.student_school_dw_id AS school_dw_id,
                                    str.academic_year_start_date,
                                    str.academic_year_end_date,
                                    str.academic_year,
                                    str.student_grade_dw_id,
                                    str.tenant_dw_id,
                                    str.organisation_dw_id,
                                    str.student_status,
                                    str.student_first_created_date
                             FROM student_registrations str
                                      INNER JOIN calendar_year cy
                                                 ON cy.calendar_month_start_date BETWEEN date_trunc('month', str.academic_year_start_date)
                                                     AND date_trunc('month', str.academic_year_end_date)
                             WHERE str.student_first_created_date IS NOT NULL
                               AND str.student_first_created_date BETWEEN str.academic_year_start_date AND str.academic_year_end_date)

     SELECT distinct
       sms.calendar_month_start_date,
       sms.calendar_month_end_date,
       dsc.school_name,
       dsc.school_dw_id,
       dsc.tenant_dw_id,
       dsc.tenant_name,
       dsc.organisation_dw_id                                    AS org_dw_id,
       dsc.school_organisation                                   AS organization_name,
       dsc.school_city_name,
       dsc.school_label,
       dsc.school_country_name,
       dsc.academic_year_id,
       dsc.academic_year_start_date,
       dsc.academic_year_end_date,
       sms.academic_year,
       dst.student_dw_id,
       dst.student_id,
       sms.student_status,
       g.grade_dw_id,
       g.grade_name,
       g.grade_id,
       CASE
           WHEN date_trunc('month', sms.student_first_created_date) = sms.calendar_month_start_date THEN 1
           ELSE 0 END                                            AS is_registered,
       CASE WHEN onb.student_first_login_date IS NOT NULL
       AND date_trunc('month', onb.student_first_login_date) = sms.calendar_month_start_date THEN 1 ELSE 0 END AS is_onboarded,
       CASE WHEN sl.student_dw_id IS NOT NULL THEN 1 ELSE 0 END  AS is_active,
       CASE WHEN sl_next_month.student_dw_id IS NOT NULL THEN 1 ELSE 0 END AS is_active_next_month
FROM student_month_spine sms
         INNER JOIN alefdw.dim_student dst
                    ON dst.student_dw_id = sms.student_dw_id
                        AND dst.student_school_dw_id = sms.school_dw_id
         INNER JOIN bi_alefdw.bi_all_schools_dim_mv dsc
                    ON dsc.school_dw_id = sms.school_dw_id
                        AND dsc.academic_year_start_date = sms.academic_year_start_date
                        AND dsc.academic_year_end_date = sms.academic_year_end_date
                        AND lower(dsc.tenant_name) = 'idn'
         INNER JOIN alefdw.dim_grade g
                    ON g.grade_dw_id = sms.student_grade_dw_id
                        AND g.school_id = dsc.school_id
                        AND g.academic_year_id = dsc.academic_year_id
         LEFT JOIN onboarding_data onb
                   ON onb.student_dw_id = sms.student_dw_id
                       AND onb.school_dw_id = sms.school_dw_id
                       AND onb.student_grade_dw_id = sms.student_grade_dw_id
                       AND onb.onb_month = sms.calendar_month_start_date
                       AND onb.academic_year_start_date = sms.academic_year_start_date
                       AND onb.academic_year_end_date = sms.academic_year_end_date
         LEFT JOIN (SELECT DISTINCT student_dw_id,
                                    school_dw_id,
                                    student_grade_dw_id,
                                    login_month AS calendar_month_start_date,
                                    academic_year_start_date,
                                    academic_year_end_date
                    FROM login_data) sl
                   ON sl.student_dw_id = sms.student_dw_id
                       AND sl.school_dw_id = sms.school_dw_id
                       AND sl.student_grade_dw_id = sms.student_grade_dw_id
                       AND sl.calendar_month_start_date = sms.calendar_month_start_date
                       AND sl.academic_year_start_date = sms.academic_year_start_date
                       AND sl.academic_year_end_date = sms.academic_year_end_date
         LEFT JOIN (SELECT DISTINCT student_dw_id,
                                    school_dw_id,
                                    student_grade_dw_id,
                                    login_month AS calendar_month_start_date,
                                    academic_year_start_date,
                                    academic_year_end_date
                    FROM login_data) sl_next_month
                   ON sl_next_month.student_dw_id = sms.student_dw_id
                       AND sl_next_month.school_dw_id = sms.school_dw_id
                       AND sl_next_month.student_grade_dw_id = sms.student_grade_dw_id
                       AND
                      sl_next_month.calendar_month_start_date = trunc(DATEADD(month, 1, sms.calendar_month_start_date))
                       AND sl_next_month.academic_year_start_date = sms.academic_year_start_date
                       AND sl_next_month.academic_year_end_date = sms.academic_year_end_date
         );