Use Gazetteer;
GO

DECLARE 
    @InputStringsToShred App.TokenizerInput ,
    @SearchTokens App.TokenizerOutput;

INSERT INTO @InputStringsToShred (SourceKey, SourceString)
    VALUES    (2070794, 'Providence Park')
                       , (1119167,'Columbia Heights School (historical)')
                    ;

--INSERT INTO @SearchTokens ()
SELECT * FROM App.fnTokenizeTableOfStrings(@InputStringsToShred)  ;

/*
select * from appdata.FeatureSearchName
where StatePostalCode='OR'
and FeatureName like '%Providence%'
*/


--GO
--IF Object_ID(N'App.TokenizerOutput') IS NOT NULL
--    DROP TYPE App.TokenizerOutput;
--GO
--CREATE TYPE App.TokenizerOutput AS TABLE 
-- ( 
--TokenizerOutput_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,
--Tokenizer_sfk INT NOT NULL,
--TokenOrdinal INT NOT NULL,
--Token VARCHAR(128) NOT NULL
--);
