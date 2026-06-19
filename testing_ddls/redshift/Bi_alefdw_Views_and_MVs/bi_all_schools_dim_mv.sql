CREATE MATERIALIZED VIEW bi_alefdw_dev.bi_all_schools_dim_mv AUTO REFRESH YES AS
-- a SCD type of table  -  multiple academic years per school including Academic years before IP->Course changes
WITH school_academic_year AS
         (SELECT saya.saya_school_id,
                 saya.academic_year_dw_id,
                 saya.academic_year_id,
                 saya.academic_year_type,
                 LEAST(saya.academic_year_start_date,
                       COALESCE(ay2.academic_year_start_date, saya.academic_year_start_date)) AS academic_year_start_date, -- use the least (minimum) between the switched years
                 saya.academic_year_end_date,                                                                               -- Use the ay_end of the current selected academic year
                 saya.academic_year_is_roll_over_completed
         FROM (SELECT *,
                     ROW_NUMBER() OVER (
                        PARTITION BY sayarn.saya_school_id, DATE_PART_YEAR(ay.academic_year_start_date)
                        ORDER BY sayarn.saya_created_time DESC) AS rn
              FROM alefdw.dim_school_academic_year_association sayarn
              INNER JOIN alefdw.dim_academic_year ay
                  ON sayarn.saya_academic_year_id = ay.academic_year_id
              WHERE ay.academic_year_status = 1
              QUALIFY rn = 1) saya
         LEFT JOIN alefdw.dim_academic_year ay2
             ON saya.saya_previous_academic_year_id = ay2.academic_year_id
             AND ay2.academic_year_status = 1
             AND saya.saya_type = 'SWITCH'
)
SELECT  school_dw_id,
        school_id,
        initcap(trim(school_name)) AS school_name,
        school_city_name,
        org.organization_name      AS school_organisation,
        org.organization_dw_id     AS organisation_dw_id,
        school_country_name,
        school_composition,
        school_latitude,
        school_longitude,
        NULLIF(school_cx_cluster, '') AS school_cx_cluster,
        school_alias,
        tenant_id,
        tenant_dw_id,
        tenant_name,
        case when dtn.tenant_name = 'Private' then 'Private ' + dsc.school_country_name
             when school_country_name = 'CANADA' then dsc.school_country_name
             else dtn.tenant_name end AS tenant_name_alias,
        tenant_timezone,
        nvl(tag_name, 'NA')        AS school_label,
        school_created_time,
        school_updated_time,
        school_status,
        aay.*
FROM alefdw.dim_school dsc
         INNER JOIN school_academic_year aay
                    ON dsc.school_id = aay.saya_school_id
         LEFT JOIN (select distinct tag_association_id,
                                    listagg(tag_name, ',') WITHIN GROUP (ORDER BY tag_name asc) AS tag_name

                    FROM alefdw.dim_tag dt
                    where tag_status = 1
                      and tag_association_attach_status = 1
                    GROUP BY tag_association_id) dtg ON dtg.tag_association_id = dsc.school_id
         LEFT JOIN alefdw.dim_tenant dtn
                   ON dtn.tenant_id = dsc.school_tenant_id
         LEFT JOIN alefdw.dim_organization org ON dsc.school_organization_dw_id = org.organization_dw_id
WHERE lower(nvl(tag_name, 'NA')) NOT LIKE '%alef_test_schools%'
AND school_deleted_time IS NULL
