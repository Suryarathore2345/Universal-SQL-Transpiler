CREATE MATERIALIZED VIEW bi_alefdw_dev.core_ip_class_activity_content_mv AS
SELECT DISTINCT dip.instructional_plan_id         AS course_id,
             dip.instructional_plan_name          AS course_name,
             dc.class_dw_id,
             dc.class_id,
             dc.class_title,
             dc.class_gen_subject,
             dc.class_grade_id,
             g.grade_k12grade                     AS grade_name,
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
             DATE_PART_YEAR(sch.academic_year_start_date) || ' - ' ||
                DATE_PART_YEAR (sch.academic_year_end_date)                           AS academic_year
FROM alefdw.dim_instructional_plan dip
      JOIN alefdw.dim_class dc
           ON dip.instructional_plan_id = dc.class_material_id
      JOIN bi_alefdw.bi_all_schools_dim_mv sch
           ON dc.class_school_id = sch.school_id
               AND dc.class_academic_year_id = sch.academic_year_id
      JOIN alefdw.dim_grade g
          ON dc.class_grade_id = g.grade_id
      JOIN alefdw.dim_week dw
           ON dip.instructional_plan_item_week_dw_id = dw.week_dw_id
      JOIN alefdw.dim_term dtrm
           ON dw.week_term_id = dtrm.term_id
      JOIN alefdw.dim_learning_objective dip_dlo
           ON dip.instructional_plan_item_lo_dw_id = dip_dlo.lo_dw_id
               AND COALESCE(dip_dlo.lo_type, 'NA') <> 'EXPERIENTIAL_LESSON'
               AND COALESCE(dip_dlo.lo_template_uuid,'NA') NOT IN ('235229fa-4707-4286-8ec2-85f70347096a', '15295fd1-b5e3-46f9-9045-86ee3b13552b')
               AND dip_dlo.lo_status = 1
      LEFT JOIN  alefdw.dim_curriculum_subject dcs
            ON dc.class_curriculum_subject_id = dcs.curr_subject_id
            AND dcs.curr_subject_dw_id = 129   -- Arabits subject
WHERE dip.instructional_plan_status = 1
AND instructional_plan_item_optional IS FALSE
AND dc.class_status = 1
AND DATE_PART_YEAR(sch.academic_year_start_date) >= 2021; ---- there are some issue with earlier AYs that induce errors