/*
Populate the feature name search table with both official and unofficial names.

Notes:
* Because the table includes both types of names, many feature ids are repeated. 
* The official and unofficial names are sequence numbered within a feature id, with the official name always starting with 1.
* Just in case, include a soft foreign key link on the unofficial names back to the AllNames table.

September 2014

*/
USE Gazetteer;
GO

SET ROWCOUNT 0;

INSERT INTO AppData.FeatureSearchName (FeatureID,FeatureName,StatePostalCode,StateName,OfficialFeatureNameFlag,FeatureNameSequenceNumber,AllNames_fk)

SELECT  

nf.[FEATURE_ID] as FeatureID,
nf.[FEATURE_NAME] as FeatureName,
nf.[STATE_ALPHA] AS StatePostalCode,
sf.StateName,
1 AS  OfficialNameFlag,
1 AS FeatureNameSequenceNumber,      -- if not one, then its an alternaive name
0 AS AllNames_fk

FROM [USGS].[NationalFile] nf
JOIN AppData.StateFilter sf ON  nf.[STATE_ALPHA] = sf.StatePostalCode
JOIN AppData.CountyFilter cf ON nf.STATE_NUMERIC+nf.COUNTY_NUMERIC = cf.FIPSCode

WHERE 
--exclude County and State features from Search table
NOT EXISTS (SELECT FEATURE_ID FROM USGS.GovernmentUnit gu WHERE gu.FEATURE_ID=nf.FEATURE_ID)

UNION ALL

/*
  Unofficial Names
*/

SELECT 

nf.[FEATURE_ID] as FeatureID,
nf.[FEATURE_NAME] as FeatureName,
nf.[STATE_ALPHA] AS StatePostalCode,
sf.StateName,
0 AS  OfficialNameFlag,
 -- if not one, then its an alternaive name
1+ ROW_NUMBER () OVER (PARTITION BY an.FEATURE_ID ORDER BY an.DATE_CREATED DESC, an.FEATURE_NAME) AS FeatureNameSequenceNumber,     
AllName_pk as AllNames_fk

FROM USGS.AllName  an
JOIN [USGS].[NationalFile] nf ON an.Feature_ID = nf.Feature_ID
JOIN AppData.StateFilter sf ON  nf.[STATE_ALPHA] = sf.StatePostalCode
WHERE 
an.FEATURE_NAME_OFFICIAL <> 'Y';

GO 

SELECT TOP 100 * FROM AppData.FeatureSearchName ORDER BY NEWID();




