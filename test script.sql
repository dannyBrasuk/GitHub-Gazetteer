Use Gazetteer;
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



