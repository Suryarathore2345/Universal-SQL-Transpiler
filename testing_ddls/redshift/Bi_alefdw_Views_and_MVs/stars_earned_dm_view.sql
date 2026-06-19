CREATE OR REPLACE VIEW bi_alefdw_dev.stars_earned_dm_view
AS
WITH fle_stars AS (SELECT DISTINCT dsc.tenant_name,
                              dsc.school_dw_id,
                              dsc.school_name,
                              dsc.school_organisation,
                              dsc.organisation_dw_id,
                              dg.grade_name,
                              dg.grade_dw_id,
                              fle.fle_student_dw_id                                    AS student_dw_id,
                              LOWER(fle.fle_material_type)                             AS course_type,
                              fle.created_date,
                              DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                              DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                              SUM(fle.max_stars)                                       AS total_stars
                    FROM (SELECT fle_lo_dw_id,
                                 fle_student_dw_id,
                                 fle_material_type,
                                 MAX(CAST(fle_created_time AS DATE)) AS created_date,
                                 MAX(fle_star_earned)                AS max_stars
                            FROM alefdw.fact_learning_experience
                                WHERE UPPER(fle_material_type) <> 'PATHWAY'
                                AND fle_is_activity_completed = TRUE
                                AND fle_star_earned > 0
                            GROUP BY 1,2,3) fle
                          JOIN bi_alefdw.bi_student_dim_mv dst
                               ON fle.fle_student_dw_id = dst.student_dw_id
                                   AND dst.student_status = 1
                          JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                              ON dst.student_school_dw_id = dsc.school_dw_id
                                   AND TRUNC(created_date) BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
                          JOIN alefdw.dim_grade dg
                              ON dg.grade_dw_id = dst.student_grade_dw_id
                    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

ktg_stars AS (SELECT DISTINCT dsc.tenant_name,
                              dsc.school_dw_id,
                              dsc.school_name,
                              dsc.school_organisation,
                              dsc.organisation_dw_id,
                              dg.grade_name,
                              dg.grade_dw_id,
                              fks.ktg_session_student_dw_id                           AS student_dw_id,
                              LOWER(fks.ktg_session_material_type)                    AS course_type,
                              fks.created_date,
                              DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                              DATE_PART(YEAR, dsc.academic_year_end_date)             AS academic_year,
                              SUM(fks.max_stars)                                      AS total_stars
                    FROM (SELECT ktg_session_dw_id,
                                 ktg_session_student_dw_id,
                                 ktg_session_material_type,
                                 MAX(CAST(ktg_session_dw_created_time AS DATE)) AS created_date,
                                 MAX(ktg_session_stars)                         AS max_stars
                              FROM alefdw.fact_ktg_session
                                 WHERE UPPER(ktg_session_material_type) <> 'PATHWAY'
                                 AND ktg_session_stars > 0
                              GROUP BY 1,2,3) fks
                          JOIN bi_alefdw.bi_student_dim_mv dst
                               ON fks.ktg_session_student_dw_id = dst.student_dw_id
                                    AND dst.student_status = 1
                          JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                              ON dst.student_school_dw_id = dsc.school_dw_id
                                    AND TRUNC(created_date) BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
                          JOIN alefdw.dim_grade dg
                              ON dg.grade_dw_id = dst.student_grade_dw_id
                    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

pract_stars AS (SELECT DISTINCT dsc.tenant_name,
                                dsc.school_dw_id,
                                dsc.school_name,
                                dsc.school_organisation,
                                dsc.organisation_dw_id,
                                dg.grade_name,
                                dg.grade_dw_id,
                                fps.practice_session_student_dw_id                       AS student_dw_id,
                                LOWER(fps.practice_session_material_type)                AS course_type,
                                fps.created_date,
                                DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                                DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                                SUM(fps.max_stars)                                       AS total_stars
                   FROM (SELECT practice_session_dw_id,
                                practice_session_student_dw_id,
                                practice_session_material_type,
                                MAX(CAST(practice_session_dw_created_time AS DATE)) AS created_date,
                                MAX(practice_session_stars)                         AS max_stars
                          FROM alefdw.fact_practice_session
                             WHERE UPPER(practice_session_material_type) <> 'PATHWAY'
                             AND practice_session_stars > 0
                          GROUP BY 1,2,3) fps
                        JOIN bi_alefdw.bi_student_dim_mv dst
                             ON fps.practice_session_student_dw_id = dst.student_dw_id
                                AND dst.student_status = 1
                        JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                             ON dst.student_school_dw_id = dsc.school_dw_id
                                AND TRUNC(created_date) BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
                        JOIN alefdw.dim_grade dg
                             ON dg.grade_dw_id = dst.student_grade_dw_id
                   GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

awards_stars AS (SELECT DISTINCT dsc.tenant_name,
                                 dsc.school_dw_id,
                                 dsc.school_name,
                                 dsc.school_organisation,
                                 dsc.organisation_dw_id,
                                 dg.grade_name,
                                 dg.grade_dw_id,
                                 fsa.fsa_student_dw_id                                    AS student_dw_id,
                                 LOWER(fsa.class_material_type)                           AS course_type,
                                 fsa.created_date,
                                 DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                                 DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                                 SUM(fsa.max_stars)                                       AS total_stars
                    FROM (SELECT a.fsa_dw_id,
                                     a.fsa_student_dw_id,
                                     c.class_material_type,
                                     a.fsa_class_dw_id,
                                     MAX(CAST(a.fsa_created_time AS DATE)) AS created_date,
                                     MAX(a.fsa_stars)                      AS max_stars
                              FROM alefdw.fact_star_awarded a
                                JOIN alefdw.dim_class c
                                    ON a.fsa_class_dw_id = c.class_dw_id
                                  WHERE UPPER(class_material_type) <> 'PATHWAY'
                                  AND fsa_stars > 0
                                GROUP BY 1,2,3,4) fsa
                             JOIN bi_alefdw.bi_student_dim_mv dst
                                  ON fsa.fsa_student_dw_id = dst.student_dw_id
                                    AND dst.student_status = 1
                             JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                  ON dst.student_school_dw_id = dsc.school_dw_id
                                    AND TRUNC(created_date) BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
                             JOIN alefdw.dim_grade dg
                                  ON dg.grade_dw_id = dst.student_grade_dw_id
                    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

weekly_goal_stars AS (SELECT DISTINCT dsc.tenant_name,
                                      dsc.school_dw_id,
                                      dsc.school_name,
                                      dsc.school_organisation,
                                      dsc.organisation_dw_id,
                                      dg.grade_name,
                                      dg.grade_dw_id,
                                      fwg.fwg_student_dw_id                                    AS student_dw_id,
                                      LOWER(fwg.class_material_type)                           AS course_type,
                                      fwg.created_date,
                                      DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                                      DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                                      SUM(fwg.max_stars)                                       AS total_stars
                         FROM (SELECT fwg_dw_id,
                                     fwg_student_dw_id,
                                     class_material_type,
                                     fwg_class_dw_id,
                                     MAX(CAST(fwg_created_time AS DATE)) AS created_date,
                                     MAX(fwg_star_earned)                AS max_stars
                                  FROM alefdw.fact_weekly_goal w
                                    JOIN alefdw.dim_class c
                                        ON w.fwg_class_dw_id = c.class_dw_id
                                      WHERE UPPER(class_material_type) <> 'PATHWAY'
                                      AND fwg_star_earned > 0
                                  GROUP BY 1,2,3,4) fwg
                              JOIN bi_alefdw.bi_student_dim_mv dst
                                  ON fwg.fwg_student_dw_id = dst.student_dw_id
                                    AND dst.student_status = 1
                              JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                  ON dst.student_school_dw_id = dsc.school_dw_id
                                    AND TRUNC(created_date) BETWEEN dsc.academic_year_start_date AND dsc.academic_year_end_date
                              JOIN alefdw.dim_grade dg
                                  ON dg.grade_dw_id = dst.student_grade_dw_id
                         GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

fle_stars_pathway AS (SELECT DISTINCT dsc.tenant_name,
                                      dsc.school_dw_id,
                                      dsc.school_name,
                                      dsc.school_organisation,
                                      dsc.organisation_dw_id,
                                      dg.grade_name,
                                      dg.grade_dw_id,
                                      fle.fle_student_dw_id                                    AS student_dw_id,
                                      LOWER(fle.fle_material_type)                             AS course_type,
                                      fle.created_date,
                                      DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                                      DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                                      SUM(fle.max_stars)                                       AS total_stars
                        FROM (SELECT fle_lo_dw_id,
                                     fle_student_dw_id,
                                     fle_material_type,
                                     MAX(CAST(fle_created_time AS DATE)) AS created_date,
                                     MAX(fle_star_earned)                AS max_stars
                                FROM alefdw.fact_learning_experience
                                    WHERE UPPER(fle_material_type) = 'PATHWAY'
                                    AND fle_is_activity_completed = TRUE
                                    AND fle_star_earned > 0
                                GROUP BY 1,2,3) fle
                              JOIN bi_alefdw.bi_student_dim_mv dst
                                   ON fle.fle_student_dw_id = dst.student_dw_id
                                       AND dst.student_status = 1
                              LEFT JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                  ON dst.student_school_dw_id = dsc.school_dw_id
                              LEFT JOIN alefdw.dim_grade dg
                                  ON dg.grade_dw_id = dst.student_grade_dw_id
                        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

ktg_stars_pathway AS (SELECT DISTINCT dsc.tenant_name,
                              dsc.school_dw_id,
                              dsc.school_name,
                              dsc.school_organisation,
                              dsc.organisation_dw_id,
                              dg.grade_name,
                              dg.grade_dw_id,
                              fks.ktg_session_student_dw_id                            AS student_dw_id,
                              LOWER(fks.ktg_session_material_type)                     AS course_type,
                              fks.created_date,
                              DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                              DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                              SUM(fks.max_stars)                                       AS total_stars
                    FROM (SELECT ktg_session_dw_id,
                                 ktg_session_student_dw_id,
                                 ktg_session_material_type,
                                 MAX(CAST(ktg_session_dw_created_time AS DATE)) AS created_date,
                                 MAX(ktg_session_stars)                         AS max_stars
                              FROM alefdw.fact_ktg_session
                                 WHERE UPPER(ktg_session_material_type) = 'PATHWAY'
                                 AND ktg_session_stars > 0
                              GROUP BY 1,2,3) fks
                          JOIN bi_alefdw.bi_student_dim_mv dst
                               ON fks.ktg_session_student_dw_id = dst.student_dw_id
                                    AND dst.student_status = 1
                          LEFT JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                              ON dst.student_school_dw_id = dsc.school_dw_id
                          LEFT JOIN alefdw.dim_grade dg
                              ON dg.grade_dw_id = dst.student_grade_dw_id
                    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

pract_stars_pathway AS (SELECT DISTINCT dsc.tenant_name,
                                dsc.school_dw_id,
                                dsc.school_name,
                                dsc.school_organisation,
                                dsc.organisation_dw_id,
                                dg.grade_name,
                                dg.grade_dw_id,
                                fps.practice_session_student_dw_id                       AS student_dw_id,
                                LOWER(fps.practice_session_material_type)                AS course_type,
                                fps.created_date,
                                DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                                DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                                SUM(fps.max_stars)                                       AS total_stars
                   FROM (SELECT practice_session_dw_id,
                                practice_session_student_dw_id,
                                practice_session_material_type,
                                MAX(CAST(practice_session_dw_created_time AS DATE)) AS created_date,
                                MAX(practice_session_stars)                         AS max_stars
                          FROM alefdw.fact_practice_session
                             WHERE UPPER(practice_session_material_type) = 'PATHWAY'
                             AND practice_session_stars > 0
                          GROUP BY 1,2,3) fps
                        JOIN bi_alefdw.bi_student_dim_mv dst
                             ON fps.practice_session_student_dw_id = dst.student_dw_id
                                AND dst.student_status = 1
                        LEFT JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                             ON dst.student_school_dw_id = dsc.school_dw_id
                        LEFT JOIN alefdw.dim_grade dg
                             ON dg.grade_dw_id = dst.student_grade_dw_id
                   GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

awards_stars_pathway AS (SELECT DISTINCT dsc.tenant_name,
                                 dsc.school_dw_id,
                                 dsc.school_name,
                                 dsc.school_organisation,
                                 dsc.organisation_dw_id,
                                 dg.grade_name,
                                 dg.grade_dw_id,
                                 fsa.fsa_student_dw_id                                    AS student_dw_id,
                                 LOWER(fsa.class_material_type)                           AS course_type,
                                 fsa.created_date,
                                 DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                                 DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                                 SUM(fsa.max_stars)                                       AS total_stars
                    FROM (SELECT a.fsa_dw_id,
                                     a.fsa_student_dw_id,
                                     c.class_material_type,
                                     a.fsa_class_dw_id,
                                     MAX(CAST(a.fsa_created_time AS DATE)) AS created_date,
                                     MAX(a.fsa_stars)                      AS max_stars
                              FROM alefdw.fact_star_awarded a
                                JOIN alefdw.dim_class c
                                    ON a.fsa_class_dw_id = c.class_dw_id
                                  WHERE UPPER(class_material_type) = 'PATHWAY'
                                  AND fsa_stars > 0
                                GROUP BY 1,2,3,4) fsa
                             JOIN bi_alefdw.bi_student_dim_mv dst
                                  ON fsa.fsa_student_dw_id = dst.student_dw_id
                                    AND dst.student_status = 1
                             LEFT JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                  ON dst.student_school_dw_id = dsc.school_dw_id
                             LEFT JOIN alefdw.dim_grade dg
                                  ON dg.grade_dw_id = dst.student_grade_dw_id
                    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),

weekly_goal_stars_pathway AS (SELECT DISTINCT dsc.tenant_name,
                                      dsc.school_dw_id,
                                      dsc.school_name,
                                      dsc.school_organisation,
                                      dsc.organisation_dw_id,
                                      dg.grade_name,
                                      dg.grade_dw_id,
                                      fwg.fwg_student_dw_id                                    AS student_dw_id,
                                      LOWER(fwg.class_material_type)                           AS course_type,
                                      fwg.created_date,
                                      DATE_PART(YEAR, dsc.academic_year_start_date) || '-' ||
                                      DATE_PART(YEAR, dsc.academic_year_end_date)              AS academic_year,
                                      SUM(fwg.max_stars)                                       AS total_stars
                         FROM (SELECT fwg_dw_id,
                                     fwg_student_dw_id,
                                     class_material_type,
                                     fwg_class_dw_id,
                                     MAX(CAST(fwg_created_time AS DATE)) AS created_date,
                                     MAX(fwg_star_earned)                AS max_stars
                                  FROM alefdw.fact_weekly_goal w
                                    JOIN alefdw.dim_class c
                                        ON w.fwg_class_dw_id = c.class_dw_id
                                      WHERE UPPER(class_material_type) = 'PATHWAY'
                                      AND fwg_star_earned > 0
                                  GROUP BY 1,2,3,4) fwg
                              JOIN bi_alefdw.bi_student_dim_mv dst
                                  ON fwg.fwg_student_dw_id = dst.student_dw_id
                                    AND dst.student_status = 1
                              LEFT JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                                  ON dst.student_school_dw_id = dsc.school_dw_id
                              LEFT JOIN alefdw.dim_grade dg
                                  ON dg.grade_dw_id = dst.student_grade_dw_id
                         GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)

SELECT a.*, 'learning experience' AS activity_type
    FROM fle_stars a
    UNION ALL
    SELECT b.*, 'star awarded' AS activity_type
    FROM awards_stars b
    UNION ALL
    SELECT c.*, 'ktg sessions' AS activity_type
    FROM ktg_stars c
    UNION ALL
    SELECT d.*, 'practice session' AS activity_type
    FROM pract_stars d
    UNION ALL
    SELECT e.*, 'weekly goals' AS activity_type
    FROM weekly_goal_stars e
    UNION ALL
    SELECT bp.*, 'star awarded' AS activity_type
    FROM awards_stars_pathway bp
    UNION ALL
    SELECT cp.*, 'ktg sessions' AS activity_type
    FROM ktg_stars_pathway cp
    UNION ALL
    SELECT dp.*, 'practice session' AS activity_type
    FROM pract_stars_pathway dp
    UNION ALL
    SELECT ep.*, 'weekly goals' AS activity_type
    FROM weekly_goal_stars_pathway ep
    UNION ALL
    SELECT ap.*, 'learning experience' AS activity_type
    FROM fle_stars_pathway ap
WITH NO SCHEMA BINDING;
