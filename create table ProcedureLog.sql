USE Gazetteer;
GO

IF OBJECT_ID('AppData.ProcedureLog ')  IS NOT NULL
    DROP TABLE [AppData].[ProcedureLog] ;

CREATE TABLE [AppData].[ProcedureLog]  
( 
	[ProcedureLog_pk]	int IDENTITY(1,1) NOT NULL,
	[ProcedureName]  	varchar(max) NOT NULL,
            [ParameterSet]             varchar(max) NULL,
	[StatusMessage]  	varchar(max) NULL,
	[ErrorMessage]   	varchar(max) NULL,
	[ReturnCode]     	int NULL,
	[StartTime]      	datetime2 NOT NULL CONSTRAINT [DF_ProcedureLog_StartTime]  DEFAULT (getdate()),
	[EndTime]        	datetime2 NULL,
	CONSTRAINT [PK_ProcedureLog] PRIMARY KEY NONCLUSTERED([ProcedureLog_pk])
)
ON [Secondary]
TEXTIMAGE_ON [Secondary]
WITH (DATA_COMPRESSION = NONE);
GO
