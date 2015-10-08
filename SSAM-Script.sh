#!/bin/bash

########################################
#### User Custom Value Settings ########
########################################
#SenderName="SSAMS"
mailingList=(
	"uyu423@gmail.com"
#	"foo@bar.com"
#	"yourID@yourDomain.com"
)

MonitoringProcess=(
#	'httpd' 
	'apache2'
	'mysqld' 
	'java' 
	'Passenger' 
	'sshd'
)
EmergencyCommands=(
	"service httpd restart"
	"service mysqld restart"
#	"/etc/init.d/tomcat7 restart"
#	"init 6"
)

MaxUsingPMemPerBoundary=95
MaxUsingVRMemPerBoundary=70
#MaxUsingDiskBoundary=1	#for Testing
MaxUsingDiskBoundary=95
#MaxMonitoringCnt=1	#for Testing
MaxMonitoringCnt=128
NetworkInterface="eth0"
########################################
########################################


########################################
#### Script Value Settings #############
########################################
Dir="/var/log/SSAM-Script"
FileName="SSAM-Script"
countFile="${Dir}/${FileName}.cnt"
logFile="${Dir}/${FileName}.log"
mailFile="${Dir}/${FileName}.mail"
emergFile="${Dir}/${FileName}.emerg"
########################################

########################################
initSSAMScript() {
	if [ ! -d ${Dir} ]; then
		mkdir ${Dir}
	fi
	touch ${countFile}
	touch ${logFile}
	touch ${mailFile}
	touch ${emergFile}
}
########################################

########################################
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
########################################

########################################
sendingMail() {
	for mail in "${mailingList[@]}"; do
#		mail -a "From: ${SenderName} <${WhoAmI}@${HOSTNAME}>" -s "[SSAM-Script] $1" ${mail} < "$2"
		mail -s "[SSAM-Script] $1" ${mail} < "$2"
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
	periodicMesg=${periodicMesg}"\n\n==== Server Status Automatic Monitoring Script (rev ${SSAMScript_REV}) ====\n\n\n"
	periodicMesg=${periodicMesg}"\n== Server Default Informatione ==\n"
	periodicMesg=${periodicMesg}"$ServerInfo\n"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Using Physical Memory Status ==\n"
	periodicMesg=${periodicMesg}"Physical Memory(Real) Size\t: ${TotalPMem} M\n"
	periodicMesg=${periodicMesg}"Physical Memory(Real) Used\t: ${UsingPMem} M\n"
	periodicMesg=${periodicMesg}"Physical Mem(Real) Used %\t: ${UsingPMemPer} %\n"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Using Virtual Memory Status ==\n"
	periodicMesg=${periodicMesg}"Virtual Memory(Swap) Size\t: ${TotalVRMem} M\n"
	periodicMesg=${periodicMesg}"Virtual Memory(Swap) Used\t: ${UsingVRMem} M\n"
	periodicMesg=${periodicMesg}"Virtual Mem(Swap) Used %\t: ${UsingVRMemPer} %\n"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Process Status (ProcName UsedMem) ==\n"
	periodicMesg=${periodicMesg}"${ProcessList}"
#	periodicMesg=${periodicMesg}"Others ${otherProcessSize} M\n"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Disk Free Status ==\n"
	periodicMesg=${periodicMesg}"${freeDisksForMail[@]}"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Boot Last 5 Time Log ==\n"
	periodicMesg=${periodicMesg}${UpTime[@]}
	periodicMesg=${periodicMesg}"\nLog End\n"
	periodicMesg=${periodicMesg}"==\n\n"
	periodicMesg=${periodicMesg}"${DATE}\n\n"
	periodicMesg=${periodicMesg}"==== SSAM-Script (rev $SSAMScript_REV) has a GPL v2 License (https://github.com/uyu423/SSAM-Script) ====\n"
	periodicMesg=${periodicMesg}"\n\nEnd Of Report"
}
########################################

loggingMonitoringData() {
	echo ""
}

########################################
checkedPMem() {
	TotalPMem=`free -m | grep -v total | grep -v buffers | grep -v Swap | awk '{ print $2 }'`
	UsingPMem=`free -m | grep -v total | grep -v Mem | grep -v Swap | awk '{ print $3 }'`
	UsingPMemPer=`expr \( $UsingPMem \* 100 \/ $TotalPMem \)`
}
########################################

########################################
checkedVRMem() {
	TotalVRMem=`free -m | grep Swap | awk '{ print $2 }'`
	UsingVRMem=`free -m | grep Swap | awk '{ print $3 }'`
	UsingVRMemPer=`expr \( $UsingVRMem \* 100 \/ $TotalVRMem \)`
}
########################################

########################################
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
########################################

########################################
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
########################################


########################################
checkedUptime() {
	i=0; while read line; do
		UpTime[$i]="$line\n"
		(( i++ ))
	done < <(last reboot | head -5)
}
########################################

########################################
MemoryEmergencyProcessing() {
	for Comm in "${EmergencyCommands[@]}"; do
		${Comm}
	done
}

