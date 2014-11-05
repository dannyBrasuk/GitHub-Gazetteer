USE Gazetteer
GO
IF OBJECT_ID('App.fnStatusMessage') IS NOT NULL
    DROP FUNCTION App.fnStatusMessage;
GO
CREATE FUNCTION App.fnStatusMessage
(
    @StatusMessage VARCHAR(MAX),
    @Message VARCHAR(MAX),
    @QuantityRecordsAffected INT = NULL
)    
RETURNS VARCHAR(MAX)
WITH SCHEMABINDING
AS
BEGIN

DECLARE @TextToAppend VARCHAR(MAX) =
        CASE WHEN @Message IS NOT NULL THEN @Message + '  '  ELSE '' END
        + CASE WHEN @QuantityRecordsAffected IS NOT NULL THEN CAST (@QuantityRecordsAffected as VARCHAR(20)) + ' records affected. '   ELSE '' END
        + ' ('+ CONVERT(VARCHAR(20),CURRENT_TIMESTAMP,120) + '). '
; 
SET @StatusMessage = ISNULL(@StatusMessage,'') + @TextToAppend;
RETURN(@StatusMessage)

END
GO
/*
DECLARE @StatusMessage VARCHAR(MAX) = NULL, @RC INT = 0;
SET @StatusMessage =+ App.fnStatusMessage(@StatusMessage,'Started', DEFAULT);
PRINT @StatusMessage;
SET @RC = 100;
SET @StatusMessage =+ App.fnStatusMessage(@StatusMessage,'Did something', @RC);
PRINT @StatusMessage;
*/