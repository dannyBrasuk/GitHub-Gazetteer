Use Gazetteer;
GO
IF Object_ID(N'App.fnFeatureSearchName_Select_Name_By_FeatureID') IS NOT NULL
    DROP FUNCTION App.fnFeatureSearchName_Select_Name_By_FeatureID;
GO
CREATE FUNCTION App.fnFeatureSearchName_Select_Name_By_FeatureID (@FeatureID  INT)
RETURNS VARCHAR(120)
WITH SCHEMABINDING
AS
    BEGIN
        RETURN (SELECT TOP 1FeatureName
                            FROM AppData.FeatureSearchName
                            WHERE FeatureID = @FeatureID
                        )
    END

GO
--Test
SELECT App.fnFeatureSearchName_Select_Name_By_FeatureID(2474479);