USE Gazetteer;
GO

IF OBJECT_ID('App.ErrorMessage_Compose')   IS NOT NULL
    DROP PROCEDURE [App].[ErrorMessage_Compose];
GO

CREATE PROCEDURE [App].[ErrorMessage_Compose]
@ErrorMessage nvarchar(max) = null output,
@PrintMessage bit = 0
AS
set nocount on;
set @ErrorMessage = 
    'Error number: ' + IsNull(convert(nvarchar(10),ERROR_NUMBER()),'n/a') + '. ' +
    'Severity: ' + IsNull(convert(nvarchar(10),ERROR_SEVERITY()),'n/a') + '. ' +
    'State: ' + IsNull(convert(nvarchar(10),ERROR_STATE()),'n/a') + '. '  +
    'Procedure: ' + IsNull(convert(nvarchar(max),ERROR_PROCEDURE()),'n/a') + '. ' +
    'Line: ' + IsNull(convert(nvarchar(10),ERROR_LINE()),'n/a') + '. ' +
    'Message: ' + IsNull(convert(nvarchar(max),ERROR_MESSAGE()),'n/a') + '.';
if @PrintMessage = 1
   select @ErrorMessage as ErrorMessage
Return(0);

GO
