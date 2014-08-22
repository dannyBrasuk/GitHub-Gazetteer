Use Gazetteer;
GO

CREATE TABLE USGS.[AllName] 
 ( 
	[FEATURE_ID]                                 int NULL,
	[FEATURE_NAME]                         varchar(120) NULL,
	[FEATURE_NAME_OFFICIAL]   	char(1) NULL,
            [CITATION]                                      varchar(4000) NULL,
	[DATE_CREATED]                          date NULL
	)
ON [Secondary]
WITH (DATA_COMPRESSION = NONE)
GO