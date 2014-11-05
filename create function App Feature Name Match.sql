Use Gazetteer;
GO
IF OBJECT_ID (N'App.fnFeatureNameSearch') IS NOT NULL
    DROP FUNCTION App.fnFeatureNameSearch;
GO
CREATE FUNCTION App.fnFeatureNameSearch 
            (   
                --Search Target Table  (include feature ID;  limit it to the classes of interest)
                @FeatureSearchCandidates AS App.FeatureKeyList READONLY,

                --Feature Name Search (fuzzy)
                @FeatureNameSearchRequest AS App.NameSearchRequestList READONLY
                )
RETURNS @MatchingFeature  TABLE 
(
  FeatureID INT, MatchStrengthRank INT
)
--WITH SCHEMABINDING
AS
BEGIN

              DECLARE
                    @InputStringList AS App.TokenizerInput ,
                    @InputStringTokenXref AS App.TokenizerOutput
                ;
                INSERT INTO @InputStringList(SourceKey, SourceString)
                    SELECT ISNULL(NameRequestKey,1) , NameRequest FROM @FeatureNameSearchRequest;

                INSERT INTO @InputStringTokenXref (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        Tokenizer_sfk,
                        TokenOrdinal,
                        Token,
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@InputStringList);

--NOW join this to class key words and (historical ) , and ARTICLES  do it here, since its not generic to any tokenizeing opeation

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
 WHERE FeatureNameSequenceNumber=1
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

                ;WITH TokenCounts (Tokenizer_sfk, TokenCount)
                AS
                (
                    SELECT
                        c.Tokenizer_sfk,
                        COUNT(*) AS TokenCount
                    FROM @FeatureSearchCandidateNameTokenXRef c
--WHERE c.IgnoreTokenFlag = 0
                    GROUP BY c.Tokenizer_sfk
                )
                 ,TokenScores
                AS
                (
                    SELECT 
                        c.Tokenizer_sfk,
                            --   c.TokenOrdinal,
                        App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2) AS  MetaphoneScore,
                        App.fnLevenshteinPercent(i.Token, c.Token) AS LevenshteinPercent
                    FROM @InputStringTokenXref  i CROSS APPLY @FeatureSearchCandidateNameTokenXRef c
                    WHERE
                           (
                                App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2)  > 0
                                OR
                                App.fnLevenshteinPercent(i.Token, c.Token) > 66
                            ) AND i.TokenLength > 2 AND c.TokenLength > 2
-- AND i.IgnoreTokenFlag = 0
-- AND c.IgnoreTokenFlag = 0
                   )
                 , PossibleMatches
                 AS
                 (
                    SELECT 
                        s.Tokenizer_sfk,
                        COUNT(*)  as CountOfTokensThatPassed,
                        MAX(q.TokenCount) AS TokenCount,
                        AVG(s.MetaphoneScore) AS MeanMetaphoneScore,
                        AVG(s.LevenshteinPercent) AS MeanLevenshteinPercent
                    FROM TokenScores s JOIN TokenCounts q ON s.Tokenizer_sfk  = q.Tokenizer_sfk
                    GROUP BY s.Tokenizer_sfk
                    )
                    SELECT
                         p.Tokenizer_sfk,
                         n.FeatureID,
                         n.FeatureName,
                         n.FeatureNameSequenceNumber,
                         p.CountOfTokensThatPassed,
                         p.TokenCount ,
                         p.MeanMetaphoneScore,
                         p.MeanLevenshteinPercent
                    FROM PossibleMatches p 
                    JOIN AppData.FeatureSearchName n ON p.Tokenizer_sfk = n.FeatureSearchName_pk
                    
 
   --     INSERT INTO   @MatchingFeature (FeatureID, MatchStrengthRank)
 
 
          RETURN
END
GO