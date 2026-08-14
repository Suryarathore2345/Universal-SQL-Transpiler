CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_class_total_students_prev_ay
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.class_total_students_prev_ay_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.class_total_students_prev_ay_staging
        WITH (CLUSTER BY (class_dw_id, school_dw_id))
        AS
        WITH distinct_class_teachers AS (
            SELECT DISTINCT
                dc.class_dw_id,
                dt.teacher_id
            FROM ${rs_coredw}.dim_class AS dc
            INNER JOIN ${rs_coredw}.dim_class_user AS dcu
                ON dcu.class_user_class_dw_id = dc.class_dw_id
            INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim AS ay
                ON dc.class_academic_year_id = ay.academic_year_id
               AND dc.class_school_id        = ay.school_id
            LEFT JOIN ${rs_coredw}.dim_teacher AS dt
                ON dcu.class_user_user_dw_id = dt.teacher_dw_id
               AND dt.teacher_id NOT IN (
                    SELECT DISTINCT teacher_id
                    FROM ${rs_bi_coredw}.exclude_teacher_id
               )
            WHERE dcu.class_user_role_dw_id   = 1
              AND dc.class_course_status      = 'CONCLUDED'
              AND dcu.class_user_attach_status = 1
        ),
        class_teachers AS (
            SELECT
                class_dw_id,
                STRING_AGG(CONVERT(VARCHAR(MAX), teacher_id), ',') WITHIN GROUP (ORDER BY teacher_id) AS teacher_ids
            FROM distinct_class_teachers
            GROUP BY class_dw_id
        )
        SELECT
            dc.class_dw_id,
            dc.class_id,
            dc.class_material_id                                     AS instructional_plan_id,
            sch.school_dw_id,
            sch.school_name,
            UPPER(dc.class_title)                                    AS class_title,
            UPPER(dc.class_gen_subject)                              AS class_gen_subject,
            dc.class_curriculum_id,
            ISNULL(dsec.section_dw_id, 10001)                        AS class_section_dw_id,
            UPPER(ISNULL(dsec.section_alias, 'NA'))                  AS class_section_name,
            ct.teacher_ids,
            dg.grade_name,
            dc.class_academic_calendar_id,
            CONVERT(VARCHAR(4), YEAR(sch.academic_year_end_date))    AS content_academic_year_name,
            dcs.curr_subject_id                                      AS course_subject_id,
            COUNT(DISTINCT dcu.class_user_user_dw_id)                AS class_total_students
        FROM ${rs_coredw}.dim_class AS dc
        INNER JOIN ${rs_coredw}.dim_class_user AS dcu
            ON dcu.class_user_class_dw_id = dc.class_dw_id
        INNER JOIN ${rs_bi_coredw}.bi_all_schools_dim AS sch
            ON dc.class_academic_year_id = sch.academic_year_id
           AND dc.class_school_id        = sch.school_id
        INNER JOIN ${rs_coredw}.dim_curriculum_subject AS dcs
            ON dc.class_curriculum_subject_id = dcs.curr_subject_id
        INNER JOIN ${rs_coredw}.dim_grade AS dg
            ON dg.grade_id = dc.class_grade_id
        LEFT JOIN ${rs_coredw}.dim_section AS dsec
            ON dsec.section_id = dc.class_section_id
        LEFT JOIN class_teachers AS ct
            ON ct.class_dw_id = dc.class_dw_id
        WHERE dcu.class_user_role_dw_id    = 2
          AND dcu.class_user_attach_status = 1
          AND dc.class_status              = 1
          AND dc.class_course_status       = 'CONCLUDED'
          AND dc.class_material_type      != 'PATHWAY'
          AND dc.class_title      NOT LIKE '%power skills%'
          AND dc.class_title      NOT LIKE '%extra resources%'
          AND dc.class_gen_subject != 'core stars'
        GROUP BY
            dc.class_dw_id, dc.class_id, dc.class_material_id, sch.school_dw_id, sch.school_name,
            dc.class_title, dc.class_gen_subject, dc.class_curriculum_id, dsec.section_dw_id,
            dsec.section_alias, ct.teacher_ids, dg.grade_name, dc.class_academic_calendar_id,
            sch.academic_year_end_date, dcs.curr_subject_id;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.class_total_students_prev_ay;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.class_total_students_prev_ay_staging', 'class_total_students_prev_ay';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
