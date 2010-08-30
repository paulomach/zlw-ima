#!/bin/bash
#
# Script to call wvdial and continuosly check
# the connection. If its lost, redial
#
CONF=tmobile
LOGF=/var/log/connection.log
LOGCMD="logger -s"
T0=0
T1=0

connect() {
	$LOGCMD "Starting wvdial connection"
	[ -n ${CONF} ] && wvdial ${CONF} &
	[ $? -eq 1 ] && $LOGCMD "Modem not responding" 
	sleep 3
	WPID=$(pgrep wvdial)
	PPPPID=$(pgrep pppd)
	[ $? -ne 0 ] && connect || $LOGCMD "Connection stabilished"
}

reconnect() {
	$LOGCMD "Reconnection"
	terminate
	connect
}

terminate() {
	$LOGCMD "Killing connection"
	kill -9 ${PPPPID} ${WPID}
	sleep 3
	PPPPID=$(pgrep pppd)
	[ -n $? ] && [ $? -ne 0 ] && terminate
}

update_diff_counter() {
	T0=$(netstat -st|grep -A 8 Tcp:|grep "segments received"|cut -d" " -f 5)
	ping -c1 google.com &> /dev/null
	sleep 1
	let T1=$(netstat -st|grep -A 8 Tcp:|grep "segments received"|cut -d" " -f 5)-$T0
}

check() {
	# 1st check: Are the commands running?
	WPID=$(pgrep wvdial)
	PPPPID=$(pgrep pppd)
	if [ -z ${PPPPID} ] || [ -z ${WPID} ] ; then
		$LOGCMD "pppd and/or dialer not running"
		RET=1
	# 2nd check: the connection is really up?
	# TODO: pings tunnel? AT commands?
	update_diff_counter	
	elif [ $T1 -eq 0 ]; then
		RET=1
	else 
		RET=0
	fi
}


# Start...
touch $LOGF
connect

# Main loop
while true; do
# different treatment to different problems
	sleep 7
	check 
	[ $RET -eq 1 ] && reconnect
	[ $RET -eq 2 ] && /sbin/reboot

done

