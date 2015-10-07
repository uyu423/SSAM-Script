# SSAM-Script
## Overview
SSAM(Server Status Automatic Monitoring) Script, server monitoring and automated process restart scripts
* **Tested on next Environment** : CentOS 5.11 / Ubuntu 15.04 / Ubuntu 15.10
* **Requirements** : sendmail(stmp settings), mail command(mailutils)
* **MUST BE REQUIRE ROOT PRIVILEGES**

### Notification Type

### Excute Emergency Commands

## Installaion
<pre>
$ sudo git clone https://github.com/uyu423/SSAM-Script.git /root/scripts/SSAM-Script
$ sudo chmod 700 /root/scripts/SSAM-Script/SSAM-Script.sh
</pre>

## Set a User Custom values
### 'User Custom Value Settings' variables of SSAM-Script.sh (line 4)
* mailingList : array,
* MonitoringProcess : array,
* EmergencyCommands : array,
* MaxUsingPMemPerBoundary : 
* MaxUsingVRMemPerBoundary : 
* MaxUsingDiskBoundary :
* MaxMonitoringCnt : 
* NetworkInterface : 

## Mail Notification Testing

## Set a User Custom values

## SSAM-Script in CRONTAB Setup
* The following code sample checks the server every five minutes
<pre>
// Ubuntu 15.04
$ sudo echo "*/5 * * * * bash /root/scripts/SSAM-Script/SSAM-Script.sh > /var/log/SSAM-Script/SSAM-Script.log 2> /var/log/SSAM-Script/SSAM-Script.err" >> /var/spool/cron/crontabs/root
// Centos 5.11
$ sudo echo "*/5 * * * * bash /root/scripts/SSAM-Script/SSAM-Script.sh > /var/log/SSAM-Script/SSAM-Script.log 2> /var/log/SSAM-Script/SSAM-Script.err" >> /var/spool/cron/root
</pre>

* Additional, the recommendations Please contact uyu423@gmail.com or github issue tab
