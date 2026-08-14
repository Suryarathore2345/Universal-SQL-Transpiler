CREATE OR ALTER VIEW ${os_bi_coredw}.stars_earned_dm_view
AS
WITH fle_stars AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fle.fle_student_dw_id AS student_dw_id,
        LOWER(fle.fle_material_type) AS course_type,
        fle.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fle.max_stars) AS total_stars
    FROM (
        SELECT
            fle_lo_dw_id,
            fle_student_dw_id,
            fle_material_type,
            MAX(CONVERT(date, fle_created_time)) AS created_date,
            MAX(fle_star_earned) AS max_stars
        FROM ${rs_coredw}.fact_learning_experience
        WHERE fle_material_type <> 'PATHWAY'
          AND fle_is_activity_completed = 'true'
          AND fle_star_earned > 0
        GROUP BY
            fle_lo_dw_id,
            fle_student_dw_id,
            fle_material_type
    ) AS fle
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fle.fle_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
       AND fle.created_date >= CONVERT(DATETIME2, dsc.academic_year_start_date)  -- OPT-7: SARGable rewrite
           AND fle.created_date < DATEADD(DAY, 1, CONVERT(DATETIME2, dsc.academic_year_end_date))
    JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fle.fle_student_dw_id,
        LOWER(fle.fle_material_type),
        fle.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

ktg_stars AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fks.ktg_session_student_dw_id AS student_dw_id,
        LOWER(fks.ktg_session_material_type) AS course_type,
        fks.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fks.max_stars) AS total_stars
    FROM (
        SELECT
            ktg_session_dw_id,
            ktg_session_student_dw_id,
            ktg_session_material_type,
            MAX(CONVERT(date, ktg_session_dw_created_time)) AS created_date,
            MAX(ktg_session_stars) AS max_stars
        FROM ${rs_coredw}.fact_ktg_session
        WHERE ktg_session_material_type <> 'PATHWAY'
          AND ktg_session_stars > 0
        GROUP BY
            ktg_session_dw_id,
            ktg_session_student_dw_id,
            ktg_session_material_type
    ) AS fks
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fks.ktg_session_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
       AND fks.created_date >= CONVERT(DATETIME2, dsc.academic_year_start_date)  -- OPT-7: SARGable rewrite
           AND fks.created_date < DATEADD(DAY, 1, CONVERT(DATETIME2, dsc.academic_year_end_date))
    JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fks.ktg_session_student_dw_id,
        LOWER(fks.ktg_session_material_type),
        fks.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

pract_stars AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fps.practice_session_student_dw_id AS student_dw_id,
        LOWER(fps.practice_session_material_type) AS course_type,
        fps.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fps.max_stars) AS total_stars
    FROM (
        SELECT
            practice_session_dw_id,
            practice_session_student_dw_id,
            practice_session_material_type,
            MAX(CONVERT(date, practice_session_dw_created_time)) AS created_date,
            MAX(practice_session_stars) AS max_stars
        FROM ${rs_coredw}.fact_practice_session
        WHERE practice_session_material_type <> 'PATHWAY'
          AND practice_session_stars > 0
        GROUP BY
            practice_session_dw_id,
            practice_session_student_dw_id,
            practice_session_material_type
    ) AS fps
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fps.practice_session_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
       AND fps.created_date >= CONVERT(DATETIME2, dsc.academic_year_start_date)  -- OPT-7: SARGable rewrite
           AND fps.created_date < DATEADD(DAY, 1, CONVERT(DATETIME2, dsc.academic_year_end_date))
    JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fps.practice_session_student_dw_id,
        LOWER(fps.practice_session_material_type),
        fps.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

