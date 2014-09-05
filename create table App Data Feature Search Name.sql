USE Gazetteer;
GO

/*

This table should have more records than Feature IDs, because it has the alternative names.


*/

CREATE TABLE AppData.FeatureSearchName
(
FeatureSearchName_pk,
FeatureID,
FeatureName,
StatePostalCode,
StateName,
OfficialFeatureNameFlag,
FeatureNameSequenceNumber  --order by date)
--need a link back the "all names" table
)
AS Secondary;
GO
SELECT  
TOP 500

nf.[FEATURE_ID] as FeatureID,
nf.[FEATURE_NAME] as FeatureName,
nf.[STATE_ALPHA] AS StatePostalCode,
sf.StateName,

CASE 
     WHEN EXISTS (SELECT FEATURE_ID FROM USGS.AllName an WHERE an.FEATURE_ID = nf.FEATURE_ID  AND FEATURE_NAME_OFFICIAL = 'Y') THEN 1
     ELSE 0
END AS OfficialNameFlag,

--alternative name flag
CASE 
     WHEN EXISTS (SELECT FEATURE_ID FROM USGS.AllName an WHERE an.FEATURE_ID = nf.FEATURE_ID  AND FEATURE_NAME_OFFICIAL = '') THEN 1
     ELSE 0
END AS AltermativeNameFlag,

nf.[FEATURE_NAME]  as MapLabel,

CASE 
     WHEN EXISTS (SELECT FEATURE_ID FROM USGS.Concise c WHERE c.FEATURE_ID = nf.FEATURE_ID) THEN 1
     ELSE 0
END AS ConciseMapFlag,

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

--spatial filter
nf.[PRIM_LAT_DEC] AS Latitude,
nf.[PRIM_LONG_DEC] AS Longitude,


--misc


ISNULL(fdh.DESCRIPTION,'') FeatureDescription,
ISNULL(fdh.HISTORY,'') AS FeatureHistory,

ISNULL((SELECT CITATION FROM USGS.AllName an WHERE an.FEATURE_ID = nf.FEATURE_ID  AND FEATURE_NAME_OFFICIAL = 'Y') ,'') as Citation,
nf.[ELEV_IN_M] AS ElevationInMeters,
nf.[DATE_CREATED] AS DateCreated, 
nf.[DATE_EDITED]  AS DateEdited

FROM [USGS].[NationalFile] nf
JOIN AppData.FeatureClassFilter fc ON nf.[FEATURE_CLASS]  = fc.FeatureClassName
JOIN AppData.StateFilter sf ON  nf.[STATE_ALPHA] = sf.StatePostalCode
JOIN AppData.CountyFilter cf ON nf.STATE_NUMERIC+nf.COUNTY_NUMERIC = cf.FIPSCode
LEFT OUTER JOIN USGS.FeatureDescriptionHistory fdh ON fdh.FEATURE_ID = nf.FEATURE_ID

WHERE 
--exclude County and State features from Search table
NOT EXISTS (SELECT FEATURE_ID FROM USGS.GovernmentUnit gu WHERE gu.FEATURE_ID=nf.FEATURE_ID)

AND COUNTY_NUMERIC='067' and STATE_NUMERIC = '13'
And Feature_Name Like '%Sewell%'

--AND nf.FEATURE_ID = 1408925

ORDER BY nf.[FEATURE_NAME], nf.[STATE_ALPHA];
