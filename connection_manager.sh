#!/bin/bash
#
# Script to call wvdial and continuosly check
# the connection. If its lost, redial
#
CONF=tmobile
LOGF=/var/log/connection.log
LOGCMD="logger -s"

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

check() {
	# 1st check: Are the commands running?
	WPID=$(pgrep wvdial)
	PPPPID=$(pgrep pppd)
	if [ -z ${PPPPID} ] || [ -z ${WPID} ] ; then
		$LOGCMD "pppd and/or dialer not running"
		RET=1
	# 2nd check: the connection is really up?
	# TODO: best method? pings? AT commands?
	#elif [ ] ; then
		
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
	check 
	[ $RET -eq 1 ] && reconnect
	[ $RET -eq 2 ] && /sbin/reboot

done