awards_stars AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fsa.fsa_student_dw_id AS student_dw_id,
        LOWER(fsa.class_material_type) AS course_type,
        fsa.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fsa.max_stars) AS total_stars
    FROM (
        SELECT
            a.fsa_dw_id,
            a.fsa_student_dw_id,
            c.class_material_type,
            a.fsa_class_dw_id,
            MAX(CONVERT(date, a.fsa_created_time)) AS created_date,
            MAX(a.fsa_stars) AS max_stars
        FROM ${rs_coredw}.fact_star_awarded AS a
        JOIN ${rs_coredw}.dim_class AS c
            ON a.fsa_class_dw_id = c.class_dw_id
        WHERE c.class_material_type <> 'PATHWAY'
          AND a.fsa_stars > 0
        GROUP BY
            a.fsa_dw_id,
            a.fsa_student_dw_id,
            c.class_material_type,
            a.fsa_class_dw_id
    ) AS fsa
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fsa.fsa_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
       AND fsa.created_date >= CONVERT(DATETIME2, dsc.academic_year_start_date)  -- OPT-7: SARGable rewrite
           AND fsa.created_date < DATEADD(DAY, 1, CONVERT(DATETIME2, dsc.academic_year_end_date))
    JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fsa.fsa_student_dw_id,
        LOWER(fsa.class_material_type),
        fsa.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

weekly_goal_stars AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fwg.fwg_student_dw_id AS student_dw_id,
        LOWER(fwg.class_material_type) AS course_type,
        fwg.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fwg.max_stars) AS total_stars
    FROM (
        SELECT
            fwg_dw_id,
            fwg_student_dw_id,
            class_material_type,
            fwg_class_dw_id,
            MAX(CONVERT(date, fwg_created_time)) AS created_date,
            MAX(fwg_star_earned) AS max_stars
        FROM ${rs_coredw}.fact_weekly_goal AS w
        JOIN ${rs_coredw}.dim_class AS c
            ON w.fwg_class_dw_id = c.class_dw_id
        WHERE c.class_material_type <> 'PATHWAY'
          AND w.fwg_star_earned > 0
        GROUP BY
            fwg_dw_id,
            fwg_student_dw_id,
            class_material_type,
            fwg_class_dw_id
    ) AS fwg
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fwg.fwg_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
       AND fwg.created_date >= CONVERT(DATETIME2, dsc.academic_year_start_date)  -- OPT-7: SARGable rewrite
           AND fwg.created_date < DATEADD(DAY, 1, CONVERT(DATETIME2, dsc.academic_year_end_date))
    JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fwg.fwg_student_dw_id,
        LOWER(fwg.class_material_type),
        fwg.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

fle_stars_pathway AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fle.fle_student_dw_id AS student_dw_id,
        LOWER(fle.fle_material_type) AS course_type,
        fle.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fle.max_stars) AS total_stars
    FROM (
        SELECT
            fle_lo_dw_id,
            fle_student_dw_id,
            fle_material_type,
            MAX(CONVERT(date, fle_created_time)) AS created_date,
            MAX(fle_star_earned) AS max_stars
        FROM ${rs_coredw}.fact_learning_experience
        WHERE fle_material_type = 'PATHWAY'
          AND fle_is_activity_completed = 'true'
          AND fle_star_earned > 0
        GROUP BY
            fle_lo_dw_id,
            fle_student_dw_id,
            fle_material_type
    ) AS fle
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fle.fle_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    LEFT JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
    LEFT JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fle.fle_student_dw_id,
        LOWER(fle.fle_material_type),
        fle.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

ktg_stars_pathway AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fks.ktg_session_student_dw_id AS student_dw_id,
        LOWER(fks.ktg_session_material_type) AS course_type,
        fks.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fks.max_stars) AS total_stars
    FROM (
        SELECT
            ktg_session_dw_id,
            ktg_session_student_dw_id,
            ktg_session_material_type,
            MAX(CONVERT(date, ktg_session_dw_created_time)) AS created_date,
            MAX(ktg_session_stars) AS max_stars
        FROM ${rs_coredw}.fact_ktg_session
        WHERE ktg_session_material_type = 'PATHWAY'
          AND ktg_session_stars > 0
        GROUP BY
            ktg_session_dw_id,
            ktg_session_student_dw_id,
            ktg_session_material_type
    ) AS fks
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fks.ktg_session_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    LEFT JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
    LEFT JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fks.ktg_session_student_dw_id,
        LOWER(fks.ktg_session_material_type),
        fks.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

