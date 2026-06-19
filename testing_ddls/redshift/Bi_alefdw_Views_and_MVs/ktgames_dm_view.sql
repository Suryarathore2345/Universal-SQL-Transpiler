CREATE OR REPLACE view bi_alefdw_dev.ktgames_dm_view AS
WITH recommended_games as
         (select *
          from (SELECT DISTINCT ktg_id,
                                dd.full_date                                                                                                AS ktg_created_date,
                                school_dw_id,
                                school_name,
                                school_organisation,
                                dsc.tenant_name,
                                school_city_name,
                                school_country_name,
                                ktg_student_dw_id,
                                ktg_type,
                                ktg_question_type,
                                initcap(COALESCE(dsu.subject_gen_subject, dc.class_gen_subject))                                            AS subject,
                                grade_k12grade                                                                                              as grade,
                                grade_dw_id,
                                section_dw_id,
                                ktg_subject_dw_id,
                                section_name,
                                initcap(dc.class_title)                                                                                     as class_title,
                                date_part(year, dsc.academic_year_start_date) || '-' ||
                                date_part(year, dsc.academic_year_end_date)                                                                 AS academic_year,
                                dsc.academic_year_start_date,
                                dsc.academic_year_end_date,
                                convert_timezone('UTC', dsc.tenant_timezone, fkg.ktg_created_time)                                          as ktg_created_time,
                                rank()
                                over ( partition by ktg_id order by convert_timezone('UTC', dsc.tenant_timezone, fkg.ktg_created_time) asc) as created_time_rank
                FROM alefdw.fact_ktg fkg
                         JOIN bi_alefdw.bi_active_schools_dim_mv dsc ON dsc.school_dw_id = fkg.ktg_school_dw_id
                    AND trunc(ktg_created_time) >= dsc.academic_year_start_date
                    AND trunc(ktg_created_time) <= dsc.academic_year_end_date
                         LEFT JOIN alefdw.dim_subject dsu ON dsu.subject_dw_id = fkg.ktg_subject_dw_id
                         JOIN alefdw.dim_grade dg ON dg.grade_dw_id = fkg.ktg_grade_dw_id
                         LEFT JOIN alefdw.dim_section dse ON dse.section_dw_id = fkg.ktg_section_dw_id
                         LEFT JOIN alefdw.dim_class dc ON dc.class_dw_id = fkg.ktg_class_dw_id
                         JOIN alefdw.dim_date dd
                              ON to_char(convert_timezone('UTC', dsc.tenant_timezone, fkg.ktg_created_time),
                                         'YYYYMMDD') = dd.date_id) created_ktg_draft
          where created_time_rank = 1),

     ktg_sessions_dataset as
         (SELECT distinct ktg_session_id
                        , ktg_session_school_dw_id
                        , ktg_session_dw_created_time
                        , ktg_session_academic_year_dw_id
                        , ktg_session_event_type
                        , ktg_session_question_id
                        , ktg_session_score
                        , ktg_session_is_start
                        , ktg_session_end_time
                        , ktg_session_time_spent
                        , ktg_session_question_time_allotted
                        , dsc.tenant_timezone
                        , fks.ktg_session_start_time
          FROM alefdw.fact_ktg_session fks
                   JOIN bi_alefdw.bi_active_schools_dim_mv dsc
                        ON dsc.school_dw_id = fks.ktg_session_school_dw_id
                            AND trunc(ktg_session_start_time) >= dsc.academic_year_start_date
                            AND trunc(ktg_session_start_time) <= dsc.academic_year_end_date),

     ktg_session_stats AS
         (SELECT DISTINCT ktg_session_id,
                          TRUNC(AVG(
                                        CASE
                                            WHEN ktg_session_score < 0 THEN 0
                                            ELSE nvl(ktg_session_score * 100, 0)
                                            END),
                                2)                                AS average_score,
                          SUM(
                                  CASE
                                      WHEN fks.ktg_session_time_spent < 0 THEN 0
                                      else nvl(LEAST(ktg_session_time_spent, ktg_session_question_time_allotted),
                                               0)
                                      END)                        AS total_time_spent,
                          COUNT(DISTINCT ktg_session_question_id) AS ktg_total_questions
          FROM ktg_sessions_dataset fks
          WHERE ktg_session_question_id IS NOT NULL
            AND ktg_session_end_time IS NOT NULL
            AND ktg_session_time_spent IS NOT NULL
          GROUP BY 1),

     ktg_session_status as
         (SELECT distinct ktg_session_id,
                          CASE
                              WHEN ktg_session_is_start IS FAlSE THEN 'Completed'
                              WHEN ktg_session_is_start is TRUE THEN 'In-Progress'
                              END ktg_status
          FROM ktg_sessions_dataset fks
          WHERE ktg_session_end_time IS NOT NULL
            AND ktg_session_time_spent IS NOT NULL
            AND ktg_session_event_type = 1),

     ktg_start_time as
         (select ktg_session_id,
                 ktg_session_start_date,
                 ktg_session_start_time,
                 ktg_session_end_date,
                 ktg_session_end_time
          from (select distinct ktg_session_id,
                                trunc(convert_timezone('UTC', tenant_timezone, fks.ktg_session_start_time))                               as ktg_session_start_date,
                                convert_timezone('UTC', tenant_timezone, fks.ktg_session_start_time)                                      as ktg_session_start_time,
                                trunc(convert_timezone('UTC', tenant_timezone, fks.ktg_session_end_time))                                 as ktg_session_end_date,
                                convert_timezone('UTC', tenant_timezone, fks.ktg_session_end_time)                                        as ktg_session_end_time,
                                rank() over ( partition by ktg_session_id order by convert_timezone('UTC',
                                                                                                    tenant_timezone,
                                                                                                    fks.ktg_session_dw_created_time) asc) as ks_rank
                FROM ktg_sessions_dataset fks) ktg_data
          where ks_rank = 1),

     ktg_first_completion_date as
         (SELECT ktg.ktg_student_dw_id,
                 MIN(kst.ktg_session_end_date) as first_completion_date
          FROM recommended_games ktg
                   JOIN ktg_start_time kst on md5(ktg.ktg_id) = md5(kst.ktg_session_id)
          GROUP BY 1)

