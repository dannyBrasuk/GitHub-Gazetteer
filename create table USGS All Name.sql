/*
Import the flat file of ALL Names into this "work" table.  From here, it gets massaged and written out elsewhere tables to support the "App."

Names in this table are unofficial, alternative names to those found in the National File.  Often the names
are historical.

September 2014

*/
USE Gazetteer;
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