pract_stars_pathway AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fps.practice_session_student_dw_id AS student_dw_id,
        LOWER(fps.practice_session_material_type) AS course_type,
        fps.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fps.max_stars) AS total_stars
    FROM (
        SELECT
            practice_session_dw_id,
            practice_session_student_dw_id,
            practice_session_material_type,
            MAX(CONVERT(date, practice_session_dw_created_time)) AS created_date,
            MAX(practice_session_stars) AS max_stars
        FROM ${rs_coredw}.fact_practice_session
        WHERE practice_session_material_type = 'PATHWAY'
          AND practice_session_stars > 0
        GROUP BY
            practice_session_dw_id,
            practice_session_student_dw_id,
            practice_session_material_type
    ) AS fps
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fps.practice_session_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    LEFT JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
    LEFT JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fps.practice_session_student_dw_id,
        LOWER(fps.practice_session_material_type),
        fps.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

awards_stars_pathway AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fsa.fsa_student_dw_id AS student_dw_id,
        LOWER(fsa.class_material_type) AS course_type,
        fsa.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fsa.max_stars) AS total_stars
    FROM (
        SELECT
            a.fsa_dw_id,
            a.fsa_student_dw_id,
            c.class_material_type,
            a.fsa_class_dw_id,
            MAX(CONVERT(date, a.fsa_created_time)) AS created_date,
            MAX(a.fsa_stars) AS max_stars
        FROM ${rs_coredw}.fact_star_awarded AS a
        JOIN ${rs_coredw}.dim_class AS c
            ON a.fsa_class_dw_id = c.class_dw_id
        WHERE c.class_material_type = 'PATHWAY'
          AND a.fsa_stars > 0
        GROUP BY
            a.fsa_dw_id,
            a.fsa_student_dw_id,
            c.class_material_type,
            a.fsa_class_dw_id
    ) AS fsa
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fsa.fsa_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    LEFT JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
    LEFT JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fsa.fsa_student_dw_id,
        LOWER(fsa.class_material_type),
        fsa.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
),

weekly_goal_stars_pathway AS (
    SELECT
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fwg.fwg_student_dw_id AS student_dw_id,
        LOWER(fwg.class_material_type) AS course_type,
        fwg.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date)) AS academic_year,
        SUM(fwg.max_stars) AS total_stars
    FROM (
        SELECT
            fwg_dw_id,
            fwg_student_dw_id,
            class_material_type,
            fwg_class_dw_id,
            MAX(CONVERT(date, fwg_created_time)) AS created_date,
            MAX(fwg_star_earned) AS max_stars
        FROM ${rs_coredw}.fact_weekly_goal AS w
        JOIN ${rs_coredw}.dim_class AS c
            ON w.fwg_class_dw_id = c.class_dw_id
        WHERE c.class_material_type = 'PATHWAY'
          AND w.fwg_star_earned > 0
        GROUP BY
            fwg_dw_id,
            fwg_student_dw_id,
            class_material_type,
            fwg_class_dw_id
    ) AS fwg
    JOIN ${rs_bi_coredw}.bi_student_dim AS dst
        ON fwg.fwg_student_dw_id = dst.student_dw_id
       AND dst.student_status = 1
    LEFT JOIN ${rs_bi_coredw}.bi_active_schools_dim AS dsc
        ON dst.student_school_dw_id = dsc.school_dw_id
    LEFT JOIN ${rs_coredw}.dim_grade AS dg
        ON dg.grade_dw_id = dst.student_grade_dw_id
    GROUP BY
        dsc.tenant_name,
        dsc.school_dw_id,
        dsc.school_name,
        dsc.school_organisation,
        dsc.organisation_dw_id,
        dg.grade_name,
        dg.grade_dw_id,
        fwg.fwg_student_dw_id,
        LOWER(fwg.class_material_type),
        fwg.created_date,
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_start_date))
            + '-' +
        CONVERT(varchar(4), DATEPART(YEAR, dsc.academic_year_end_date))
)

