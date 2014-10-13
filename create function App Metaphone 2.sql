Use Gazetteer;
/*

Assumption:  The DoubleMetaphone DLL is has been registered with db server.

*/

CREATE TYPE App.DoubleMetaphoneResult
EXTERNAL NAME DoubleMetaphone.[Phonetic.Tools.DoubleMetaphoneResult];

GO
IF Object_ID('App.fnDoubleMetaphoneEncode') IS NOT NULL
    DROP FUNCTION App.fnDoubleMetaphoneEncode;
GO

CREATE FUNCTION App.fnDoubleMetaphoneEncode (@string NVARCHAR(256))
RETURNS App.DoubleMetaphoneResult
AS
EXTERNAL NAME DoubleMetaphone.[Phonetic.Tools.DoubleMetaphone].DoubleMetaphoneEncode

GO

IF Object_ID('App.fnDoubleMetaphoneCompare ') IS NOT NULL
    DROP FUNCTION App.fnDoubleMetaphoneCompare ;
GO

CREATE FUNCTION App.fnDoubleMetaphoneCompare (@r1 App.DoubleMetaphoneResult, @r2 App.DoubleMetaphoneResult)
RETURNS Integer
AS
EXTERNAL NAME DoubleMetaphone.[Phonetic.Tools.DoubleMetaphone].DoubleMetaphoneCompare
GO

/*
Testing
*/
--DECLARE @Target App.DoubleMetaphoneResult, @Source App.DoubleMetaphoneResult;
--SET @Target = App.fnDoubleMetaphoneEncode('Gazetteer');
--SET @Source = App.fnDoubleMetaphoneEncode('Gazetter');

DECLARE @Target VARCHAR(100), @Source VARCHAR(100);
SET @Target = 'Gazetteer';
SET @Source = 'Gazetteer';
SELECT 'No Difference (strong match)' as MatchType,  @Target as [Target], @Source as [Source], App.fnDoubleMetaphoneCompare(App.fnDoubleMetaphoneEncode(@Target), App.fnDoubleMetaphoneEncode(@Source)) as [Result];

SET @Target = 'Gazetteer';
SET @Source = 'Gazetter';
SELECT '1 char difference (strong match)' as MatchType,  @Target as [Target], @Source as [Source], App.fnDoubleMetaphoneCompare(App.fnDoubleMetaphoneEncode(@Target), App.fnDoubleMetaphoneEncode(@Source)) as [Result];

SET @Target = 'Gazetteer';
SET @Source = 'Gazeters';
SELECT '2 char difference (strong match)' as MatchType,  @Target as [Target], @Source as [Source], App.fnDoubleMetaphoneCompare(App.fnDoubleMetaphoneEncode(@Target), App.fnDoubleMetaphoneEncode(@Source)) as [Result];

SET @Target = 'Gazetteer';
SET @Source = 'garbage';
SELECT 'junk difference (no match)' as MatchType,  @Target as [Target], @Source as [Source], App.fnDoubleMetaphoneCompare(App.fnDoubleMetaphoneEncode(@Target), App.fnDoubleMetaphoneEncode(@Source)) as [Result];

SET @Target = 'Michel';
SET @Source = 'Michael';
SELECT 'partial match (medium)' as MatchType,  @Target as [Target], @Source as [Source], App.fnDoubleMetaphoneCompare(App.fnDoubleMetaphoneEncode(@Target), App.fnDoubleMetaphoneEncode(@Source)) as [Result];
