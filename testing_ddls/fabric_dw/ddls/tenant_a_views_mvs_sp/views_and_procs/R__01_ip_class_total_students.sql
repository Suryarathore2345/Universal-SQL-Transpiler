CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_ip_class_total_students
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.ip_class_total_students_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.ip_class_total_students_staging
        WITH (CLUSTER BY (class_dw_id, school_dw_id))
        AS
        WITH CLASS_TEACHERS AS (
            SELECT
                class_dw_id,
                STRING_AGG(teacher_id, ',') WITHIN GROUP (ORDER BY teacher_id) AS teacher_ids
            FROM (
                SELECT DISTINCT
                    dc.class_dw_id,
                    dt.teacher_id
                FROM ${rs_coredw}.dim_class AS dc
                JOIN ${rs_coredw}.dim_class_user AS dcu
                    ON dcu.class_user_class_dw_id = dc.class_dw_id
                LEFT JOIN ${rs_coredw}.dim_teacher AS dt
                    ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                   AND dt.teacher_status = 1
                   AND dt.teacher_id NOT IN (
                        SELECT DISTINCT teacher_id
                        FROM ${rs_bi_coredw}.exclude_teacher_id
                   )
                WHERE dc.class_status = 1
                  AND dcu.class_user_role_dw_id = 1
                  AND dc.class_course_status = 'ACTIVE'
                  AND dcu.class_user_status = 1
                  AND dc.class_material_type <> 'PATHWAY'
                  AND dcu.class_user_attach_status = 1
            ) distinct_teachers
            GROUP BY class_dw_id
        )
        SELECT
            dc.class_dw_id,
            dip.instructional_plan_id,
            sc.school_dw_id,
            UPPER(dc.class_title)                                   AS class_title,
            UPPER(dc.class_gen_subject)                             AS class_gen_subject,
            dc.class_curriculum_id,
            ISNULL(dse.section_dw_id, CONVERT(BIGINT, 10001))       AS section_dw_id,
            UPPER(ISNULL(dse.section_name, 'NA'))                   AS section_name,
            UPPER(ISNULL(dsec.section_name, 'NA'))                  AS class_section_name,
            ct.teacher_ids,
            dcg.curr_grade_dw_id,
            dcg.curr_grade_name,
            dg.grade_name,
            dcs.curr_subject_dw_id,
            dcs.curr_subject_name,
            dcay.content_academic_year_id,
            dcay.content_academic_year_name,
            COUNT(DISTINCT ds.student_dw_id)                        AS class_total_students
        FROM ${rs_coredw}.dim_class AS dc
        JOIN ${rs_coredw}.dim_class_user AS dcu
            ON dcu.class_user_class_dw_id = dc.class_dw_id
        JOIN ${rs_bi_coredw}.bi_active_schools_dim AS sc
            ON CONVERT(VARCHAR(36), dc.class_school_id) = CONVERT(VARCHAR(36), sc.school_id)
        JOIN ${rs_coredw}.dim_student AS ds
            ON dcu.class_user_user_dw_id = ds.student_dw_id
           AND sc.school_dw_id = ds.student_school_dw_id
        JOIN ${rs_coredw}.dim_content_academic_year AS dcay
            ON CONVERT(VARCHAR(32), dc.class_content_academic_year) = dcay.content_academic_year_name
        JOIN ${rs_coredw}.dim_curriculum_grade AS dcg
            ON dc.class_curriculum_grade_id = dcg.curr_grade_id
        JOIN ${rs_coredw}.dim_curriculum_subject AS dcs
            ON dc.class_curriculum_subject_id = dcs.curr_subject_id
        JOIN ${rs_coredw}.dim_instructional_plan AS dip
            ON dc.class_curriculum_grade_id = dip.instructional_plan_curriculum_grade_id
           AND dc.class_curriculum_subject_id = dip.instructional_plan_curriculum_subject_id
           AND dc.class_curriculum_id = dip.instructional_plan_curriculum_id
           AND dcay.content_academic_year_id = dip.instructional_plan_content_academic_year_id
           AND dc.class_curriculum_instructional_plan_id = dip.instructional_plan_id
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
          AND dip.instructional_plan_status = 1
          AND dc.class_status = 1
          AND dcs.curr_subject_status = 1
          AND dcg.curr_grade_status = 1
          AND dc.class_course_status = 'ACTIVE'
          AND dc.class_material_type <> 'PATHWAY'
        GROUP BY
            dc.class_dw_id,
            dip.instructional_plan_id,
            sc.school_dw_id,
            UPPER(dc.class_title),
            UPPER(dc.class_gen_subject),
            dc.class_curriculum_id,
            ISNULL(dse.section_dw_id, CONVERT(BIGINT, 10001)),
            UPPER(ISNULL(dse.section_name, 'NA')),
            UPPER(ISNULL(dsec.section_name, 'NA')),
            ct.teacher_ids,
            dcg.curr_grade_dw_id,
            dcg.curr_grade_name,
            dg.grade_name,
            dcs.curr_subject_dw_id,
            dcs.curr_subject_name,
            dcay.content_academic_year_id,
            dcay.content_academic_year_name;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.ip_class_total_students;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.ip_class_total_students_staging', 'ip_class_total_students';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
