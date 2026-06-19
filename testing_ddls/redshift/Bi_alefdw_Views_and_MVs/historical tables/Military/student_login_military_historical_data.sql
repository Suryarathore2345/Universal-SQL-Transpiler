DROP TABLE IF EXISTS bi_alefdw_dev.student_login_military_historical_data;
CREATE TABLE bi_alefdw_dev.student_login_military_historical_data DISTKEY (school_dw_id)
                                                                  SORTKEY (reg_student_dw_id, local_date) AS
WITH calendar_year AS (SELECT DISTINCT full_date
                       FROM alefdw.dim_date
                       WHERE
                           full_date <= (sysdate - INTERVAL '1' DAY)::DATE
                         AND date_part_year(full_date)::INT >= (date_part_year(sysdate::DATE)::INT) - 5),
     login_data AS (SELECT DISTINCT sl.login_local_date_time::DATE AS local_date,
                                    t.tenant_dw_id,
                                    t.tenant_name,
                                    ay.organisation_dw_id          AS content_repository_dw_id,
                                    ds.student_grade_dw_id,
                                    ay.school_organisation         AS content_repository_name,
                                    sl.student_dw_id
                    FROM bi_alefdw.student_login sl
                             INNER JOIN alefdw.dim_tenant t ON t.tenant_dw_id = sl.tenant_dw_id
                             INNER JOIN
                         bi_alefdw.bi_student_dim_mv ds
                         ON ds.student_dw_id = sl.student_dw_id
                             INNER JOIN alefdw.dim_grade dg
                                        ON dg.grade_dw_id = ds.student_grade_dw_id
                             INNER JOIN alefdw.dim_school sch
                                        ON sch.school_id = dg.school_id AND sch.school_dw_id = sl.school_dw_id
                             INNER JOIN bi_alefdw.bi_all_schools_dim_mv ay
                                        ON ay.academic_year_id = dg.academic_year_id
                                            AND ay.school_dw_id = sch.school_dw_id
                    WHERE
                        sl.school_dw_id in (2081, 2113, 2145)
                      AND (sl.login_local_date_time::DATE BETWEEN ay.academic_year_start_date AND ay.academic_year_end_date))

SELECT reg_data.*,
       log.student_dw_id    log_student_dw_id,
       CURRENT_TIMESTAMP AS inserted_at
FROM (SELECT DISTINCT date_part_year(ay.academic_year_start_date)::VARCHAR + ' - ' +
                      date_part_year(ay.academic_year_end_date)::VARCHAR AS academic_year,
                      academic_year_start_date,
                      academic_year_end_date,
                      sch.school_dw_id,
                      sch.school_id,
                      sch.school_name,
                      t.tenant_dw_id,
                      ds.student_dw_id                                   AS reg_student_dw_id,
                      ds.student_id                                      AS reg_student_id,
                      ay.organisation_dw_id                              AS content_repository_dw_id,
                      ay.school_organisation                             AS content_repository_name,
                      full_date::DATE                                    AS local_date,
                      t.tenant_name,
                      grade_dw_id,
                      grade_name
      FROM alefdw.dim_student ds
               CROSS JOIN calendar_year cy
               inner join alefdw.dim_grade g ON ds.student_grade_dw_id = g.grade_dw_id
               inner join alefdw.dim_school sch
                          ON sch.school_id = g.school_id
                              AND ds.student_school_dw_id = sch.school_dw_id
               inner join bi_alefdw.bi_all_schools_dim_mv ay
                          ON ay.academic_year_id = g.academic_year_id
                              AND ay.school_id = g.school_id
                              AND ds.student_school_dw_id = ay.school_dw_id
               inner join alefdw.dim_tenant t ON t.tenant_id = sch.school_tenant_id
      WHERE ds.student_school_dw_id in (2081, 2113, 2145)
        AND (
          full_date BETWEEN convert_timezone('UTC', t.tenant_timezone, ds.student_created_time)::DATE AND convert_timezone('UTC', t.tenant_timezone, ds.student_active_until)::DATE
              OR (student_status = 1 AND ds.student_active_until IS NULL AND
                  full_date >= convert_timezone('UTC', t.tenant_timezone, ds.student_created_time)::DATE))
        AND (full_date between ay.academic_year_start_date AND ay.academic_year_end_date)
     ) reg_data
         LEFT JOIN login_data log
                   ON log.tenant_dw_id = reg_data.tenant_dw_id
                       AND log.local_date::DATE = reg_data.local_date::DATE
                       AND reg_data.content_repository_dw_id = log.content_repository_dw_id
                       AND reg_data.content_repository_name = log.content_repository_name
                       AND reg_data.grade_dw_id = log.student_grade_dw_id
                       AND reg_data.reg_student_dw_id = log.student_dw_id;