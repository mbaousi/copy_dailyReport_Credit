#!/bin/bash
cd /var/daily-report/
Before=$(date --date="2 days ago" +"%Y-%m-%d")
Current=$(date --date="1 days ago" +"%Y-%m-%d")
sed -i "s/$Before/$Current/g" /var/daily-report/daily_report.sh
bash /var/daily-report/daily_report.sh


