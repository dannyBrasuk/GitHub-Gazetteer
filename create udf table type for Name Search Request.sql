Use Gazetteer;
GO


IF Type_ID(N'App.NameSearchRequestList') IS NOT NULL
    DROP TYPE App.NameSearchRequestList;

GO
CREATE TYPE [App].[NameSearchRequestList] AS TABLE 
 ( 
NameSearchRequest_pk INT NOT NULL IDENTITY(1,1)  PRIMARY KEY,   
NameRequestKey  SQL_VARIANT NULL UNIQUE,           
NameRequest  VARCHAR(120)  NOT NULL
);
