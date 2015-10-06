#!/bin/bash

mailingList=(
	"uyu423@gmail.com"
#	"foo@bar.com"
#	"yourID@yourDomain.com"
)

Dir="/var/log/SSAMS"
countFile="${Dir}/SSAMS.cnt"
logFile="${Dir}/SSAMS.log"
mailFile="${Dir}/SSAMS.mail"
emergFile="${Dir}/SSAMS.emerg"

MonitoringProcess=(
	'httpd' 'mysqld' 'java' 'Passenger' 'sshd'
)
EmergencyCommands=(
	'service httpd restart'
	'service mysqld restart'
	'/etc/init.d/tomcat7 restart'
)

MaxUsingPMemPerBoundary=97
MaxUsingVRMemPerBoundary=70
#MaxUsingDiskBoundary=1
MaxUsingDiskBoundary=97
#MaxMonitoringCnt=1
MaxMonitoringCnt=72
NetworkInterface="eth0"

initSSAMS() {
	if [ ! -d ${Dir} ]; then
		mkdir ${Dir}
	fi
	touch ${countFile}
	touch ${logFile}
	touch ${mailFile}
	touch ${emergFile}
}

counting() {
	if [ -f ${countFile} ]; then
		NowMonitoringCnt=`cat ${countFile}`
	else
		NowMonitoringCnt=0
	fi
	(( NowMonitoringCnt++ ))
	echo ${NowMonitoringCnt} > ${countFile}
}

countingReset() {
	rm -rf ${countFile}
}

sendingMail() {
	for mail in "${mailingList[@]}"; do
		mail -s "[SSAMS] $1" ${mail} < "$2"
#		echo -e `cat ${mailFile}`
	done
}

sendingEmergencyMail() {
	echo -e "$2" > "${emergFile}"
	sendingMail "$1" "${emergFile}"
}

sendingPreodicalMail() {
	echo -e "${periodicMesg}" > "${mailFile}"
	sendingMail "Periodical '${HOSTNAME}' Server Status Report" "${mailFile}"
}

makePreodicalMailContents() {
	periodicMesg=${periodicMesg}"\n=================================================================================\n"
	periodicMesg=${periodicMesg}"=== Server Status Automatic Monitoring Script (rev 0.1) =========================\n"
	periodicMesg=${periodicMesg}"=================================================================================\n\n"
	periodicMesg=${periodicMesg}"\n============ Server Default Informatione ========================================\n"
	periodicMesg=${periodicMesg}"$ServerInfo\n"
	periodicMesg=${periodicMesg}"=================================================================================\n"
	periodicMesg=${periodicMesg}"\n============ Server Using Physical Memory State =================================\n"
	periodicMesg=${periodicMesg}"Total Physical Memory : ${TotalPMem} M\n"
	periodicMesg=${periodicMesg}"Using Physical Memory : ${UsingPMem} M\n"
	periodicMesg=${periodicMesg}"Using / Total PMem Per : ${UsingPMemPer} %\n"
	periodicMesg=${periodicMesg}"=================================================================================\n"
	periodicMesg=${periodicMesg}"\n============ Server Using Virtual Memory State ==================================\n"
	periodicMesg=${periodicMesg}"Total Virtual Memory : ${TotalVRMem} M\n"
	periodicMesg=${periodicMesg}"Using Virtual Memory : ${UsingVRMem} M\n"
	periodicMesg=${periodicMesg}"Using / Total VRMem Per : ${UsingVRMemPer} %\n"
	periodicMesg=${periodicMesg}"=================================================================================\n"
	periodicMesg=${periodicMesg}"\n============ Server Process State ===============================================\n"
	periodicMesg=${periodicMesg}"[PROC_PATH / MEMORY]\n"
	periodicMesg=${periodicMesg}"${ProcessList}"
#	periodicMesg=${periodicMesg}"Others ${otherProcessSize} M\n"
	periodicMesg=${periodicMesg}"=================================================================================\n"
	periodicMesg=${periodicMesg}"\n============ Server Disk Free State =============================================\n"
	periodicMesg=${periodicMesg}"${freeDisksForMail[@]}"
	periodicMesg=${periodicMesg}"=================================================================================\n"
	periodicMesg=${periodicMesg}"\n============ Server Last Boot Time ==============================================\n"
	periodicMesg=${periodicMesg}${UpTime}
	periodicMesg=${periodicMesg}"=================================================================================\n\n"
	periodicMesg=${periodicMesg}"${DATE}\n"
	periodicMesg=${periodicMesg}"!! SSAMS (rev $SSAMS_REV) Copyright by YoWu (uyu423@gmail.com) -\n"
	periodicMesg=${periodicMesg}"\n\nEnd Of Mail"
}

