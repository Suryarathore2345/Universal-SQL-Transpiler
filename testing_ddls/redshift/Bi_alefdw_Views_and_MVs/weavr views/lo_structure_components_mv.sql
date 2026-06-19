CREATE MATERIALIZED VIEW bi_alefdw_dev.lo_structure_components_mv AS
(
SELECT distinct dlo.lo_id                                                             AS activity_id,
                dlo.lo_title                                                          AS activity_title,
                dlo.lo_dw_id                                                          AS activity_dw_id,
--                dat.at_component_uuid                                                 AS component_id,   -- when needed we can uncomment this
--                dat.at_component_name                                                 AS component_name, -- when needed we can uncomment this
--                dat.at_activity_type                                                  AS component_type, -- when needed we can uncomment this
                dcs.id                                                                AS content_section_id,
                dcs.dw_id                                                             AS content_section_dw_id,
                dcs.type                                                              AS content_section_type,
                dcs.title                                                             AS content_section_title,
                dasa.content_id,
                dasa.template_component_uuid                                          AS template_id,
                dsl.widget_id,
                dsl.widget_title,
                dsl.widget_type,
                dsl.widget_sub_type,
                dsl.id                                                                AS slide_id,
                TRUNC(CONVERT_TIMEZONE('UTC', dt.tenant_timezone, dasa.active_until)) AS dasa_active_until,
                TRUNC(CONVERT_TIMEZONE('UTC', dt.tenant_timezone, dasa.created_time)) AS dasa_created_time,
                dasa.status
FROM alefdw.dim_activity_section_association AS dasa
         JOIN alefdw.dim_learning_objective dlo
              ON dasa.activity_id = dlo.lo_id
         JOIN alefdw.dim_content_section dcs ON dcs.id = dasa.section_id
         JOIN alefdw.dim_content_slide dsl ON dsl.section_id = dcs.id
         JOIN alefdw.dim_tenant dt ON dt.tenant_id = dasa.tenant_id
--         JOIN alefdw.dim_activity_template dat ON dat.at_component_uuid = dasa.template_component_uuid    -- when needed we can uncomment this

WHERE lo_status = 1
  AND dasa.status = 1
  AND dcs.status = 1
  AND dsl.status = 1
  AND nvl(dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
    );