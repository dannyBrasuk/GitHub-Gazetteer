USE Gazetteer;
GO
IF OBJECT_ID('App.FeatureSearchManager') IS NOT NULL
        DROP PROCEDURE [App].[FeatureSearchManager];
GO
CREATE PROCEDURE [App].[FeatureSearchManager]

--general
@maximumNumberOfSearchCandidates INT = 50,

--Feature Name Search (fuzzy)
@featureNameSearchRequest VARCHAR(120) = '',

--Nearest neighbor option
@latitude float =  0,
@longitude float = 0,
@distanceInKilometers INT =  0 ,

--State filter
@statePostalCode VARCHAR(2) = '',

--Feature Class Filters.  TODO - convert to a table type of INT class fk
@featureClass_fk INT =  0

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

                    SET @ParameterSet = 'Search X/Y= ' + CAST(@Longitude AS VARCHAR(20)) + ' / ' + CAST(@Latitude AS VARCHAR(20)) ;
                    EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk OUT, @ParameterSet = @ParameterSet, @StatusMessage = @StatusMessage, @ProcedureName = @ProcedureName;

--Built a list of Feature ID keys; Save to a table type.  Pass it to the  fuzzy name match proc, if requested
--Return is a data set of keys

          
          DECLARE  @Candidates AS TABLE ( FeatureID INT, DistanceInMeters INT);
  

      --nearest neightbor option
        IF @latitude <> 0 and @longitude <> 0
                INSERT INTO @Candidates  (FeatureID, DistanceInMeters)
                        EXEC App.Feature_Select_ByNearestNeighbor 
                            @latitude  =  @latitude,
                            @longitude  = @longitude,
                            @distanceInKilometers  =  @distanceInKilometers ,
                            @numberOfCandidates  = @maximumNumberOfSearchCandidates
                        ;

            --reduce by other filters
            --Delete me keys
            DECLARE @DeleteMe AS TABLE (FeatureID INT NOT NULL);
            INSERT INTO @DeleteMe (FeatureID)
                SELECT c.FeatureID
                FROM @Candidates c
                JOIN AppData.FeatureSearchFilter f ON c.FeatureID = f.FeatureID
                WHERE f.FeatureClass_fk <> @featureClass_fk
                    UNION ALL
                SELECT c.FeatureID
                FROM @Candidates c
                JOIN AppData.FeatureSearchFilter f ON c.FeatureID = f.FeatureID
                JOIN AppData.StateFilter s ON f.StateFeatureID = s.FeatureID
                WHERE s.StatePostalCode <> @statePostalCode
                ;
               
                DELETE FROM @Candidates WHERE FeatureID IN (SELECT FeatureID FROM @DeleteMe);

                --Fuzzy name search; if requested.
                IF ISNULL(@FeatureNameSearchRequest,'') <> ''

                    BEGIN

                              EXEC App.FeatureSearchName_Select_FeatureID_ByFeatureName
                                    --@FeatureSearchTarget = @Candidates
                                    @featureNameSearchRequest  = @featureNameSearchRequest 

                              --JOIN BACK to Distance and FeatureNameSequenceNumber, to enhance the ranking

                     END

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


/*

DECLARE @RC INT;

EXEC  @RC =  [App].[FeatureSearchManager]

@MaximumNumberOfSearchCandidates  = 50

@featureNameSearchRequest = 'Jen Weld',

@latitude  =  45.528666,
@longitude  = -122.694135,
@distanceInKilometers  =  5 ,

@statePostalCode = 'OR',

@featureClass_fk = 37
;

*/




 
