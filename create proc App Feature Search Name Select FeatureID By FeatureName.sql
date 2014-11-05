USE Gazetteer;
GO
IF OBJECT_ID('App.FeatureSearchName_Select_FeatureID_ByFeatureName') IS NOT NULL
        DROP PROCEDURE [App].[FeatureSearchName_Select_FeatureID_ByFeatureName];
GO
CREATE PROCEDURE [App].[FeatureSearchName_Select_FeatureID_ByFeatureName]

--Search Target Table  (include feature ID;  limit it to the classes of interest)
@FeatureSearchCandidates AS App.FeatureKeyList READONLY,

--Feature Name Search (fuzzy)
@FeatureNameSearchRequest AS App.NameSearchRequestList READONLY,

@Debug BIT = 0

AS

SET NOCOUNT ON;

DECLARE 
    @RC INT = 0
    ,@ErrorMessage VARCHAR(MAX) = ''
    ,@ProcedureName VARCHAR(MAX) = OBJECT_NAME(@@PROCID)
    ,@ParameterSet VARCHAR(MAX) = ''
    ,@StatusMessage VARCHAR(MAX) = 'In Progress'
    ,@ProcedureLog_fk INT = 0 
;

BEGIN

	BEGIN TRY

                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk OUT, @ParameterSet = @ParameterSet, @StatusMessage = @StatusMessage, @ProcedureName = @ProcedureName;

                --Tokenize the request / input name.  Function assumes a table of strings to shread
                DECLARE
                    @InputStringList AS App.TokenizerInput ,
                    @InputStringTokenXref AS App.TokenizerOutput
                ;
                INSERT INTO @InputStringList(SourceKey, SourceString)
                   SELECT ISNULL(NameRequestKey,1), NameRequest FROM @FeatureNameSearchRequest;

                    IF @Debug  = 1
                            SELECT * FROM @InputStringList ;

                INSERT INTO @InputStringTokenXref (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        Tokenizer_sfk,
                        TokenOrdinal,
                        Token,
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@InputStringList);

--NOW join this to class key words and (historical ) , and ARTICLES  do it here, since its not generic to any tokenizeing opeation

                            IF @Debug  = 1
                                     SELECT * FROM @InputStringTokenXref

                --Tokenize the feature names in the search target
                DECLARE
                    @FeatureSearchCandidateNames AS App.TokenizerInput,
                    @FeatureSearchCandidateNameTokenXRef AS App.TokenizerOutput
                ;

                --get the feature names to search against
--Note:  cannot be feature ID since its one to many
                INSERT INTO @FeatureSearchCandidateNames   (SourceKey, SourceString)
                        SELECT 
                            DISTINCT n.FeatureSearchName_pk, n.FeatureName
                        FROM @FeatureSearchCandidates c
                        JOIN AppData.FeatureSearchName n ON c.FeatureID = n.FeatureID
 --WHERE FeatureNameSequenceNumber=1
                            IF @Debug = 1
                                SELECT * FROM @FeatureSearchCandidateNames;



                --tokenize
                --in the tokenizer, flag the tokens ot ignore
                --TODO:   Deal with "(historical)"  using some sort of bit flag to say, ignore,  in the token list

                INSERT INTO @FeatureSearchCandidateNameTokenXRef (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        CAST(SourceKey AS INT),
--inconsisteny in data types!
                        TokenOrdinal,
                        Token,
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@FeatureSearchCandidateNames)  ;

                            IF @Debug = 1
                                    SELECT * FROM @FeatureSearchCandidateNameTokenXRef;

                --Metaphone scoring  TODO convert to function, wiht two tables as input
--ranking 
                --1) percent of tokens used in matching (i.e., score of 2 or 3)
                --2) weighted average  metaphone score,  

                ;WITH ValidTokens (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                AS
                (
                    SELECT Tokenizer_sfk, TokenOrdinal, Token, Metaphone2
                    FROM  @InputStringTokenXref
                    WHERE TokenLength > 2
--AND  IgnoreTokenFlag = 0
                )
                ,TokenCounts (Tokenizer_sfk, TokenCount)
                AS
                (
                    SELECT
                        Tokenizer_sfk,
                        COUNT(*) AS TokenCount
                    FROM ValidTokens
                    GROUP BY Tokenizer_sfk
                )
                 ,LevenshteinPercent (Tokenizer_sfk, TokenOrdinal, LevenshteinPercent)
                AS
                (
                    SELECT 
                        c.Tokenizer_sfk,
                        i.TokenOrdinal,
                        App.fnLevenshteinPercent(i.Token, c.Token) AS LevenshteinPercent
                    FROM ValidTokens  i CROSS APPLY @FeatureSearchCandidateNameTokenXRef c
                    WHERE
                                App.fnLevenshteinPercent(i.Token, c.Token) > 66
                                AND c.TokenLength > 2
-- AND c.IgnoreTokenFlag = 0
                   )
                 ,MetaphoneScores (Tokenizer_sfk, TokenOrdinal, MetaphoneScore)
                AS
                (
                    SELECT 
                        c.Tokenizer_sfk,
                         i.TokenOrdinal,
                        App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2) AS  MetaphoneScore
                    FROM ValidTokens  i CROSS APPLY @FeatureSearchCandidateNameTokenXRef c
                    WHERE
                                App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2)  > 0
                                AND c.TokenLength > 2
