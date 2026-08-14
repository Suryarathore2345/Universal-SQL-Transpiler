CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_lo_structure_components
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        IF OBJECT_ID('${os_bi_coredw}.lo_structure_components_staging') IS NOT NULL
            DROP TABLE IF EXISTS ${os_bi_coredw}.lo_structure_components_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.lo_structure_components_staging
        WITH (CLUSTER BY (activity_dw_id))
        AS
        SELECT DISTINCT
            dlo.lo_id                                           AS activity_id,
            dlo.lo_title                                        AS activity_title,
            dlo.lo_dw_id                                        AS activity_dw_id,
            dcs.id                                              AS content_section_id,
            dcs.dw_id                                           AS content_section_dw_id,
            dcs.type                                            AS content_section_type,
            dcs.title                                           AS content_section_title,
            dasa.content_id,
            dasa.template_component_uuid                        AS template_id,
            dsl.widget_id,
            dsl.widget_title,
            dsl.widget_type,
            dsl.widget_sub_type,
            dsl.id                                              AS slide_id,
            CONVERT(DATE, dasa.active_until AT TIME ZONE 'UTC' AT TIME ZONE dt.windows_timezone) AS dasa_active_until,
            CONVERT(DATE, dasa.created_time AT TIME ZONE 'UTC' AT TIME ZONE dt.windows_timezone) AS dasa_created_time,
            dasa.status
        FROM ${rs_coredw}.dim_activity_section_association AS dasa
        JOIN ${rs_coredw}.dim_learning_objective AS dlo
            ON dasa.activity_id = dlo.lo_id
        JOIN ${rs_coredw}.dim_content_section AS dcs
            ON dcs.id = dasa.section_id
        JOIN ${rs_coredw}.dim_content_slide AS dsl
            ON dsl.section_id = dcs.id
        JOIN ${rs_coredw}.dim_tenant AS dt
            ON dt.tenant_id = dasa.tenant_id
        WHERE dlo.lo_status = 1
          AND dasa.status = 1
          AND dcs.status = 1
          AND dsl.status = 1
          AND ISNULL(dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON';

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.lo_structure_components;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.lo_structure_components_staging', 'lo_structure_components';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