isMemoryEmergency() {
	EmergMesg=""
#	UsingPMemPer=100
#	UsingVRMemPer=100
	if [ ${UsingPMemPer} -ge ${MaxUsingPMemPerBoundary} ]; then
		EmergMesg=${EmergMesg}"\n!! Out of Memory SOON !!\n\n"
		EmergMesg=${EmergMesg}"!! Server Memory Status \n\n"
		EmergMesg=${EmergMesg}"Physical Memory(Real) Size\t: ${TotalPMem} M\n"
		EmergMesg=${EmergMesg}"Physical Memory(Real) Used\t: ${UsingPMem} M\n"
		EmergMesg=${EmergMesg}"Physical Mem(Real) %\t: ${UsingPMemPer} %\n\n"
		EmergMesg=${EmergMesg}"Virtual Memory(Swap) Size\t: ${TotalVRMem} M\n"
		EmergMesg=${EmergMesg}"Virtual Memory(Swap) Used\t: ${UsingVRMem} M\n"
		EmergMesg=${EmergMesg}"Virtual Mem(Swap) Used %\t: ${UsingVRMemPer} %\n\n"
		if [ ${UsingVRMemPer} -ge ${MaxUsingVRMemPerBoundary} ]; then
			MemoryEmergencyProcessing
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
		EmergMesg=${EmergMesg}"!! SSAM-Script (rev $SSAMScript_REV) Copyright by YoWu (uyu423@gmail.com) -\n"
		EmergMesg=${EmergMesg}"\n\nEnd Of Report"
		sendingEmergencyMail "${NotifyLev} '${HOSTNAME}' Server Status Report: Out of Memory Soon !!" "${EmergMesg}"
	fi
}
########################################

########################################
DiskEmergencyProcessing() {
	echo ""
}
isDiskEmergency() {
	EmergMesg=""
	for freeDisk in "${freeDisks[@]}"; do
		totalDiskSize=`echo -e ${freeDisk} | awk '{ print $2 }'`
		usingDiskSize=`echo -e ${freeDisk} | awk '{ print $3 }'`
#		echo -e ${freeDisk}; echo -e ${totalDiskSize}; echo -e ${usingDiskSize} #for Debug
		if [ ${usingDiskSize} -eq 0 ]; then
			continue
		else
			usingDiskPer=`expr \( $usingDiskSize \* 100 \/ $totalDiskSize \)`
#			echo -e ${usingDiskPer}	# for Debug
			if [ $usingDiskPer -ge $MaxUsingDiskBoundary ]; then
#				DiskEmergencyProcessing	# Not Define
				EmergMesg=${EmergMesg}"\n!! Server Storage is FULL Soon !!\n\n"
				EmergMesg=${EmergMesg}"`echo -e \"${freeDisk}\" | awk '{ print $1, $6 }'`\n"
				EmergMesg=${EmergMesg}"Total : ${totalDiskSize} / Using : ${usingDiskSize} M/ Per : ${usingDiskPer} %\n\n"
				EmergMesg=${EmergMesg}"!! Please Clean up Server Storage !!\n\n"
				EmergMesg=${EmergMesg}"!! Additional Information !!\n"
				EmergMesg=${EmergMesg}"${ServerInfo}\n\n"
				EmergMesg=${EmergMesg}"${DATE}\n"
				EmergMesg=${EmergMesg}"!! SSAM-Script (rev $SSAMScript_REV) Copyright by YoWu (uyu423@gmail.com) -\n"
				EmergMesg=${EmergMesg}"\n\nEnd Of Report"
				sendingEmergencyMail "EMERGENCY '${HOSTNAME}' Server Status Report: Storage FULL Soon !!" "${EmergMesg}"
			fi
		fi
	done
}
########################################

########################################
makeServerInfomation() {
	i=0
	while read line; do
		ReleaseInfo[$i]="$line\n"
		(( i++ ))
	done < <(find /etc/*-release | xargs cat | head -6)
	ServerInfo=""
	ServerInfo=${ServerInfo}"Hostname\t: $HOSTNAME\n"
	ServerInfo=${ServerInfo}"Server IP Address\t: `ip a s ${NetworkInterface} | awk '/inet / { print $2 }'`\n"
#	ServerInfo=${ServerInfo}"Public IP Address : `curl bot.whatismyipaddress.com 2> /dev/null`\n"	#slowly
	ServerInfo=${ServerInfo}"Public IP Address\t: `wget http://ipecho.net/plain -O - -q ; echo 2> /dev/null`\n"
	ServerInfo=${ServerInfo}"Shell Type\t: $SHELL\n"
	ServerInfo=${ServerInfo}"Machine Type\t: $MACHTYPE\n"
	ServerInfo=${ServerInfo}"Uname ALL\t: `uname -a`\n"
	ServerInfo=${ServerInfo}"Release Information\t: \n${ReleaseInfo[@]}"
}

########################################
#### Main Function Process #############
########################################
SSAMScript_REV="0.1.2"
WhoAmI=`whoami`
DATE="!! Server Status Checked Datetime : "`date`
if [ "$WhoAmI" != "root" ]; then
	echo "ERROR : This script requires root privileges."
	exit
fi

initSSAMScript

checkedPMem
checkedVRMem
isMemoryEmergency

sleep 1

checkedDiskFree
isDiskEmergency

checkedProc
checkedUptime

counting

sleep 1

# Periodical reports sent checks
if [ $NowMonitoringCnt -ge $MaxMonitoringCnt ]; then
	makeServerInfomation
	makePreodicalMailContents
	sendingPreodicalMail
	countingReset
fi
########################################
