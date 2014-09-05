USE Gazetteer;
GO
CREATE TABLE AppData.FeatureGuide
(
FeatureGuide_pk,
FeatureID,                  --one record per feature ID
FeatureName ,            --Official feature name
StatePostalCode,
AltermativeNameList,  -- append together all unofficial names names, in date order (per [Citiation], on [date] in (if known, not 1899).

--MapLabel
ConciseMapLabel,
FeatureClassName,

FeatureDescription,
FeatureHistory,
FeatureCitation,     -- on Official entry in the All Names table
ElevationInMeters,
DateCreated,
DateEdited,
)
AS Secondary;
GO
/*
Recursive calls to build a list of alternative feature names.


*/

--write this into a temp table

;WITH FeatureIdByAlternativeName (FeatureID, FeatureName, RankFeatureName, MaxRankFeatureName)
AS
(
        SELECT   TOP 500
                            FEATURE_ID,  
                            FEATURE_NAME +
                                    CASE 
                                            WHEN DATE_CREATED = '1899-12-30' THEN ''
                                            ELSE  ' (' + CONVERT(VARCHAR(10),DATE_CREATED,120) +')'
                                     END,
                            ROW_NUMBER() OVER (PARTITION BY FEATURE_ID ORDER BY DATE_CREATED DESC, FEATURE_NAME) AS RankFeatureName,   
                            COUNT(FEATURE_NAME) OVER (PARTITION BY FEATURE_ID) AS MaxRankFeatureName
        FROM USGS.AllName
        WHERE FEATURE_NAME_OFFICIAL= ''    
                         AND FEATURE_ID = '1468985'
)
, recursive_CTE ( FeatureID, RankFeatureName, MaxRankFeatureName, FeatureName ) 
AS
(           
            --anchor query
            SELECT 
                        a.FeatureID,  a.RankFeatureName, a.MaxRankFeatureName,  
                        CAST(a.FeatureName AS VARCHAR(MAX))
            FROM FeatureIdByAlternativeName a
            WHERE RankFeatureName=1

            UNION ALL

            --recursive member
            SELECT  
                    i.FeatureID, i.RankFeatureName, i.MaxRankFeatureName,
                    CAST(r.FeatureName + ', ' + i.FeatureName AS VARCHAR(MAX))
            FROM recursive_CTE r 
            JOIN  FeatureIdByAlternativeName i ON r.FeatureID = i.FeatureID
            WHERE i.RankFeatureName=1+r.RankFeatureName

  )
SELECT r.FeatureID, r.FeatureName
FROM recursive_CTE r
WHERE r.RankFeatureName=r.MaxRankFeatureName;


GO

--join this to the temp table

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

ORDER BY Feature_Name --NEWID()
