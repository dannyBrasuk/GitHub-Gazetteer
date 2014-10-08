USE Gazetteer;
Go

/*
*   Verify the Geog objects before creating spatial index
*/

 update AppData.FeatureSearchFilter  set Geog=Geog.MakeValid()  where Geog.STIsValid()=0;;

--Indexes needed to support Nearest Neighbor search

IF EXISTS (SELECT object_id FROM sys.indexes i WHERE i.NAME = 'sidxFeatureSearchFilter_geog')
        DROP INDEX [sidxFeatureSearchFilter_geog] ON  [AppData].[FeatureSearchFilter];

CREATE SPATIAL INDEX [sidxFeatureSearchFilter_geog] 
ON [AppData].[FeatureSearchFilter]
(
    [Geog]
)USING  GEOGRAPHY_AUTO_GRID 
WITH (DATA_COMPRESSION = PAGE);


