USE Gazetteer;
GO
CREATE TABLE AppData.FeatureGuide
(
FeatureID                   --one record per feature ID
FeatureName             --Official feature name
StatePostalCode
AltermativeNameList  -- append together all unofficial names names, in date order (per [Citiation], on [date] in (if known, not 1899).

--MapLabel
ConciseMapLabel

FeatureClassName

FeatureDescription
FeatureHistory
FeatureCitation     -- on Official entry in the All Names table
ElevationInMeters
DateCreated
DateEdited
)
AS Secondary;
GO
CREATE TABLE AppData.FeatureSearchName
(
FeatureID,
FeatureName,
FeatureNameSequenceNumber  --order by date)
--need a link back the "all names" table
)
AS Secondary;
GO
CREATE TABLE AppData.FeatureSearchFilter
(
FeatureID,
OfficialFeatureNameFlag,
FeatureClass_fk,
StateFeatureID,
CountyFeatureID,
HistoricalFlag,
PopulatedPlaceFlag,
Geog                    --which is best for nearest neighbor
)
AS Secondary;
GO