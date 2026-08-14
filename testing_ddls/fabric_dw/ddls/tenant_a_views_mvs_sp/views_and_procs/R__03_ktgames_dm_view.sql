CREATE OR ALTER  VIEW ${os_bi_coredw}.ktgames_dm_view AS
WITH recommended_games AS (
    SELECT
        ktg_id,
        ktg_created_date,
        school_dw_id,
        school_name,
        school_organisation,
        tenant_name,
        school_city_name,
        school_country_name,
        ktg_student_dw_id,
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
        created_time_rank
    FROM (
        SELECT DISTINCT 
            ktg_id,
            dd.full_date AS ktg_created_date,
            school_dw_id,
            school_name,
            school_organisation,
            dsc.tenant_name,
            school_city_name,
            school_country_name,
            ktg_student_dw_id,
            ktg_type,
            ktg_question_type,
            UPPER(ISNULL(dsu.subject_gen_subject, dc.class_gen_subject)) AS subject,
            grade_k12grade AS grade,
            grade_dw_id,
            section_dw_id,
            ktg_subject_dw_id,
            section_name,
            UPPER(dc.class_title) AS class_title,
            CONCAT(
                CONVERT(VARCHAR(4), YEAR(dsc.academic_year_start_date)),
                '-',
                CONVERT(VARCHAR(4), YEAR(dsc.academic_year_end_date))
            ) AS academic_year,
            dsc.academic_year_start_date,
            dsc.academic_year_end_date,
            CONVERT(
                DATETIME2,
                fkg.ktg_created_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
            ) AS ktg_created_time,
            RANK() OVER (
                PARTITION BY ktg_id
                ORDER BY
                    CONVERT(
                        DATETIME2,
                        fkg.ktg_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
) ASC
            ) AS created_time_rank
        FROM ${rs_coredw}.fact_ktg fkg
        JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc 
            ON dsc.school_dw_id = fkg.ktg_school_dw_id
            AND CONVERT(DATE, ktg_created_time) >= dsc.academic_year_start_date
            AND CONVERT(DATE, ktg_created_time) <= dsc.academic_year_end_date

        LEFT JOIN ${rs_coredw}.dim_subject dsu 
            ON dsu.subject_dw_id = fkg.ktg_subject_dw_id
        JOIN ${rs_coredw}.dim_grade dg 
            ON dg.grade_dw_id = fkg.ktg_grade_dw_id
        LEFT JOIN ${rs_coredw}.dim_section dse 
            ON dse.section_dw_id = fkg.ktg_section_dw_id
        LEFT JOIN ${rs_coredw}.dim_class dc 
            ON dc.class_dw_id = fkg.ktg_class_dw_id
        JOIN ${rs_coredw}.dim_date dd
            ON FORMAT(
                CONVERT(
                    DATETIME2,
                    fkg.ktg_created_time
                        AT TIME ZONE 'UTC'
                        AT TIME ZONE ISNULL(dsc.windows_timezone, 'UTC')
), 'yyyyMMdd'
               ) = dd.date_id
    ) created_ktg_draft
    WHERE created_time_rank = 1
),

ktg_sessions_dataset AS (
    SELECT DISTINCT 
        ktg_session_id,
        ktg_session_school_dw_id,
        ktg_session_dw_created_time,
        ktg_session_academic_year_dw_id,
        ktg_session_event_type,
        ktg_session_question_id,
        ktg_session_score,
        ktg_session_is_start,
        ktg_session_end_time,
        ktg_session_time_spent,
        ktg_session_question_time_allotted,
        dsc.windows_timezone,
        fks.ktg_session_start_time
    FROM ${rs_coredw}.fact_ktg_session fks
    JOIN ${rs_bi_coredw}.bi_active_schools_dim dsc
        ON dsc.school_dw_id = fks.ktg_session_school_dw_id
        AND CONVERT(DATE, ktg_session_start_time) >= dsc.academic_year_start_date
        AND CONVERT(DATE, ktg_session_start_time) <= dsc.academic_year_end_date

),

