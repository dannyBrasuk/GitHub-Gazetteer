USE Gazetteer;
GO

IF OBJECT_ID('App.ProcedureLog_Merge')   IS NOT NULL
    DROP PROCEDURE [App].[ProcedureLog_Merge];
GO
CREATE PROCEDURE [App].[ProcedureLog_Merge]

	@ProcedureLog_fk INT = 0 OUTPUT,
	@ProcedureName VARCHAR(MAX) = '',
            @ParameterSet VARCHAR(MAX) = '',
	@StatusMessage VARCHAR(MAX) = '',
	@ErrorMessage VARCHAR(MAX) = '',
	@EndTime DATETIME2 = NULL,
	@ReturnCode INT = NULL

AS

SET NOCOUNT ON;

	DECLARE @ProcedureLog AS TABLE(Action VARCHAR(20), ProcedureLog_pk INT);

	MERGE INTO [AppData].[ProcedureLog] AS TARGET
	USING (VALUES (@ProcedureLog_fk, @ProcedureName, @ParameterSet, @StatusMessage, @ErrorMessage,  @EndTime, @ReturnCode) )
	AS SOURCE (ProcedureLog_pk, ProcedureName, ParameterSet, StatusMessage, ErrorMessage, EndTime, ReturnCode)
	ON TARGET.ProcedureLog_pk = SOURCE.ProcedureLog_pk
	WHEN MATCHED THEN
		UPDATE SET
			StatusMessage = SOURCE.StatusMessage, 
			ErrorMessage = SOURCE.ErrorMessage,
			EndTime = SOURCE.EndTime,
			ReturnCode = SOURCE.ReturnCode
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (ProcedureName, ParameterSet, StatusMessage, ErrorMessage, ReturnCode, EndTime)
			VALUES (SOURCE.ProcedureName, SOURCE.ParameterSet,  SOURCE.StatusMessage, SOURCE.ErrorMessage, SOURCE.ReturnCode, SOURCE.EndTime)
	OUTPUT $Action, Inserted.ProcedureLog_pk INTO @ProcedureLog;

	--Return new key if new record inserted;
	If ISNULL(@ProcedureLog_fk,0) = 0
		SET @ProcedureLog_fk = (SELECT ProcedureLog_pk FROM @ProcedureLog WHERE Action = 'Insert');

 
RETURN (@@Error);
GO
