# PMT Database Installation Instructions

**Follow these instructions to install a brand new database instance of the PMT
Database. These instructions assume that you have PostgreSQL 9.3.0 and PostGIS 
2.1.0 installed.**
 
_[Click for instructions on installing PostgreSQL and PostGIS on Ubuntu](#installation-on-ubuntu)_


1. Create a database called pmt:
```
	CREATE DATABASE pmt WITH OWNER = postgres ENCODING = 'UTF8'TABLESPACE = pg_default LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' CONNECTION LIMIT = -1;

	COMMENT ON DATABASE pmt IS 'default administrative connection database';
	
	\connect pmt;
	
	CREATE EXTENSION POSTGIS; --(if using pgadmin change the connection to the new pmt database)
```  
2. Execute **2.CreateDatabase.sql**. (_Creates the database model_)
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
	18. LoadPMTSpatialData17.sql

(_pro-tip: use \i directive in psql to load sql from files_)

4. Execute **4.UpdateSpatialData.sql**. (_Repairs spatial data loaded in step 3_)
5. Open **5.IATIStandards.sql** and follow the steps outlined within.  (_Adds IATI Standards_)
6. Execute **6.TaxonomyGAUL0.sql**. (_Links the spatial data to the IATI Statndards_)
7. Execute **7.PerformanceTuning.sql**.
8. Execute the following sql commands, one at a time:
```
	VACUUM;

	ANALYZE;
```
9. Open **9.Permissions.sql** and follow the steps outlined within.  (_Adds users and permissions_)


## Installation on Ubuntu

Instructions for installation of _PostgreSQL 9.3.0 and PostGIS 2.1.0 on Ubuntu 12.04 (EC2)_

This version installs everything from the source packages including all the dependices on 
a fresh EC2.

```
	sudo apt-get update
	sudo apt-get -y upgrade 

	sudo wget http://anonscm.debian.org/loggerhead/pkg-postgresql/postgresql-common/trunk/download/head:/apt.postgresql.org.s-20130224224205-px3qyst90b3xp8zj-1/apt.postgresql.org.sh

	sudo chmod 777 apt.postgresql.org.sh
	--Note: if using 12.04 use:
	sudo ./apt.postgresql.org.sh precise
	--Note: if using 12.10 use
	--sudo ./apt.postgresql.org.sh quantal
	(hit enter)

	sudo apt-get install postgresql-9.3 postgresql-contrib-9.3 postgresql-9.3-postgis-2.1 postgresql-9.3-postgis-scripts -y


	sudo su postgres

	psql

	alter user postgres with password '<your password here>';

	\q
	exit

	--or VI or VIM or whatever editor
	sudo pico /etc/postgresql/9.3/main/postgresql.conf

	--from this 
	listen_addresses = ‘localhost’  
	--to 
	listen_addresses = ‘*’  

	sudo pico /etc/postgresql/9.3/main/pg_hba.conf
	--add this line:
	host    all             all             0.0.0.0/0               md5

	sudo /etc/init.d/postgresql restart
```
