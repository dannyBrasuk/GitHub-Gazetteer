USE Gazetteer;
GO
IF OBJECT_ID('App.Feature_Select_ForDisplay') IS NOT NULL
        DROP PROCEDURE [App].[Feature_Select_ForDisplay];
GO
CREATE PROCEDURE [App].[Feature_Select_ForDisplay]

    --FeatureID Key table  @Candidates table
    --include selection criteria

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

BEGIN

	BEGIN TRY

DECLARE @Candidates AS TABLE (FeatureID INT, DistanceInMeters INT);

                SET @ParameterSet = 'Feature ID list';
                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk OUT, @ParameterSet = @ParameterSet, @StatusMessage = @StatusMessage, @ProcedureName = @ProcedureName;

                         SELECT 
                                        g.FeatureID ,
                                        g.StateName,
                                        g.FeatureName,
                                        g.FeatureClassName,
                                        g.AltermativeNameList,
                                        g.FeatureDescription,
                                        g.FeatureHistory,
                                        g.FeatureCitation,
                                        g.HistoricalFlag,
                                        g.ElevationInMeters,
                                        g.DisplayOnMapFlag,
                                        g.Latitude,
                                        g.Longitude,
                                        c.DistanceInMeters
                                    FROM @Candidates c
                                    JOIN App.vFeatureData_SelectForDisplay g ON c.FeatureID = g.FeatureID
                                    ORDER BY c.DistanceInMeters;


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

EXEC [App].[Feature_Select_ForDisplay]  -- use defaults;

GO 
SELECT TOP 5 * FROM [AppData].[ProcedureLog]  ORDER BY ProcedureLog_pk DESC;