SELECT DISTINCT ktg_id,
                ktg_created_date,
                school_dw_id,
                school_name,
                school_organisation,
                tenant_name,
                school_city_name,
                school_country_name,
                ktg.ktg_student_dw_id,
                ktg_type,
                ktg_question_type,
                subject,
                grade,
                grade_dw_id,
                section_dw_id,
                ktg_subject_dw_id,
                section_name,
                class_title,
                academic_year,
                academic_year_start_date,
                academic_year_end_date,
                ktg_created_time,
                coalesce(ktgs.ktg_session_id, kt_st.ktg_session_id) as ktg_session_id,
                trunc(round(ktgs.average_score, 2), 2)              as average_score,
                kst.ktg_session_start_date,
                ktgs.total_time_spent,
                ktgs.ktg_total_questions,
                kst.ktg_session_start_time,
                kst.ktg_session_end_date,
                kst.ktg_session_end_time,
                nvl(kt_st.ktg_status, 'NotStarted')                 as ktg_status,
                kfcd.first_completion_date
FROM recommended_games ktg
         LEFT JOIN ktg_session_stats ktgs on md5(ktg.ktg_id) = md5(ktgs.ktg_session_id)
         LEFT JOIN ktg_session_status kt_st on md5(ktg.ktg_id) = md5(kt_st.ktg_session_id)
         LEFT JOIN ktg_start_time kst on md5(ktg.ktg_id) = md5(kst.ktg_session_id)
         LEFT JOIN ktg_first_completion_date kfcd ON kfcd.ktg_student_dw_id = ktg.ktg_student_dw_id

WITH NO SCHEMA BINDING;