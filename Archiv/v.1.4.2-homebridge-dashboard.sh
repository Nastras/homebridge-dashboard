#!/bin/bash
# Name: homebridge-dashboard.sh
# Version: 1.4.2
# Autor: sschuste & Nastra (SmartApfel Forum)
# Link: https://github.com/Nastras/homebridge-dashboard

TEMP=`getopt -o l:p: --long lang:,path: -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

while true; do
	case "$1" in
		-l | --lang ) I18N_FILE=$2; shift 2 ;;
		-p | --path ) I18N_PATH=$2; shift 2 ;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

# Did we get the I18N_FILE via a command line argument? If not, then grep it from locale.
if [ "x$I18N_FILE" == "x" ]; then
	I18N_FILE=$(locale | grep "LC_CTYPE" | awk -F= '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d \")

	# If we still don't know the language, set it to english
  	if [ "x$I18N_FILE" == "x" ]; then
		I18N_FILE="en_gb.utf-8"
	fi
fi

# Did we get the path to the i18n file via a command line argument? 
if [ ! -z $I18N_PATH ]; then 
	# Yes, we got a path as command line argument
	I18N_PATH="$I18N_PATH/"
	if [ ! -f "$I18N_PATH$I18N_FILE" ]; then
		echo "Couldn't find $I18N_PATH$I18N_FILE. Exiting."
		exit 1
	fi
else
	# No, there was no path in command line argument
	DEFAULT_PATH="/usr/local/share/homebridge-dashboard/"
	if [ ! -f "$DEFAULT_PATH$I18N_FILE" ]; then
		echo "Couldn't find $DEFAULT_PATH$I18N_FILE. Exiting."
		exit 1
	else
		I18N_PATH=$DEFAULT_PATH
	fi
fi

. "$I18N_PATH$I18N_FILE" 
export POSIXLY_CORRECT=1

function output {
	case "$1" in
		red)
		COLOR="\e[1;31m"
		;;
		green)
		COLOR="\e[1;32m"
		;;
		yellow)
		COLOR="\e[1;33m"
		;;
		magenta)
		COLOR="\e[1;35m"
		;;
		cyan)
		COLOR="\e[1;36m"
		;;
		white)
		COLOR="\e[1;97m"
		;;
	esac

	let DOTS=21-$(echo -n $2 | wc -m)
        FILL=$(echo $(for i in $(seq 1 $DOTS); do printf "."; done))
        echo -e "\e[0;35m$4\e[0;97m$2$FILL: $COLOR$3"
}


# Datum
DATUM=`date +"%A, %e %B %Y"`

# Zeit
ZEIT=`date +"%H:%M:%S %Z"`

# Modell
MODELL=`cat /sys/firmware/devicetree/base/model | tr -d '\0'`

# System
SYSTEM=`hostnamectl | grep System | awk -F: '{print $2}' | xargs`

# Kernel
KERNEL=`uname -rs`

# Uptime
UP0=`cut -d. -f1 /proc/uptime`
UP1=$(($UP0/86400))		# Tage
UP2=$(($UP0/3600%24))	# Stunden
UP3=$(($UP0/60%60))		# Minuten
UP4=$(($UP0%60))		# Sekunden
UPTIME="$UP1 $DISPLAY_DAYS, $UP2:$UP3 $DISPLAY_HOURS"

# Durchschnittliche Auslasung
LOAD1=`cat /proc/loadavg | awk '{print $1}'`	# Letzte Minute
LOAD5=`cat /proc/loadavg | awk '{print $2}'`	# Letzte 5 Minuten
LOAD15=`cat /proc/loadavg | awk '{print $3}'`	# Letzte 15 Minuten
LOAD="$LOAD1 ($DISPLAY_LOAD1) | $LOAD5 ($DISPLAY_LOAD5) | $LOAD15 ($DISPLAY_LOAD15)"

# Arbeitsspeicher
RAM1=`free -h --mega | grep 'Mem' | awk '{print $2}'`	# Total
RAM2=`free -h --mega | grep 'Mem' | awk '{print $3}'`	# Used
RAM3=`free -h --mega | grep 'Mem' | awk '{print $4}'`	# Free
RAM4=`free -h --mega | grep 'Swap' | awk '{print $3}'`	# Swap used
RAM="$DISPLAY_RAMTOTAL: $RAM1 | $DISPLAY_RAMUSED: $RAM2 | $DISPLAY_RAMFREE: $RAM3 | $DISPLAY_RAMSWAP: $RAM4"

# Temperatur
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
if [ "$DISPLAY_TEMPUNIT" == "C" ]; then
	TEMP=$(awk -v TEMP=$TEMP 'BEGIN { printf "%.1f",TEMP/1000 }')
fi
if [ "$DISPLAY_TEMPUNIT" == "F" ]; then
	TEMP=$(awk -v TEMP=$TEMP 'BEGIN { printf "%.1f",((9/5) * TEMP/1000) +32 }')
fi
TEMP="$TEMPº $DISPLAY_TEMPUNIT"


# Speicher verbunden
SPEICHERSD=`lsblk | grep -w mmcblk0 | grep -i disk | awk '{print $1}'`
SPEICHERUSB1=`lsblk | grep -w sda | grep -i disk | awk '{print $1}'`
SPEICHERUSB2=`lsblk | grep -w sdb | grep -i disk | awk '{print $1}'`
SPEICHERUSB3=`lsblk | grep -w sdc | grep -i disk | awk '{print $1}'`
SPEICHERUSB4=`lsblk | grep -w sdd | grep -i disk | awk '{print $1}'`
DISKS="SD: $SPEICHERSD | USB1: $SPEICHERUSB1 | USB2: $SPEICHERUSB2 | USB3: $SPEICHERUSB3 | USB4: $SPEICHERUSB4"

# Speicherbeleguwng
DISK1=`df -h | grep 'dev/root' | awk '{print $2}'`	# Gesamtspeicher
DISK2=`df -h | grep 'dev/root' | awk '{print $3}'`	# Belegt
DISK3=`df -h | grep 'dev/root' | awk '{print $4}'`	# Frei
CAPACITY="$DISPLAY_DISKTOTAL: $DISK1 | $DISPLAY_DISKUSED: $DISK2 | $DISPLAY_DISKFREE: $DISK3"

# Hostname
HOSTNAME=`hostname -f`

# IP-Adressen ermitteln
if ( /sbin/ifconfig | grep -q "eth0" ) ; then IP_LAN=`ifconfig eth0 | grep "inet" | cut -d ":" -f 2 | awk '{print $2}'` ; else IP_LAN="---" ; fi ;
if ( /sbin/ifconfig | grep -q "wlan0" ) ; then IP_WLAN=`ifconfig wlan0 | grep "inet" | cut -d ":" -f 2 | awk '{print $2}'` ; else IP_WLAN="---" ; fi ;
IP_ADDRESSES="$DISPLAY_IPADDRLAN: $IP_LAN | $DISPLAY_IPADDRWIFI: $IP_WLAN"

# Benutzer
BENUTZER=`whoami | awk '{print $1}'`

# letzter Login
LAST1=`last -2 -a | awk 'NR==2{print $3}'`	# Wochentag
LAST2=`last -2 -a | awk 'NR==2{print $5}'`	# Tag
LAST3=`last -2 -a | awk 'NR==2{print $4}'`	# Monat
LAST4=`last -2 -a | awk 'NR==2{print $6}'`	# Uhrzeit
LAST5=`last -2 -a | awk 'NR==2{print $10}'`	# Remote-Computer
LAST="$LAST1, $LAST2 $LAST3 $LAST4 $DISPLAY_FROM $LAST5"

# Homebridge Version
HOMEBRIDGE=`homebridge --version`

# Node Version
NODE=`node -v | tr -d [:alpha:]`

# Npm Version
NPM=`npm -v | tr -d [:alpha:]`

# Npm Updates
# NPMUPDATES=`npm outdated -g | grep global -i | wc -l`
NPMUPDATES=`npm-check -g | grep -i " to go from" | wc -l`

# Homebridge Instanzen Aktiv
INSTANZAKTIV="$(systemctl -t service | grep -w homebridge | wc -l) $DISPLAY_INSTANCE"

# Homebridge Instanzen Inaktiv
INSTANZINAKTIV="$(systemctl -t service | grep -w homebridge | grep -i activating | wc -l) $DISPLAY_INSTANCE"


echo -e "\e[1;35m$DISPLAY_TITLE"
echo 
output "yellow"  "$DISPLAY_DATE" "$DATUM"						"                   ██                   "
output "magenta" "$DISPLAY_TIME" "$ZEIT"						"                  ████                  "
output "magenta" "$DISPLAY_MODEL" "$MODELL"						"                ████████    ███████     "
output "magenta" "$DISPLAY_SYSTEM" "$SYSTEM"						"              ███      ██████    ██     "
output "magenta" "$DISPLAY_KERNEL" "$KERNEL"						"            ███           ███    ██     "
output "magenta" "$DISPLAY_UPTIME" "$UPTIME"						"          ███      ███     ██    ██     "
output "magenta" "$DISPLAY_LOAD" "$LOAD"						"        ███      ███ ███    █    ██     "
output "magenta" "$DISPLAY_RAMUSAGE" "$RAM"						"      ███      ███     ███       ██     "
output "magenta" "$DISPLAY_TEMP" "$TEMP"						"    ███      ███         ███      ██    "
output "magenta" "$DISPLAY_DISKS" "$DISKS"						"  ███      ███     ███     ███     ██   "
output "magenta" "$DISPLAY_DISKCAPACITY" "$CAPACITY"					" ███     ███     ███████     ███    ██  "
output "magenta" "$DISPLAY_HOSTNAME" "$HOSTNAME"					" ███   ███     ███     ███     ███      "
output "magenta" "$DISPLAY_IPADDR" "$IP_ADDRESSES"					"   █████     ███         ███    ███     "
output "magenta" "$DISPLAY_USERNAME" "$BENUTZER"					"           ███     ██      ███  ███     "
output "magenta" "$DISPLAY_LASTLOGIN" "$LAST"						"         ███    ████████     ████       "
output "magenta" "$DISPLAY_HOMEBRIDGEVERSION" "$HOMEBRIDGE"				"        ███   ███      ███              "
output "magenta" "$DISPLAY_NODEVERSION" "$NODE"						"          █████         ███             "
output "magenta" "$DISPLAY_NPMVERSION" "$NPM"						"                         ███            "
output "cyan"    "$DISPLAY_NPMUPDATES" "$NPMUPDATES $DISPLAY_NPMUPDATESAVAILABLE"	"                       ███              "
output "green"   "$DISPLAY_HOMEBRIDGEACTIVE" "$INSTANZAKTIV"				"                     ███                "
output "red"     "$DISPLAY_HOMEBRIDGEINACTIVE" "$INSTANZINAKTIV"			"                   ███                  "
