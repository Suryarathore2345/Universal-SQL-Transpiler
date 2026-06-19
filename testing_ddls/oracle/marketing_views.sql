-- Oracle: Marketing Analytical Views

CREATE OR REPLACE VIEW marketing.vw_campaign_performance AS
SELECT
    c.campaign_id,
    c.campaign_name,
    c.campaign_type,
    c.channel,
    c.start_date,
    c.end_date,
    c.budget,
    c.spent,
    NVL(l.lead_count, 0)           AS total_leads,
    NVL(l.converted_count, 0)      AS converted_leads,
    CASE WHEN NVL(l.lead_count, 0) > 0
         THEN ROUND(l.converted_count * 100 / l.lead_count, 2)
         ELSE 0
    END                             AS conversion_rate_pct,
    CASE WHEN NVL(l.converted_count, 0) > 0
         THEN ROUND(c.spent / l.converted_count, 2)
         ELSE NULL
    END                             AS cost_per_acquisition
FROM marketing.campaigns c
LEFT JOIN (
    SELECT
        campaign_id,
        COUNT(*)                                AS lead_count,
        SUM(CASE WHEN converted_at IS NOT NULL THEN 1 ELSE 0 END) AS converted_count
    FROM marketing.leads
    GROUP BY campaign_id
) l ON c.campaign_id = l.campaign_id;

CREATE OR REPLACE VIEW marketing.vw_lead_funnel AS
SELECT
    l.source,
    l.country_code,
    COUNT(*)                        AS total_leads,
    SUM(CASE WHEN status = 'NEW' THEN 1 ELSE 0 END)          AS new_leads,
    SUM(CASE WHEN status = 'QUALIFIED' THEN 1 ELSE 0 END)     AS qualified_leads,
    SUM(CASE WHEN status = 'PROPOSAL' THEN 1 ELSE 0 END)      AS in_proposal,
    SUM(CASE WHEN converted_at IS NOT NULL THEN 1 ELSE 0 END) AS converted,
    ROUND(
        SUM(CASE WHEN converted_at IS NOT NULL THEN 1 ELSE 0 END) * 100
        / NULLIF(COUNT(*), 0), 2
    )                               AS overall_conversion_pct,
    AVG(
        CASE WHEN converted_at IS NOT NULL
             THEN converted_at - created_at
        END
    )                               AS avg_days_to_convert
FROM marketing.leads l
GROUP BY l.source, l.country_code;

CREATE OR REPLACE VIEW marketing.vw_monthly_lead_trend AS
SELECT
    TRUNC(created_at, 'MM')        AS lead_month,
    source,
    COUNT(*)                        AS leads_created,
    SUM(lead_score)                 AS total_score,
    ROUND(AVG(lead_score), 2)       AS avg_score,
    SUM(CASE WHEN converted_at IS NOT NULL THEN 1 ELSE 0 END) AS conversions
FROM marketing.leads
GROUP BY TRUNC(created_at, 'MM'), source;
