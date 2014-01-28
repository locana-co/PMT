#!/usr/bin/python
# -*- coding: utf-8 -*-

import psycopg2
import json
import urllib
import urllib2
import sys

con = None
con = psycopg2.connect("") 

cnt = 0

sqlFile = sys.argv[1]
print 'Argument List:', str(sys.argv[1])

try:
	cur = con.cursor()
	
	for line in file(sqlFile, 'r'):
		cnt = cnt + 1
 		cur.execute(line.strip())          
		print cnt
	
	con.commit()
	
except Exception, e:
  print 'Error %s' % e    
finally:
  if con:
    con.close()
    
