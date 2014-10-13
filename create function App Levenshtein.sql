Use Gazetteer;
/*

Assumption:  The Levenshtein DLL is has been registered with db server.

*/

GO
IF Object_ID('App.fnLevenshteinPercent') IS NOT NULL
    DROP FUNCTION App.fnLevenshteinPercent;
GO

CREATE Function App.fnLevenshteinPercent(@S1 nvarchar(4000), @S2 nvarchar(4000))
    RETURNS float as EXTERNAL NAME Levenshtein.StoredFunctions.LevenshteinPercent;

GO
IF Object_ID('App.fnLevenshteinDistance') IS NOT NULL
    DROP FUNCTION App.LevenshteinDistance;
GO

CREATE Function App.fnLevenshteinDistance(@S1 nvarchar(4000), @S2 nvarchar(4000))
    RETURNS INT as EXTERNAL NAME Levenshtein.StoredFunctions.LevenshteinDistance;
GO

/*
Testing
*/
SELECT  'Percent' as FunctionType, 'No difference' as 'Input type',  App.fnLevenshteinPercent( 'Gazetteer', 'Gazetteer') As Result
UNION ALL
SELECT  'Distance' as FunctionType, 'No difference' as 'Input type',  App.fnLevenshteinDistance( 'Gazetteer', 'Gazetteer')  As Result;

SELECT  'Percent' as FunctionType, 'No difference' as 'Input type',  App.fnLevenshteinPercent( 'Gazetteer', 'Gazetter') As Result
UNION ALL
SELECT  'Distance' as FunctionType, '1 letter difference' as 'Input type',  App.fnLevenshteinDistance( 'Gazetteer', 'Gazetter') As Result;

SELECT  'Percent' as FunctionType, '2 letter difference' as 'Input type',  App.fnLevenshteinPercent( 'Gazetteer', 'Gazeter') As Result
UNION ALL
SELECT  'Distance' as FunctionType, '2 letter  difference' as 'Input type',  App.fnLevenshteinDistance( 'Gazetteer', 'Gazeter') As Result;

SELECT  'Percent' as FunctionType, 'garbage' as 'Input type',  App.fnLevenshteinPercent( 'Gazetteer', 'garbage') As Result
UNION ALL
SELECT  'Distance' as FunctionType, 'garbage' as 'Input type',  App.fnLevenshteinDistance( 'Gazetteer', 'garbage') As Result;