SELECT
a.tenant_name,
a.school_dw_id,
a.school_name,
a.school_organisation,
a.organisation_dw_id,
a.grade_name,
a.grade_dw_id,
a.student_dw_id,
a.course_type,
a.created_date,
a.academic_year,
a.total_stars,
'learning experience' AS activity_type
FROM fle_stars AS a
UNION ALL
SELECT
b.tenant_name,
b.school_dw_id,
b.school_name,
b.school_organisation,
b.organisation_dw_id,
b.grade_name,
b.grade_dw_id,
b.student_dw_id,
b.course_type,
b.created_date,
b.academic_year,
b.total_stars,
'star awarded' AS activity_type
FROM awards_stars AS b
UNION ALL
SELECT
c.tenant_name,
c.school_dw_id,
c.school_name,
c.school_organisation,
c.organisation_dw_id,
c.grade_name,
c.grade_dw_id,
c.student_dw_id,
c.course_type,
c.created_date,
c.academic_year,
c.total_stars,
'ktg sessions' AS activity_type
FROM ktg_stars AS c
UNION ALL
SELECT
d.tenant_name,
d.school_dw_id,
d.school_name,
d.school_organisation,
d.organisation_dw_id,
d.grade_name,
d.grade_dw_id,
d.student_dw_id,
d.course_type,
d.created_date,
d.academic_year,
d.total_stars,
'practice session' AS activity_type
FROM pract_stars AS d
UNION ALL
SELECT
e.tenant_name,
e.school_dw_id,
e.school_name,
e.school_organisation,
e.organisation_dw_id,
e.grade_name,
e.grade_dw_id,
e.student_dw_id,
e.course_type,
e.created_date,
e.academic_year,
e.total_stars,
'weekly goals' AS activity_type
FROM weekly_goal_stars AS e
UNION ALL
SELECT
bp.tenant_name,
bp.school_dw_id,
bp.school_name,
bp.school_organisation,
bp.organisation_dw_id,
bp.grade_name,
bp.grade_dw_id,
bp.student_dw_id,
bp.course_type,
bp.created_date,
bp.academic_year,
bp.total_stars,
'star awarded' AS activity_type
FROM awards_stars_pathway AS bp
UNION ALL
SELECT
cp.tenant_name,
cp.school_dw_id,
cp.school_name,
cp.school_organisation,
cp.organisation_dw_id,
cp.grade_name,
cp.grade_dw_id,
cp.student_dw_id,
cp.course_type,
cp.created_date,
cp.academic_year,
cp.total_stars,
'ktg sessions' AS activity_type
FROM ktg_stars_pathway AS cp
UNION ALL
SELECT
dp.tenant_name,
dp.school_dw_id,
dp.school_name,
dp.school_organisation,
dp.organisation_dw_id,
dp.grade_name,
dp.grade_dw_id,
dp.student_dw_id,
dp.course_type,
dp.created_date,
dp.academic_year,
dp.total_stars,
'practice session' AS activity_type
FROM pract_stars_pathway AS dp
UNION ALL
SELECT
ep.tenant_name,
ep.school_dw_id,
ep.school_name,
ep.school_organisation,
ep.organisation_dw_id,
ep.grade_name,
ep.grade_dw_id,
ep.student_dw_id,
ep.course_type,
ep.created_date,
ep.academic_year,
ep.total_stars,
'weekly goals' AS activity_type
FROM weekly_goal_stars_pathway AS ep
UNION ALL
SELECT
ap.tenant_name,
ap.school_dw_id,
ap.school_name,
ap.school_organisation,
ap.organisation_dw_id,
ap.grade_name,
ap.grade_dw_id,
ap.student_dw_id,
ap.course_type,
ap.created_date,
ap.academic_year,
ap.total_stars,
'learning experience' AS activity_type
FROM fle_stars_pathway AS ap;
