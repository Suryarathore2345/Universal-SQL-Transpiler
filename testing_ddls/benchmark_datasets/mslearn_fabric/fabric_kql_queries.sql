-- ============================================================================
-- Fabric Real-Time Intelligence: KQL-style SQL queries
-- Source: MicrosoftLearning/mslearn-fabric (MIT License)
-- Dialect: Microsoft Fabric (T-SQL against KQL database via SQL endpoint)
-- Key constructs: queries against streaming/eventstream data (Bikestream),
--                 CASE for NULL handling, GROUP BY with HAVING
-- ============================================================================

-- ==========================================================
-- Lab 12: Query KQL database data via T-SQL
-- ==========================================================

SELECT TOP 100 * FROM Bikestream;

SELECT TOP 10 Street, No_Bikes
FROM Bikestream;

SELECT TOP 10 Street, No_Empty_Docks AS [Number of Empty Docks]
FROM Bikestream;

SELECT SUM(No_Bikes) AS [Total Number of Bikes]
FROM Bikestream;

SELECT Neighbourhood, SUM(No_Bikes) AS [Total Number of Bikes]
FROM Bikestream
GROUP BY Neighbourhood;

SELECT CASE
         WHEN Neighbourhood IS NULL OR Neighbourhood = '' THEN 'Unidentified'
         ELSE Neighbourhood
       END AS Neighbourhood,
       SUM(No_Bikes) AS [Total Number of Bikes]
FROM Bikestream
GROUP BY CASE
           WHEN Neighbourhood IS NULL OR Neighbourhood = '' THEN 'Unidentified'
           ELSE Neighbourhood
         END
ORDER BY Neighbourhood ASC;

SELECT CASE
         WHEN Neighbourhood IS NULL OR Neighbourhood = '' THEN 'Unidentified'
         ELSE Neighbourhood
       END AS Neighbourhood,
       SUM(No_Bikes) AS [Total Number of Bikes]
FROM Bikestream
GROUP BY CASE
           WHEN Neighbourhood IS NULL OR Neighbourhood = '' THEN 'Unidentified'
           ELSE Neighbourhood
         END
HAVING Neighbourhood = 'Chelsea'
ORDER BY Neighbourhood ASC;
