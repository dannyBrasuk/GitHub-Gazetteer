/*
This table is searched by feature name.  It's companion table is the tokenized names of features.

This table should have more records than Feature IDs, because it includes all the alternative names.  
In other words, Feature IDs are repeated.  The FeatureNameSequenceNumber column is specific to a Feature ID.
The "official" feature name always is feature sequence of 1.

September 2014
*/

USE Gazetteer;
GO

IF OBJECT_ID('AppData.FeatureSearchName') IS NOT NULL
    DROP TABLE AppData.FeatureSearchName;

CREATE TABLE AppData.FeatureSearchName
(
FeatureSearchName_pk  INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_FeatureSearchName PRIMARY KEY,
FeatureID  INT NOT NULL, 
FeatureName VARCHAR(120) NOT NULL,
StatePostalCode VARCHAR(40) NOT NULL,
StateName VARCHAR(40) NOT NULL,
OfficialFeatureNameFlag BIT NOT NULL,
FeatureNameSequenceNumber SMALLINT NOT NULL,
AllNames_fk INT NOT NULL
)
ON Secondary;
GO

