CREATE OR ALTER VIEW ${os_bi_coredw}.tutor_ai_dm_view
AS
WITH date_dimension AS (
    SELECT DISTINCT
        full_date                  AS local_date,
        calendar_week_number       AS week_num,
        uae_week_number            AS uae_week_num,
        calendar_year_week_number  AS wy_num,
        uae_year_week_number       AS uae_wy_num,
        calendar_year_month_number AS year_month
    FROM ${rs_coredw}.dim_date dt
    WHERE full_date >= DATEADD(day, -365, CONVERT(date, GETDATE()))
      AND full_date <= DATEADD(day, -1, CONVERT(date, GETDATE()))
),

user_context AS (
    SELECT
        ftuc.ftc_user_dw_id,
        ftuc.ftc_context_id,
        ftuc.ftc_role,
        ftuc.ftc_grade,
        ftuc.ftc_subject,
        ftuc.ftc_tutor_locked,
        ftuc.ftc_language,
        ftuc.ftc_tenant_dw_id,
        ftuc.ftc_grade_dw_id,
        ftuc.ftc_school_dw_id,
        ac.windows_timezone,
        CONVERT(DATETIME, ftuc.ftc_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(ac.windows_timezone, 'UTC')) AS user_created_time,
        ac.school_organisation,
        ac.tenant_name,
        ac.school_name,
        ftuc.ftc_created_time,
        ac.academic_year_start_date,
        ac.academic_year_end_date,
        CONVERT(varchar(4), YEAR(ac.academic_year_start_date)) + '-' +
        CONVERT(varchar(4), YEAR(ac.academic_year_end_date)) AS academic_year
    FROM ${rs_coredw}.fact_tutor_user_context ftuc
    JOIN ${rs_bi_coredw}.bi_active_schools_dim ac
        ON ac.school_dw_id = ftuc.ftc_school_dw_id
       AND CONVERT(date, ftuc.ftc_created_time)
           BETWEEN ac.academic_year_start_date AND ac.academic_year_end_date
    JOIN ${rs_bi_coredw}.bi_student_dim dst
        ON dst.student_dw_id = ftuc.ftc_user_dw_id
       AND dst.student_status = 1

),

tutor_onboarding AS (
    SELECT
        fto_user_dw_id,
        fto_dw_id,
        fto_created_time,
        fto_question_id,
        fto_user_free_text_response,
        fto_onboarding_complete,
        fto_onboarding_skipped
    FROM (
        SELECT
            fto_user_dw_id,
            fto_dw_id,
            fto_created_time,
            fto_question_id,
            fto_user_free_text_response,
            fto_onboarding_complete,
            fto_onboarding_skipped,
            ROW_NUMBER() OVER (
                PARTITION BY fto_user_dw_id, fto_question_id
                ORDER BY
                    CASE
                        WHEN fto_onboarding_complete = CONVERT(BIT, 1)
                          OR fto_onboarding_skipped  = CONVERT(BIT, 1) THEN 1
                        ELSE 2
                    END,
                    fto_created_time DESC
            ) AS row_num
        FROM ${rs_coredw}.fact_tutor_onboarding
        WHERE CONVERT(BIT, 1) = 1
        AND fto_onboarding_skipped IS NOT NULL
          AND fto_onboarding_complete IS NOT NULL
    ) x
    WHERE row_num = 1
),

tutor_session AS (
    SELECT DISTINCT
        fts_session_id,
        fts_context_id,
        fts_user_dw_id,
        fts_activity_status,
        fts_session_state,
        fts_language,
        fts_session_message_limit_reached,
        fts_material_type,
        CASE
            WHEN fts_session_state = 1 THEN MIN(fts_created_time)
            WHEN fts_session_state = 2 THEN MAX(fts_created_time)
            WHEN fts_session_state = 3 THEN MIN(fts_created_time)
        END AS fts_created_time
    FROM ${rs_coredw}.fact_tutor_session
    WHERE fts_session_state IN (1,2,3)
    GROUP BY
        fts_session_id,
        fts_context_id,
        fts_user_dw_id,
        fts_activity_status,
        fts_session_state,
        fts_language,
        fts_session_message_limit_reached,
        fts_material_type
)

