#!/bin/bash

#
# sysInfo.sh
# Made by: Derek Dorrance
# Date: 3-9-2020
# Version: 2.0
# Desctiption: This script populates a CSV file with sysinfo. It should be 
#              scheduled to run by cron every hour. 
#               CSV Headers include: date (YYYY-MM-DD), time (military HH:MM:SS),
#                                    hostname, ip address, number users logged on,
#                                    disk usage, cpu usage, network connectivity, 
#                                   and network speed                
####################################################################################

## Pseudo Code:
# * Function to print get all info and store in variables
# * date + time will be formatted with 
# * hostname available at 
# * Get IP address from ifconfig, filter out IP addr with awk
# * Get users logged in, count output with wc
# * Get disk usage, format human readable 
# * Network connectivity: Boolean (Internet = True, No Internet = False)
# * Network speed: run speedtest.net tool and filter output with awk


# Path to CSV Output file. Will be /home/username/sysinfo.csv.
# The USERNAME value is replaced by sysinfoInstaller.sh

CSV_PATH="/home/{{USERNAME}}/sysinfo.csv"


# Get the flags from the script execution call.
# d = disk, c = cpu, n = net. 
while getopts ":dcn" opt; do
  case ${opt} in
    d ) 
        disk=1
        ;;
    c ) 
        cpu=1
        ;;
    n )
        net=1
        ;;
    \? ) echo "Usage: cmd [-d] [-c] [-n]"
        ;;
  esac
done

writeCSV () {
    #Check if CSV exists, if not, then create it and write headers as the first line
    # otherwise, values are appended
    if [ ! -f "$CSV_PATH" ]; then
        echo "date,time,hostname,ipaddress,numusers,diskusage,cpuusage,temp,connectivity,downspeed,upspeed" > $CSV_PATH
    fi 

    # Get all the system info and set to variables
    dateFormatted="$(date +%Y-%m-%d)"
    timeFormatted="$(date +%H-%M-%S)"
    IPAddress="$(hostname -I)"
    numUsers="$(w | wc -l)"  #Use w to get users, use wc to count output lines
    numUsers=$((numUsers - 2)) #Remove two lines from wc line count. This is just header info
    # Gets disk usage from df, filter for '/' file system, use Percentage ($5)
    diskUsage="$(df -h | awk '{if($6=="/") print $5}')"
    cpuusage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')

    #Network connectivity, using speedtest.net's speedtest-cli tool
    output=$(speedtest --simple)

    #Check if speedtest exited with 1 (error), if so, there is no net connectivity
    if [ "$?" -ne "1" ]; then
        upSpeed="$(echo $output | awk '{print $8}')" #Printing the 8th field of the output from speedtest.
        downSpeed="$(echo $output | awk '{print $5}')" #Printing the 5th field of the output from speedtest.
       
        connectivity="$(echo $output | awk '{print $2}')"
    else 
        upSpeed="0"
        downSpeed="0"
        connectivity="N/A"
    fi
    {
        echo -n "$dateFormatted,"
        echo -n "$timeFormatted,"
        echo -n "$(hostname),"
        echo -n "$IPAddress,"
        echo -n "$numUsers,"
        echo -n "$diskUsage,"
        echo -n "$cpuusage,"
        echo -n "102," #Dummy data for temp 
        echo -n "$connectivity,"
        echo -n "$downSpeed,"
        echo  "$upSpeed" 
    } >> $CSV_PATH 
}

writeCSV

#Check if there are 24 or more entries, if so, send that sysinfo.csv to the serverIP and remove the original, if successful
csvSize=$(cat $CSV_PATH | wc -l)

if [ $csvSize -gt 24 ]; then
    rsync --remove-source-files -av $CSV_PATH -e "ssh -i $HOME/.ssh/id_rsa" "{{USERNAME}}@{{SERVERIP}}:/home/{{USERNAME}}/sysinfo.csv" 
fi
