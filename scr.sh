#!/bin/bash

# Saame konfiguratsiooni failist muutja TIME väärtuse
source conf.cfg

prev_value=""
PID=0

# Leiame 5g Modemi ID
out=$(mmcli -L)
m_id=$(echo "$out" | grep -oP '/org/freedesktop/ModemManager1/Modem/\K\d+')

echo "Modem ID: $m_id"

# Cleanup funktsioon, mis käivitatakse skripti lõpetamisel, kustutab ericcsoni programmi protsessi, kui see on käimas.
cleanup() {
	if [[ "$PID" -ne 0 ]]; then
		kill -9 "$PID"
	fi
	exit 0
}

# Püüa SIGINT signaal ja käivita cleanup funktsioon
trap cleanup SIGINT

while true; do

	# Leiame ModemManageri abil asukoha andmed
	input=$(mmcli -m $m_id --location-get)

	echo "$input"

	# Loeme väljundist vajalikud andmed (MCC, MNC, TAC, Cell ID)
	mcc=$(echo "$input" | grep -oP '(?<=operator mcc: )\d+')
	mnc=$(echo "$input" | grep -oP '(?<=operator mnc: )\d+')
	tac=$(echo "$input" | grep -oP '(?<=tracking area code: )\d+')
	cell_id_hex=$(echo "$input" | grep -oP '(?<=cell id: )\w+')

	# Teisendame hex kujul oleva cell id dec kujule
	cell_id_dec=$((16#$cell_id_hex))

	# Printime muutujad välja
	echo MCC:"$mcc" MNC:"$mnc" CELL_ID:"$cell_id_dec" TAC:"$tac" - $(date +"%T") "|" PID: "$PID"

	# Kui ericssoni programmi protsess eelmisest loopi iteratsioonist on käimas, siis tapa see
	if [[ "$PID" -ne 0 ]]; then
		kill -9 $PID
	fi

	# Kui cell id on muutunud, siis käivita ericssoni programm uuesti -i 2 reziimis ja väljasta vastav teade
	if [[ "$cell_id_dec" != "$prev_value" ]]; then

		echo -e "\e[31mCell change detected\e[0m"

		/home/taltech/Desktop/5g-gnss/build/example-lpp osr -f rtcm -h 129.192.82.103 -p 5431 --imsi=248010203229380 -c "$mcc" -n "$mnc" -t "$tac" -i 2 --tcp=192.168.3.1 --tcp-port=3000 & #>output.txt 2>&1 &

		# Salvestame protsessi ID, et saaksime seda hiljem vajadusel lõpetada
		PID=$!

		# Kui cell id ei ole muutunud, siis käivita ericssoni programm uuesti -i 1 reziimis
	else

		/home/taltech/Desktop/5g-gnss/build/example-lpp osr -f rtcm -h 129.192.82.103 -p 5431 --imsi=248010203229380 -c "$mcc" -n "$mnc" -t "$tac" -i 1 --tcp=192.168.3.1 --tcp-port=3000 & #>output.txt 2>&1 &

		# Salvestame protsessi ID, et saaksime seda hiljem vajadusel lõpetada
		PID=$!

	fi

	# Salvestame eelmise cell id väärtuse, et saaksime järgmisel loopi iteratsioonil kontrollida, kas cell id on muutunud
	prev_value="$cell_id_dec"

	# Ootame TIME sekundit enne järgmise loopi iteratsiooni
	sleep $TIME

done
