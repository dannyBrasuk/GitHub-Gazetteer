USE Gazetteer;
GO
IF OBJECT_ID('App.FeatureSearchName_Select_FeatureID_ByFeatureName') IS NOT NULL
        DROP PROCEDURE [App].[FeatureSearchName_Select_FeatureID_ByFeatureName];
GO
CREATE PROCEDURE [App].[FeatureSearchName_Select_FeatureID_ByFeatureName]

--Search Target Table  (include feature ID;  limit it to the classes of interest)
@FeatureSearchCandidates AS App.FeatureKeyList READONLY,

--Input, Feature Name Search (fuzzy)
@FeatureNameSearchRequest AS App.NameSearchRequestList READONLY,

@MaximumNumberOfMatches INT = 3,

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

                        /*
                    Tokenize the request / input name.  Function assumes a table of strings to shread
                */

                DECLARE
                    @InputStringList AS App.TokenizerInput ,
                    @InputStringTokenXref AS App.TokenizerOutput
                ;
                INSERT INTO @InputStringList(SourceKey, SourceString)
                   SELECT ISNULL(NameRequestKey,1), NameRequest FROM @FeatureNameSearchRequest;

                INSERT INTO @InputStringTokenXref (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        Tokenizer_sfk,
                        TokenOrdinal,
                        Token,
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@InputStringList);

                    IF @Debug = 1
                        SELECT * FROM @InputStringTokenXref ;

                /*
                    For the search universe, get the feature names.
                    Note that because some features have more than one name, the feature ID cannot be the uniqie key.
                */

                DECLARE
                    @FeatureSearchCandidateNames AS App.TokenizerInput,
                    @FeatureSearchCandidateNameTokenXRef AS App.TokenizerOutput
                ;

                INSERT INTO @FeatureSearchCandidateNames   (SourceKey, SourceString)
                        SELECT 
                                n.FeatureSearchName_pk, n.FeatureName
                        FROM @FeatureSearchCandidates c
                        JOIN AppData.FeatureSearchName n ON c.FeatureID = n.FeatureID

                /*
                    Tokenize the feature candidates
                */
                
           IF @Debug = 1
                   SELECT CURRENT_TIMESTAMP AS [Shredding Started On Feature Candidate List]

            INSERT INTO @FeatureSearchCandidateNameTokenXRef (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        CAST(SourceKey AS INT),             ----TODO inconsisteny in data types!  
                        TokenOrdinal,
                        Token,
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@FeatureSearchCandidateNames)  ;

            IF @Debug = 1
                   SELECT CURRENT_TIMESTAMP AS [Shredding Ended On Feature Candidate List];

            IF @Debug = 1
                SELECT * FROM @FeatureSearchCandidateNameTokenXRef ;
/*
    These two steps are unqiue to the Gazetteer data set. There are more efficeint ways to handle them.

    -Key words like "Park" and "Cemetary" only server to distort the match score.
    -Note that I'm ignoring the phrases like Post Office for now.


*/
                UPDATE @FeatureSearchCandidateNameTokenXRef 
                SET IgnoreTokenFlag = 1
                WHERE TOKEN = '(Historical)';

                UPDATE @FeatureSearchCandidateNameTokenXRef 
                SET IgnoreTokenFlag = 1
                FROM AppData.FeatureClassFilter c JOIN @FeatureSearchCandidateNameTokenXRef  f
                ON f.TOKEN = c.FeatureClassName;

                IF @Debug = 1
                        SELECT IgnoreTokenFlag, COUNT(*) AS [Token Count]  
                        FROM @FeatureSearchCandidateNameTokenXRef
                        GROUP BY IgnoreTokenFlag
                /*
                    Scoring. 
                */

            IF @Debug = 1
                   SELECT CURRENT_TIMESTAMP AS [Matching Started];

                ;WITH ValidInputTokens (InputTokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                AS
                (
                    SELECT Tokenizer_sfk, TokenOrdinal, Token, Metaphone2
                    FROM  @InputStringTokenXref
                    WHERE TokenLength > 2
                                    AND  IgnoreTokenFlag = 0
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
                                          AND c.IgnoreTokenFlag = 0
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
                                AND c.IgnoreTokenFlag = 0
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
                     ,TopChoices (FeatureID, MeanMatchIndex, RankOrder, FeatureSequenceSelection)
                     AS
                     (
                        SELECT
                            n.FeatureID,
                            r.MeanMatchIndex,
                            r.RankOrder,
                            ROW_NUMBER() OVER (PARTITION BY n.FeatureID ORDER BY r.RankOrder DESC, FeatureNameSequenceNumber) AS FeatureSequenceSelection
                        FROM SelectionRank r
                        JOIN AppData.FeatureSearchName n ON r.FeatureSearchName_pk = n.FeatureSearchName_pk
                    )
                    SELECT
                                    TOP (@MaximumNumberOfMatches)
                                    FeatureID,
                                    MeanMatchIndex,
                                    RankOrder
                            FROM TopChoices
                            WHERE FeatureSequenceSelection = 1
                            ORDER BY RankOrder;
 
            IF @Debug = 1
                   SELECT CURRENT_TIMESTAMP AS [Matching Ended];

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