ktg_session_stats AS (
    SELECT DISTINCT 
        ktg_session_id,
        ROUND(FLOOR(
            AVG(
                CASE
                    WHEN ktg_session_score < 0 THEN 0
                    ELSE ISNULL(ktg_session_score * 100, 0)
                END
            ) * 100) / 100.0, 2
        ) AS average_score,
        SUM(
            CASE
                WHEN fks.ktg_session_time_spent < 0 THEN 0
                ELSE ISNULL(
                    CASE 
                        WHEN ktg_session_time_spent < ktg_session_question_time_allotted 
                        THEN ktg_session_time_spent 
                        ELSE ktg_session_question_time_allotted 
                    END, 0
                )
            END
        ) AS total_time_spent,
        COUNT(DISTINCT ktg_session_question_id) AS ktg_total_questions
    FROM ktg_sessions_dataset fks
    WHERE ktg_session_question_id IS NOT NULL
      AND ktg_session_end_time IS NOT NULL
      AND ktg_session_time_spent IS NOT NULL
    GROUP BY ktg_session_id
),

ktg_session_status AS (
    SELECT DISTINCT 
        ktg_session_id,
        CASE
            WHEN ktg_session_is_start = 0 THEN 'Completed'
            WHEN ktg_session_is_start = 1 THEN 'In-Progress'
        END AS ktg_status
    FROM ktg_sessions_dataset fks
    WHERE ktg_session_end_time IS NOT NULL
      AND ktg_session_time_spent IS NOT NULL
      AND ktg_session_event_type = 1
),

ktg_start_time AS (
    SELECT 
        ktg_session_id,
        ktg_session_start_date,
        ktg_session_start_time,
        ktg_session_end_date,
        ktg_session_end_time
    FROM (
        SELECT DISTINCT 
            ktg_session_id,
            CONVERT(
                DATE,
                fks.ktg_session_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(fks.windows_timezone, 'UTC')
            ) AS ktg_session_start_date,
            CONVERT(
                DATETIME2,
                fks.ktg_session_start_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(fks.windows_timezone, 'UTC')
            ) AS ktg_session_start_time,
            CONVERT(
                DATE,
                fks.ktg_session_end_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(fks.windows_timezone, 'UTC')
            ) AS ktg_session_end_date,
            CONVERT(
                DATETIME2,
                fks.ktg_session_end_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(fks.windows_timezone, 'UTC')
            ) AS ktg_session_end_time,
            RANK() OVER (
                PARTITION BY ktg_session_id
                ORDER BY
                    CONVERT(
                        DATETIME2,
                        fks.ktg_session_dw_created_time
                            AT TIME ZONE 'UTC'
                            AT TIME ZONE ISNULL(fks.windows_timezone, 'UTC')
) ASC
            ) AS ks_rank
        FROM ktg_sessions_dataset fks
    ) ktg_data
    WHERE ks_rank = 1
),

ktg_first_completion_date AS (
    SELECT 
        ktg.ktg_student_dw_id,
        MIN(kst.ktg_session_end_date) AS first_completion_date
    FROM recommended_games ktg
    JOIN ktg_start_time kst 
        ON ktg.ktg_id = kst.ktg_session_id
    GROUP BY ktg.ktg_student_dw_id
)

SELECT DISTINCT 
    ktg_id,
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
    ISNULL(ktgs.ktg_session_id, kt_st.ktg_session_id) AS ktg_session_id,
    ROUND(FLOOR(ktgs.average_score * 100) / 100.0, 2) AS average_score,
    kst.ktg_session_start_date,
    ktgs.total_time_spent,
    ktgs.ktg_total_questions,
    kst.ktg_session_start_time,
    kst.ktg_session_end_date,
    kst.ktg_session_end_time,
    ISNULL(kt_st.ktg_status, 'NotStarted') AS ktg_status,
    kfcd.first_completion_date
FROM recommended_games ktg
LEFT JOIN ktg_session_stats ktgs 
    ON ktg.ktg_id = ktgs.ktg_session_id
LEFT JOIN ktg_session_status kt_st 
    ON ktg.ktg_id = kt_st.ktg_session_id
LEFT JOIN ktg_start_time kst 
    ON ktg.ktg_id = kst.ktg_session_id
LEFT JOIN ktg_first_completion_date kfcd 
    ON kfcd.ktg_student_dw_id = ktg.ktg_student_dw_id;
