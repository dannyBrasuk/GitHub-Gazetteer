USE Gazetteer;
GO
IF OBJECT_ID('App.FeatureSearchName_Select_FeatureID_ByFeatureName') IS NOT NULL
        DROP PROCEDURE [App].[FeatureSearchName_Select_FeatureID_ByFeatureName];
GO
CREATE PROCEDURE [App].[FeatureSearchName_Select_FeatureID_ByFeatureName]

--Search Target Table  (include feature ID;  limit it to the classes of interest)
@FeatureSearchCandidates AS App.FeatureKeyList,

--Feature Name Search (fuzzy)
@FeatureNameSearchRequest VARCHAR(120) = '',

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
                @InputStringList AS App.TokenizerInput ,
                @InputStringTokenXref AS App.TokenizerOutput;

                INSERT INTO @InputStringList(SourceKey, SourceString)
                    VALUES    (1, @FeatureNameSearchRequest);

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
                    @FeatureCandidateTokenXref AS App.TokenizerOutput
                ;

                --get the feature names to search against
                INSERT INTO @FeatureCandidateList   (SourceKey, SourceString)
                        SELECT 
                            n.FeatureID, n.FeatureName
                        FROM @Candidates c
                        JOIN AppData.FeatureSearchName n ON c.FeatureID = n.FeatureID
                        
                            IF @Debug = 1
                                SELECT * FROM @FeatureCandidateList;



                --tokenize
                --in the tokenizer, flag the tokens ot ignore
                --TODO:   Deal with "(historical)"  using some sort of bit flag to say, ignore,  in the token list

                INSERT INTO @FeatureCandidateTokenXref (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        Tokenizer_sfk,
                        TokenOrdinal,
                        Token,
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@FeatureCandidateList)  ;

                            IF @Debug = 1
                                    SELECT * FROM @FeatureCandidateTokenXref;

                --Metaphone scoring  TODO convert to function, wiht two tables as input
--ranking 
                --1) percent of tokens used in matching (i.e., score of 2 or 3)
                --2) weighted average  metaphone score,  


                SELECT 
                i.Tokenizer_sfk, c.Tokenizer_sfk,
                i.TokenOrdinal, c.TokenOrdinal,
                App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2) as MetaphoneScore

                    --test only
                     ,i.Token, c.Token

                FROM @InputStringTokenXref i, @FeatureCandidateTokenXref c
                WHERE
                        App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2)  IN (2,3)
                        AND i.TokenLength > 2
                        AND c.TokenLength > 2

                -- AND i.IgnoreTokenFlag = 0
                --AND c.IgnoreTokenFlag = 0

                ORDER BY 
                i.Tokenizer_sfk, i.TokenOrdinal;


                   --levanshtein  TODO convert to function with two tables are input

--UNION ALL and RANK (not row number, but Rank)

                   --sum up and draw conclusion

                SET @StatusMessage = 'Success';
                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk, @StatusMessage = @StatusMessage, @ReturnCode = @RC;

	END TRY
  
	BEGIN CATCH
 
		SET @RC = -1;
                        SET @StatusMessage = 'Error';
		EXEC [App].[Errors_GetInfo] @Message = @ErrorMessage OUT, @PrintMessage = 0;

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

