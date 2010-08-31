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
i=0

connect() {
	$LOGCMD "Starting wvdial connection"
	[ -n ${CONF} ] && wvdial ${CONF} &
	[ $? -eq 1 ] && $LOGCMD "Modem not responding" 
	sleep 8
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
	sleep 2
	PPPPID=$(pgrep pppd)
	[ -n $? ] && [ $? -ne 0 ] && terminate
}

update_diff_counter() {
# check for received data segments
	T0=$(netstat -st|grep -A 8 Tcp:|grep "segments received"|cut -d" " -f 5)
	ping -c2 google.com &> /dev/null
	sleep 4
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
	elif [ $T1 -eq 0 ]; then
		let i++
		if [ $i -eq 7 ]; then
			i=0
			RET=1
		elif [ $i -gt 10 ]; then
			RET=2
		else
			RET=0
		fi
	else
		i=0
		RET=0
	fi
}


# Start...
touch $LOGF
connect

# Main loop
while true; do
# different treatment to different problems
	update_diff_counter
	check 
	echo T0 $T0 - T1 $T1 - i $i
	[ $RET -eq 1 ] && reconnect
	[ $RET -eq 2 ] && echo REBOOT
done

