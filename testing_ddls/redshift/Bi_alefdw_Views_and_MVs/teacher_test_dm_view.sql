CREATE OR REPLACE VIEW bi_alefdw_dev.teacher_test_dm_view AS
WITH cte_teachers AS
         (SELECT DISTINCT teacher_dw_id,
                          teacher_id,
                          class_dw_id
          FROM alefdw.dim_class dc
                   JOIN alefdw.dim_class_user dcu ON dcu.class_user_class_dw_id = dc.class_dw_id
                   LEFT JOIN alefdw.dim_teacher dt
                             ON dcu.class_user_user_dw_id = dt.teacher_dw_id
                                 AND dt.teacher_status = 1
                                 AND teacher_id NOT IN
                                     (SELECT DISTINCT teacher_id FROM bi_alefdw.exclude_teacher_id)
          WHERE class_status = 1
            AND dcu.class_user_role_dw_id = 1
            AND class_course_status = 'ACTIVE'
            AND class_user_status = 1
            AND dcu.class_user_attach_status = 1),
     tt_lq_assigned AS
         (SELECT DISTINCT dtt.tt_dw_id,
                          dtt.tt_test_id,
                          dttbla.ttbla_dw_id,
                          dttbla.ttbla_test_blueprint_id,
                          count(DISTINCT dttbla.ttbla_lesson_id) AS lessons_assigned,
                          count(DISTINCT ttia_test_item_id)      AS questions_assigned
          FROM alefdw.dim_teacher_test_blueprint_lesson_association AS dttbla
                   JOIN alefdw.dim_learning_objective lo
                        ON fnv_hash(lo.lo_id) = fnv_hash(dttbla.ttbla_lesson_id) AND lo.lo_status = 1
                   JOIN alefdw.dim_teacher_test dtt
                        ON fnv_hash(dtt.tt_test_blueprint_id) = fnv_hash(dttbla.ttbla_test_blueprint_id)
                   JOIN alefdw.dim_teacher_test_item_association dttia
                        ON fnv_hash(dttia.ttia_test_id) = fnv_hash(dtt.tt_test_id) AND dttbla.ttbla_status=1 AND dttia.ttia_status=1
          GROUP BY dtt.tt_dw_id, dtt.tt_test_id, dttbla.ttbla_dw_id, dttbla.ttbla_test_blueprint_id),

     tt_assigned_students AS
         (SELECT DISTINCT ttca_test_id,
                          ttca_dw_id,
                          ttca_test_delivery_id,
                          ttca_test_candidate_id
          FROM alefdw.dim_teacher_test_candidate_association AS ttca
                   JOIN bi_alefdw.bi_student_dim_mv ds
                        ON ds.student_id = ttca.ttca_test_candidate_id
          WHERE ttca_status = 1
            AND student_status = 1),

     dim_teacher_test as
         (SELECT DISTINCT tt.tt_dw_id,
                          tt.tt_test_id,
                          tt.tt_test_class_id                                                    AS class_id,
                          tt.tt_test_created_by_id                                               AS teacher_id,
                          tt.tt_test_title,
                          tt.tt_test_blueprint_id,
                          tt.tt_test_status,
                          trunc(convert_timezone('UTC', sc.tenant_timezone, tt.tt_created_time)) AS tt_created_date,
                          convert_timezone('UTC', sc.tenant_timezone, tt.tt_created_time)        AS created_time,
                          trunc(convert_timezone('UTC', sc.tenant_timezone, tt.tt_updated_time)) AS published_date,
                          convert_timezone('UTC', sc.tenant_timezone, tt.tt_updated_time)        AS published_time,
                          tas.ttca_test_candidate_id                                             AS tt_assigned_student_id,
                          convert_timezone('UTC', sc.tenant_timezone, ds.ttds_test_start_time)   AS ttds_test_start_time,
                          convert_timezone('UTC', sc.tenant_timezone, ds.ttds_test_end_time)     AS ttds_test_end_time,
                          CASE
                              WHEN DATE(tt_created_time) = DATE(ttds_test_start_time) THEN 'today'
                              WHEN DATE(tt_created_time) < DATE(ttds_test_start_time) THEN 'future_date'
                              ELSE 'other'
                              END                                                                AS tt_start_date_flag,
                          lqa.lessons_assigned,
                          lqa.questions_assigned,
                          ds.ttds_dw_id,
                          ds.ttds_test_delivery_id
          FROM alefdw.dim_teacher_test tt
                   JOIN alefdw.dim_class dc on dc.class_id = tt.tt_test_class_id AND tt.tt_status = 1
                   JOIN bi_alefdw.bi_active_schools_dim_mv sc
                        ON fnv_hash(dc.class_school_id) = fnv_hash(sc.school_id)
                            AND trunc(tt_created_time) >= sc.academic_year_start_date
                            AND trunc(tt_created_time) <= sc.academic_year_end_date
                   JOIN alefdw.dim_teacher_test_delivery_settings ds
                        ON fnv_hash(ds.ttds_test_id) = fnv_hash(tt.tt_test_id) AND ttds_status = 1
                   JOIN tt_lq_assigned lqa
                        ON fnv_hash(lqa.tt_test_id) = fnv_hash(tt.tt_test_id)
                   JOIN tt_assigned_students tas
                        ON fnv_hash(tas.ttca_test_delivery_id) = fnv_hash(ds.ttds_test_delivery_id)
          WHERE tt.tt_status = 1
            and upper(tt_test_status) = 'PUBLISHED'

          UNION ALL

          SELECT DISTINCT tt.tt_dw_id,
                          tt.tt_test_id,
                          tt.tt_test_class_id                                                    AS class_id,
                          tt.tt_test_created_by_id                                               AS teacher_id,
                          tt.tt_test_title,
                          tt.tt_test_blueprint_id,
                          tt.tt_test_status,
                          trunc(convert_timezone('UTC', sc.tenant_timezone, tt.tt_created_time)) AS tt_created_date,
                          convert_timezone('UTC', sc.tenant_timezone, tt.tt_created_time)        AS created_time,
                          trunc(convert_timezone('UTC', sc.tenant_timezone, tt.tt_updated_time)) AS published_date,
                          convert_timezone('UTC', sc.tenant_timezone, tt.tt_updated_time)        AS published_time,
                          tas.ttca_test_candidate_id                                             AS tt_assigned_student_id,
                          convert_timezone('UTC', sc.tenant_timezone, ds.ttds_test_start_time)   AS ttds_test_start_time,
                          convert_timezone('UTC', sc.tenant_timezone, ds.ttds_test_end_time)     AS ttds_test_end_time,
                          CASE
                              WHEN DATE(tt_created_time) = DATE(ttds_test_start_time) THEN 'today'
                              WHEN DATE(tt_created_time) < DATE(ttds_test_start_time) THEN 'future_date'
                              ELSE 'other'
                              END                                                                AS tt_start_date_flag,
                          lqa.lessons_assigned,
                          lqa.questions_assigned,
                          ds.ttds_dw_id,
                          ds.ttds_test_delivery_id
          FROM alefdw.dim_teacher_test tt
                   JOIN alefdw.dim_class dc on dc.class_id = tt.tt_test_class_id AND tt.tt_status = 1
                   JOIN bi_alefdw.bi_active_schools_dim_mv sc
                        ON fnv_hash(dc.class_school_id) = fnv_hash(sc.school_id)
                            AND trunc(tt_created_time) >= sc.academic_year_start_date
                            AND trunc(tt_created_time) <= sc.academic_year_end_date
                   LEFT JOIN alefdw.dim_teacher_test_delivery_settings ds
                             ON fnv_hash(ds.ttds_test_id) = fnv_hash(tt.tt_test_id) AND ttds_status = 1
                   LEFT JOIN tt_lq_assigned lqa
                             ON fnv_hash(lqa.tt_test_id) = fnv_hash(tt.tt_test_id)
                   LEFT JOIN tt_assigned_students tas
                             ON fnv_hash(tas.ttca_test_delivery_id) = fnv_hash(ds.ttds_test_delivery_id)
          WHERE tt.tt_status = 1
            and (upper(tt_test_status) = 'DRAFT' OR upper(tt_test_status) = 'VALID'))


