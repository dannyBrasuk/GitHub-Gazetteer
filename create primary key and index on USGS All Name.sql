Use Gazetteer;
GO


/*

Need an index to support the rollup of Alternative Names into a list.

*/


ALTER TABLE USGS.AllName ADD AllName_pk INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_AllName PRIMARY KEY;
GO

CREATE INDEX idxAllName_FeatureID
ON  USGS.AllName (FEATURE_ID)
INCLUDE (FEATURE_NAME_OFFICIAL, FEATURE_NAME, DATE_CREATED)
ON IndexFileGroup;


GO

CREATE INDEX idxAllName_OfficialFlag
ON  USGS.AllName (FEATURE_NAME_OFFICIAL)
INCLUDE (FEATURE_ID, FEATURE_NAME, DATE_CREATED )
ON IndexFileGroup;