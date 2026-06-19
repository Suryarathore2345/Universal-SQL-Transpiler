CREATE OR REPLACE VIEW bi_alefdw_dev.incgames_dm_view AS

WITH cte_teachers AS
    (
        SELECT DISTINCT teacher_dw_id, teacher_id
        FROM alefdw.dim_teacher
        WHERE teacher_status = 1
        AND teacher_active_until IS NULL
    ),

date_dimension AS
    (
        SELECT DISTINCT
            full_date                 AS local_date,
            calendar_week_number      AS week_num,
            uae_week_number           AS uae_week_num,
            calendar_year_week_number AS wy_num,
            uae_year_week_number      AS uae_wy_num
        FROM alefdw.dim_date dt
        WHERE dt.full_date >= Trunc(sysdate) - 365
        AND dt.full_date <= Trunc(sysdate)
    ),
class_total_students AS (
SELECT
                '9999' as curr_subject_name,
                '9999' as curr_grade_name,
                 999 as curr_grade_dw_id,
                999 as curr_subject_dw_id,
                st.class_gen_subject,
                st.school_dw_id,
                st.section_dw_id,
                st.class_dw_id,
                st.class_title,
                st.class_total_students
        FROM bi_alefdw.class_total_students_mv st join bi_alefdw.bi_active_schools_dim_mv ach
              on st.school_dw_id = ach.school_dw_id
          UNION ALL
          SELECT
                st.curr_subject_name,
                st.curr_grade_name,
                st.curr_grade_dw_id,
                st.curr_subject_dw_id,
                st.class_gen_subject,
                st.school_dw_id,
                st.section_dw_id,
                st.class_dw_id,
                st.class_title,
                st.class_total_students
          from bi_alefdw.ip_class_total_students_mv st join bi_alefdw.bi_active_schools_dim_mv ach
              on st.school_dw_id = ach.school_dw_id
)
SELECT DISTINCT
                f.inc_game_id,
                fs.inc_game_session_id,
                dd.local_date,
                FO.inc_game_outcome_player_dw_id             AS student_dw_id,
                fs.inc_game_session_game_id,
                fo.inc_game_outcome_game_id,
                fo.inc_game_outcome_status,
                f.inc_game_is_assessment,
                fo.inc_game_outcome_is_assessment,
                fs.inc_game_session_status,
                CASE fo.inc_game_outcome_status
                    WHEN 1 THEN 'Completed'
                    WHEN 2 THEN 'Cancelled'
                    WHEN 3 THEN 'Left'
                    ELSE 'Undefined'
                    END                                      AS game_outcome_status,
                CASE
                    WHEN f.inc_game_id IS NOT NULL THEN f.inc_game_id
                    ELSE NULL::character varying
                    END                                      AS created,
                CASE
                    WHEN fs.inc_game_session_game_id IS NOT NULL THEN fs.inc_game_session_game_id
                    ELSE NULL::character varying
                    END                                      AS started,
                CASE
                    WHEN fs.inc_game_session_game_id IS NOT NULL THEN convert_timezone('UTC', ds.tenant_timezone, fs.inc_game_session_start_time)
                    ELSE NULL::timestamp without time zone
                    END                                      AS started_date,
                CASE
                    WHEN fo.inc_game_outcome_status = 1
                        THEN convert_timezone('UTC', ds.tenant_timezone, fs.inc_game_session_end_time)
                    END                                      AS completed_date,
                CASE
                    WHEN fo.inc_game_outcome_status = 2
                        THEN trunc(convert_timezone('UTC', ds.tenant_timezone, fs.inc_game_session_end_time))
                    END                                      AS cancelled_date,
                f.inc_game_teacher_dw_id,
                t.teacher_id,
                CASE
                    WHEN f.inc_game_id IS NOT NULL THEN f.inc_game_teacher_dw_id
                    ELSE NULL::bigint
                    END                                      AS teacher_created_inc_game,
                CASE
                    WHEN fs.inc_game_session_game_id IS NOT NULL THEN f.inc_game_teacher_dw_id
                    ELSE NULL::bigint
                    END                                      AS teacher_started_inc_game,
                date_part(year, ds.academic_year_start_date) || '-' ||
                date_part(year, ds.academic_year_end_date) AS academic_year,
                nvl(dc.class_gen_subject,dc.curr_subject_name) as class_gen_subject,
                dg.grade_k12grade,
                ds.school_dw_id,
                ds.school_name,
                dt.tenant_name,
                f.inc_game_num_questions,
                f.inc_game_title,
                f.inc_game_created_time,
                f.inc_game_date_dw_id,
                fs.inc_game_session_num_players,
                fs.inc_game_session_num_joined_players,
                fs.inc_game_session_start_time,
                fs.inc_game_session_time_spent,
                fo.inc_game_outcome_score,
                lo.lo_title,
                f.inc_game_class_dw_id,
                dc.class_dw_id,
                dc.class_title,
                ds.organisation_dw_id,
                ds.school_organisation,
                dc.class_total_students,
                first_value(fs.inc_game_session_end_time) over (partition by inc_game_outcome_player_dw_id order by fs.inc_game_session_end_time asc
                    rows between unbounded preceding and unbounded following) AS player_first_completed_date
FROM alefdw.fact_inc_game f -- capture a game
    INNER JOIN
    (
           select
              inc_game_session_game_id
            , inc_game_session_id
            , inc_game_session_status
            , inc_game_session_start_time
            , inc_game_session_end_time
            , inc_game_session_num_players
            , inc_game_session_num_joined_players
            , inc_game_session_time_spent
            , rank() over (partition by inc_game_session_game_id order by inc_game_session_start_time desc) as latest_session
           from alefdw.fact_inc_game_session
                --where inc_game_session_status NOT IN (1, 4)
          ) fs ON md5(fs.inc_game_session_game_id) = md5(f.inc_game_id)
         LEFT JOIN alefdw.fact_inc_game_outcome fo ON md5(fo.inc_game_outcome_game_id) = md5(f.inc_game_id)
               and fs.inc_game_session_id = fo.inc_game_outcome_session_id-- outcome of the game
         INNER JOIN alefdw.dim_tenant dt ON dt.tenant_dw_id = f.inc_game_tenant_dw_id
         INNER JOIN alefdw.dim_grade dg ON dg.grade_dw_id = f.inc_game_grade_dw_id
                AND dg.grade_status = 1
         INNER JOIN alefdw.dim_learning_objective lo ON lo.lo_dw_id = f.inc_game_lo_dw_id
                AND lo.lo_status = 1
             INNER JOIN bi_alefdw.bi_active_schools_dim_mv ds ON ds.school_dw_id = f.inc_game_school_dw_id
              AND (f.inc_game_created_time >= ds.academic_year_start_date
                         AND f.inc_game_created_time <= ds.academic_year_end_date)
         INNER JOIN class_total_students dc on dc.class_dw_id = f.inc_game_class_dw_id
         INNER JOIN date_dimension dd ON trunc(f.inc_game_created_time) = dd.local_date
         INNER JOIN cte_teachers AS t ON t.teacher_dw_id = f.inc_game_teacher_dw_id
where latest_session = 1

WITH NO SCHEMA BINDING;


