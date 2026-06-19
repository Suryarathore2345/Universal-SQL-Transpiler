CREATE OR REPLACE VIEW bi_alefdw_dev.pathway_level_completion_dm_view_py AS
WITH school_prveviousay AS (                   -- define previous Academic Year start and end date by school
			SELECT school_id,
				academic_year_id,
				academic_year_start_date AS previous_academic_year_start_date,
				academic_year_end_date AS previous_academic_year_end_date
			FROM (
				SELECT *,
					ROW_NUMBER() OVER (
						PARTITION BY school_id ORDER BY academic_year_end_date DESC
						) AS rank
				FROM bi_alefdw.bi_all_schools_dim_mv ay
				WHERE academic_year_is_roll_over_completed
				) pr_ay
			WHERE pr_ay.rank = 1
			)
     ,
    fact_levels_recommended_last AS (
    SELECT flr_pathway_dw_id,
           flr_student_dw_id,
           flr_course_dw_id,
           flr_course_activity_container_dw_id as flr_level_dw_id,
           flr_created_time,
           grade_name,
           grade_dw_id,
           class_school_id
    FROM (
             SELECT *,
                    ROW_NUMBER() OVER (
                        PARTITION BY flr_student_dw_id,
                            caa_activity_dw_id ORDER BY flr_created_time DESC
                        ) AS rank
             FROM alefdw.fact_levels_recommended flc
                      INNER JOIN alefdw.dim_course_activity_association dplaa
                                 ON flc.flr_course_activity_container_dw_id = dplaa.caa_container_dw_id
                                     AND dplaa.caa_status = 1
                                     AND flr_status = 1
                      INNER JOIN alefdw.dim_class dc
                                 ON dc.class_dw_id = flc.flr_class_dw_id
                      INNER JOIN alefdw.dim_grade g
                                  ON md5(g.grade_id) = md5(dc.class_grade_id)
                      INNER JOIN school_prveviousay ay
                              ON md5(ay.academic_year_id) = md5(g.academic_year_id)
         )
    WHERE rank = 1
)
SELECT DISTINCT sch.school_dw_id,
                flr.grade_name,
                flr.flr_student_dw_id,
                flr.flr_level_dw_id,
                flr.flr_created_time,
                flc.flc_course_activity_container_dw_id                               AS level_dw_id_completed,
                flc.flc_created_time                                                  AS level_completed_time
FROM  fact_levels_recommended_last flr
INNER JOIN alefdw.dim_school sch ON md5(flr.class_school_id)  = md5(sch.school_id)
         LEFT JOIN alefdw.dim_course dcr
                   ON flr.flr_course_dw_id = dcr.course_dw_id
                       AND dcr.course_status = 1
         LEFT JOIN alefdw.dim_course_activity_container dcac
                   ON md5(dcac.course_activity_container_course_id) = md5(dcr.course_id)
                       AND dcac.course_activity_container_dw_id = flr.flr_level_dw_id
                       AND dcac.course_activity_container_status = 1
          LEFT JOIN alefdw.fact_level_completed flc
                   ON flc.flc_course_activity_container_dw_id = flr.flr_level_dw_id
                       AND flc.flc_student_dw_id = flr.flr_student_dw_id
    WHERE dcr.course_type = 'PATHWAY'
WITH NO SCHEMA BINDING;




