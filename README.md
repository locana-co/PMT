Portfolio Management Tool (PMT)
===============================




The new PMT Database. Using [PostgreSQL](http://www.postgresql.org/) 9.2 and [PostGIS] (http://postgis.net/) 2.0.3  

Instructions for the installation of a _new PMT_ database
---------------------------------------------------------
**_Follow these instructions to install a brand new instance of PMT._**

1. Create a database called pmt:
```
	CREATE DATABASE pmt WITH OWNER = postgres ENCODING = 'UTF8'TABLESPACE = pg_default LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' CONNECTION LIMIT = -1;

	COMMENT ON DATABASE pmt IS 'default administrative connection database';

	CREATE EXTENSION POSTGIS; --(if using pgadmin change the connection to the new pmt database)
```  
2. Execute **CreatePMTDatabase.sql**. (_Creates the database model_)
3. Execute all spatial scripts in the **_PMTSpatialData_** folder in **the order listed below**. (_Populates the database with spatial data_)
	
	1.  LoadPMTSpatialData0.sql	
	2.  LoadPMTSpatialData1.sql
	3.  LoadPMTSpatialData2.sql
	4.  LoadPMTSpatialData3.sql
	5.  LoadPMTSpatialData4.sql
	6.  LoadPMTSpatialData5.sql
	7.  LoadPMTSpatialData6.sql
	8.  LoadPMTSpatialData7.sql
	9.  LoadPMTSpatialData8.sql
	10. LoadPMTSpatialData9.sql
	11. LoadPMTSpatialData10.sql
	12. LoadPMTSpatialData11.sql
	13. LoadPMTSpatialData12.sql
	14. LoadPMTSpatialData13.sql
	15. LoadPMTSpatialData14.sql
	16. LoadPMTSpatialData15.sql
	17. LoadPMTSpatialData16.sql

4. Execute **UpdatePMTSpatialData.sql**. (_Creates a reference table from the spatial data loaded in step 3_)
5. Open **LoadIATIStandards.sql** and follow the steps outlined within.  (_Adds IATI Standards_)
6. Execute **AddTaxonomyGAUL0.sql**. (_Links the spatial data to the IATI Statndards_)
7. Execute **PMTPerformanceTuning.sql**.
8. Execute the following sql commands, one at a time:
```
	VACUUM;

	ANALYZE;
```
9. Open **PMTPermissions.sql** and follow the steps outlined within.  (_Adds users and permissions_)