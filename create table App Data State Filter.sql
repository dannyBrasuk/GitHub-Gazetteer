USE Gazetteer;
GO
IF OBJECT_ID('AppData.StateFilter') IS NOT NULL
    DROP TABLE AppData.StateFilter;
GO
CREATE TABLE AppData.StateFilter
(
FeatureID INT NOT NULL CONSTRAINT PK_StateFilter PRIMARY KEY, 
StatePostalCode VARCHAR(40)  NOT NULL,
StateName VARCHAR(40)  NOT NULL,
CountryCode VARCHAR(2) NOT NULL,
CountryName VARCHAR(100)  NOT NULL,
StateFlag BIT NOT NULL
)
ON Secondary;

GO
INSERT INTO   AppData.StateFilter (FeatureID, StatePostalCode, StateName, CountryCode, CountryName, StateFlag)
    SELECT
        FEATURE_ID, STATE_ALPHA, STATE_NAME,  COUNTRY_ALPHA, COUNTRY_NAME,
        CASE WHEN COUNTRY_ALPHA = 'US' THEN 1 ELSE 0 END
    FROM [USGS].[GovernmentUnit]
    WHERE UNIT_TYPE='State'
    ORDER BY Feature_ID;
GO


SELECT
*
FROM AppData.StateFilter