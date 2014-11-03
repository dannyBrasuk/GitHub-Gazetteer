Use Gazetteer;
GO

/*
Note: the logic here is a little unlikely. target of feature search is likely to be more broad

On the other hand, distance should be a ranking element,

*/
/*
    Match Request
*/

DECLARE 
    @RC AS INT;

DECLARE @RC INT;

EXEC  @RC =  [App].[FeatureSearchManager]

@MaximumNumberOfSearchCandidates  = 50

@featureNameSearchRequest = 'Jen Weld Field',

@latitude  =  45.528666,
@longitude  = -122.694135,
@distanceInKilometers  =  5 ,

@statePostalCode = 'OR',

@featureClass_fk = 37
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

Jeld Wen Field is a Locale feature class (37)
A "park" is feature class fk 41

*/



