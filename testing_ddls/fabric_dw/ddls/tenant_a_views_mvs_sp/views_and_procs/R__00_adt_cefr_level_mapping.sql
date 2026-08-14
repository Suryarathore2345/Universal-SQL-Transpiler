CREATE OR ALTER PROCEDURE ${os_bi_coredw}.usp_refresh_adt_cefr_level_mapping
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- --------------------------------------------------------
        -- Step 1: Drop stale staging table if it exists
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.adt_cefr_level_mapping_staging;

        -- --------------------------------------------------------
        -- Step 2: CTAS - Build staging table with full transformation
        -- --------------------------------------------------------
        CREATE TABLE ${os_bi_coredw}.adt_cefr_level_mapping_staging
        WITH (CLUSTER BY (grade))
        AS
        SELECT
            grade,
            range_scale_score,
            category,
            grade_offset,
            cefr_level,
            CONVERT(INT, LEFT(range_scale_score, CHARINDEX('-', range_scale_score) - 1)) AS min_scale_score,
            CONVERT(INT, SUBSTRING(range_scale_score, CHARINDEX('-', range_scale_score) + 1, CHARINDEX('-', range_scale_score + '-', CHARINDEX('-', range_scale_score) + 1) - CHARINDEX('-', range_scale_score) - 1)) AS max_scale_score,
            MAX(CASE WHEN category = 'MEETS' THEN cefr_level END)
                OVER (PARTITION BY grade) AS target_cefr_level
        FROM ${rs_coredw}.dim_cefr_level_mapping;

        -- --------------------------------------------------------
        -- Step 3: Drop existing production table
        -- --------------------------------------------------------
        DROP TABLE IF EXISTS ${os_bi_coredw}.adt_cefr_level_mapping;

        -- --------------------------------------------------------
        -- Step 4: Promote staging to production
        -- --------------------------------------------------------
        EXEC sp_rename '${os_bi_coredw}.adt_cefr_level_mapping_staging', 'adt_cefr_level_mapping';

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
