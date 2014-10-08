USE Gazetteer;
GO

IF OBJECT_ID('AppData.WebLog ')  IS NOT NULL 
    DROP TABLE [AppData].[WebLog] ;

CREATE TABLE [AppData].[WebLog]  
( 
	[WebLog_pk]               int IDENTITY(1,1) NOT NULL,
            [CallingIP]                    varchar(15) NOT NULL,
	[CallingFunction]         varchar(128) NOT NULL,
	[Request]                      varchar(max) NULL,
	[Response]                   varchar(max) NULL,
	[ReturnCode]               int NULL,
	[StartTime]      	datetime2 NOT NULL CONSTRAINT [DF_WebLog_StartTime]  DEFAULT (getdate()),
	[EndTime]        	datetime2 NULL,
	CONSTRAINT [PK_WebLog] PRIMARY KEY NONCLUSTERED([WebLog_pk]
)
WITH FILLFACTOR = 80
	)
ON [Secondary]
TEXTIMAGE_ON [Secondary]
WITH (DATA_COMPRESSION = NONE);
GO
