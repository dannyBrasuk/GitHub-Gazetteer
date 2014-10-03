/*
Table used to query features by standard geography (e.g., state and county), for a specific type of feature (e.g.., historical, populated place, or feature class.),
or to filter a selection generated from another query.

This table also can be queried spatially, using nearest neighbor function, for example.

September 2014.

*/
USE Gazetteer;
GO

IF OBJECT_ID('AppData.FeatureSearchFilter') IS NOT NULL
    DROP TABLE AppData.FeatureSearchFilter;


CREATE TABLE AppData.FeatureSearchFilter
(
FeatureSearchFilter_pk INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_FeatureSearchFilter PRIMARY KEY,
FeatureID INT NOT NULL,
FeatureClass_fk INT NOT NULL,
StateFeatureID  INT NOT NULL,               --sfk
CountyFeatureID  INT NOT NULL,          --sfk
HistoricalFlag BIT NOT NULL,
PopulatedPlaceFlag BIT NOT NULL,
Latitude decimal (12,6) NOT NULL,
Longitude decimal (12,6) NOT NULL,
Geog geography NULL                   
)
ON Secondary;
GO
