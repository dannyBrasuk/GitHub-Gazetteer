Gazetteer
=========

Microsoft SQL Server 2012 code used to support search tool of for Gazetteer features from the USGS's Geographics Names Information System.

Data Source: http://geonames.usgs.gov/domestic/download_data.htm

Data Vintage:  September 2014.

Step 0:  Create the database and schema.

Step 1:  Create the "work" tables and load into them the text files downloaded from USGS. The table names match the file names.

Step 2:  Create the "app data" tables.

Step 3:  Initialize the "app data" tables with the insert scripts.

Step 4.  Create the necessary indexes to support the queries and app features.

Step 5   Install the procs needed to support the queries and app features.
 


