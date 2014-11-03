GO
IF Object_ID(N'App.TokenizerOutput') IS NOT NULL
    DROP TYPE App.TokenizerOutput;
GO
CREATE TYPE App.TokenizerOutput AS TABLE 
 ( 
TokenizerOutput_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,
Tokenizer_sfk INT NOT NULL,
TokenOrdinal INT NOT NULL,
Token VARCHAR(128) NOT NULL,
TokenLength AS (LEN(Token)),
Metaphone2 App.DoubleMetaphoneResult NULL,
IgnoreTokenFlag BIT NULL
);