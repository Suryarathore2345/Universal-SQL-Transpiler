CREATE OR REPLACE VIEW bi_alefdw_dev.teacher_messages_dm_view AS
WITH responses AS ( -- define responded messages - teacher messages with at least 1 guardian message in the thread
    SELECT DISTINCT thread.tft_thread_id,
                    tmsg.teacher_message_id,
                    true AS response
    FROM alefdw.dim_teacher_feedback_thread thread
             JOIN (SELECT DISTINCT tft_thread_id,
                                   tft_message_id AS teacher_message_id
                   FROM alefdw.dim_teacher_feedback_thread
                   WHERE tft_event_subject = 2
                     AND tft_actor_type = 1 -- get teacher messages in the threads with guardian messages
    ) tmsg
                  ON thread.tft_thread_id = tmsg.tft_thread_id
    WHERE thread.tft_event_subject = 2
      AND thread.tft_actor_type = 2 -- get threads with guardian messages only
),
     messages AS (
--define messages events
SELECT DISTINCT m.tft_created_time        AS message_date,
                m.tft_thread_id,
                m.tft_message_id,
                s.tft_student_dw_id,
                s.tft_response_enabled,
                m.tft_actor_type,
                nvl(f.tft_is_read, false) AS tft_is_read,
                nvl(resp.response, false) AS response
FROM alefdw.dim_teacher_feedback_thread m
         INNER JOIN (SELECT DISTINCT tft_thread_id,
                                     tft_student_dw_id,
                                     tft_response_enabled
                     FROM alefdw.dim_teacher_feedback_thread
                     WHERE tft_event_subject = 1) s -- -- thread attributes to be used in association with school
                    ON s.tft_thread_id = m.tft_thread_id
         LEFT JOIN (SELECT DISTINCT tft_thread_id,
                                    tft_updated_time,
                                    tft_is_read
                    FROM alefdw.dim_teacher_feedback_thread
                    WHERE tft_event_subject = 1) f -- defining read events
                   ON m.tft_thread_id = f.tft_thread_id
                       AND m.tft_created_time <= f.tft_updated_time -- the read should be after the message was sent
         LEFT JOIN responses resp ON m.tft_message_id = resp.teacher_message_id
WHERE m.tft_event_subject = 2 -- messages only
    )
SELECT trunc(message_date)                                           AS message_date,
       sch.school_dw_id,
       sch.school_name,
       count(*)                                                      AS messages_total,
       nvl(sum(CASE WHEN tft_actor_type = 1 THEN 1 END), 0)          AS messages_teacher,
       nvl(sum(CASE WHEN tft_actor_type = 2 THEN 1 END), 0)          AS messages_guardian,
       nvl(sum(CASE m.tft_is_read WHEN true THEN 1 END), 0)          AS messages_read,
       nvl(sum(CASE m.tft_response_enabled WHEN true THEN 1 END), 0) AS messages_response_enabled,
       nvl(sum(CASE m.response WHEN true THEN 1 END), 0)             AS messages_responded
FROM messages m
         JOIN bi_alefdw.bi_student_dim_mv st ON st.student_dw_id = m.tft_student_dw_id
    AND student_status = 1
         JOIN bi_alefdw.bi_active_schools_dim_mv sch ON sch.school_dw_id = st.student_school_dw_id
GROUP BY 1, 2, 3
WITH NO SCHEMA BINDING;