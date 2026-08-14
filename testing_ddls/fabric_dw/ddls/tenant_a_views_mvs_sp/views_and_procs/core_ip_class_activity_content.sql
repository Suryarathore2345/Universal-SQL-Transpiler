CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_core_ip_class_activity_content
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.core_ip_class_activity_content_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.core_ip_class_activity_content_staging
        WITH (CLUSTER BY (class_dw_id, school_dw_id))
        AS
        SELECT DISTINCT 
            dip.instructional_plan_id AS course_id,
            dip.instructional_plan_name AS course_name,
            dc.class_dw_id,
            dc.class_id,
            dc.class_title,
            dc.class_gen_subject,
            dc.class_grade_id,
            g.grade_k12grade AS grade_name,
            sch.school_id,
            sch.school_dw_id,
            sch.school_name,
            sch.school_alias,
            sch.school_label,
            sch.school_cx_cluster,
            sch.school_city_name,
            sch.school_country_name,
            sch.tenant_name,
            sch.school_organisation,
            dip.instructional_plan_item_lo_dw_id AS activity_dw_id,
            lo_title,
            dcs.curr_subject_id AS course_subject_id,
            dip.instructional_plan_item_order,
            dw.week_start_date,
            dw.week_end_date,
            dtrm.term_academic_period_order,
            dtrm.term_start_date,
            dtrm.term_end_date,
            'WEEK' AS pacing,
            sch.academic_year_start_date,
            sch.academic_year_end_date,
            sch.academic_year_id,
            CONCAT(CONVERT(VARCHAR(4), YEAR(sch.academic_year_start_date)), ' - ', 
                CONVERT(VARCHAR(4), YEAR(sch.academic_year_end_date))) AS academic_year
        FROM ${rs_coredw}.dim_instructional_plan dip
        JOIN ${rs_coredw}.dim_class dc
            ON dip.instructional_plan_id = dc.class_material_id
        JOIN ${rs_bi_coredw}.bi_all_schools_dim sch
            ON dc.class_school_id = sch.school_id
            AND dc.class_academic_year_id = sch.academic_year_id
        JOIN ${rs_coredw}.dim_grade g
            ON dc.class_grade_id = g.grade_id
        JOIN ${rs_coredw}.dim_week dw
            ON dip.instructional_plan_item_week_dw_id = dw.week_dw_id
        JOIN ${rs_coredw}.dim_term dtrm
            ON dw.week_term_id = dtrm.term_id
        JOIN ${rs_coredw}.dim_learning_objective dip_dlo
            ON dip.instructional_plan_item_lo_dw_id = dip_dlo.lo_dw_id
            AND ISNULL(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
            AND ISNULL(dip_dlo.lo_template_uuid, 'NA') NOT IN ('235229fa-4707-4286-8ec2-85f70347096a', '15295fd1-b5e3-46f9-9045-86ee3b13552b')
            AND dip_dlo.lo_status = 1
        LEFT JOIN ${rs_coredw}.dim_curriculum_subject dcs
            ON dc.class_curriculum_subject_id = dcs.curr_subject_id
            AND dcs.curr_subject_dw_id = 129   -- Arabits subject
        WHERE dip.instructional_plan_status = 1
            AND instructional_plan_item_optional = 0
            AND dc.class_status = 1
            AND sch.academic_year_start_date >= '2021-01-01'

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.core_ip_class_activity_content;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.core_ip_class_activity_content_staging', 'core_ip_class_activity_content';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;