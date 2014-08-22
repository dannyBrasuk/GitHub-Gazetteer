Use Gazetteer;
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