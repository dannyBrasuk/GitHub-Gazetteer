Use Gazetteer;
GO
IF OBJECT_ID (N'App.fnNearestFeatures') IS NOT NULL
    DROP FUNCTION App.fnNearestFeatures;

GO

CREATE FUNCTION App.fnNearestFeatures 
            (   
                @Latitude float =  0,
                @Longitude float = 0,
                @DistanceInKilometers INT =  0 ,
                @MaximumNumberOfCandidates INT = 0
                )
RETURNS @NearestFeatures  TABLE 
(
    FeatureID INT NOT NULL,
    DistanceInMeters INT NOT NULL
)
--WITH SCHEMABINDING
AS
BEGIN

        DECLARE
                @SearchPoint geography = geography::Point(@Latitude, @Longitude, 4326) ,
                @DistanceInMeters INT = @DistanceInKilometers * 1000;
 
        INSERT INTO   @NearestFeatures (FeatureID, DistanceInMeters)
        SELECT
              TOP (@MaximumNumberOfCandidates)
              b.FeatureID,
              CAST(ROUND(b.geog.STDistance(@searchPoint),0) AS INT) AS DistanceInMeters
          FROM AppData.FeatureSearchFilter b  WITH (INDEX = sidxFeatureSearchFilter_geog)
          WHERE 
              b.geog.STDistance(@searchPoint) < @DistanceInMeters
          ORDER BY b.geog.STDistance(@SearchPoint);
 
          RETURN
END
GO