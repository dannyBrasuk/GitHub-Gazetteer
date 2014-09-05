use Gazetteer;
GO

CREATE TABLE AppData.FeatureClassFilter
(
FeatureClass_pk INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_FeatureClassFilter PRIMARY KEY, 
FeatureClassName VARCHAR(40)  NOT NULL
)
ON Secondary;

GO
INSERT INTO   AppData.FeatureClassFilter (FeatureClassName)
SELECT FEATURE_CLASS
FROM USGS.NationalFile
GROUP BY FEATURE_CLASS
ORDER BY FEATURE_CLASS; 

GO
SELECT
*
FROM AppData.FeatureClassFilter