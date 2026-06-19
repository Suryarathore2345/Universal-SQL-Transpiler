------===== FETCH UNIQUE ATTEMPTS (SLIDE+STUDENT) AT DAILY PERIOD  =======----
CREATE MATERIALIZED VIEW bi_alefdw_dev.structure_components_attempts_mv_view AS
(
SELECT local_date,
       fsl.school_dw_id,
       fsl.class_dw_id,
       fsl.tenant_dw_id,
       fsl.fle_lo_dw_id,
       dsc.tenant_name,
       dsc.school_organisation,
       dsc.school_name,
       fsl.grade_name,
       fsl.class_gen_subject,
       fsl.class_title,
       fsl.widget_id,
       count(DISTINCT concat(slide_id, student_id)) AS slide_student_attempts
FROM bi_alefdw.fact_slide_progress_mv fsl
         JOIN bi_alefdw.bi_active_schools_dim_mv dsc ON dsc.school_dw_id = fsl.school_dw_id
GROUP BY local_date,
         fsl.school_dw_id,
         fsl.class_dw_id,
         fsl.class_title,
         fsl.class_gen_subject,
         fsl.tenant_dw_id,
         fsl.fle_lo_dw_id,
         dsc.tenant_name,
         dsc.school_organisation,
         dsc.school_name,
         fsl.grade_name,
         fsl.class_gen_subject,
         fsl.class_title,
         fsl.widget_id
    );