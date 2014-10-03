/*
Import the flat file of Governmental Units (i.e., counties and states) for features into this "work" table.  
This table is not actually used in the application.

September 2014

*/

USE Gazetteer;
GO
CREATE TABLE USGS.[GovernmentUnit] 
 ( 
	[FEATURE_ID]     	            int NULL,
            [UNIT_TYPE]                        varchar(50) NULL,
	[COUNTY_NUMERIC] 	varchar(3) NULL,
	[COUNTY_NAME]    	varchar(100) NULL,
	[STATE_NUMERIC]  	varchar(2) NULL,
	[STATE_ALPHA]    	            varchar(2) NULL,
            [STATE_NAME]    	            varchar(100) NULL,
            [COUNTRY_ALPHA]   	varchar(2) NULL,
            [COUNTRY_NAME]   	varchar(100) NULL,
	[FEATURE_NAME]             varchar(120) NULL
	)
ON [Secondary]
WITH (DATA_COMPRESSION = NONE)
GO

