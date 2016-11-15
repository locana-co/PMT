#!/usr/bin/env bash

#sudo apt-get update
#sudo apt-get upgrade -y

#sudo apt-get install git -y
#sudo git clone https://github.com/spatialdev/PMT-Database
#you'll have to enter your creds
#this takes a while

#postgis shell install
#To run this navigate to the same dir as the shell
#go: sudo yes | sh pginstall.sh
#####ASSUMPTIONS###
#the postgres is the vanilla install and puts its data here: /var/lib/postgresql/9.3/main/
# or else a copy line below needs to be changed to the current data directory

#Assumes you're sitting on a fresh Ubuntu 12.04 installation and connected to the net. 

#git pulls the fresh repo and none of the default directories are moved around. 
#if thats the case then you have to do extra stuff.
#cd PMT-Database

sudo wget http://anonscm.debian.org/loggerhead/pkg-postgresql/postgresql-common/trunk/download/head:/apt.postgresql.org.s-20130224224205-px3qyst90b3xp8zj-1/apt.postgresql.org.sh
#change the persmissions
sudo chmod 777 apt.postgresql.org.sh
sudo ./apt.postgresql.org.sh precise
sudo apt-get install postgresql-9.3 postgresql-contrib-9.3 postgresql-9.3-postgis-2.1 postgresql-9.3-postgis-scripts -y
#woot

sudo /etc/init.d/postgresql stop
sleep 5
sudo sed -i "92c host        all                all                0.0.0.0/0                md5" /etc/postgresql/9.3/main/pg_hba.conf
sudo sed -i "59c listen_addresses = '*' " /etc/postgresql/9.3/main/postgresql.conf

sudo /etc/init.d/postgresql start
sleep 5
#create the database
sudo -u postgres psql -c "ALTER user postgres WITH PASSWORD 'postgres'"

#woot


#Copy all the IATI XML files into the postgres data directory
#TODO: Would be awesome to wget files directly from IATI code lists
#/var/lib/postgresql/9.3/main
sudo cp -a IATICodeLists/. /var/lib/postgresql/9.3/main/
sleep 5
sudo -u postgres psql -c "create database pmt WITH OWNER = postgres ENCODING = 'UTF8' TABLESPACE = pg_default LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' CONNECTION LIMIT = -1;"
sudo -u postgres psql -d pmt -c "COMMENT ON DATABASE pmt IS 'default administrative connection database';"
sudo -u postgres psql -d pmt -c "CREATE EXTENSION POSTGIS;"
#switch to the PMT-Database directory that you put the repo in
sudo -u postgres psql -d pmt -c "\i PMTCreateDatabase.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData0.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData1.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData2.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData3.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData4.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData5.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData6.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData7.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData8.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData9.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData10.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData11.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData12.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData13.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData14.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData15.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData16.sql"
sudo -u postgres psql -d pmt -c "\i PMTSpatialData/LoadPMTSpatialData17.sql"
sudo -u postgres psql -d pmt -c "\i PMTUpdateSpatialData.sql"

sudo -u postgres psql -d pmt -c "\i PMTIATIStandards.sql"
sudo -u postgres psql -d pmt -c "\i PMTTaxonomyGAUL0.sql"
sudo -u postgres psql -d pmt -c "\i PMTPerformanceTuning.sql"

sudo -u postgres psql -d pmt -c "VACUUM;"
sudo -u postgres psql -d pmt -c "ANALYZE;"


#if you break the database back out of psql connect  back to postgres and drop the pmt and start over
#\connect postgres
#sudo -u postgres psql -d postgres -c "drop database pmt;"
#If you break it do the stuff below to purge

# sudo apt-get --purge remove postgresql\* -y
# sudo rm -r /etc/postgresql-common/
# sudo rm -r /var/lib/postgresql/

#check ports to make sure postgres is not still listening on 5432
#sudo netstat -lp | grep postgresql
