Use Gazetteer;
GO

/*
    Demo nun.
*/
DECLARE @RC AS INT;
DECLARE @FeatureClassList AS App.FeatureClassList;

INSERT INTO @FeatureClassList (FeatureClassID)
    VALUES (41);

DECLARE @FeaturesFound as Table (FeatureID INT NOT NULL, DistanceInMeters INT NOT NULL);

--INSERT INTO @FeaturesFound(FeatureID , DistanceInMeters)
    EXEC @RC = [App].[FeatureSearchManager]

--required
@MaximumNumberOfSearchCandidates  = 50,
@CurrentLocationLatitude  =  45.528666,
@CurrentLocationLongitude  = -122.694135,

--fuzzy name search (optional)
@FeatureNameSearchRequest = 'Jen Weld',

--nearest neighbor (optional)
@DistanceInKilometers  =  5 ,

--state filter (optional)
@StatePostalCode = 'OR',

--feature class filter (optional)
@FeatureClassList = @FeatureClassList,

@Debug = 1
;

--SELECT 
--         f.*,
--        s.DistanceInMeters
--FROM @FeaturesFound s
--JOIN App.vFeatureData_SelectForDisplay f ON s.FeatureID = f.FeatureID
--ORDER BY s.DistanceInMeters;


SELECT @RC as RC;

SELECT TOP 3 * 
FROM AppData.ProcedureLog 
WHERE ProcedureName = 'FeatureSearchManager' 
ORDER BY ProcedureLog_pk DESC;

SELECT TOP 3 * 
FROM AppData.ProcedureLog 
WHERE ProcedureName = 'FeatureSearchName_Select_FeatureID_ByFeatureName' 
ORDER BY ProcedureLog_pk DESC;


/*

Pull sample data:

--oops Providence Park and Jen Weld are not the same in this dataset.

select * from appdata.FeatureSearchName
where StatePostalCode='OR'
and FeatureName like '%Providence%'

lat/long for apartment is:  45.528666, -122.694135

EXEC App.Feature_Select_ForDisplay 

select * from App.vFeatureData_SelectForDisplay where FeatureID in (2070794, 1124541)

select * from App.vFeatureData_SelectForDisplay where StatePostalCode = 'GA' and featureClass_fk = 37


Jeld Wen Field is a Locale feature class (37)
A "park" is feature class fk 41

*/



