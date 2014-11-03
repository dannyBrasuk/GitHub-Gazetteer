Use Gazetteer;
GO


IF Type_ID(N'App.FeatureClassList') IS NOT NULL
    DROP TYPE App.FeatureClassList;
GO
CREATE TYPE [App].[FeatureClassList] AS TABLE 
 ( 
FeatureClassList_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,                
FeatureClassID INT NULL
);
