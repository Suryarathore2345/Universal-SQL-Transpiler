CREATE OR REPLACE VIEW eagles_alefdw_dev.student_no_guardian_view AS
SELECT st.student_dw_id,
	st.student_id,
	sch.school_id,
	sch.school_name,
	g.grade_name,
    sc.section_dw_id,
    sc.section_name
FROM bi_alefdw.bi_student_dim_mv st
INNER JOIN bi_alefdw.bi_active_schools_dim_mv sch
    ON sch.school_dw_id = st.student_school_dw_id
INNER JOIN alefdw.dim_grade g
    ON g.grade_dw_id = st.student_grade_dw_id
    AND sch.school_id = g.school_id
    AND sch.academic_year_id = g.academic_year_id
INNER JOIN alefdw.dim_section sc
    ON sc.section_dw_id = st.student_section_dw_id and section_status = 1
WHERE st.student_status = 1
AND NOT EXISTS (
    SELECT 1
    FROM alefdw.dim_guardian gr
    WHERE gr.guardian_student_dw_id = st.student_dw_id AND guardian_status = 1)
WITH NO SCHEMA BINDING;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.student_no_guardian_view to group business_intelligence;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.student_no_guardian_view to group datascience;

grant delete, insert, references, select, trigger, update on eagles_alefdw_dev.student_no_guardian_view to group tdc;

grant select on eagles_alefdw_dev.student_no_guardian_view to group ro_users;