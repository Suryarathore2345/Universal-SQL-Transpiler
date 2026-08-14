CREATE OR ALTER VIEW ${os_bi_coredw}.incgames_dm_view AS

WITH cte_teachers AS (
    SELECT DISTINCT teacher_dw_id, teacher_id
    FROM ${rs_coredw}.dim_teacher
    WHERE teacher_status = 1
      AND teacher_active_until IS NULL
),

date_dimension AS (
    SELECT DISTINCT
        full_date                 AS local_date,
        calendar_week_number      AS week_num,
        uae_week_number           AS uae_week_num,
        calendar_year_week_number AS wy_num,
        uae_year_week_number      AS uae_wy_num
    FROM ${rs_coredw}.dim_date dt
    WHERE dt.full_date >= DATEADD(day, -365, CONVERT(DATE, GETDATE()))
      AND dt.full_date <= CONVERT(DATE, GETDATE())
),

class_total_students AS (
    SELECT
        '9999' AS curr_subject_name,
        '9999' AS curr_grade_name,
        999    AS curr_grade_dw_id,
        999    AS curr_subject_dw_id,
        st.class_gen_subject,
        st.school_dw_id,
        st.section_dw_id,
        st.class_dw_id,
        st.class_title,
        st.class_total_students
    FROM ${rs_bi_coredw}.class_total_students st
    JOIN ${rs_bi_coredw}.bi_active_schools_dim ach
        ON st.school_dw_id = ach.school_dw_id

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
    FROM ${rs_bi_coredw}.ip_class_total_students st
    JOIN ${rs_bi_coredw}.bi_active_schools_dim ach
        ON st.school_dw_id = ach.school_dw_id
)

SELECT DISTINCT
    f.inc_game_id,
    fs.inc_game_session_id,
    dd.local_date,
    fo.inc_game_outcome_player_dw_id AS student_dw_id,
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
    END AS game_outcome_status,

    CASE
        WHEN f.inc_game_id IS NOT NULL THEN CONVERT(VARCHAR(100), f.inc_game_id)
        ELSE NULL
    END AS created,

    CASE
        WHEN fs.inc_game_session_game_id IS NOT NULL THEN CONVERT(VARCHAR(100), fs.inc_game_session_game_id)
        ELSE NULL
    END AS started,

    CASE
        WHEN fs.inc_game_session_game_id IS NOT NULL
        THEN CONVERT(
            DATETIME2,
            fs.inc_game_session_start_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
)
        ELSE NULL
    END AS started_date,

    CASE
        WHEN fo.inc_game_outcome_status = 1
        THEN CONVERT(
            DATETIME2,
            fs.inc_game_session_end_time
                AT TIME ZONE 'UTC'
                AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC')
)
    END AS completed_date,

    CASE
        WHEN fo.inc_game_outcome_status = 2
        THEN CONVERT(
                DATE,
                fs.inc_game_session_end_time
                    AT TIME ZONE 'UTC'
                    AT TIME ZONE ISNULL(ds.windows_timezone, 'UTC'
                    )
)
    END AS cancelled_date,

    f.inc_game_teacher_dw_id,
    t.teacher_id,

    CASE
        WHEN f.inc_game_id IS NOT NULL THEN f.inc_game_teacher_dw_id
        ELSE CONVERT(BIGINT, NULL)
    END AS teacher_created_inc_game,

    CASE
        WHEN fs.inc_game_session_game_id IS NOT NULL THEN f.inc_game_teacher_dw_id
        ELSE CONVERT(BIGINT, NULL)
    END AS teacher_started_inc_game,

    CONVERT(VARCHAR(4), DATEPART(year, ds.academic_year_start_date))
        + '-' +
    CONVERT(VARCHAR(4), DATEPART(year, ds.academic_year_end_date)) AS academic_year,

    ISNULL(dc.class_gen_subject, dc.curr_subject_name) AS class_gen_subject,
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
    FIRST_VALUE(fs.inc_game_session_end_time) OVER (
        PARTITION BY inc_game_outcome_player_dw_id
        ORDER BY
            CASE WHEN fs.inc_game_session_end_time IS NULL THEN 1 ELSE 0 END,
            fs.inc_game_session_end_time ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS player_first_completed_date
FROM ${rs_coredw}.fact_inc_game f
INNER JOIN (
    SELECT
        inc_game_session_game_id,
        inc_game_session_id,
        inc_game_session_status,
        inc_game_session_start_time,
        inc_game_session_end_time,
        inc_game_session_num_players,
        inc_game_session_num_joined_players,
        inc_game_session_time_spent,
        RANK() OVER (
            PARTITION BY inc_game_session_game_id
            ORDER BY
                inc_game_session_start_time DESC
        ) AS latest_session
    FROM ${rs_coredw}.fact_inc_game_session
) fs
    ON fs.inc_game_session_game_id = f.inc_game_id
LEFT JOIN ${rs_coredw}.fact_inc_game_outcome fo
    ON fo.inc_game_outcome_game_id = f.inc_game_id
   AND fs.inc_game_session_id = fo.inc_game_outcome_session_id
INNER JOIN ${rs_coredw}.dim_tenant dt
    ON dt.tenant_dw_id = f.inc_game_tenant_dw_id
INNER JOIN ${rs_coredw}.dim_grade dg
    ON dg.grade_dw_id = f.inc_game_grade_dw_id
   AND dg.grade_status = 1
INNER JOIN ${rs_coredw}.dim_learning_objective lo
    ON lo.lo_dw_id = f.inc_game_lo_dw_id
   AND lo.lo_status = 1
INNER JOIN ${rs_bi_coredw}.bi_active_schools_dim ds
    ON ds.school_dw_id = f.inc_game_school_dw_id
   AND (f.inc_game_created_time >= ds.academic_year_start_date
        AND f.inc_game_created_time <= ds.academic_year_end_date)
INNER JOIN class_total_students dc
    ON dc.class_dw_id = f.inc_game_class_dw_id
INNER JOIN date_dimension dd
    ON f.inc_game_created_time >= CONVERT(DATETIME2, dd.local_date) AND f.inc_game_created_time < DATEADD(DAY, 1, CONVERT(DATETIME2, dd.local_date))  -- OPT-15: SARGable rewrite
INNER JOIN cte_teachers AS t
    ON t.teacher_dw_id = f.inc_game_teacher_dw_id
WHERE fs.latest_session = 1;
