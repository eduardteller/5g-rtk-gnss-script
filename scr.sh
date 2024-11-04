#!/bin/bash
source conf.cfg

prev_value=""

out=$(mmcli -L)
m_id=$(echo "$out" | grep -oP '/org/freedesktop/ModemManager1/Modem/\K\d+')
PID=null

# Function to handle cleanup on exit
cleanup() {
	if [[ -n "$PID" && "$PID" != "null" ]]; then
		kill $PID
	fi
	exit 0
}

# Trap SIGINT (Ctrl+C) and call the cleanup function
trap cleanup SIGINT

while true; do

	current_value=$(mmcli -m "$m_id" --command='AT+QENG="servingcell"' | grep '+QENG: "LTE"' | awk -F, '{mcc=$3; mnc=$4; cellid=$5; print mcc, mnc, cellid}' | while read -r mcc mnc cellid; do printf "%s %s %d\n" "$mcc" "$mnc" "$((16#$cellid))"; done)

	read -r mcc mnc cellid <<<"$current_value"
	echo MCC:"$mcc" MNC:"$mnc" CELL_ID:"$cellid" - $(date +"%T")

	if [[ -n "$PID" && "$PID" != "null" ]]; then
		kill $PID
	fi

	if [[ "$current_value" != "$prev_value" ]]; then

		echo "Cell change detected"
		/home/taltech/SUPL-3GPP-LPP-client/build/example-lpp osr -f rtcm -h 129.192.82.125 -p 5431 --imsi=248010203229380 -c "$mcc" -n "$mnc" -t 1 -i 2 --tcp=192.168.3.1 --tcp-port=3000 >/dev/null &
		PID=$!

	else

		/home/taltech/SUPL-3GPP-LPP-client/build/example-lpp osr -f rtcm -h 129.192.82.125 -p 5431 --imsi=248010203229380 -c "$mcc" -n "$mnc" -t 1 -i 1 --tcp=192.168.3.1 --tcp-port=3000 >/dev/null &
		PID=$!

	fi

	prev_value="$current_value"

	sleep $TIME

done
