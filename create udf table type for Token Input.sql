Use Gazetteer;
GO


IF Type_ID(N'App.TokenizerInput') IS NOT NULL
    DROP TYPE App.TokenizerInput;
GO
CREATE TYPE [App].[TokenizerInput] AS TABLE 
 ( 
Tokenizer_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,                
SourceKey SQL_VARIANT NULL UNIQUE,
SourceString  VARCHAR(128)  NOT NULL
);
