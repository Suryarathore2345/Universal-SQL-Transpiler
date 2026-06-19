CREATE OR REPLACE VIEW bi_alefdw_dev.guardian_aggregared_alain_view AS
(
WITH calendar_year AS (SELECT a.*,
                              -- 🗓️ Calendar Year
                              DATE_TRUNC('year', week_start_date)::date                                         AS calendar_year_start_date,
                              (DATEADD(day, -1,
                                       DATEADD(year, 1, DATE_TRUNC('year', week_start_date))))::date            AS calendar_year_end_date,
                              DATE_TRUNC('month', week_start_date)::date                                        AS calendar_month_start_date,
                              (DATEADD(day, -1,
                                       DATEADD(month, 1, DATE_TRUNC('month', week_start_date))))::date          AS calendar_month_end_date
                       FROM (SELECT DISTINCT DATE_TRUNC('week', full_date
                                             ):: date AS week_start_date,
                                             DATE(DATE_TRUNC('week', full_date
                                                  ) + INTERVAL '6 day'
                                             )        AS week_end_date
                             FROM alefdw.dim_date
                             WHERE week_start_date <= CURRENT_DATE
                               AND full_date >= (SELECT min(activity_date)
                                                 FROM bi_alefdw.guardian_activity_dm_view
                                                 WHERE academic_year is not null)) a),
     max_ay AS (Select school_dw_id, max(academic_year) as max_ay from bi_alefdw.guardian_activity_dm_view group by 1)

SELECT calendar_year_start_date,
       calendar_year_end_date,
       calendar_month_start_date,
       calendar_month_end_date,
       cy.week_start_date,
       week_end_date,
       ga.school_dw_id,
       ga.school_name,
       ga.tenant_name,
       ga.organisation_dw_id,
       ga.school_organisation,
       REGEXP_REPLACE(max_ay, '-', ' - ')             AS AY,
       ga.guardian_dw_id,
       guardian_registered_date                       as registered_date,
       count(distinct case
                          when activity_date between week_start_date and week_end_date
                              then activity_date end) as active_days

FROM calendar_year cy
         CROSS JOIN bi_alefdw.guardian_activity_dm_view ga
         JOIN max_ay ay on ga.school_dw_id = ay.school_dw_id
where guardian_registered_date <= week_start_date
  AND lower(ga.school_city_name) = 'al ain'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
WITH NO SCHEMA BINDING;
