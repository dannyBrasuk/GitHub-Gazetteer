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

@MaximumNumberOfMatches INT = 1,

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
                                n.FeatureSearchName_pk, n.FeatureName
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

                ;WITH ValidInputTokens (InputTokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                AS
                (
                    SELECT Tokenizer_sfk, TokenOrdinal, Token, Metaphone2
                    FROM  @InputStringTokenXref
                    WHERE TokenLength > 2
--AND  IgnoreTokenFlag = 0
                )
                ,InputTokenCounts (InputTokenizer_sfk, InputTokenCount)
                AS
                (
                    SELECT
                        InputTokenizer_sfk a,
                        COUNT(*) AS InputTokenCount
                    FROM ValidInputTokens
                    GROUP BY InputTokenizer_sfk
                )
                 ,LevenshteinPercent (FeatureSearchName_pk, LevenshteinPercent)
                AS
                (
                    SELECT 
                        c.Tokenizer_sfk,
                        App.fnLevenshteinPercent(i.Token, c.Token) AS LevenshteinPercent
                    FROM ValidInputTokens  i CROSS APPLY @FeatureSearchCandidateNameTokenXRef c
                    WHERE
                                App.fnLevenshteinPercent(i.Token, c.Token) > 66
                                AND c.TokenLength > 2
-- AND c.IgnoreTokenFlag = 0
                   )
                 ,MetaphoneScores (FeatureSearchName_pk, MetaphoneScore)
                AS
                (
                    SELECT 
                        c.Tokenizer_sfk,
                        App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2) AS  MetaphoneScore
                    FROM ValidInputTokens  i CROSS APPLY @FeatureSearchCandidateNameTokenXRef c
                    WHERE
                                App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2)  > 0
                                AND c.TokenLength > 2
-- AND c.IgnoreTokenFlag = 0
                   )
                , MetaphoneAggregate (FeatureSearchName_pk, MetaphoneIndex, PercentTokensPassed )
                 AS
                 (
                        SELECT  
                                        a.FeatureSearchName_pk, MetaphoneIndex,
                                        CAST(ROUND( CAST(CountOfTokensThatPassed AS FLOAT) / CAST (InputTokenCount AS FLOAT)  , 2) AS INT)  PercentTokensPassed
                        FROM
                        (
                            SELECT 
                                s.FeatureSearchName_pk,
                                COUNT(*)  as CountOfTokensThatPassed,
                                CAST(ROUND(CAST(AVG(s.MetaphoneScore) AS FLOAT) * 100,3) AS INT) AS MetaphoneIndex     --normalize to 100
                            FROM MetaphoneScores s
                            GROUP BY s.FeatureSearchName_pk
                            ) a 
                            CROSS APPLY InputTokenCounts q 
                  )
                 , LevenshteinAggregate  (FeatureSearchName_pk, LevenshteinIndex, PercentTokensPassed)
                 AS
                 (
                        SELECT
                                a.FeatureSearchName_pk, LevenshteinIndex,
                                CAST(ROUND(CAST(CountOfTokensThatPassed AS FLOAT) / CAST (InputTokenCount AS FLOAT)  , 2) AS INT)  PercentTokensPassed
                        FROM
                        (
                            SELECT 
                                s.FeatureSearchName_pk,
                                COUNT(*)  as CountOfTokensThatPassed,
                                AVG(s.LevenshteinPercent) AS LevenshteinIndex       --its a percentage, so sort of equivalent to a normalized value
                            FROM LevenshteinPercent s 
                            GROUP BY s.FeatureSearchName_pk
                          ) a 
                            CROSS APPLY InputTokenCounts q  
                    )
                    ,PossibleMatches  (FeatureSearchName_pk, MatchIndex)
                    AS
                    (
                        SELECT FeatureSearchName_pk, LevenshteinIndex AS MatchIndex
                        FROM LevenshteinAggregate  a
                            UNION 
                        SELECT FeatureSearchName_pk, MetaphoneIndex AS MatchIndex
                        FROM MetaphoneAggregate  a
                    )
                    ,SelectionRank 
                    AS
                    (
                         SELECT
                                p.FeatureSearchName_pk,
                                AVG(MatchIndex) AS MeanMatchIndex,
                                RANK() OVER (ORDER BY AVG(MatchIndex)  DESC) AS RankOrder
                         FROM PossibleMatches p
                         GROUP BY FeatureSearchName_pk
                     )
                     ,TopChoices
                     AS
                     (
                        SELECT
                            n.FeatureID,
                            n.FeatureName,
                            r.RankOrder,
                            ROW_NUMBER() OVER (PARTITION BY n.FeatureID ORDER BY r.RankOrder DESC, FeatureNameSequenceNumber) AS FeatureSequenceSelection
                        FROM SelectionRank r
                        JOIN AppData.FeatureSearchName n ON r.FeatureSearchName_pk = n.FeatureSearchName_pk
                    )
--pass back the feature ID, and Rank. combine with distance to further rank
                    SELECT
                            TOP (@MaximumNumberOfMatches)
                            FeatureID,
                            FeatureName,
                            RankOrder
                    FROM TopChoices
                    WHERE FeatureSequenceSelection = 1
                    ORDER BY RankOrder;

                    SET @RC = @@RowCount;
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

