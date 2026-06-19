CREATE MATERIALIZED VIEW bi_alefdw_dev.core_ip_class_ic_content_mv AS
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
             sch.school_city_name,
             sch.school_country_name,
             sch.school_status,
             sch.tenant_name,
             sch.school_organisation,
             dip.instructional_plan_item_ic_dw_id AS activity_dw_id,
             ic.ic_title,
             icr.ic_num_questions,
             DENSE_RANK() OVER (PARTITION BY dc.class_dw_id, dc.class_material_id, dc.class_gen_subject
                 ORDER BY dw.week_start_date, dip.instructional_plan_item_order) AS ic_order,
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
      JOIN alefdw.dim_interim_checkpoint ic
           ON dip.instructional_plan_item_ic_dw_id = ic.ic_dw_id
               AND ic.ic_status = 1
      LEFT JOIN  alefdw.dim_curriculum_subject dcs
            ON dc.class_curriculum_subject_id = dcs.curr_subject_id
            AND dcs.curr_subject_dw_id = 129   -- Arabits subject
      LEFT JOIN (SELECT ic_rule_ic_dw_id,
                        SUM(ic_rule_no_questions) AS ic_num_questions
                 FROM alefdw.dim_interim_checkpoint_rules
                 WHERE ic_rule_status = 1
                 GROUP BY 1) icr
            ON icr.ic_rule_ic_dw_id = ic.ic_dw_id
WHERE dip.instructional_plan_status = 1
AND instructional_plan_item_optional IS FALSE
AND dc.class_status = 1
AND DATE_PART_YEAR(sch.academic_year_start_date) >= 2021;---- there are some issue with earlier AYs that induce errors