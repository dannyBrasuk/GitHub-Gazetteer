/*
Import the flat file of Feature Descriptions into this "work" table.  From here, it gets massaged and written out elsewhere tables to support the "App."

September 2014

*/

USE Gazetteer;
GO

CREATE TABLE USGS.[FeatureDescriptionHistory] 
 ( 
	[FEATURE_ID]                          int NULL,
	[DESCRIPTION]                        varchar(3000) NULL,
            [HISTORY]                                 varchar(3000) NULL
	)
ON [Secondary]
WITH (DATA_COMPRESSION = NONE)
GO