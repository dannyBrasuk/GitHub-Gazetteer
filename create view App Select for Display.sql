USE Gazetteer;
GO
IF OBJECT_ID('App.vFeatureData_SelectForDisplay') IS NOT NULL
    DROP VIEW App.vFeatureData_SelectForDisplay;
GO
CREATE VIEW App.vFeatureData_SelectForDisplay
WITH SCHEMABINDING
AS
SELECT
g.FeatureID ,
g.StateName,
g.FeatureName,
c.FeatureClassName,
g.AltermativeNameList,
g.FeatureDescription,
g.FeatureHistory,
g.FeatureCitation,
f.HistoricalFlag,
g.ElevationInMeters,
g.DisplayOnMapFlag,
f.Latitude,
f.Longitude
FROM AppData.FeatureGuide g
JOIN AppData.FeatureSearchFilter f ON g.FeatureID = f.FeatureID
JOIN AppData.FeatureClassFilter c ON c.FeatureClass_pk = f.FeatureClass_fk

--WHERE g.FeatureID = 322726
