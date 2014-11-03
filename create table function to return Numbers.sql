Use Gazetteer;
GO
IF OBJECT_ID (N'App.fnNumbersList') IS NOT NULL
    DROP FUNCTION App.fnNumbersList;

GO

CREATE FUNCTION App.fnNumbersList (@MaxNumbers INT = 100)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN 
(
        --Return a list of sequential numbers, beginning with zero, and up to "MaxNumbers" long.
        --Likely got this fast solution from Itzik Ben-Gen.
        WITH e1(n) AS
        (
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
            SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
        ), -- 10
        e2(n) AS (SELECT 1 FROM e1 CROSS JOIN e1 AS b), -- 10*10
        e3(n) AS (SELECT 1 FROM e1 CROSS JOIN e2) -- 10*100
        SELECT TOP (@MaxNumbers)  ROW_NUMBER() OVER (ORDER BY n) - 1 as n 
        FROM e3 
        ORDER BY n

);
GO
/*
 SELECT  n FROM App.fnNumbersList(DEFAULT);
*/


 