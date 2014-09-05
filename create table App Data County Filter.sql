USE Gazetteer;
GO
IF OBJECT_ID('AppData.CountyFilter') IS NOT NULL
    DROP TABLE AppData.CountyFilter;
GO
CREATE TABLE AppData.CountyFilter
(
FeatureID INT NOT NULL CONSTRAINT PK_CountyFilter PRIMARY KEY, 
CountyName VARCHAR(40)  NOT NULL,
StatePostalCode VARCHAR(2) NOT NULL,
FullCountyName AS (CountyName + ', ' + StatePostalCode),
FIPSCode VARCHAR(5) NOT NULL,
StateFlag BIT NOT NULL
)
ON Secondary;

GO
INSERT INTO   AppData.CountyFilter (FeatureID, CountyName,  StatePostalCode, FIPSCode, StateFlag)
    SELECT
        FEATURE_ID,  COUNTY_NAME, STATE_ALPHA, STATE_NUMERIC+COUNTY_NUMERIC ,
        CASE WHEN COUNTRY_ALPHA = 'US' THEN 1 ELSE 0 END
    FROM [USGS].[GovernmentUnit]
    WHERE UNIT_TYPE='County'
    ORDER BY Feature_ID;
GO


SELECT
*
FROM AppData.CountyFilter