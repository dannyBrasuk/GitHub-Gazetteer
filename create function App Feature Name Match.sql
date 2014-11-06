Use Gazetteer;
GO
IF OBJECT_ID (N'App.fnFeatureNameSearch') IS NOT NULL
    DROP FUNCTION App.fnFeatureNameSearch;
GO
CREATE FUNCTION App.fnFeatureNameSearch 
            (   
                --Search Target Table  (include feature ID;  limit it to the classes of interest)
                @FeatureSearchCandidates AS App.FeatureKeyList READONLY,

                --Input , Feature Name Search (fuzzy)
                @FeatureNameSearchRequest AS App.NameSearchRequestList READONLY,

                --number of candidates (possible matches) to return
                 @MaximumNumberOfMatches INT = 1

                )
RETURNS @PossibleMatchingFeaturesList  TABLE 
(
    FeatureID INT NOT NULL, 
    MatchRankOrder INT NOT NULL,
    MatchScore INT NOT NULL
)
--WITH SCHEMABINDING
AS
BEGIN
  
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
                
            INSERT INTO @FeatureSearchCandidateNameTokenXRef (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        CAST(SourceKey AS INT),             ----TODO inconsisteny in data types!  
                        TokenOrdinal,
                        Token,
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@FeatureSearchCandidateNames)  ;

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


                /*
                    Scoring. 
                */

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
                    INSERT INTO @PossibleMatchingFeaturesList (FeatureID, MatchScore, MatchRankOrder)
                            SELECT
                                    TOP (@MaximumNumberOfMatches)
                                    FeatureID,
                                    MeanMatchIndex,
                                    RankOrder
                            FROM TopChoices
                            WHERE FeatureSequenceSelection = 1
                            ORDER BY RankOrder;
 
          RETURN
END
GO