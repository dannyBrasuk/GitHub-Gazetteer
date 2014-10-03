/*
Inventory of the source files and version dates.

September 2014
*/

USE Gazetteer;
GO
INSERT INTO USGS.FileEdition (TableName, FileVintageDate)
    VALUES  ('NationalFile', '20140802'),
                        ('Concise', '20091130'),
                        ('PopulatedPlace', '20140802'),
                        ('HistoricalFeature', '20140802'),
                        ('Government Unit', '20140802'),
                        ('AllName', '20140802'),
                        ('FeatureDescriptionHistory', '20140802'),
                        ('NationalFederalCode', '20140802')
;
SELECT
*
FROM USGS.FileEdition;