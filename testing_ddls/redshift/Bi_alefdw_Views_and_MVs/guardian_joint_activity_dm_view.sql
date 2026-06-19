
CREATE OR REPLACE VIEW bi_alefdw_dev.guardian_joint_activity_dm_view AS
WITH fact_guardian_joint_activity AS (SELECT DISTINCT fgja.*,
                                                      dcaa.caa_activity_dw_id,
                                                      dcaa.caa_activity_type,
                                                      lo.lo_dw_id,
                                                      lo.lo_title,
                                                      lo.lo_language
                                      FROM (SELECT fgja.*,
                                                   fgja_completed.fgja_completed_time
                                            FROM (SELECT *,
                                                         ROW_NUMBER() OVER (
                                                             PARTITION BY fgja_student_dw_id, fgja_guardian_dw_id, fgja_dw_id, coalesce(fgja_attempt, 1)
                                                             ORDER BY fgja_created_time DESC
                                                             ) AS Row
                                                  FROM alefdw.fact_guardian_joint_activity) AS fgja
                                                     LEFT JOIN (SELECT DISTINCT fgja_student_dw_id,
                                                                                fgja_guardian_dw_id,
                                                                                fgja_attempt,
                                                                                fgja_created_time as fgja_completed_time
                                                                FROM alefdw.fact_guardian_joint_activity AS fgja
                                                                WHERE fgja.fgja_state = 3) AS fgja_completed
                                                               ON fgja.fgja_student_dw_id =
                                                                  fgja_completed.fgja_student_dw_id
                                                                   AND fgja.fgja_guardian_dw_id =
                                                                       fgja_completed.fgja_guardian_dw_id
                                                                   AND fgja.fgja_attempt = fgja_completed.fgja_attempt
                                            WHERE fgja.ROW = 1) as fgja
                                               JOIN alefdw.dim_course dcr
                                                    ON fgja.fgja_course_dw_id = dcr.course_dw_id
                                                        AND dcr.course_status = 1 AND dcr.course_type = 'PATHWAY'
                                               JOIN alefdw.dim_course_activity_container dcac
                                                    ON fgja.fgja_course_activity_container_dw_id =
                                                       dcac.course_activity_container_dw_id
                                                        AND fgja.fgja_course_dw_id = dcr.course_dw_id
                                               JOIN alefdw.dim_course_activity_association dcaa
                                                    ON dcaa.caa_course_dw_id = dcr.course_dw_id
                                                        AND dcaa.caa_status = 1 AND dcaa.caa_attach_status = 1
                                                        AND dcaa.caa_is_joint_parent_activity = TRUE
                                               JOIN alefdw.dim_learning_objective lo
                                                    ON dcaa.caa_activity_dw_id = lo.lo_dw_id
                                                        AND UPPER(lo.lo_language) LIKE 'EN_%'
                                                        AND lo.lo_status = 1),
     class_grade_section_title AS (select distinct dc.class_dw_id,
                                                   initcap(dc.class_title)              as class_title,
                                                   initcap(NVL(dse.section_name, 'NA')) as section_name,
                                                   dg.grade_dw_id
                                   FROM alefdw.dim_class AS dc
                                            JOIN alefdw.dim_class_user as dcu
                                                 on dc.class_dw_id = dcu.class_user_class_dw_id
                                            JOIN alefdw.dim_grade dg on md5(dg.grade_id) = md5(dc.class_grade_id)
                                            JOIN alefdw.dim_section dse
                                                 on dc.class_section_id = dse.section_id
                                            JOIN alefdw.dim_course dcr
                                                 ON md5(dc.class_material_id) = md5(dcr.course_id)
                                                     AND dcr.course_status = 1 AND dcr.course_type = 'PATHWAY'
                                   WHERE dc.class_status = 1
                                     AND dc.class_course_status = 'ACTIVE'
                                     AND dc.class_material_type = 'PATHWAY'
                                     and dg.grade_status = 1
                                     and dse.section_status = 1
                                     AND dcu.class_user_role_dw_id = 2
                                     AND dcu.class_user_attach_status = 1
                                     and dcu.class_user_status = 1)

SELECT DISTINCT trunc(convert_timezone('UTC', dsc.tenant_timezone, fgja.fgja_created_time)) as local_date,
                convert_timezone('UTC', dsc.tenant_timezone, fgja.fgja_created_time)        as fgja_created_time,
                convert_timezone('UTC', dsc.tenant_timezone,
                                 fgja.fgja_completed_time)                                  as fgja_completed_time,
                fgja.fgja_dw_id,
                dsc.academic_year_dw_id,
                dsc.tenant_id,
                dsc.organisation_dw_id,
                fgja.fgja_school_dw_id                                                      as school_dw_id,
                fgja.fgja_class_dw_id                                                       as class_dw_id,
                cgst.grade_dw_id,
                fgja.fgja_pathway_dw_id                                                     as pathway_dw_id,
                fgja.fgja_student_dw_id                                                     as student_dw_id,
                fgja.fgja_guardian_dw_id                                                    as guardian_dw_id,
                fgja.caa_activity_dw_id                                                     as plaa_activity_dw_id,
                fgja.lo_dw_id,
                dsc.academic_year_start_date,
                dsc.academic_year_end_date,
                date_part(year, dsc.academic_year_start_date) || '-' ||
                date_part(year, dsc.academic_year_end_date)                                                        as academic_year,
                dsc.tenant_name,
                dsc.school_organisation,
                dsc.school_country_name,
                dsc.school_city_name,
                dsc.school_name,
                cgst.class_title,
                fgja.fgja_k12_grade                                                         as k12_grade,
                cgst.section_name,
                fgja.caa_activity_type                                                      as plaa_activity_type,
                fgja.fgja_attempt                                                           as attempt,
                fgja.fgja_rating                                                            as rating,
                fgja.fgja_state                                                             as state,
                CASE
                    fgja.fgja_state
                    when 1 then 'Assigned'
                    when 2 then 'Started'
                    when 3 then 'Completed'
                    when 4 then 'Rated'
                    else 'Invalid State'
                    END                                                                        state_status,
                fgja.lo_title,
                fgja.lo_language,
                gsa.total_guardians
FROM fact_guardian_joint_activity as fgja
         JOIN bi_alefdw.bi_student_dim_mv as dst
              ON dst.student_dw_id = fgja.fgja_student_dw_id
                  AND dst.student_status = 1
         JOIN bi_alefdw.bi_active_schools_dim_mv as dsc
              ON dsc.school_dw_id = dst.student_school_dw_id
                AND (convert_timezone('UTC', dsc.tenant_timezone, fgja.fgja_created_time) >= dsc.academic_year_start_date
                      AND convert_timezone('UTC', dsc.tenant_timezone, fgja.fgja_created_time) <= dsc.academic_year_end_date)
         JOIN class_grade_section_title as cgst
              on cgst.class_dw_id = fgja.fgja_class_dw_id
         JOIN (SELECT DISTINCT school_dw_id,
                               COUNT(DISTINCT guardian_dw_id) as total_guardians
               FROM bi_alefdw.guardian_student_association_dm_view as gsa
               GROUP BY 1) AS gsa
              on gsa.school_dw_id = fgja.fgja_school_dw_id
WITH NO SCHEMA BINDING;

