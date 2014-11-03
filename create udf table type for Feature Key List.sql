Use Gazetteer;
GO


IF Type_ID(N'App.FeatureKeyList') IS NOT NULL
    DROP TYPE [App].[FeatureKeyList];
GO
CREATE TYPE [App].[FeatureKeyList] AS TABLE 
( 
FeatureKeyList_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,                
FeatureID INT NOT NULL UNIQUE,
DistanceInMeters INT NULL       --optional; used with nearest neighbor searches
);
