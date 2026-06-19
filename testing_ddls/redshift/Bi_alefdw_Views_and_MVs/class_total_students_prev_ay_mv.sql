CREATE MATERIALIZED VIEW bi_alefdw_dev.class_total_students_prev_ay_mv AS
WITH class_teachers AS ( --define teacher assigned to the class
        SELECT dc.class_dw_id,
            listagg(DISTINCT teacher_id, ',') WITHIN GROUP (ORDER BY class_user_created_time) AS teacher_ids
        FROM alefdw.dim_class dc
        INNER JOIN alefdw.dim_class_user dcu
            ON dcu.class_user_class_dw_id = dc.class_dw_id
        INNER JOIN bi_alefdw.bi_all_schools_dim_mv ay
            ON dc.class_academic_year_id = ay.academic_year_id
                AND dc.class_school_id = ay.school_id
        LEFT JOIN alefdw.dim_teacher dt
            ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                AND teacher_id NOT IN (
                    SELECT DISTINCT teacher_id
                    FROM bi_alefdw.exclude_teacher_id
                    )
        WHERE dcu.class_user_role_dw_id = 1
            AND dc.class_course_status = 'CONCLUDED'
            AND dcu.class_user_attach_status = 1
            GROUP BY 1
)
SELECT dc.class_dw_id,
    dc.class_id,
	dc.class_material_id AS instructional_plan_id,
	sch.school_dw_id,
	school_name,
	initcap(dc.class_title) AS class_title,
	initcap(dc.class_gen_subject) AS class_gen_subject,
	dc.class_curriculum_id,
    NVL(dsec.section_dw_id, '10001') AS class_section_dw_id,
    initcap(NVL(dsec.section_alias, 'NA')) as class_section_name,
	teacher_ids,
	dg.grade_name,
	dc.class_academic_calendar_id,
	CAST(date_part_year(sch.academic_year_end_date) AS VARCHAR(20)) as content_academic_year_name,
	dcs.curr_subject_id AS course_subject_id,
	count(DISTINCT dcu.class_user_user_dw_id) AS class_total_students
FROM alefdw.dim_class dc
INNER JOIN alefdw.dim_class_user dcu
	ON dcu.class_user_class_dw_id = dc.class_dw_id
INNER JOIN bi_alefdw.bi_all_schools_dim_mv sch
	ON dc.class_academic_year_id = sch.academic_year_id
    AND dc.class_school_id = sch.school_id
INNER JOIN alefdw.dim_curriculum_subject dcs
	ON dc.class_curriculum_subject_id = dcs.curr_subject_id
INNER JOIN alefdw.dim_grade dg
	ON dg.grade_id = dc.class_grade_id
LEFT JOIN alefdw.dim_section dsec
	ON dsec.section_id = dc.class_section_id
LEFT JOIN class_teachers ct
	ON ct.class_dw_id = dc.class_dw_id
WHERE dcu.class_user_role_dw_id = 2
	AND dcu.class_user_attach_status = 1
    AND dc.class_status = 1
	AND dc.class_course_status = 'CONCLUDED'
    AND dc.class_material_type != 'PATHWAY'
    AND lower(dc.class_title) NOT LIKE '%power skills%'
    AND lower(dc.class_title) NOT LIKE '%extra resources%'
    AND lower(dc.class_gen_subject) != 'alef stars'
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
