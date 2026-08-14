CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_class_total_students
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.class_total_students_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.class_total_students_staging
        WITH (CLUSTER BY (class_dw_id, school_dw_id))
        AS
        WITH distinct_class_teachers AS (
            SELECT
                dc.class_dw_id,
                dt.teacher_id,
                MIN(dcu.class_user_created_time) AS class_user_created_time
            FROM ${rs_coredw}.dim_class AS dc
            JOIN ${rs_coredw}.dim_class_user AS dcu
                ON dcu.class_user_class_dw_id = dc.class_dw_id
            LEFT JOIN ${rs_coredw}.dim_teacher AS dt
                ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                AND dt.teacher_status = 1
                AND dt.teacher_id NOT IN (SELECT DISTINCT teacher_id FROM ${rs_bi_coredw}.exclude_teacher_id)
            WHERE dc.class_status = 1
                AND dcu.class_user_role_dw_id = 1
                AND dc.class_course_status = 'ACTIVE'
                AND dcu.class_user_status = 1
                AND dc.class_material_type <> 'PATHWAY'
                AND dcu.class_user_attach_status = 1
            GROUP BY dc.class_dw_id, dt.teacher_id
        ),
        CLASS_TEACHERS AS (
            SELECT
                class_dw_id,
                STRING_AGG(CONVERT(VARCHAR(MAX), teacher_id), ',') WITHIN GROUP (ORDER BY class_user_created_time) AS teacher_ids
            FROM distinct_class_teachers
            GROUP BY class_dw_id
        )
        SELECT DISTINCT
            dc.class_dw_id,
            dc.class_id,
            dcr.course_id                                           AS instructional_plan_id,
            sc.school_dw_id,
            UPPER(dc.class_title)                                   AS class_title,
            UPPER(dc.class_gen_subject)                             AS class_gen_subject,
            dc.class_curriculum_id,
            ISNULL(dse.section_dw_id, '10001')                      AS section_dw_id,
            UPPER(ISNULL(dse.section_alias, 'NA'))                  AS section_name,
            UPPER(ISNULL(dsec.section_alias, 'NA'))                 AS class_section_name,
            ct.teacher_ids,
            dg.grade_name,
            dc.class_academic_calendar_id                           AS content_academic_year_id,
            CONVERT(VARCHAR(MAX), YEAR(sc.academic_year_end_date))  AS content_academic_year_name,
            dcsa.cs_subject_id                                      AS course_subject_id,
            COUNT(DISTINCT ds.student_dw_id)                        AS class_total_students
        FROM ${rs_coredw}.dim_class AS dc
        JOIN ${rs_coredw}.dim_class_user AS dcu
            ON dcu.class_user_class_dw_id = dc.class_dw_id
        JOIN ${rs_bi_coredw}.bi_active_schools_dim AS sc
            ON dc.class_school_id = sc.school_id
        JOIN ${rs_coredw}.dim_student AS ds
            ON dcu.class_user_user_dw_id = ds.student_dw_id
            AND sc.school_dw_id = ds.student_school_dw_id
        JOIN ${rs_coredw}.dim_course AS dcr
            ON dcr.course_id = dc.class_material_id
        LEFT JOIN ${rs_coredw}.dim_course_subject_association AS dcsa
            ON dcsa.cs_course_dw_id = dcr.course_dw_id
            AND dcsa.cs_status = 1
            AND dcsa.cs_subject_dw_id = 129
        JOIN ${rs_coredw}.dim_grade AS dg
            ON dg.grade_id = dc.class_grade_id
        LEFT JOIN ${rs_coredw}.dim_section AS dse
            ON dse.section_dw_id = ds.student_section_dw_id
        LEFT JOIN ${rs_coredw}.dim_section AS dsec
            ON dsec.section_id = dc.class_section_id
        LEFT JOIN CLASS_TEACHERS AS ct
            ON ct.class_dw_id = dc.class_dw_id
        WHERE dcu.class_user_status = 1
            AND dcu.class_user_role_dw_id = 2
            AND dcu.class_user_attach_status = 1
            AND ds.student_status = 1
            AND dcr.course_status = 1
            AND dcr.course_type = 'CORE'
            AND dc.class_status = 1
            AND dc.class_course_status = 'ACTIVE'
            AND dc.class_material_type <> 'PATHWAY'
        GROUP BY
            dc.class_dw_id,
            dc.class_id,
            dcr.course_id,
            sc.school_dw_id,
            dc.class_title,
            dc.class_gen_subject,
            dc.class_curriculum_id,
            dse.section_dw_id,
            dse.section_alias,
            dsec.section_alias,
            ct.teacher_ids,
            dg.grade_name,
            dc.class_academic_calendar_id,
            sc.academic_year_end_date,
            dcsa.cs_subject_id;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.class_total_students;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.class_total_students_staging', 'class_total_students';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
