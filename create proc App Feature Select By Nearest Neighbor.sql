USE Gazetteer;
GO
IF OBJECT_ID('App.Feature_Select_ByNearestNeighbor') IS NOT NULL
        DROP PROCEDURE [App].[Feature_Select_ByNearestNeighbor];
GO
CREATE PROCEDURE [App].[Feature_Select_ByNearestNeighbor]

    @latitude float =  0,
    @longitude float = 0,
    @distanceInKilometers INT =  0 ,
    @NumberOfCandidates INT = 0

AS

SET NOCOUNT ON;

DECLARE 
    @RC INT = 0
    ,@ErrorMessage VARCHAR(MAX) = ''
    ,@ProcedureName VARCHAR(MAX) = OBJECT_NAME(@@PROCID)
    ,@ParameterSet VARCHAR(MAX) = ''
    ,@StatusMessage VARCHAR(MAX) = 'In Progress'
    ,@ProcedureLog_fk INT = 0 
;
DECLARE
    @searchPoint geography = geography::Point(@latitude, @longitude, 4326) ,
    @distanceInMeters INT = @distanceInKilometers * 1000
;

BEGIN

	BEGIN TRY

                SET @ParameterSet = 'Search X/Y= ' + CAST(@Longitude AS VARCHAR(20)) + ' / ' + CAST(@Latitude AS VARCHAR(20)) ;
                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk OUT, @ParameterSet = @ParameterSet, @StatusMessage = @StatusMessage, @ProcedureName = @ProcedureName;

                    --Candidates are returned back to the controller proc
                SELECT
                    TOP (@NumberOfCandidates)
                    b.FeatureID,
                    CAST(ROUND(b.geog.STDistance(@searchPoint),0) AS INT) AS DistanceInMeters
                FROM AppData.FeatureSearchFilter b  WITH (INDEX = sidxFeatureSearchFilter_geog)
                WHERE 
                    b.geog.STDistance(@searchPoint) < @distanceInMeters
                ORDER BY b.geog.STDistance(@searchPoint);

                SET @StatusMessage = 'Success';
                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk, @StatusMessage = @StatusMessage, @ReturnCode = @RC;

	END TRY
  
	BEGIN CATCH
 
		SET @RC = -1;
                        SET @StatusMessage = 'Error';
		EXEC [App].[Errors_GetInfo] @Message = @ErrorMessage OUT, @PrintMessage = 0;

		EXEC [App].[ProcedureLog_Merge]
				@ProcedureLog_fk = @ProcedureLog_fk OUT,
				@ProcedureName = @ProcedureName,
				@StatusMessage = @StatusMessage,
				@ErrorMessage = @ErrorMessage,
				@ReturnCode = @RC;

	END CATCH

RETURN(@RC)

END

GO

EXEC [App].[Feature_Select_ByNearestNeighbor]  
    @latitude  =  33.9595924,
    @longitude  = -84.4651686,
    @distanceInKilometers  =  50 ,
    @NumberOfCandidates  = 10

GO 
SELECT TOP 5 * FROM [AppData].[ProcedureLog]  ORDER BY ProcedureLog_pk DESC;
