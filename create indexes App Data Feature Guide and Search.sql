USE Gazetteer;
GO

--FeatureID Index On FeatureSearchFilter
IF EXISTS (SELECT object_id FROM sys.indexes i WHERE i.NAME = 'idxFeatureSearchFilter_FeatureID')
        DROP INDEX [idxFeatureSearchFilter_FeatureID] ON  [AppData].[FeatureSearchFilter_FeatureID];

CREATE INDEX idxFeatureSearchFilter_FeatureID
ON  AppData.FeatureSearchFilter (FeatureID)
INCLUDE (FeatureClass_fk, HistoricalFlag, PopulatedPlaceFlag, Latitude, Longitude)
ON IndexFileGroup;

--Feature Class Index On FeatureSearchFilter
IF EXISTS (SELECT object_id FROM sys.indexes i WHERE i.NAME = 'idxFeatureSearchFilter_FeatureClass')
        DROP INDEX [idxFeatureSearchFilter_FeatureClass] ON  [AppData].[FeatureSearchFilter_FeatureClass];

CREATE INDEX idxFeatureSearchFilter_FeatureClass
ON  AppData.FeatureSearchFilter (FeatureClass_fk)
INCLUDE (FeatureID)
ON IndexFileGroup;

--FeatureID Index On FeatureGuide
IF EXISTS (SELECT object_id FROM sys.indexes i WHERE i.NAME = 'idxFeatureGuide_FeatureID')
        DROP INDEX [idxFeatureGuide_FeatureID] ON  [AppData].[FeatureGuide_FeatureID];

CREATE INDEX idxFeatureGuide_FeatureID
ON  AppData.FeatureGuide (FeatureID)
INCLUDE (DisplayOnMapFlag)
ON IndexFileGroup;



--State Index On FeatureSearchFilter
IF EXISTS (SELECT object_id FROM sys.indexes i WHERE i.NAME = 'idxFeatureSearchFilter_StateFeatureID')
        DROP INDEX [idxFeatureSearchFilter] ON  [AppData].[FeatureSearchFilter_StateFeatureID];

CREATE INDEX idxFeatureSearchFilter_StateFeatureID
ON  AppData.FeatureSearchFilter (StateFeatureID)
INCLUDE (CountyFeatureID, FeatureID)
ON IndexFileGroup;