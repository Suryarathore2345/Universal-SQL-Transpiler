CREATE OR REPLACE VIEW bi_alefdw_dev.student_badges_dm_view
AS
WITH section_total_students AS ( -- to take section total students
    SELECT DISTINCT sc.school_dw_id,
                    dg.grade_k12grade,
                    dg.grade_dw_id,
                    NVL(dse.section_dw_id, '10001')      AS section_dw_id,
                    initcap(NVL(dse.section_name, 'NA')) AS section_name,
                    dg.grade_name,
                    count(DISTINCT ds.student_dw_id)     AS section_total_students
    FROM alefdw.dim_section dse
             JOIN bi_alefdw.bi_active_schools_dim_mv sc ON md5(dse.school_id) = md5(sc.school_id)
             JOIN bi_alefdw.bi_student_dim_mv ds
                  ON sc.school_dw_id = ds.student_school_dw_id AND ds.student_section_dw_id = dse.section_dw_id
             JOIN alefdw.dim_grade dg ON md5(dg.grade_dw_id) = md5(ds.student_grade_dw_id)
    WHERE ds.student_status = 1
      AND section_status = 1
    GROUP BY 1, 2, 3, 4, 5, 6
),
     earned_badges AS (
                    SELECT dd.full_date AS local_date,
                      fba_dw_id,
                      fba_id,
                      fba_badge_dw_id,
                      fba_student_dw_id,
                      fba_school_dw_id,
                      fba_grade_dw_id,
                      fba_section_dw_id,
                      --fba_class_dw_id,
                      fba_tenant_dw_id,
                      fba_academic_year_dw_id,
                      fba_content_repository_dw_id,
                      fba_organization_dw_id,
                      fba_date_dw_id
               FROM alefdw.fact_badge_awarded fba
                        JOIN alefdw.dim_date dd
                             ON fba.fba_date_dw_id = dd.date_id
                        JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                             ON fba.fba_school_dw_id = dsc.school_dw_id
                             AND trunc(fba.fba_created_time) >= dsc.academic_year_start_date
                             AND trunc(fba.fba_created_time) <= dsc.academic_year_end_date
)
SELECT DISTINCT local_date,
                db.bdg_dw_id,
                db.bdg_id,
                db.bdg_grade,
                db.bdg_title,
                db.bdg_tier,
                db.bdg_type,
                db.bdg_category,
                db.bdg_tenant_dw_id,
                db.bdg_threshold,
                eb.fba_student_dw_id,
                dst.student_id,
                dsc.tenant_name,
                dsc.school_dw_id,
                dsc.school_id,
                dsc.school_name,
                dsc.school_alias                            AS school_adek_id,
                dsc.school_country_name,
                dsc.school_city_name,
                dsc.school_label,
                dsc.school_organisation                     AS organisation_name,
                dsc.school_latitude,
                dsc.school_longitude,
                dg.grade_k12grade                           AS grade,
                dg.grade_dw_id,
                dst.student_section_dw_id,
                sts.section_total_students,
                sts.section_name,
                dsc.academic_year_start_date,
                dsc.academic_year_end_date,
                date_part(year, dsc.academic_year_start_date) || '-' ||
                date_part(year, dsc.academic_year_end_date) AS academic_year
FROM earned_badges eb
         INNER JOIN alefdw.dim_badge db ON db.bdg_dw_id = eb.fba_badge_dw_id
    AND db.bdg_status IN (1,2)
         INNER JOIN bi_alefdw.bi_student_dim_mv dst
                    ON dst.student_dw_id = eb.fba_student_dw_id
                        AND dst.student_status = 1
                        AND dst.student_active_until IS NULL
         INNER JOIN section_total_students sts
                    ON sts.school_dw_id = dst.student_school_dw_id
                        AND sts.grade_dw_id = dst.student_grade_dw_id
                        AND sts.section_dw_id = NVL(dst.student_section_dw_id, '10001')
         INNER JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                    ON dsc.school_dw_id = eb.fba_school_dw_id
                        AND dsc.academic_year_dw_id = eb.fba_academic_year_dw_id
                        AND dst.student_school_dw_id = dsc.school_dw_id
         INNER JOIN alefdw.dim_grade dg
                    ON dg.grade_dw_id = eb.fba_grade_dw_id
                        AND dg.grade_status = 1
                        AND dg.school_id = dsc.school_id
WITH NO SCHEMA BINDING;