loggingMonitoringData() {
	echo ""
}

EmergencyProcessing() {
	for Comm in "${EmergencyCommands[@]}"; do
		${Comm}
	done
}

checkedPMem() {
	TotalPMem=`free -m | grep -v total | grep -v buffers | grep -v Swap | awk '{ print $2 }'`
	UsingPMem=`free -m | grep -v total | grep -v Mem | grep -v Swap | awk '{ print $3 }'`
	UsingPMemPer=`expr \( $UsingPMem \* 100 \/ $TotalPMem \)`
}

checkedVRMem() {
	TotalVRMem=`free -m | grep Swap | awk '{ print $2 }'`
	UsingVRMem=`free -m | grep Swap | awk '{ print $3 }'`
	UsingVRMemPer=`expr \( $UsingVRMem \* 100 \/ $TotalVRMem \)`
}

checkedProc() {
	ProcessList=""
	getOtherProcComm="ps aux"
	for index in ${!MonitoringProcess[*]}; do
		ProcessList=${ProcessList}`ps aux | grep ${MonitoringProcess[$index]} | grep -v grep | awk '{print $11, $6}' | awk '{total = total + $2} END {print $1, total/1024}'`' M\n'
		getOtherProcComm=${getOtherProcComm}" | grep -v ${MonitoringProcess[$index]}"
	done
#	otherProcessSize=`${getOtherProcComm} | awk '{ print \$6 }' | awk '{total = total + \$1} END { print total/1024 }'`
#	echo ${getOtherProcComm}
}

checkedDiskFree() {
	i=0
	while read line; do
		freeDisks[$i]="$line\n"
		(( i++ ))
	done < <(df -m | grep -v Filesystem)
	i=0
	while read line; do
		freeDisksForMail[$i]="$line\n"
		(( i++ ))
	done < <(df -h)
}


checkedUptime() {
	UpTime=`last reboot | head -1`"\n"
}

isMemoryEmergency() {
	EmergMesg=""
#	UsingPMemPer=100
#	UsingVRMemPer=100
	if [ ${UsingPMemPer} -ge ${MaxUsingPMemPerBoundary} ]; then
		EmergMesg=${EmergMesg}"\n!! Out of Memory SOON !!\n\n"
		EmergMesg=${EmergMesg}"!! Server Memory Status \n\n"
		EmergMesg=${EmergMesg}"Total Physical Memory : ${TotalPMem} M\n"
		EmergMesg=${EmergMesg}"Using Physical Memory : ${UsingPMem} M\n"
		EmergMesg=${EmergMesg}"Using / Total PMem Per : ${UsingPMemPer} %\n\n"
		EmergMesg=${EmergMesg}"Total Virtual Memory : ${TotalVRMem} M\n"
		EmergMesg=${EmergMesg}"Using Virtual Memory : ${UsingVRMem} M\n"
		EmergMesg=${EmergMesg}"Using / Total VRMem Per : ${UsingVRMemPer} %\n\n"
		if [ ${UsingVRMemPer} -ge ${MaxUsingVRMemPerBoundary} ]; then
#			EmergencyProcessing
			NotifyLev="EMERGENCY"
			EmergMesg=${EmergMesg}"\n!! Notification Level : ${NotifyLev} !!\n"
			EmergMesg=${EmergMesg}"[Using PMem Per] >= ${MaxUsingPMemPerBoundary} %\n"
			EmergMesg=${EmergMesg}"[Using VRMem Per] >= ${MaxUsingVRMemPerBoundary} %\n"
			EmergMesg=${EmergMesg}"!! The Server has automatically execute the following command !!\n\n"
			for Comm in "${EmergencyCommands[@]}"; do
				EmergMesg=${EmergMesg}"${Comm}\n"
			done
		else
			NotifyLev="IMMEDIATE"
			EmergMesg=${EmergMesg}"\n!! Notification Level : ${NotifyLev} !!\n"
			EmergMesg=${EmergMesg}"[Using PMem Per] >= ${MaxUsingPMemPerBoundary} %, Only\n\n"
			EmergMesg=${EmergMesg}"so, The Server does not re-allocate Memory \n"
			EmergMesg=${EmergMesg}"required Notify Level, re-allocate Memory : Emergency \n"
			EmergMesg=${EmergMesg}"Emergency Level required : \n"
			EmergMesg=${EmergMesg}"[Using PMem Per] >= ${MaxUsingPMemPerBoundary} %\n"
			EmergMesg=${EmergMesg}"[Using VRMem Per] >= ${MaxUsingVRMemPerBoundary} %\n"
		fi
		EmergMesg=${EmergMesg}"\n\n${DATE}\n"
		EmergMesg=${EmergMesg}"!! SSAMS (rev $SSAMS_REV) Copyright by YoWu (uyu423@gmail.com) -\n"
		EmergMesg=${EmergMesg}"\n\nEnd Of Mail"
		sendingEmergencyMail "!! ${NotifyLev} '${HOSTNAME}' Server Status Report: Out of Memory Soon !!" "${EmergMesg}"
	fi
}

