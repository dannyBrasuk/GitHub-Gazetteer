USE Gazetteer;
GO
IF OBJECT_ID('App.FeatureSearchManager') IS NOT NULL
        DROP PROCEDURE [App].[FeatureSearchManager];
GO
CREATE PROCEDURE [App].[FeatureSearchManager]

--Requireed Minimum
@MaximumNumberOfSearchCandidates AS INT = 50,
@CurrentLocationLatitude AS FLOAT =  0,
@CurrentLocationLongitude  AS FLOAT = 0,

--Feature Name Search (fuzzy)
@FeatureNameSearchRequest AS VARCHAR(120) = '',

--Nearest neighbor option.  Note the Kilometers dimension.
@DistanceInKilometers AS INT =  0 ,

--State filter
@StatePostalCode AS VARCHAR(2) = '',

--Feature Class Filters.  TODO - convert to a table type of INT class fk
@FeatureClassList AS App.FeatureClassList

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

        DECLARE
                @searchPoint geography = geography::Point(@CurrentLocationLatitude, @CurrentLocationLongitude, 4326) ,
                @distanceInMeters INT = @distanceInKilometers * 1000
                ;

        SET @ParameterSet = 'Search X/Y= ' + CAST(@CurrentLocationLongitude AS VARCHAR(20)) 
                            + ' / ' + CAST(@CurrentLocationLatitude AS VARCHAR(20)) 
                            + '.  Max Candidate Count: ' +  CAST(@MaximumNumberOfSearchCandidates AS VARCHAR(20)) 
                            + '.';
        EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk OUT, @ParameterSet = @ParameterSet, @StatusMessage = @StatusMessage, @ProcedureName = @ProcedureName;

        /* 
            Trap for no parameters
        */
        IF @CurrentLocationLatitude IS NULL OR @CurrentLocationLongitude IS NULL
                BEGIN
                    SET @RC = -1;
                    RAISERROR ('Insufficient parameters. Must have at least latitude and longitude.', 16, 1);
                END

        /*
             Built a list of Feature ID keys based on the options and data presented.
        */

        DECLARE  @FeatureSearchCandidates AS App.FeatureKeyList;

           /*
                   Nearest neightbor option
            */

            IF ISNULL(@DistanceInKilometers,0) > 0
                BEGIN
                        INSERT INTO @FeatureSearchCandidates  (FeatureID, DistanceInMeters)
                                EXEC App.Feature_Select_ByNearestNeighbor 
                                    @Latitude  =  @Latitude,
                                    @Longitude  = @Longitude,
                                    @DistanceInKilometers  =  @DistanceInKilometers ,
                                    @NumberOfCandidates  = @MaximumNumberOfSearchCandidates
                                ;
                        SET @RC = @@Rowcount;        
                        SET @StatusMessage =+ App.fnStatusMessage(@StatusMessage,'Nearest Neighbor completed.', @RC);
                        EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk, @StatusMessage = @StatusMessage;
                END
            ELSE
                /*
                        OR, ... state option
                 */ 
               BEGIN
                        IF ISNULL(@StatePostalCode,'') <> ''
                             INSERT INTO @FeatureSearchCandidates  (FeatureID,DistanceInMeters)
                                    SELECT FeatureID, 
                                                      CAST(ROUND(f.geog.STDistance(@searchPoint),0) AS INT) AS DistanceInMeters
                                    FROM AppData.FeatureSearchFilter f
                                    JOIN AppData.StateFilter s ON f.StateFeatureID = s.FeatureID
                                    WHERE s.StatePostalCode = @StatePostalCode
    
                         SET @RC = @@Rowcount;        
                         SET @StatusMessage =+ App.fnStatusMessage(@StatusMessage,'Nearest Neighbor completed.', @RC);
                         EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk, @StatusMessage = @StatusMessage;
                END

           /*
                   Reduce  feature candidate selection by Feature Class filters
            */
            DECLARE @DeleteMe AS TABLE (FeatureID INT NOT NULL);

            IF EXISTS (SELECT FeatureClassID FROM @FeatureClassList)
                    BEGIN

                            --If Feature Classes are filtered, force in Locale, since its sort an all purpose class
                            IF NOT EXISTS (SELECT FeatureClassID FROM @FeatureClassList WHERE FeatureClassID = 37)
                                INSERT INTO @FeatureClassList (FeatureClassID) VALUES (37);

                            INSERT INTO @DeleteMe (FeatureID)
                                SELECT c.FeatureID
                                FROM @Candidates c
                                JOIN AppData.FeatureSearchFilter f ON c.FeatureID = f.FeatureID
                                JOIN @FeatureClassList fc ON fc.FeatureClassID <> f.featureClass_fk
                                ;

                        DELETE FROM @FeatureSearchCandidates WHERE FeatureID IN (SELECT FeatureID FROM @DeleteMe);

                        SET @RC = @@Rowcount;        
                        SET @StatusMessage =+ App.fnStatusMessage(@StatusMessage,'Remove candidates per filter.', @RC);
                        EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk, @StatusMessage = @StatusMessage;

                 END

 
   
                --Fuzzy name search; if requested.
                IF ISNULL(@FeatureNameSearchRequest,'') <> ''

                    BEGIN

                              EXEC App.FeatureSearchName_Select_FeatureID_ByFeatureName
                                   @FeatureSearchTarget = @FeatureSearchCandidates
                                    @FeatureNameSearchRequest  = @featureNameSearchRequest 

                              --JOIN BACK to Distance and FeatureNameSequenceNumber, to enhance the ranking

                     END

                SET @StatusMessage = 'Success';
                EXEC [App].[ProcedureLog_Merge] @ProcedureLog_fk = @ProcedureLog_fk, @StatusMessage = @StatusMessage, @ReturnCode = @RC;

	END TRY
  
	BEGIN CATCH
 
                    --General error
                    IF @RC >= 0
                            BEGIN
                                SET @RC = -1;
                                EXEC [App].[Errors_GetInfo] @Message = @ErrorMessage OUT, @PrintMessage = 0;
                            END

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



DECLARE @RC AS INT;
DECLARE @FeatureClassList AS App.FeatureClassList;

INSERT INTO @FeatureClassList (FeatureClassID)
    VALUES (41);

EXEC  @RC =  [App].[FeatureSearchManager]

@MaximumNumberOfSearchCandidates  = 50

@FeatureNameSearchRequest = 'Jen Weld',

@Latitude  =  45.528666,
@Longitude  = -122.694135,
@DistanceInKilometers  =  5 ,

@StatePostalCode = 'OR',

@FeatureClassList = @FeatureClassList
;






 
