
CREATE TABLE [dbo].[NationalFedCodes]  ( 
	[FEATURE_ID]         	int NOT NULL,
	[FEATURE_NAME]       	varchar(120) NULL,
	[FEATURE_CLASS]      	varchar(50) NULL,
	[CENSUS_CODE]        	varchar(5) NULL,
	[CENSUS_CLASS_CODE]  	varchar(2) NULL,
	[GSA_CODE]           	varchar(4) NULL,
	[OPM_CODE]           	varchar(9) NULL,
	[STATE_NUMERIC]      	varchar(2) NULL,
	[STATE_ALPHA]        	varchar(2) NULL,
	[COUNTY_SEQUENCE]    	int NULL,
	[COUNTY_NUMERIC]     	varchar(3) NULL,
	[COUNTY_NAME]        	varchar(100) NULL,
	[PRIMARY_LATITUDE]   	numeric(11,7) NULL,
	[PRIMARY_LONGITUDE]  	numeric(12,7) NULL,
	[DATE_CREATED]       	date NULL,
	[DATE_EDITED]        	date NULL,
	[NationalFedCodes_pk]	int IDENTITY(1,1) NOT NULL,
	CONSTRAINT [PK_NationalFedCodes] PRIMARY KEY CLUSTERED([NationalFedCodes_pk])
)
GO
