/*
Populate the feature characters search table, to enable queries on feature class, historical entries, standard geographies
like state and county, as well as spatial locations.

For spatial queries, note that WGS 84 is assumed, even though the data actually is delivered as NAD 83. The two are close enough that
I'm assuming away the need to re-project the coordinates.

September 2014

*/

USE Gazetteer;
GO

SET ROWCOUNT 0;

--TRUNCATE TABLE AppData.FeatureSearchFilter ;
GO
INSERT INTO AppData.FeatureSearchFilter 
    (   FeatureID,FeatureClass_fk,StateFeatureID,CountyFeatureID,HistoricalFlag,PopulatedPlaceFlag,
        Longitude,Latitude, Geog)

SELECT  

nf.[FEATURE_ID] as FeatureID,

--filter elements
fc.FeatureClass_pk AS FeatureClass_fk,
sf.FeatureID as StateFeatureID,
cf.FeatureID as CountyFeatureID,

CASE 
     WHEN EXISTS (SELECT FEATURE_ID FROM USGS.HistoricalFeature hf WHERE hf.FEATURE_ID = nf.FEATURE_ID) THEN 1
     ELSE 0
END AS HistoricalFlag,

CASE 
     WHEN EXISTS (SELECT FEATURE_ID FROM USGS.PopulatedPlace pp WHERE pp.FEATURE_ID = nf.FEATURE_ID) THEN 1
     ELSE 0
END AS PopulatedPlaceFlag,

--spatial filter  -- Note - it's NAD 83 (4269)!  But to avoid reprojection, I'm going to pretend WGS 84 (4326). Close enough.
nf.[PRIM_LONG_DEC] AS Longitude,
nf.[PRIM_LAT_DEC] AS Latitude,

geography::Point(nf.[PRIM_LAT_DEC], nf.[PRIM_LONG_DEC] , 4326)

FROM [USGS].[NationalFile] nf
JOIN AppData.FeatureClassFilter fc ON nf.[FEATURE_CLASS]  = fc.FeatureClassName
JOIN AppData.StateFilter sf ON  nf.[STATE_ALPHA] = sf.StatePostalCode
JOIN AppData.CountyFilter cf ON nf.STATE_NUMERIC+nf.COUNTY_NUMERIC = cf.FIPSCode
LEFT OUTER JOIN USGS.FeatureDescriptionHistory fdh ON fdh.FEATURE_ID = nf.FEATURE_ID

WHERE 
--exclude County and State features from Search table
NOT EXISTS (SELECT FEATURE_ID FROM USGS.GovernmentUnit gu WHERE gu.FEATURE_ID=nf.FEATURE_ID)

GO 

SELECT TOP 100 * FROM AppData.FeatureSearchFilter ORDER BY NEWID();
