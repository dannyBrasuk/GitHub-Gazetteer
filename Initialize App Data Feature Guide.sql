/*
Recursive calls to build a list of alternative feature names.

Write this into a temp table.

Note if a CTE is used for this dataset, #FeatureIdByAlternativeName, instead of a temp table, it boogs down

*/
USE Gazetteer;
GO

SET ROWCOUNT 0;

CREATE TABLE  #AltNameList  (FeatureID INT NOT NULL, AltermativeNameList VARCHAR(MAX), AltNameList_pk INT IDENTITY(1,1) CONSTRAINT PK_AltNameList PRIMARY KEY);

CREATE TABLE #FeatureIdByAlternativeName (FeatureID INT NOT NULL, FeatureName VARCHAR(MAX) NOT NULL, RankFeatureName INT NOT NULL, MaxRankFeatureName INT NOT NULL, FeatureIdByAlternativeName_pk INT IDENTITY(1,1) CONSTRAINT PK_FeatureIdByAlternativeName PRIMARY KEY);

INSERT INTO #FeatureIdByAlternativeName (FeatureID, FeatureName, RankFeatureName, MaxRankFeatureName) 
    SELECT  
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
--	AND FEATURE_ID in ('335299') --,'1218425','1393413','435', '861530' , '78621', '211001');
--  ORDER BY NEWID();

CREATE INDEX idx#FeatureIdByAlternativeName ON #FeatureIdByAlternativeName (FeatureID) INCLUDE (FeatureName);

--Keep only the 10 newest names; if more than 10, insert "plus N more" names into the list.

DECLARE @MaxListLength INT = 10;

;with Top10
AS
(
	SELECT
		FeatureID, 
		CASE WHEN RankFeatureName=@MaxListLength+1 THEN 'plus ' + CAST( MaxRankFeatureName-@MaxListLength AS VARCHAR(MAX)) + ' more' ELSE FeatureName END as FeatureName,
		RankFeatureName, 
		CASE WHEN MaxRankFeatureName <= @MaxListLength THEN MaxRankFeatureName ELSE @MaxListLength+1 END AS MaxRankFeatureName
	FROM #FeatureIdByAlternativeName
	WHERE RankFeatureName <= (@MaxListLength+1)
)
,recursive_CTE ( FeatureID, RankFeatureName, MaxRankFeatureName, FeatureName ) 
AS
(           
    --anchor query
    SELECT 
                a.FeatureID,  a.RankFeatureName, a.MaxRankFeatureName,  
                CAST(a.FeatureName AS VARCHAR(MAX))
    FROM Top10 a
    WHERE RankFeatureName=1

    UNION ALL

    --recursive member
    SELECT  
            i.FeatureID, i.RankFeatureName, i.MaxRankFeatureName,
            CAST(r.FeatureName + ', ' + i.FeatureName AS VARCHAR(MAX))
    FROM recursive_CTE r 
    JOIN  Top10 i ON r.FeatureID = i.FeatureID
    WHERE i.RankFeatureName=1+r.RankFeatureName
			
 )
INSERT INTO #AltNameList (FeatureID, AltermativeNameList)
    SELECT r.FeatureID, r.FeatureName
    FROM recursive_CTE r
    WHERE r.RankFeatureName=r.MaxRankFeatureName
	OPTION (MAXRECURSION 0);

CREATE INDEX idx#AltNameList ON #AltNameList (FeatureID);


INSERT INTO AppData.FeatureGuide (FeatureID, FeatureName, StateName, AltermativeNameList, FeatureDescription, FeatureHistory, FeatureCitation, DisplayOnMapFlag, ElevationInMeters, DateCreated, DateEdited)
    SELECT  
    nf.[FEATURE_ID] as FeatureID,
    nf.[FEATURE_NAME] as FeatureName,
    sf.StateName,
    ISNULL(anl.AltermativeNameList,'') AS AltermativeNameList,

    ISNULL(fdh.DESCRIPTION,'') FeatureDescription,
    ISNULL(fdh.HISTORY,'') AS FeatureHistory,

    ISNULL((SELECT CITATION FROM USGS.AllName an WHERE an.FEATURE_ID = nf.FEATURE_ID  AND FEATURE_NAME_OFFICIAL = 'Y') ,'') as FeatureCitation,
    CASE WHEN c.FEATURE_ID IS  NULL THEN 0 ELSE 1 END as DisplayOnMapFlag,
    nf.[ELEV_IN_M] AS ElevationInMeters,
    nf.[DATE_CREATED] AS DateCreated, 
    nf.[DATE_EDITED]  AS DateEdited

    FROM [USGS].[NationalFile] nf
    JOIN AppData.FeatureClassFilter fc ON nf.[FEATURE_CLASS]  = fc.FeatureClassName
    JOIN AppData.StateFilter sf ON  nf.[STATE_ALPHA] = sf.StatePostalCode
    JOIN AppData.CountyFilter cf ON nf.STATE_NUMERIC+nf.COUNTY_NUMERIC = cf.FIPSCode
    LEFT OUTER JOIN USGS.FeatureDescriptionHistory fdh ON fdh.FEATURE_ID = nf.FEATURE_ID
    LEFT OUTER JOIN USGS.Concise c  ON c.FEATURE_ID = nf.FEATURE_ID
    LEFT OUTER JOIN #AltNameList anl ON anl.FeatureID = nf.FEATURE_ID

    WHERE 
    --exclude County and State features from guide table
    NOT EXISTS (SELECT FEATURE_ID FROM USGS.GovernmentUnit gu WHERE gu.FEATURE_ID=nf.FEATURE_ID)

    --AND nf.FEATURE_ID IN ( 1408925, 1468985);

	DROP TABLE #AltNameList;
	DROP TABLE #FeatureIdByAlternativeName;
GO 
SET ROWCOUNT 100;

SELECT TOP 100 * FROM AppData.FeatureGuide ORDER BY NEWID();

--SELECT TOP 100 * FROM AppData.FeatureGuide a WHERE a.DisplayOnMapFlag=1 ORDER BY NEWID();
