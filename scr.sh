#!/bin/bash
source conf.cfg

prev_value=""

out=$(mmcli -L)
m_id=$(echo "$out" | grep -oP '/org/freedesktop/ModemManager1/Modem/\K\d+')
PID=null

echo "Modem ID: $m_id"

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

	input=$(mmcli -m $m_id --location-get)

	# Extract MCC, MNC, LAC, TAC, and Cell ID
	mcc=$(echo "$input" | grep -oP '(?<=operator mcc: )\d+')
	mnc=$(echo "$input" | grep -oP '(?<=operator mnc: )\d+')
	tac=$(echo "$input" | grep -oP '(?<=tracking area code: )\d+')
	cell_id_hex=$(echo "$input" | grep -oP '(?<=cell id: )\w+')

	# Convert Cell ID from hexadecimal to decimal
	cell_id_dec=$((16#$cell_id_hex))

	echo MCC:"$mcc" MNC:"$mnc" CELL_ID:"$cell_id_dec" TAC:"$tac" - $(date +"%T") "|" PID: "$PID"

	if [[ -n "$PID" && "$PID" != "null" ]]; then
		kill $PID
	fi

	if [[ "$cell_id_dec" != "$prev_value" ]]; then

		echo -e "\e[31mCell change detected\e[0m"
		/home/taltech/Desktop/5g-gnss/build/example-lpp osr -f rtcm -h 129.192.82.125 -p 5431 --imsi=248010203229380 -c "$mcc" -n "$mnc" -t "$tac" -i 2 --tcp=192.168.3.1 --tcp-port=3000 & #>output.txt 2>&1 &
		PID=$!
	else

		/home/taltech/Desktop/5g-gnss/build/example-lpp osr -f rtcm -h 129.192.82.125 -p 5431 --imsi=248010203229380 -c "$mcc" -n "$mnc" -t "$tac" -i 1 --tcp=192.168.3.1 --tcp-port=3000 & #>output.txt 2>&1 &
		PID=$!
	fi

	prev_value="$cell_id_dec"

	sleep $TIME

done
