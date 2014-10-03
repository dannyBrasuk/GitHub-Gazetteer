--SELECT *
--FROM [USGS].[AllName]
--Where  FEATURE_ID = '1468985';

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
                        --AND FEATURE_ID = '1468985'
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