USE Gazetteer;
GO
CREATE TABLE USGS.FileEdition
(
TableName             VARCHAR(128)  NOT NULL,
FileVintageDate     DATE NOT NULL
)
ON Secondary;