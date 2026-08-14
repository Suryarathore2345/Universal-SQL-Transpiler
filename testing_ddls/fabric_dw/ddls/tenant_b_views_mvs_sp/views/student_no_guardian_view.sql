CREATE OR ALTER VIEW ${OS_EAGLES_COREDW}.student_no_guardian_view AS
SELECT st.student_dw_id,
	st.student_id,
	sch.school_id,
	sch.school_name,
	g.grade_name,
    sc.section_dw_id,
    sc.section_name
FROM ${RS_BI_COREDW}.bi_student_dim st
INNER JOIN ${RS_BI_COREDW}.bi_active_schools_dim sch
    ON sch.school_dw_id = st.student_school_dw_id
INNER JOIN ${RS_COREDW}.dim_grade g
    ON g.grade_dw_id = st.student_grade_dw_id
    AND sch.school_id = g.school_id
    AND sch.academic_year_id = g.academic_year_id
INNER JOIN ${RS_COREDW}.dim_section sc
    ON sc.section_dw_id = st.student_section_dw_id and section_status = 1
LEFT JOIN ${RS_COREDW}.dim_guardian gr
    ON gr.guardian_student_dw_id = st.student_dw_id
    AND gr.guardian_status = 1
WHERE st.student_status = 1
AND gr.guardian_student_dw_id IS NULL
AND NOT EXISTS (
    SELECT 1
    FROM ${RS_COREDW}.dim_guardian gr
    WHERE gr.guardian_student_dw_id = st.student_dw_id AND guardian_status = 1);