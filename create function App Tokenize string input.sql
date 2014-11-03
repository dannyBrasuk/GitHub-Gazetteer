Use Gazetteer;
GO
IF OBJECT_ID (N'App.fnTokenizeTableOfStrings') IS NOT NULL
    DROP FUNCTION App.fnTokenizeTableOfStrings;
GO
CREATE FUNCTION App.fnTokenizeTableOfStrings (@InputStringsToShred App.TokenizerInput  READONLY)
RETURNS @Tokens  TABLE 
 ( 
Tokenizer_sfk INT NOT NULL,
SourceKey SQL_VARIANT NOT NULL,
TokenOrdinal INT NOT NULL,
Token VARCHAR(128) NOT NULL
)
WITH SCHEMABINDING
AS

        BEGIN

                --Make a table of numbers for the shredder, beginning with zero. Need at least as many of numbers as the length of the longest input string.
                DECLARE @MaxNumbers INT = (SELECT MAX(LEN(SourceString)) FROM @InputStringsToShred);

                DECLARE @Numbers TABLE (SequenceNumber INT NOT NULL);
                INSERT INTO @Numbers (SequenceNumber)
                     SELECT  n FROM App.fnNumbersList(@MaxNumbers);

                INSERT @Tokens (Tokenizer_sfk, SourceKey, TokenOrdinal, Token)
                SELECT 
                               frst.Tokenizer_pk,       
                               frst.SourceKey,
                               frst.RowNumber AS TokenOrdinal,
                                --Since Levenshtein is case sensitive, always upper case the tokens.
                               LEFT(UPPER(SUBSTRING(frst.SourceString, frst.FirstCharacter, (1 + COALESCE(lst.LastCharacter, LEN(frst.SourceString)) - frst.FirstCharacter))),40) AS Token	
                FROM     
                            (
                                SELECT  
                                       tb.Tokenizer_pk,
                                       tb.SourceKey,
                                       tb.SourceString AS SourceString,
                                       n.SequenceNumber + 1 AS FirstCharacter,
                                       ROW_NUMBER() OVER (PARTITION BY tb.Tokenizer_pk ORDER BY n.SequenceNumber) AS RowNumber
                               FROM @InputStringsToShred tb
                               JOIN @Numbers  n ON SUBSTRING(tb.SourceString, n.SequenceNumber, 1) IN (' ', ',' , '/', '-') AND n.SequenceNumber <= LEN(tb.SourceString)
                             ) AS frst

                LEFT JOIN   
                            (
                                  SELECT  
                                            tb2.Tokenizer_pk,
                                            tb2.SourceKey,
                                            n.SequenceNumber - 1 AS LastCharacter,
                                            ROW_NUMBER() OVER (PARTITION BY tb2.Tokenizer_pk ORDER BY n.SequenceNumber ASC) AS RowNumber
                                   FROM @InputStringsToShred tb2
                                   JOIN @Numbers n ON SUBSTRING(tb2.SourceString, n.SequenceNumber, 1) IN (' ', ',' , '/', '-') AND n.SequenceNumber <= LEN(tb2.SourceString)
                            ) AS lst
                            ON frst.RowNumber + 1 = lst.RowNumber  AND frst.Tokenizer_pk = lst.Tokenizer_pk
   
            RETURN

    END
;


GO

/*

Example:

DECLARE  @InputStringsToShred App.TokenizerInput ;

INSERT INTO @InputStringsToShred (SourceKey, SourceString)
    VALUES    (2070794, 'Providence Park'),
                      (1119167,'Columbia Heights School (historical)')
                    ;

SELECT i.SourceKey, o.TokenOrdinal, o.Token 
FROM @InputStringsToShred i
JOIN App.fnTokenizeTableOfStrings(@InputStringsToShred) o ON i.Tokenizer_pk = o.Tokenizer_sfk

*/