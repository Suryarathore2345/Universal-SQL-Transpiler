CREATE MATERIALIZED VIEW bi_alefdw_dev.adt_cefr_level_mapping_mv AUTO REFRESH YES AS
SELECT
    grade,
    range_scale_score,
    category,
    grade_offset,
    cefr_level,
    CAST(SPLIT_PART(range_scale_score, '-', 1) AS INTEGER) AS min_scale_score,
    CAST(SPLIT_PART(range_scale_score, '-', 2) AS INTEGER) AS max_scale_score,
    MAX(CASE WHEN category = 'MEETS' THEN cefr_level END)
        OVER (PARTITION BY grade) AS target_cefr_level
FROM alefdw.dim_cefr_level_mapping;