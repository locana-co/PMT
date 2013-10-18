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


Instructions - Installation of the _Application Database_
----------------------------------------------------------
**_Follow these instructions to install the application database, which supports applications using PMT instances._**

1. Create a database called app:
```
	CREATE DATABASE app WITH OWNER = postgres ENCODING = 'UTF8'TABLESPACE = pg_default LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' CONNECTION LIMIT = -1;

	COMMENT ON DATABASE app IS 'application support for PMT database instances';
```
2. Execute **CreateAPPDatabase.sql**. (_Creates the application database model_)
3. Execute **LoadAppData.sql**. (_Loads existing PMT 1.0 data_)
4. Execute the following sql commands, one at a time:
```
	VACUUM;

	ANALYZE;
```
5. Open **PMTPermissions.sql** and follow the steps outlined within.  (_Adds users and permissions_)

<br />  
	
Documentation
-------------
**_Documents referenced below can be found in the Documentation folder._**

1. **PMT-Framework** - High level PMT Framework (Database & API) diagram
2. **PMT-ERD** - Entity Relationship Diagram using Chen method describing the relationships between the entities in the database
3. **PMT-Schema** - Database schema diagram of the physical structure of the database
4. **PMT Database Development Process** - Describes the development process for the PMT database model and concurrent development activities
5. **Understanding the Data Model** - Describes the PMT data model and taxonomy

<br />
Instructions for setting up Postgres 9.2.2 and PostGIS 2.0.3 on Ubuntu 12.04 (EC2)
----------------------------------------------------------------------------------

### Install the core dependcies
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt-get install -y make libxml2-dev libxslt-dev python-software-properties build-essential zlib1g-dev libreadline-dev libgdal1-dev 

### Create a directory to hold downloaded source codes
	mkdir /home/ubuntu/installs
	cd /home/ubuntu/installs

### Download and Install PostgreSQL database server
	sudo wget http://ftp.postgresql.org/pub/source/v9.2.2/postgresql-9.2.2.tar.bz2
	bzip2 -d postgresql-9.2.2.tar.bz2
	tar -xf postgresql-9.2.2.tar
	cd postgresql-9.2.2
	./configure --with-libxml --with-libxslt
	make
	sudo make install


### Configure PostgreSQL database server
##### Add 'postgres' user
	sudo adduser postgres
	Enter new UNIX password: 
	Retype new UNIX password:

##### Make and set permissions on the pgsql directory
	sudo mkdir /usr/local/pgsql/data
	sudo chown postgres /usr/local/pgsql/data

##### Initialize the postgres DB
	su - postgres
	/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data

##### Start the service and logging
	/usr/local/pgsql/bin/postgres -D /usr/local/pgsql/data >logfile 2>&1 &

##### Create a test DB
	/usr/local/pgsql/bin/createdb test
	/usr/local/pgsql/bin/psql test
	\q

##### Set postgres DB password
	su - postgres
	/usr/local/pgsql/bin/psql
	\password postgres
	<Enter new password:>
	<Enter it again:>
	\q
	
	su - ubuntu


### Add Soundex ability
	cd /home/ubuntu/installs/postgresql-9.2.2/contrib/fuzzystrmatch
	make
	sudo make install


### Make a directory for PostGIS install stuff
	cd /home/ubuntu/installs
	mkdir postgis
	cd postgis

### Download and Install requirements for PostGIS Installation

#####Proj4
	cd /home/ubuntu/installs/postgis
	wget http://download.osgeo.org/proj/proj-4.8.0.tar.gz
	gzip -d proj-4.8.0.tar.gz
	tar -xvf proj-4.8.0.tar
	cd proj-4.8.0
	./configure
	make
	sudo make install

#####GEOS
	cd /home/ubuntu/installs/postgis
	wget http://download.osgeo.org/geos/geos-3.4.0.tar.bz2
	bzip2 -d geos-3.4.0.tar.bz2
	tar -xvf geos-3.4.0.tar
	cd geos-3.4.0
	./configure
	make -j2
	sudo make install


##### JSON-C, (version 0.9 or higher)
	cd /home/ubuntu/installs/postgis
	wget http://oss.metaparadigm.com/json-c/json-c-0.9.tar.gz
	gzip -d json-c-0.9.tar.gz
	tar -xvf json-c-0.9.tar
	cd json-c-0.9
	./configure
	make
	sudo make install


##### GDAL
	cd /home/ubuntu/installs/postgis
	wget http://download.osgeo.org/gdal/gdal-1.9.2.tar.gz
	gzip -d gdal-1.9.2.tar.gz
	tar -xvf gdal-1.9.2.tar
	cd gdal-1.9.2
	./configure
	make- j2
	sudo make install

##### Update Libraries
	sudo su
	echo /usr/local/lib >> /etc/ld.so.conf

### PostGIS installation
	cd /home/ubuntu/installs/postgis
	wget http://postgis.net/stuff/postgis-2.1.0.tar.gz
	gzip -d postgis-2.1.0.tar.gz
	tar -xf postgis-2.1.0.tar
	cd postgis-2.1.0
	./configure --with-pgconfig=/usr/local/pgsql/bin/pg_config --with-raster
	make
	sudo make install

### Build PostGIS Extensions and Deploy
	cd extensions/postgis
	make clean
	make
	sudo make install
	
	cd ..
	cd postgis_topology
	make clean
	make
	sudo make install


### Modify Files
	su - postgres
	cd /usr/local/pgsql/data
	pico postgresql.conf
	
	# remove the hash and change localhost to *, then save and exit pico
	listen_addresses = '*'
<br />

	pico pg_hba.conf
	
	# Add this line, then save and exit pico
	host  all all 0.0.0.0/0 md5

The following was not necessary on EC2 instance, but was on a Ubuntu server VM instance

	su - ubuntu
	sudo pico /etc/ld.conf.d/local.conf

	# Add this line, then save and exit pico
	/usr/local/lib

### Config libraries
	sudo ldconfig 

### Restart postgres service
	su - postgres
	/usr/local/pgsql/bin/postgres -D /usr/local/pgsql/data >logfile 2>&1 &
	Grant EDIT > ./pg_ctl restart -D /usr/local/pgsql/data
	(make sure the data directory is 0700)
You may also have to restart the server, then restart the postgres service

<br />
### Create the PostGIS template
Connect to postgres DB either thru pgAdmin3 or psql and execute the following SQL
	Create extension postgis

<br />
You should be good to go….