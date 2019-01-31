PMT Server Processes
========================


##### Contents

[PMT Automated Email](#email)

[PMT Automated Database Backups](#backups)

[PMT Database Backup Storage](#S3)

* * * * *

<a name="email"/>
PMT Automated Email
========================

Description
-----------

PMT provides the capability to export data in a csv or IATI xml format through
database functions:

 * [pmt\_filter\_cvs](https://github.com/spatialdev/PMT-Database/tree/master/Documentation#pmt_filter_cvs)
 * [pmt\_filter\_iati](https://github.com/spatialdev/PMT-Database/tree/master/Documentation#pmt_filter_iati)

All of the export functions use a file naming convention and create files in /usr/local/pmt_dir on 
the database server. Each file name begins with the email address of the intended recipient, followed by an 
underscore (\_) and the database instance name. (i.e. jane.doe@myemail.com\_bmgf.csv)

Using [incrond](http://manpages.ubuntu.com/manpages/precise/man8/incrond.8.html), a inotify cron daemon
which monitors file system events, the /usr/local/pmt_dir is monitored for new files. When a new file
is detected a bash file is exectuted. The bash file extracts the email address from the file name, prepares
the email, attaches the file, emails the file to the recipient and then deletes the file from the directory.

Instructions
------------

1. Install incron  
```sudo apt-get install incron```  
2. Install postfix  
```sudo apt-get install postfix mailutils libsasl2-2 ca-certificates libsasl2-modules```
	1. The postfix configuration wizard will launch:
		1. Choose server: Internet Site
		2. For FQDN: mail.example.com
3. Configur postfix to use Go Daddy Email:
	1. Open the postfix configuration file
	```sudo vim /etc/postfix/main.cf```
	2. Add the following to the bottom of the file
	```
	relayhost = [smtpout.secureserver.net]:80
	smtp_sasl_auth_enable = yes
	smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
	smtp_sasl_security_options = noanonymous
	smtp_tls_CAfile = /etc/postfix/cacert.pem
	smtp_use_tls = yes
	message_size_limit=20480000
 	```
	3. Open the postfix password file
	```sudo vim /etc/postfix/sasl_passwd```
	4. Add the following line replacing **USERNAME@yourdomain.com** with your email and **PASSWORD** with your email password.
	```[smtpout.secureserver.net]:80    USERNAME@yourdomain.com:PASSWORD```
	5. Fix the permissions
	```sudo chmod 400 /etc/postfix/sasl_passwd```
	6. Update postfix to use the sasl_passwd file
	```sudo postmap /etc/postfix/sasl_passwd```
	7. Validate certificates
	```cat /etc/ssl/certs/Thawte_Premium_Server_CA.pem | sudo tee -a /etc/postfix/cacert.pem```
	8. Restart postfix
	```sudo /etc/init.d/postfix restart```
3. Test postfix **Replace your email address in the command below.** 
```echo "Test mail from postfix" | mail -s "Test Postfix" jane.doe@myemail.com```
	1. If you do not receive an email look in the mail log for errors
	```cat /var/log/mail.log```
	2. If you see: _warning: unable to look up public/pickup: No such file or directory_ then sendmail may still be running. You need to stop sendmail and restart postfix.
	```
	sudo /etc/init.d/sendmail stop
	sudo /etc/init.d/postfix restart
	```
4. Install mutt
```sudo apt-get install mutt``` 
5. Test mutt **Replace your email address in the command below.** 
```echo "My test email for mutt" | mutt jane.doe@myemail.com```  
5. Add user (**pmt**) to run incron and send emails  
```sudo adduser pmt```  
6. Add **pmt** user as sudo user by adding the following entry to the visudo file
	1. Open visudo file  
    	```sudo /usr/sbin/visudo```  
	2. Add the following to the file under _#user priviledge specification_  
    	```pmt ALL=(ALL:ALL) ALL```  
7. Create log file, and grant permissions to user **pmt** to use it
	```
	sudo touch /var/log/pmt_email.log
	sudo chmod 777 /var/log/pmt_email.log
	```
8. Copy the bash file from the git repo to /usr/local/bin/pmt_email.sh and grant permissions to user **pmt** to use it
```sudo chmod 777 /usr/local/bin/pmt_email.sh```  
9. Create directory for files and grant permissions to user **pmt** to use it
	```
	sudo mkdir /usr/local/pmt_dir
	sudo chmod 777 /usr/local/pmt_dir
	```
10. Give permission to pmt to run incron by adding pmt to the following file
	1. Open file  
    	```sudo vi /etc/incron.allow```  
	2. Add user **pmt** to the file and save  
    	```pmt``` 
11. Add the incron job:  
	1. Open incron table for editing  
    	```incrontab -e	```  
	2. Add the following line and save  
    	```/usr/local/pmt_dir IN_CREATE /usr/local/bin/pmt_email.sh $@ $# $% ```  
12. Start incron service
```sudo service incron start```  
13. Test process by adding a file to the watched directory. **Replace your email address in the command below.**    
```sudo touch /usr/local/pmt_dir/jane.doe@mymail.com_pmt.txt```


<a name="backups"/>
PMT Automated Database Backups
==============================

Description
-----------

Database backups are automated through cron. Backup retention is as follows:

1. Daily - runs at midnight, keep last 7 backups only
2. Weekly - runs at midnight on Sunday, keep last month of Sundays
3. Monthly - runs first Sunday of month at midnight, keep last year of monthly backups

Instructions
------------

1. Using pgAdmin execute the following on database postgres as postgres to add new 
database user pmt (only perform once per server):
```CREATE USER pmt WITH PASSWORD 'password';```
```ALTER USER pmt WITH SUPERUSER;```	
2. Setup Postgres permissions (only perform once per server):
	1. Change user to pmt (user was created in above step):
	```su pmt```
	2. Create a pgpass file
	```touch /home/pmt/.pgpass```
	3. Open .pgpass file for editing
    	```vi /home/pmt/.pgpass``` 
	4. Copy and past the following text into the file
	``` *.*.*:pmt:password ```
	5. Change permissions on pgpass file
	```chmod 600 /home/pmt/.pgpass```

2. Create directory for backup files and grant permissions (only perform once per server):
	```mkdir /usr/local/pmt_bu```
	```chmod 777 /usr/local/pmt_bu```
3. Create a cron job for database backups (repeat for each database):
	1. Open cron for editng as user
	```crontab -u pmt -e```
	2. Add the following lines, as needed, **changing 'database' to actual database name**. 
	Daily backups for dev environments and all three for production environments:
		1. Daily Backup @ Midnight (keeps last 7 days)
		```0 0 * * * pg_dump -U pmt -Ft -w database > /usr/local/pmt_bu/database_$(date +\%A).tar```
		2. Weekly Backup @ Midnight on Sunday (keeps last month)
		```0 0 * * 0 pg_dump -U pmt -Ft -w database > /usr/local/pmt_bu/database_Week$(date +\%W).tar```
		3. Monthly Backup @ Midnight on First Day (keeps last year)
		```0 0 1 * * pg_dump -U pmt -Ft -w database > /usr/local/pmt_bu/database_$(date +\%b\%Y).tar```

<a name="S3"/>
PMT Database Backup Storage
==============================

Description
------------
PMT database backup files are stored on our Amazon S3 storage bucket. The following are instructions for installing
the S3 client tools and configuring them to transfer the backup files from the server to the S3 bucket. All scheduled
PMT database backups are stored in the following S3 bucket, in their respective server folder:

* https://s3.amazonaws.com/spatialdev/projects/PMT/Data/DatabaseBUs/ScheduledBUs/<database server ip>

Databases that have been deprecated have thier final backup file on S3:

* https://s3.amazonaws.com/spatialdev/projects/PMT/Data/DatabaseBUs/ScheduledBUs/<database server ip>

Instructions
------------
1. Install [Amazon S3 Tools](http://s3tools.org/repositories) on Linux with the following command:
	1. Import S3tools signing key: 
	```wget -O- -q http://s3tools.org/repo/deb-all/stable/s3tools.key | sudo apt-key add -```
	2. Add the repo to sources.list: 
	```sudo wget -O/etc/apt/sources.list.d/s3tools.list http://s3tools.org/repo/deb-all/stable/s3tools.list```
	3. Refresh package cache and install the newest s3cmd: 
	```sudo apt-get update && sudo apt-get install s3cmd```
2. Configure [S3 Tools](http://s3tools.org/usage):
	1. Create or use an exisiting Access Key with Secret Key from the Amazon Console. These values are 
required for the configuration.
	2. Use the S3 configuration wizard:
	```s3cmd --configure```
		1. Provide the requested information.
3. Create a cron job to automate the synronization of backup files to S3
	1. Open cron for editng as sudo (the database backups are under the pmt user, but the S3 requires sudo)
	```sudo crontab -e```
	2. Add the following lines, adjusting location of S3 bucket:
	```
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
	HOME=/home/ubuntu

	##### Move Database Backups to S3
	# Daily @ 1AM syncronize all files from pmt_bu directory to S3 bucket
	0 1 * * * s3cmd sync -r /usr/local/pmt_bu/ s3://spatialdev/projects/PMT/Data/DatabaseBUs/ScheduledBUs/23.22.67.67/


PMT Database Server Maintenance
==============================	 

Description
------------
From time to time the server may run short on space. This is probably due to the server failing to remove the weekly backup files. 
To remove the files:
	1. SSH into the server
	2. Navigate to the folder using:
	```cd /usr/local/pmt_bu```
	3. See the available file space:
	```du -ah --max-depth=1```
	4. Remove the old .tar files
	``rm -f *.tar``
	