SELECT DISTINCT ct.teacher_dw_id,
                sc.school_name,
                sc.school_dw_id,
                sc.school_organisation,
                sc.tenant_name,
                dg.grade_k12grade,
                dg.grade_name,
                sc.academic_year_type,
                sc.academic_year_start_date,
                sc.academic_year_end_date,
                dc.class_gen_subject,
                dc.class_title,
                dc.class_dw_id,
                dcr.course_type,
                tt.*,

                convert_timezone('UTC', sc.tenant_timezone,
                                 FIRST_VALUE(fttcp_created_time) OVER (
                                     PARTITION BY fttcp_candidate_dw_id, tt.tt_dw_id
                                     ORDER BY fttcp_created_time
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS student_test_start_time,
                convert_timezone('UTC', sc.tenant_timezone,
                                 LAST_VALUE(
                                 CASE WHEN fttcp_status = 'RECORDER_COMPLETED' THEN fttcp_created_time END)
                                 OVER (
                                     PARTITION BY fttcp_candidate_dw_id, tt.tt_dw_id
                                     ORDER BY fttcp_created_time
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS student_test_end_time,
                fttcp.fttcp_candidate_dw_id,
                EXTRACT(EPOCH FROM
                        (last_value(fttcp_updated_at)
                         OVER (PARTITION BY fttcp_test_delivery_dw_id, fttcp_candidate_dw_id ORDER BY fttcp_updated_at desc ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) -
                         first_value(fttcp_created_at)
                         OVER (PARTITION BY fttcp_test_delivery_dw_id, fttcp_candidate_dw_id ORDER BY fttcp_created_at ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING))::INTERVAL) /
                60                                                                              AS stud_time_spent_in_mins,
                first_value(fttcp_stars_awarded)
                OVER (PARTITION BY fttcp_candidate_dw_id, fttcp_test_delivery_dw_id ORDER BY fttcp_updated_at ASC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)                   AS stars_earned,
                first_value(fttcp_score)
                OVER (PARTITION BY fttcp_candidate_dw_id, fttcp_test_delivery_dw_id ORDER BY fttcp_updated_at ASC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)                   AS test_score,
                first_value(fttcp_status)
                OVER (PARTITION BY fttcp_candidate_dw_id, fttcp_test_delivery_dw_id ORDER BY fttcp_updated_at ASC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)                   AS completion_status,
                CASE
                    WHEN first_value(fttcp_status)
                         OVER (PARTITION BY fttcp_candidate_dw_id, fttcp_test_delivery_dw_id ORDER BY fttcp_updated_at ASC
                             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) =
                         'RECORDER_COMPLETED'
                        THEN
                        CASE
                            WHEN ttds_test_end_time IS NOT NULL AND
                                 DATE(first_value(fttcp_updated_at)
                                      OVER (PARTITION BY fttcp.fttcp_test_delivery_dw_id, fttcp_candidate_dw_id)) <=
                                 DATE(ttds_test_end_time)
                                THEN 'completed_within_due_date'
                            WHEN ttds_test_end_time IS NULL THEN 'NO_DUE_DATE'
                            ELSE 'completed_outside_due_date' END
                    ELSE 'NOT_COMPLETED'
                    END                                                                         AS tt_due_date_adoption_flag
FROM cte_teachers ct
         JOIN alefdw.dim_class dc
              ON dc.class_dw_id = ct.class_dw_id and dc.class_course_status = 'ACTIVE'
         JOIN alefdw.dim_course dcr
              ON fnv_hash(dcr.course_id) = fnv_hash(dc.class_material_id) and course_status = 1
         JOIN bi_alefdw.bi_active_schools_dim_mv sc
              ON fnv_hash(dc.class_school_id) = fnv_hash(sc.school_id)
         JOIN alefdw.dim_grade dg
              ON fnv_hash(dg.grade_id) = fnv_hash(dc.class_grade_id)
         LEFT JOIN dim_teacher_test tt
                   ON ct.teacher_id = tt.teacher_id
                       AND fnv_hash(dc.class_id) = fnv_hash(tt.class_id)
         LEFT JOIN alefdw.fact_teacher_test_candidate_progress fttcp
                   ON fttcp.fttcp_test_delivery_id = tt.ttds_test_delivery_id
                       AND fnv_hash(tt.tt_assigned_student_id) = fnv_hash(fttcp.fttcp_candidate_id)
                       AND trunc(fttcp_created_time) >= sc.academic_year_start_date
                       AND trunc(fttcp_created_time) <= sc.academic_year_end_date
WITH NO SCHEMA BINDING;
