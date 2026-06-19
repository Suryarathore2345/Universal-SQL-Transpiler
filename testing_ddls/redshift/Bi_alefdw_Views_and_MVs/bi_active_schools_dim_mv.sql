CREATE MATERIALIZED VIEW bi_alefdw_dev.bi_active_schools_dim_mv as
WITH active_academic_year AS
         (SELECT saya.saya_school_id,
                 ay.academic_year_dw_id,
                 ay.academic_year_id,
                 ay.academic_year_type,
                 LEAST(ay.academic_year_start_date,
                       COALESCE(ay2.academic_year_start_date, ay.academic_year_start_date)) AS academic_year_start_date, -- use the least (minimum) between the switched years
                 ay.academic_year_end_date                                                                               -- Use the ay_end of the current selected academic year
          FROM alefdw.dim_school_academic_year_association saya
                   INNER JOIN alefdw.dim_academic_year ay
                              ON saya.saya_academic_year_id = ay.academic_year_id
                   LEFT JOIN alefdw.dim_academic_year ay2
                             ON saya.saya_previous_academic_year_id = ay2.academic_year_id
                                 AND ay2.academic_year_is_roll_over_completed = false
                                 AND ay2.academic_year_status = 1
                                 AND saya.saya_type = 'SWITCH'
          WHERE saya.saya_status = 1
            AND ay.academic_year_status = 1
            AND ay.academic_year_is_roll_over_completed = FALSE)

select distinct school_dw_id,
                school_id,
                initcap(trim(school_name))                                       school_name,
                school_city_name,
                org.organization_name                                         AS school_organisation,
                org.organization_dw_id                                        AS organisation_dw_id,
                school_country_name,
                school_composition,
                school_latitude,
                school_longitude,
                NULLIF(school_cx_cluster, '') AS school_cx_cluster,
                school_alias,
                tenant_id,
                tenant_name,
                tenant_timezone,
                nvl(tag_name, 'NA')                                              school_label,
                first_value(school_created_time)
                over (partition by school_dw_id order by school_created_time asc
                    rows between unbounded preceding and unbounded following) AS school_created_time,
                aay.*
from alefdw.dim_school dsc
         INNER JOIN active_academic_year aay
                    ON dsc.school_id = aay.saya_school_id
         LEFT JOIN (select distinct tag_association_id,
                                    listagg(tag_name, ',') WITHIN GROUP (ORDER BY tag_name asc) AS tag_name

                    FROM alefdw.dim_tag dt
                    where tag_status = 1
                      and tag_association_attach_status = 1
                    GROUP BY tag_association_id) dtg on dtg.tag_association_id = dsc.school_id
         LEFT JOIN alefdw.dim_tenant dtn
                   ON dtn.tenant_id = dsc.school_tenant_id
         LEFT JOIN alefdw.dim_organization org
                   on dsc.school_organization_dw_id = org.organization_dw_id
WHERE school_status = 1
  AND lower(nvl(tag_name, 'NA')) NOT LIKE '%alef_test_schools%';
