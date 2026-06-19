-- Snowflake: SaaS Metrics Analytical Views

CREATE OR REPLACE VIEW saas.vw_mrr_movements AS
SELECT
    DATE_TRUNC('month', s.current_period_start) AS revenue_month,
    SUM(CASE WHEN a.converted_at IS NOT NULL
              AND DATE_TRUNC('month', a.converted_at) = DATE_TRUNC('month', s.current_period_start)
             THEN s.amount ELSE 0 END)           AS new_mrr,
    SUM(CASE WHEN a.churned_at IS NOT NULL
              AND DATE_TRUNC('month', a.churned_at) = DATE_TRUNC('month', s.current_period_start)
             THEN s.amount ELSE 0 END)           AS churned_mrr,
    SUM(s.amount)                                AS total_mrr,
    COUNT(DISTINCT a.account_id)                 AS active_accounts
FROM saas.subscriptions s
JOIN saas.accounts a ON s.account_id = a.account_id
WHERE s.status = 'ACTIVE'
GROUP BY 1;

CREATE OR REPLACE VIEW saas.vw_churn_analysis AS
SELECT
    DATE_TRUNC('month', a.churned_at)      AS churn_month,
    a.plan_name,
    a.company_size,
    COUNT(*)                               AS churned_accounts,
    SUM(a.mrr)                             AS churned_mrr,
    AVG(DATEDIFF('day', a.converted_at, a.churned_at)) AS avg_lifetime_days
FROM saas.accounts a
WHERE a.churned_at IS NOT NULL
GROUP BY 1, 2, 3;

CREATE OR REPLACE VIEW saas.vw_account_health AS
SELECT
    a.account_id,
    a.account_name,
    a.plan_name,
    a.mrr,
    a.status,
    COUNT(DISTINCT u.user_id)              AS total_seats,
    COUNT(DISTINCT CASE WHEN u.last_login_at >= DATEADD('day', -30, CURRENT_TIMESTAMP())
                        THEN u.user_id END) AS active_seats_30d,
    MAX(e.occurred_at)                     AS last_event_at,
    COUNT(DISTINCT t.ticket_id)            AS open_tickets,
    SUM(CASE WHEN i.status = 'OVERDUE' THEN i.amount_due ELSE 0 END) AS overdue_balance
FROM saas.accounts a
LEFT JOIN saas.users u ON a.account_id = u.account_id AND u.deactivated_at IS NULL
LEFT JOIN saas.events e ON a.account_id = e.account_id
    AND e.occurred_at >= DATEADD('day', -30, CURRENT_TIMESTAMP())
LEFT JOIN saas.support_tickets t ON a.account_id = t.account_id AND t.status = 'OPEN'
LEFT JOIN saas.invoices i ON a.account_id = i.account_id
GROUP BY 1, 2, 3, 4, 5;

CREATE OR REPLACE VIEW saas.vw_feature_adoption AS
SELECT
    fu.feature_key,
    DATE_TRUNC('week', fu.usage_date)      AS week_start,
    COUNT(DISTINCT fu.account_id)          AS accounts_using,
    COUNT(DISTINCT fu.user_id)             AS users_using,
    SUM(fu.usage_count)                    AS total_uses,
    AVG(fu.duration_sec)                   AS avg_duration_sec
FROM saas.feature_usage fu
GROUP BY 1, 2;

CREATE OR REPLACE VIEW saas.vw_trial_conversion AS
SELECT
    DATE_TRUNC('month', a.trial_starts_at) AS trial_cohort,
    COUNT(*)                               AS trials_started,
    COUNT(CASE WHEN a.converted_at IS NOT NULL THEN 1 END) AS converted,
    COUNT(CASE WHEN a.churned_at IS NOT NULL
               AND a.converted_at IS NULL THEN 1 END)      AS churned_in_trial,
    ROUND(
        COUNT(CASE WHEN a.converted_at IS NOT NULL THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0), 2
    )                                      AS conversion_rate_pct,
    AVG(DATEDIFF('day', a.trial_starts_at, a.converted_at)) AS avg_days_to_convert
FROM saas.accounts a
WHERE a.trial_starts_at IS NOT NULL
GROUP BY 1;