SELECT DISTINCT
    dd.local_date,
    uc.ftc_user_dw_id                    AS user_dw_id,
    uc.ftc_context_id                    AS context_id,
    fts.fts_session_id                   AS session_id,
    ftc.ftc_conversation_id              AS conversation_id,
    ftc.ftc_message_id                   AS message_id,
    uc.ftc_role                          AS user_role,
    uc.ftc_grade                         AS grade,
    uc.ftc_subject                       AS subject,
    uc.ftc_tutor_locked                  AS tutor_locked,
    fto.fto_question_id                  AS onboarding_question_id,
    fto.fto_onboarding_complete          AS onboarding_complete,
    fto.fto_onboarding_skipped           AS onboarding_skipped,
    CONVERT(DATETIME, fto.fto_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(uc.windows_timezone, 'UTC')) AS onboarding_date,
    CASE
        WHEN fto.fto_user_free_text_response = CONVERT(BIT, 0)
            THEN 'Predefined Choices'
        ELSE 'Custom Answers'
    END                                  AS onboarding_user_response,
    fts.fts_activity_status              AS learning_activity_status,
    fts.fts_language                     AS session_language,
    fts.fts_session_message_limit_reached AS session_message_limit_reached,
    CASE
        WHEN fts.fts_session_state = 1 THEN 'started'
        WHEN fts.fts_session_state = 2 THEN 'in_progress'
        WHEN fts.fts_session_state = 3 THEN 'finished'
    END                                  AS session_state,
    CONVERT(DATETIME, fts.fts_created_time AT TIME ZONE 'UTC' AT TIME ZONE ISNULL(uc.windows_timezone, 'UTC')) AS session_created_date,
    uc.user_created_time,
    fts.fts_session_message_limit_reached AS is_session_limit_reached,
    fts.fts_material_type                AS course_type,
    CONVERT(
        BIT,
        CASE WHEN ftcqa.ftcqa_bot_question_id IS NOT NULL THEN 1 ELSE 0 END
    ) AS is_challenge_click,
    ftcqa.ftcqa_bot_question_id          AS challenge_question_id,
    ftcqa.ftcqa_user_attempt_id          AS user_challenge_attempt_id,
    ftcqa.ftcqa_bot_question_source      AS question_source,
    CASE
        WHEN ftcqa.ftcqa_bot_question_source <> 'bot'
             AND ftcqa.ftcqa_user_attempt_number IS NOT NULL
             AND ftcqa.ftcqa_user_attempt_source IS NULL
            THEN 'user'
        ELSE ftcqa.ftcqa_user_attempt_source
    END                                  AS attempt_source,
    ftcqa.ftcqa_user_attempt_number      AS user_challenge_attempt_number,
    ftcqa.ftcqa_user_remaining_attempts  AS user_remaining_attempts,
    ftcqa.ftcqa_user_attempt_is_correct  AS user_challenge_answer,
    ftcqa.ftcqa_is_answer_evaluated      AS is_evaluated,
    ftsu.fts_suggestion_clicked          AS is_suggestion_used,
    CONVERT(
        BIT,
        CASE WHEN ftt.ftt_translation_language IS NOT NULL THEN 1 END
    ) AS is_translation_use,
    ftt.ftt_translation_language         AS translation_language,
    CONVERT(
        BIT,
        CASE WHEN ftsi.fts_dw_id IS NOT NULL THEN 1 END
    ) AS is_simplification_used,

    CONVERT(
        BIT,
        CASE WHEN fta.fta_dw_id IS NOT NULL THEN 1 END
    ) AS is_analogous_used,
    uc.ftc_tenant_dw_id                  AS tenant_dw_id,
    uc.ftc_grade_dw_id                   AS grade_dw_id,
    uc.ftc_school_dw_id                  AS school_dw_id,
    uc.school_organisation,
    uc.tenant_name,
    uc.school_name,
    uc.academic_year_start_date,
    uc.academic_year_end_date,
    uc.academic_year
FROM user_context uc
INNER JOIN date_dimension dd
    ON dd.local_date = CONVERT(date, uc.user_created_time)
LEFT JOIN tutor_onboarding fto
    ON fto.fto_user_dw_id = uc.ftc_user_dw_id
       AND fto.fto_onboarding_skipped IS NOT NULL
       AND fto.fto_onboarding_complete IS NOT NULL
LEFT JOIN tutor_session fts
    ON fts.fts_user_dw_id = fto.fto_user_dw_id
   AND fts.fts_context_id = uc.ftc_context_id
LEFT JOIN ${rs_coredw}.fact_tutor_conversation ftc
    ON ftc.ftc_user_dw_id = fts.fts_user_dw_id
   AND ftc.ftc_context_id = fts.fts_context_id
   AND ftc.ftc_session_id = fts.fts_session_id
LEFT JOIN ${rs_coredw}.fact_tutor_challenge_question_answer ftcqa
    ON ftcqa.ftcqa_user_dw_id = uc.ftc_user_dw_id
   AND ftcqa.ftcqa_session_id = fts.fts_session_id
   AND ftcqa.ftcqa_conversation_id = ftc.ftc_conversation_id
   AND ftcqa.ftcqa_message_id = ftc.ftc_message_id
LEFT JOIN ${rs_coredw}.fact_tutor_suggestions ftsu
    ON ftsu.fts_user_dw_id = fts.fts_user_dw_id
   AND ftsu.fts_session_id = fts.fts_session_id
   AND ftsu.fts_conversation_id = ftc.ftc_conversation_id
   AND ftsu.fts_message_id = ftc.ftc_message_id
LEFT JOIN ${rs_coredw}.fact_tutor_analogous fta
    ON fta.fta_user_dw_id = fts.fts_user_dw_id
   AND fta.fta_session_id = fts.fts_session_id
   AND fta.fta_conversation_id = ftc.ftc_conversation_id
   AND fta.fta_message_id = ftc.ftc_message_id
LEFT JOIN ${rs_coredw}.fact_tutor_simplification ftsi
    ON ftsi.fts_user_dw_id = fts.fts_user_dw_id
   AND ftsi.fts_session_id = fts.fts_session_id
   AND ftsi.fts_conversation_id = ftc.ftc_conversation_id
   AND ftsi.fts_message_id = ftc.ftc_message_id
LEFT JOIN ${rs_coredw}.fact_tutor_translation ftt
    ON ftt.ftt_user_dw_id = fts.fts_user_dw_id
   AND ftt.ftt_session_id = fts.fts_session_id
   AND ftt.ftt_conversation_id = ftc.ftc_conversation_id
   AND ftt.ftt_message_id = ftc.ftc_message_id;
