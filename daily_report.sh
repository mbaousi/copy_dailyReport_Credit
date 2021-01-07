#!/bin/bash
Date=$(date --date="1 days ago" +"%Y%m%d")


#backup mongo daily
mongo IBSng --eval 'db.daily_traffic_usage.aggregate([{"$match": {"day":{"$gte": ISODate("2021-01-07T00:00:00Z"), "$lt": ISODate("2021-01-07T23:59:59Z")}}},{"$project": { "user_id" :  "$user_id","in_bytes":  "$in_bytes", "out_bytes": "$out_bytes",}},{  "$group": {"_id": { "user_id" : "$user_id", },"total_input_bytes": {"$sum": "$in_bytes"},"total_output_bytes": {"$sum": "$out_bytes"}, } }, { "$out" : "daily_usage"}, ], { allowDiskUse : true} )'
mongoexport --port 27017 -d IBSng  -c daily_usage  --type=CSV --fields=_id.user_id,total_input_bytes,total_output_bytes -o  /tmp/daily_report.csv
cat /tmp/daily_report.csv | grep -vi total_input > /tmp/daily_report_${Date}.csv

#copy to mongo backup server
scp -P 2245  /tmp/daily_report_${Date}.csv root@185.179.168.14:/tmp/
sleep 5

#create mongo table and copy daily usage to this table
psql  -h 185.179.168.14 -U mahan mahan -c "create table daily_report_$Date(user_id bigint NOT NULL PRIMARY KEY, total_input_byte text, total_output_byte text)";
psql  -h 185.179.168.14 -U mahan mahan  -c "copy daily_report_$Date from '/tmp/daily_report_$Date.csv' WITH (FORMAT csv)"


#create credit table and copy to  other data base server
psql -U ibs IBSng -c  "COPY (select users.user_id, normal_users.normal_username, users.credit from users INNER JOIN normal_users ON normal_users.user_id=users.user_id) TO '/tmp/userid_map_tmp.csv' CSV HEADER"
cat /tmp/userid_map_tmp.csv | grep -vi normal_username > /tmp/userid_map.csv
scp -P 2245  /tmp/userid_map.csv root@185.179.168.14:/tmp
psql  -h 185.179.168.14 -U mahan mahan -c "create table user_credit_$Date(user_id bigint NOT NULL PRIMARY KEY,normal_username text,credit numeric(14,4))";
psql  -h 185.179.168.14 -U mahan mahan  -c "copy user_credit_$Date from '/tmp/userid_map.csv' WITH (FORMAT csv)"


#psql -U ibs IBSng -c  "COPY (select user_id,credit from users) TO '/tmp/userid_credit_tmp.csv' CSV HEADER"
#cat /tmp/userid_credit_tmp.csv | grep -vi user_id > /tmp/userid_credit.csv
#scp -P 2245  /tmp/userid_credit.csv root@185.179.168.14:/tmp
#psql  -h 185.179.168.14 -U mahan mahan  -c 
