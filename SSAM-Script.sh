#!/bin/bash

########################################
#### Server Status Automatic        ####
#### Monitoring Script(SSAM-Script) ####
########################################
#### Autor : Yowu (uyu423@gmail.com) ###
#### Github : uyu423/SSAM-Script     ###
########################################

########################################
#### User Custom Value Settings     ####
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

AllowIpList=(
	"127.0.0.1"
	"192.168.0.*"
#	"203.229.*"
)

MaxUsingPMemPerBoundary=95
MaxUsingVRMemPerBoundary=70
MaxUsingDiskBoundary=95
MaxMonitoringCnt=128
LoginHistoryCount=10
NetworkInterface="eth0"

# For Test Command " $ sudo ./SSAM-Script.sh test "
env=$1
if [ "${env}" == "test" ]; then
	MaxMonitoringCnt=1
	MaxUsingPMemPerBoundary=1
#	MaxUsingDiskBoundary=1	#for Testing
fi
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
#	rm -rf ${countFile}
	echo -e "0" > ${countFile}
}
########################################

########################################
sendingMail() {
# if env == "test" not sending meail. only showing terminal.
	for index in ${!mailingList[*]}; do
		if [ ${index} -ne 0 ]; then
			mailingListString=${mailingListString}", "
		fi	
		mailingListString=${mailingListString}"${mailingList[$index]}"
	done
	if [ "${env}" == "test" ]; then
		echo -e "${periodicMesg}"
		echo -e "${EmergMesg}"
		echo $mailingListString
	else
		mail -s "[SSAM-Script] $1" ${mailingListString} < "$2"
	fi	
	mailingListString="";
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
	periodicMesg=${periodicMesg}"Physical Memory(Real) Size : ${TotalPMem} M\n"
	periodicMesg=${periodicMesg}"Physical Memory(Real) Used : ${UsingPMem} M\n"
	periodicMesg=${periodicMesg}"Physical Mem(Real) Used % : ${UsingPMemPer} %\n"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Using Virtual Memory Status ==\n"
	periodicMesg=${periodicMesg}"Virtual Memory(Swap) Size : ${TotalVRMem} M\n"
	periodicMesg=${periodicMesg}"Virtual Memory(Swap) Used : ${UsingVRMem} M\n"
	periodicMesg=${periodicMesg}"Virtual Mem(Swap) Used % : ${UsingVRMemPer} %\n"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Process Status (NAME USEDMEM) ==\n"
	periodicMesg=${periodicMesg}"${ProcessList}"
#	periodicMesg=${periodicMesg}"Others ${otherProcessSize} M\n"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Disk Partition Status ==\n"
	periodicMesg=${periodicMesg}"${freeDisksForMail[@]}"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Login History ==\n"
	periodicMesg=${periodicMesg}"Allow IP List : ${AllowIpListPretty}\n"
	periodicMesg=${periodicMesg}"${loginHistorys[@]}"
	periodicMesg=${periodicMesg}"==\n"
	periodicMesg=${periodicMesg}"\n== Server Boot Time Last 5 Log ==\n"
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
		freeDisks[$i]="$line\n"; (( i++ ))
	done < <(df -m | grep -v Filesystem)
	i=0
	while read line; do
		freeDisksForMail[$i]="$line\n"; (( i++ ))
	done < <(df -h)
}
########################################

########################################
checkedLoginHistory() {
	for index in ${!AllowIpList[*]}; do
		AllowIpListString=${AllowIpListString}"|${AllowIpList[$index]}"
		AllowIpListPretty=${AllowIpListPretty}" / ${AllowIpList[$index]}"
	done
	i=0; while read line; do
		loginHistorys[$i]="$line\n"; (( i++ ))
	done < <(last | egrep -v "(reboot${AllowIpListString})" | head -$1)
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

getAllProcessInfo() {
	i=0; while read line; do
		allProcInfo[$i]="$line\n"
		(( i++ ))
	done < <(ps -eo user,rss,size,vsize,pmem,pcpu,comm --sort -rss | head -n $1)
}

isMemoryEmergency() {
	getAllProcessInfo 30
	EmergMesg=""
#	UsingPMemPer=100
#	UsingVRMemPer=100
	if [ ${UsingPMemPer} -ge ${MaxUsingPMemPerBoundary} ]; then
		EmergMesg=${EmergMesg}"\n!! Out of Memory SOON !!\n\n"
		EmergMesg=${EmergMesg}"!! Server Memory Status \n\n"
		EmergMesg=${EmergMesg}"Physical Memory(Real) Size : ${TotalPMem} M\n"
		EmergMesg=${EmergMesg}"Physical Memory(Real) Used : ${UsingPMem} M\n"
		EmergMesg=${EmergMesg}"Physical Mem(Real) % : ${UsingPMemPer} %\n\n"
		EmergMesg=${EmergMesg}"Virtual Memory(Swap) Size : ${TotalVRMem} M\n"
		EmergMesg=${EmergMesg}"Virtual Memory(Swap) Used : ${UsingVRMem} M\n"
		EmergMesg=${EmergMesg}"Virtual Mem(Swap) Used % : ${UsingVRMemPer} %\n\n"
		EmergMesg=${EmergMesg}"!! Server Process Status (by User Process list)\n"
		EmergMesg=${EmergMesg}"${ProcessList}\n\n"
		EmergMesg=${EmergMesg}"!! Server Process Status (by System ps command)\n"
		EmergMesg=${EmergMesg}"${allProcInfo[@]}\n\n"
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
		EmergMesg=${EmergMesg}"!! SSAM-Script (rev $SSAMScript_REV) has a GPL v2 License (https://github.com/uyu423/SSAM-Script) -\n"
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
				EmergMesg=${EmergMesg}"!! SSAM-Script (rev $SSAMScript_REV) has a GPL v2 License (https://github.com/uyu423/SSAM-Script) -\n"
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
	ServerInfo=${ServerInfo}"Hostname : ${HOSTNAME}\n"
	ServerInfo=${ServerInfo}"Server IP Address : `/sbin/ip a s ${NetworkInterface} | awk '/inet / { print $2 }'`\n"
#	ServerInfo=${ServerInfo}"Public IP Address : `curl bot.whatismyipaddress.com 2> /dev/null`\n"	#slowly
	ServerInfo=${ServerInfo}"Public IP Address : `wget http://ipecho.net/plain -O - -q ; echo 2> /dev/null`\n"
	ServerInfo=${ServerInfo}"Shell Type : ${SHELL}\n"
	ServerInfo=${ServerInfo}"Machine Type : ${MACHTYPE}\n"
	ServerInfo=${ServerInfo}"Uname ALL : `uname -a`\n"
	ServerInfo=${ServerInfo}"Release Information : ${ReleaseInfo[@]}"
}

########################################
#### Main Function Process #############
########################################
SSAMScript_REV="0.2.0"
WhoAmI=`whoami`
DATE="!! Server Status Checked Datetime : "`date`
if [ "$WhoAmI" != "root" ]; then
	echo "ERROR : This script requires root privileges."
	exit
fi

initSSAMScript

checkedProc
checkedUptime
checkedLoginHistory $LoginHistoryCount

checkedPMem
checkedVRMem
isMemoryEmergency

sleep 1

checkedDiskFree
isDiskEmergency

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