-- AND c.IgnoreTokenFlag = 0
                   )
                , MetaphoneAggregate (Tokenizer_sfk, CountOfTokensThatPassed, MeanMetaphoneScore, PercentTokensScored )
                 AS
                 (
                        SELECT  
                                        a.Tokenizer_sfk, CountOfTokensThatPassed, MeanMetaphoneScore,
                                        CAST(ROUND( CAST(CountOfTokensThatPassed AS FLOAT) / CAST (TokenCount AS FLOAT)  , 2) AS INT)  PercentTokensScored
                        FROM
                        (
                            SELECT 
                                s.Tokenizer_sfk,
                                COUNT(*)  as CountOfTokensThatPassed,
                                AVG(s.MetaphoneScore) AS MeanMetaphoneScore
                            FROM MetaphoneScores s
                            GROUP BY s.Tokenizer_sfk
                            ) a 
                            JOIN TokenCounts q ON a.Tokenizer_sfk  = q.Tokenizer_sfk
                  )
                 , LevenshteinAggregate  (Tokenizer_sfk, CountOfTokensThatPassed, MeanLevenshteinPercent, PercentTokensScored)
                 AS
                 (
                        SELECT
                                a.Tokenizer_sfk, CountOfTokensThatPassed, MeanLevenshteinPercent,
                                CAST(ROUND(CAST(CountOfTokensThatPassed AS FLOAT) / CAST (TokenCount AS FLOAT)  , 2) AS INT)  PercentTokensScored
                        FROM
                        (
                            SELECT 
                                s.Tokenizer_sfk,
                                COUNT(*)  as CountOfTokensThatPassed,
                                AVG(s.LevenshteinPercent) AS MeanLevenshteinPercent
                            FROM LevenshteinPercent s 
                            GROUP BY s.Tokenizer_sfk
                          ) a 
                            JOIN TokenCounts q ON a.Tokenizer_sfk  = q.Tokenizer_sfk
                    )
                    ,PossibleMatches
                    AS
                    (
                        SELECT   'Lev' AS [Method], Tokenizer_sfk, CountOfTokensThatPassed, MeanLevenshteinPercent as Score, PercentTokensScored,
                                             RANK() OVER (ORDER BY PercentTokensScored DESC, MeanLevenshteinPercent DESC) AS RankOrder
                        FROM LevenshteinAggregate  a
                            UNION 
                        SELECT  'Meta' AS [Method], Tokenizer_sfk, CountOfTokensThatPassed, MeanMetaphoneScore as Score, PercentTokensScored,
                                        RANK() OVER (ORDER BY PercentTokensScored DESC, MeanMetaphoneScore DESC) AS RankOrder
                        FROM MetaphoneAggregate  a
                    )
                    SELECT
                    p.Tokenizer_sfk,
                    n.FeatureID,
                    n.FeatureName,
                    n.FeatureNameSequenceNumber,
                    p.CountOfTokensThatPassed,
                    p.PercentTokensScored,
                    p.Score,
                    p.RankOrder,
                    p.[Method]
                    FROM PossibleMatches p 
                    JOIN AppData.FeatureSearchName n ON p.Tokenizer_sfk = n.FeatureSearchName_pk
                    


                SET @StatusMessage = 'Success';
                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk, @StatusMessage = @StatusMessage, @ReturnCode = @RC;

	END TRY
  
	BEGIN CATCH
 
		SET @RC = -1;
		EXEC [App].[Errors_GetInfo] @Message = @ErrorMessage OUT, @PrintMessage = 1;

		EXEC [App].[ProcedureLog_Merge]
				@ProcedureLog_fk = @ProcedureLog_fk OUT,
				@ProcedureName = @ProcedureName,
				@StatusMessage = @StatusMessage,
				@ErrorMessage = @ErrorMessage,
				@ReturnCode = @RC;

	END CATCH

RETURN(@RC)

END

GO