isDiskEmergency() {
	EmergMesg=""
	for freeDisk in "${freeDisks[@]}"; do
		totalDiskSize=`echo -e ${freeDisk} | awk '{ print $2 }'`
		usingDiskSize=`echo -e ${freeDisk} | awk '{ print $3 }'`
#		echo -e ${freeDisk}
#		echo -e ${totalDiskSize}
#		echo -e ${usingDiskSize}
		if [ ${usingDiskSize} -eq 0 ]; then
			continue
		else
			usingDiskPer=`expr \( $usingDiskSize \* 100 \/ $totalDiskSize \)`
#			echo -e ${usingDiskPer}
			if [ $usingDiskPer -ge $MaxUsingDiskBoundary ]; then
				EmergMesg=${EmergMesg}"\n!! Server Storage is FULL Soon !!\n\n"
				EmergMesg=${EmergMesg}"`echo -e ${freeDisk} | awk '{ print $1 }'`\n"
				EmergMesg=${EmergMesg}"Total : ${totalDiskSize} / Using : ${usingDiskSize} M/ Per : ${usingDiskPer} %\n\n"
				EmergMesg=${EmergMesg}"!! Please Clean up Server Storage !!\n\n"
				EmergMesg=${EmergMesg}"!! Additional Information !!\n"
				EmergMesg=${EmergMesg}"$ServerInfo\n\n"
				EmergMesg=${EmergMesg}"${DATE}\n"
				EmergMesg=${EmergMesg}"!! SSAMS (rev $SSAMS_REV) Copyright by YoWu (uyu423@gmail.com) -\n"
				EmergMesg=${EmergMesg}"\n\nEnd Of Mail"
				sendingEmergencyMail "!! EMERGENCY '${HOSTNAME}' Server Status Report: Storage FULL Soon !!" "${EmergMesg}"
			fi
		fi
	done
}

makeServerInfomation() {
	ServerInfo=""
	ServerInfo=${ServerInfo}"Hostname : $HOSTNAME\n"
	ServerInfo=${ServerInfo}"IP Address : `ip a s ${NetworkInterface} | awk '/inet / { print $2 }'`\n"
	ServerInfo=${ServerInfo}"Shell Type : $SHELL\n"
	ServerInfo=${ServerInfo}"Machine Type : $MACHTYPE\n"
	ServerInfo=${ServerInfo}"uname -a : `uname -a`\n"
	ServerInfo=${ServerInfo}"release : `cat /etc/issue`\n"
}

#Main Function Process
SSAMS_REV="0.1"
WhoAmI=`whoami`
DATE="!! Server Status Checked Datetime : "`date`
if [ "$WhoAmI" != "root" ]; then
	echo "ERROR : This script requires root privileges."
	exit
fi

makeServerInfomation

checkedPMem
checkedVRMem
isMemoryEmergency

sleep 2

checkedDiskFree
isDiskEmergency

checkedProc
checkedUptime

counting

sleep 2

if [ $NowMonitoringCnt -ge $MaxMonitoringCnt ]; then
	makePreodicalMailContents
	sendingPreodicalMail
	countingReset
fi
