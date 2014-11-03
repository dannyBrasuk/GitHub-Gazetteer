Use Gazetteer;
GO

/*
Note: the logic here is a little unlikely. target of feature search is likely to be more broad

On the other hand, distance should be a ranking element,

*/
/*
    Match Request
*/

DECLARE 
    @RC AS INT,
    @InputStringList AS App.TokenizerInput ,
    @InputStringTokenXref AS App.TokenizerOutput,
    @FeatureCandidateList  AS App.TokenizerInput,
    @FeatureCandidateTokenXref AS App.TokenizerOutput
;
DECLARE  @FeatureSource AS TABLE ( FeatureID INT, DistanceInMeters INT)
;     

INSERT INTO @InputStringList(SourceKey, SourceString)
    VALUES    (2070794, 'Jen Weld Park')
                      -- , (1119167,'Columbia Heights School (historical)')
                    ;

                    SELECT * FROM @InputStringList ;
--TODO:   Deal with "(historical)"  using some sort of bit flag to say, ignore,  in the token list

INSERT INTO @InputStringTokenXref (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
    SELECT 
        Tokenizer_sfk,
        TokenOrdinal,
        Token,
        App.fnDoubleMetaphoneEncode(Token)
    FROM App.fnTokenizeTableOfStrings(@InputStringList);

                    ---SELECT * FROM @InputStringTokenXref;

/*
    Match Target
*/

INSERT INTO @FeatureSource  (FeatureID, DistanceInMeters)
    EXEC App.Feature_Select_ByNearestNeighbor 
        @latitude  =  45.528666,
        @longitude  = -122.694135,
        @distanceInKilometers  =  5 ,
        @StatePostalCode  = 'OR',
        @NumberOfCandidates  = 50
    ;


--Function call used for simplicty, not efficiency;
--Yes, the double insert is a bit inefficient.  Need to think about that.
INSERT INTO @FeatureCandidateList   (SourceKey, SourceString)
        SELECT 
            FeatureID, 
            App.fnFeatureSearchName_Select_Name_By_FeatureID(FeatureID)
        FROM @FeatureSource ;

          --  SELECT * FROM @FeatureCandidateList;


INSERT INTO @FeatureCandidateTokenXref (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
    SELECT 
        Tokenizer_sfk,
        TokenOrdinal,
        Token,
        App.fnDoubleMetaphoneEncode(Token)
    FROM App.fnTokenizeTableOfStrings(@FeatureCandidateList)  ;

    --SELECT * FROM @FeatureCandidateTokenXref;

/*
CROSS JOIN ON Metaphones
*/

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

ORDER BY 
i.Tokenizer_sfk, i.TokenOrdinal





/*

Pull sample data:

--oops Providence Park and Jen Weld are not the same in this dataset.

select * from appdata.FeatureSearchName
where StatePostalCode='OR'
and FeatureName like '%Providence%'

lat/long for apartment is:  45.528666, -122.694135

EXEC App.Feature_Select_ForDisplay 

select * from App.vFeatureData_SelectForDisplay where FeatureID in (2070794, 1124541)

*/



