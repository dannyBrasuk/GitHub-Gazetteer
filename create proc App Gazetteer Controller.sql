USE Gazetteer;
GO
IF OBJECT_ID('App.GazetteerController') IS NOT NULL
        DROP PROCEDURE [App].[GazetteerController];
GO
CREATE PROCEDURE [App].[GazetteerController]
@Debug BIT = 0

AS

SET NOCOUNT ON;

DECLARE 
    @RC INT = 0
    ,@ErrorMessage VARCHAR(MAX) = ''
    ,@ProcedureName VARCHAR(MAX) = OBJECT_NAME(@@PROCID)
    ,@ParameterSet VARCHAR(MAX) = ''
    ,@StatusMessage VARCHAR(MAX) = ''
    ,@ProcedureLog_fk INT = 0 
;

BEGIN

	BEGIN TRY

                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk OUT, @ParameterSet = @ParameterSet, @StatusMessage = @StatusMessage, @ProcedureName = @ProcedureName;

-                                    SELECT 
--                                            f.*,
--                                            s.DistanceInMeters
--                                    FROM @FeatureSearchCandidates s
--                                    JOIN App.vFeatureData_SelectForDisplay f ON s.FeatureID = f.FeatureID
--                                    ORDER BY s.DistanceInMeters;

               SET @StatusMessage =+ App.fnStatusMessage(@StatusMessage,'Completed.', @RC);
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

