CREATE OR ALTER VIEW ${os_bi_coredw}.military_students_kpi_historical AS
WITH term_details AS (
    SELECT DISTINCT
        academic_year,
        term_start_date,
        term_end_date,
        school_dw_id,
        term_academic_period_order AS term
    FROM ${rs_bi_coredw}.student_progress_core_military_historical_data
),

agg_data AS (
    SELECT
        school_dw_id,
        school_name,
        grade_name,
        academic_year,
        term_start_date,
        term_end_date,
        student_dw_id,
        student_id,
        class_gen_subject,
        class_dw_id,
        lo_dw_id,
        local_date,
        AVG(CONVERT(FLOAT, fle_session_time)) / 60.0 AS fle_session_time,
        AVG(CASE WHEN lo_status = 'Completed' AND fle_score >= 0 THEN CONVERT(DECIMAL(38,4), fle_score) END) AS fle_score,
        COUNT(DISTINCT CASE WHEN lo_status = 'Completed' THEN lo_dw_id END) AS completed_lessons,
        COUNT(DISTINCT lo_dw_id) AS total_lessons
    FROM ${rs_bi_coredw}.student_progress_core_military_historical_data
    GROUP BY
        school_dw_id, school_name, grade_name, academic_year,
        term_start_date, term_end_date,
        student_dw_id, student_id,
        class_gen_subject, class_dw_id, lo_dw_id, local_date
),

core_kpi AS (
    SELECT
        ad.school_dw_id,
        ad.school_name,
        ad.academic_year,
        ad.term_start_date,
        ad.term_end_date,
        ad.grade_name,
        ad.student_dw_id,
        ad.student_id,
        CONVERT(FLOAT, SUM(ad.fle_session_time)) / CONVERT(FLOAT, COUNT(DISTINCT ad.local_date)) AS avg_time_spent,
        CONVERT(FLOAT, SUM(ad.fle_session_time)) AS total_time_spent,
        CONVERT(DECIMAL(38,4), AVG(ad.fle_score)) AS avg_score,
        SUM(ad.fle_score) AS total_score,
        SUM(ad.completed_lessons) AS completed_lessons,
        SUM(ad.total_lessons) AS total_lessons_assigned,
        SUM(cs.class_students) AS class_total_students
    FROM agg_data ad
    JOIN (
        SELECT
            class_dw_id,
            lo_dw_id,
            COUNT(DISTINCT student_dw_id) AS class_students
        FROM ${rs_bi_coredw}.student_progress_core_military_historical_data
        GROUP BY class_dw_id, lo_dw_id
    ) cs
        ON ad.class_dw_id = cs.class_dw_id
       AND ad.lo_dw_id = cs.lo_dw_id
    GROUP BY
        ad.school_dw_id, ad.school_name, ad.academic_year,
        ad.term_start_date, ad.term_end_date,
        ad.grade_name, ad.student_dw_id, ad.student_id
),

login_kpi AS (
    SELECT
        school_dw_id,
        school_id,
        school_name,
        grade_dw_id,
        academic_year,
        academic_year_start_date,
        academic_year_end_date,
        reg_student_dw_id,
        reg_student_id,
        term_start_date,
        term_end_date,
        term,
        grade_name,
        SUM(login) AS total_login,
        SUM(registered_student) AS total_registered
    FROM (
        SELECT
            log.school_dw_id,
            log.school_id,
            UPPER(log.school_name) AS school_name,
            log.grade_dw_id,
            log.academic_year,
            log.academic_year_start_date,
            log.academic_year_end_date,
            log.local_date,
            log.reg_student_dw_id,
            log.reg_student_id,
            t.term,
            t.term_start_date,
            t.term_end_date,
            log.grade_name,
            COUNT(DISTINCT log.log_student_dw_id) AS login,
            COUNT(DISTINCT log.reg_student_dw_id) AS registered_student
        FROM ${rs_bi_coredw}.student_login_military_historical_data log
        INNER JOIN term_details t
            ON log.academic_year = t.academic_year
           AND log.school_dw_id = t.school_dw_id
           AND log.local_date BETWEEN t.term_start_date AND t.term_end_date
        WHERE DATENAME(WEEKDAY, log.local_date) NOT IN ('Saturday', 'Sunday')
        GROUP BY
            log.school_dw_id, log.school_id, log.school_name,
            log.grade_dw_id, log.academic_year,
            log.academic_year_start_date, log.academic_year_end_date,
            log.local_date, log.reg_student_dw_id, log.reg_student_id,
            t.term, t.term_start_date, t.term_end_date, log.grade_name
    ) a
    GROUP BY
        school_dw_id, school_id, school_name, grade_dw_id,
        academic_year, academic_year_start_date, academic_year_end_date,
        reg_student_dw_id, reg_student_id,
        term_start_date, term_end_date, term, grade_name
)

SELECT
    login.school_dw_id,
    login.school_id,
    login.school_name,
    login.grade_name,
    login.term_start_date,
    login.term_end_date,
    CASE
        WHEN CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
             BETWEEN login.term_start_date AND login.term_end_date
        THEN CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
        ELSE login.term_end_date
    END AS term_date_till_date,
    core.student_dw_id,
    core.student_id,
    core.academic_year AS core_ay,
    core.total_lessons_assigned,
    CONVERT(VARCHAR(20), login.term) AS term,
    login.academic_year,
    login.academic_year_start_date,
    login.academic_year_end_date,
    CONVERT(BIGINT, login.total_login) AS total_login,
    login.total_registered,
    login.reg_student_dw_id,
    login.reg_student_id,

    DATEDIFF(
        DAY,
        login.term_start_date,
        CASE
            WHEN CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
                 BETWEEN login.term_start_date AND login.term_end_date
            THEN CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
            ELSE login.term_end_date
        END
    )
    - DATEDIFF(
        WEEK,
        login.term_start_date,
        DATEADD(
            DAY, 1,
            CASE
                WHEN CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
                     BETWEEN login.term_start_date AND login.term_end_date
                THEN CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
                ELSE login.term_end_date
            END
        )
    )
    - DATEDIFF(
        WEEK,
        login.term_start_date,
        CASE
            WHEN CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
                 BETWEEN login.term_start_date AND login.term_end_date
            THEN CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
            ELSE login.term_end_date
        END
    ) + 1 AS term_days,

    CASE WHEN core.academic_year IS NOT NULL THEN core.avg_time_spent END AS avg_time_spent,
    CASE WHEN core.academic_year IS NOT NULL THEN core.total_time_spent END AS total_time_spent,
    CASE WHEN core.academic_year IS NOT NULL THEN core.avg_score END AS avg_score,
    CASE WHEN core.academic_year IS NOT NULL THEN CONVERT(NUMERIC(38,4), core.total_score)  END AS total_score,
    CASE WHEN core.academic_year IS NOT NULL THEN CONVERT(BIGINT, core.completed_lessons) END AS completed_lessons,
    CASE WHEN core.academic_year IS NOT NULL THEN core.class_total_students END AS class_total_students,
    CASE WHEN core.academic_year IS NOT NULL THEN 'core' END AS core_flag
FROM login_kpi login
INNER JOIN core_kpi core
    ON core.term_start_date = login.term_start_date
   AND core.student_dw_id = login.reg_student_dw_id;
