USE Gazetteer;
GO
IF OBJECT_ID('App.Errors_GetInfo')   IS NOT NULL
    DROP PROCEDURE [App].[Errors_GetInfo];
GO

CREATE PROCEDURE [App].[Errors_GetInfo]

@Message nvarchar(max) = null output,
@PrintMessage bit = 0

AS

BEGIN

        set nocount on;

        set @Message = 
            'Error number: ' + IsNull(convert(nvarchar(10),ERROR_NUMBER()),'n/a') + '. ' +
            'Severity: ' + IsNull(convert(nvarchar(10),ERROR_SEVERITY()),'n/a') + '. ' +
            'State: ' + IsNull(convert(nvarchar(10),ERROR_STATE()),'n/a') + '. '  +
            'Procedure: ' + IsNull(convert(nvarchar(max),ERROR_PROCEDURE()),'n/a') + '. ' +
            'Line: ' + IsNull(convert(nvarchar(10),ERROR_LINE()),'n/a') + '. ' +
            'Message: ' + IsNull(convert(nvarchar(max),ERROR_MESSAGE()),'n/a') + '.';

        if @PrintMessage = 1
            select @Message as ErrorMessage;

END;
/*

use in try/catch blocks

SELECT
    ERROR_NUMBER() AS ErrorNumber
    ,ERROR_SEVERITY() AS ErrorSeverity
    ,ERROR_STATE() AS ErrorState
    ,ERROR_PROCEDURE() AS ErrorProcedure
    ,ERROR_LINE() AS ErrorLine
    ,ERROR_MESSAGE() AS ErrorMessage;


create proc Adhoc.test_trycatch

as

declare @errormessage nvarchar(max);

BEGIN TRY
 	-- object name resolution errros are not caught.
	-- SELECT * FROM NonexistentTable;
    
   select 1/0 as DividebyZero;
END TRY
BEGIN CATCH
	Exec Admin.Errors_GetInfo @message = @errormessage out, @printMessage = 0;
END CATCH

select @errormessage As [My Error Message];
select 'resume with the proc' as [My continuation message];

--exec  Adhoc.test_trycatch;

*/

GO
