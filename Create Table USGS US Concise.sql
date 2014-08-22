Use Gazetteer;
GO
CREATE TABLE USGS.[Concise] 
 ( 
	[FEATURE_ID]     	            int NULL,
	[FEATURE_NAME]   	varchar(120) NULL,
	[FEATURE_CLASS]  	varchar(50) NULL,
	[STATE_ALPHA]    	            varchar(2) NULL,
	[STATE_NUMERIC]  	varchar(2) NULL,
	[COUNTY_NAME]    	varchar(100) NULL,
	[COUNTY_NUMERIC] 	varchar(3) NULL,
	[PRIMARY_LAT_DMS]	varchar(7) NULL,
	[PRIM_LONG_DMS]  	varchar(8) NULL,
	[PRIM_LAT_DEC]        	numeric(11,7) NULL,
	[PRIM_LONG_DEC]  	numeric(12,7) NULL,
	[SOURCE_LAT_DMS] 	varchar(7) NULL,
	[SOURCE_LONG_DMS]	varchar(8) NULL,
	[SOURCE_LAT_DEC] 	numeric(11,7) NULL,
	[SOURCE_LONG_DEC]	numeric(12,7) NULL,
	[ELEV_IN_M]      	int NULL,
	[MAP_NAME]       	varchar(100) NULL,
	[DATE_CREATED]   date NULL,
	[DATE_EDITED]    	date NULL 
	)
ON [Secondary]
WITH (DATA_COMPRESSION = NONE)
GO
