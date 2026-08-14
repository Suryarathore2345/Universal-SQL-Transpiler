CREATE OR ALTER VIEW ${os_bi_coredw}.teacher_messages_dm_view AS
WITH responses AS ( 
    SELECT DISTINCT 
        thread.tft_thread_id,
        tmsg.teacher_message_id,
        1 AS response            -- true → 1
    FROM ${rs_coredw}.dim_teacher_feedback_thread thread
    JOIN (
        SELECT DISTINCT 
            tft_thread_id,
            tft_message_id AS teacher_message_id
        FROM ${rs_coredw}.dim_teacher_feedback_thread
        WHERE tft_event_subject = 2
          AND tft_actor_type = 1  -- teacher messages
    ) tmsg
      ON thread.tft_thread_id = tmsg.tft_thread_id
    WHERE thread.tft_event_subject = 2
      AND thread.tft_actor_type = 2  -- guardian messages
),

messages AS (
    SELECT DISTINCT 
        m.tft_created_time AS message_date,
        m.tft_thread_id,
        m.tft_message_id,
        s.tft_student_dw_id,
        s.tft_response_enabled,
        m.tft_actor_type,
        ISNULL(f.tft_is_read, 0) AS tft_is_read,   -- false â†’ 0
        ISNULL(resp.response, 0) AS response       -- false â†’ 0
    FROM ${rs_coredw}.dim_teacher_feedback_thread m
    INNER JOIN (
        SELECT DISTINCT 
            tft_thread_id,
            tft_student_dw_id,
            tft_response_enabled
        FROM ${rs_coredw}.dim_teacher_feedback_thread
        WHERE tft_event_subject = 1
    ) s 
      ON s.tft_thread_id = m.tft_thread_id
    LEFT JOIN (
        SELECT DISTINCT 
            tft_thread_id,
            tft_updated_time,
            tft_is_read
        FROM ${rs_coredw}.dim_teacher_feedback_thread
        WHERE tft_event_subject = 1
    ) f 
      ON m.tft_thread_id = f.tft_thread_id
     AND m.tft_created_time <= f.tft_updated_time
    LEFT JOIN responses resp 
      ON m.tft_message_id = resp.teacher_message_id
    WHERE m.tft_event_subject = 2 
)

SELECT 
    CONVERT(DATE, message_date) AS message_date,
    sch.school_dw_id,
    sch.school_name,
    COUNT(*) AS messages_total,

    ISNULL(SUM(CASE WHEN tft_actor_type = 1 THEN 1 ELSE 0 END), 0) AS messages_teacher,
    ISNULL(SUM(CASE WHEN tft_actor_type = 2 THEN 1 ELSE 0 END), 0) AS messages_guardian,

    ISNULL(SUM(CASE WHEN m.tft_is_read = 1 THEN 1 ELSE 0 END), 0) AS messages_read,
    ISNULL(SUM(CASE WHEN m.tft_response_enabled = 1 THEN 1 ELSE 0 END), 0) AS messages_response_enabled,
    ISNULL(SUM(CASE WHEN m.response = 1 THEN 1 ELSE 0 END), 0) AS messages_responded

FROM messages m
JOIN ${rs_bi_coredw}.bi_student_dim st 
    ON st.student_dw_id = m.tft_student_dw_id
   AND st.student_status = 1
JOIN ${rs_bi_coredw}.bi_active_schools_dim sch 
    ON sch.school_dw_id = st.student_school_dw_id
GROUP BY 
    CONVERT(DATE, message_date),
    sch.school_dw_id,
    sch.school_name;
