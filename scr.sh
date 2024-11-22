#!/bin/bash
source conf.cfg

prev_value=""

out=$(mmcli -L)
m_id=$(echo "$out" | grep -oP '/org/freedesktop/ModemManager1/Modem/\K\d+')
PID=null

qmi_id=$(mmcli -m $m_id | grep -oP "primary port: '\K[^']+")

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

	input=$(qmicli -d /dev/$qmi_id --nas-get-serving-system)

	# Extract MCC, MNC, cellID and TAC
	mcc=$(echo "$input" | grep -oP "MCC: '\K\d+")
	mnc=$(echo "$input" | grep -oP "MNC: '\K\d+")
	cellid=$(echo "$input" | grep -oP "3GPP cell ID: '\K\d+")
	tac=$(echo "$input" | grep -oP "LTE tracking area code: '\K\d+")

	echo MCC:"$mcc" MNC:"$mnc" CELL_ID:"$cellid" TAC:"$tac" - $(date +"%T") "|" PID: "$PID"

	if [[ -n "$PID" && "$PID" != "null" ]]; then
		kill $PID
	fi

	if [[ "$current_value" != "$prev_value" ]]; then

		echo -e "\e[31mCell change detected\e[0m"
		# /home/taltech/SUPL-3GPP-LPP-client/build/example-lpp osr -f rtcm -h 129.192.82.125 -p 5431 --imsi=248010203229380 -c "$mcc" -n "$mnc" -t "$tac" -i 2 --tcp=192.168.3.1 --tcp-port=3000 & #>output.txt 2>&1 &
		# PID=$!
	else

		# /home/taltech/SUPL-3GPP-LPP-client/build/example-lpp osr -f rtcm -h 129.192.82.125 -p 5431 --imsi=248010203229380 -c "$mcc" -n "$mnc" -t "$tac" -i 1 --tcp=192.168.3.1 --tcp-port=3000 & #>output.txt 2>&1 &
		# PID=$!
	fi

	prev_value="$cellid"

	sleep $TIME

done
