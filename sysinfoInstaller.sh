#!/bin/bash

#
# sysinfoInstaller.sh
# Made by: Derek Dorrance
# Date: 3-9-2020
# Version: 1.0
# Desctiption: This script gains user input on the types of data they would like to collect
#               from this server, and which webserver they would like to receive 
#               sysinfo.csv. This script will then modify the appropriate values in
#               sysinfo.sh and webHelper.sh and install them to the appropriate directories. 
#############################################################################################


echo "=== sysinfo Installer ==="
echo "Info will be collected from this server: $(hostname)@[$(hostname -I)], "
read -p "Enter the IP address of the web server that will display the graphs: " serverIP

if [[ $serverIP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    #do stuff
else 
    echo "$serverIP is not a valid IP address, exiting"
    exit 1
fi

read -p "Would you like to collect Disk Usage info? [Y/N]" bDisk
read -p "Would you like to collect CPU info? [Y/N]" bCPU
read -p "Would you like to collect Network info? [Y/N]" bNet 


arg=""

if [ "${bDisk,,}"=="y" ]; then
    arg="${arg} -d"
    echo "Will track Disk usage"
fi
if [ "${bCPU,,}"=="y" ]; then
    arg="${arg} -c"
    echo "Will track CPU Info"
fi

if [ "${bNet,,}"=="y" ]; then
    arg="${arg} -n"
    echo "Will track Net Info"
fi

read -p "Enter cron string for scheduling, ex: '* * * * *' (Every Minute), '0 * * * *' (Every Hour)" cronString
echo "$cronString /bin/bash /home/derek/sysinfo.sh ${arg}> /dev/null 2>&1" > /etc/cron.d/sysinfo

sed -i "s/{{SERVERIP}}/${serverIP}/g" sysinfo.sh
chmod +x sysinfo.sh
chmod +x webHelper.sh
rsync -av graphmaker.gp webHelper.sh $serverIP/home/derek/
ssh -t $serverIP `echo "$cronString /bin/bash /home/derek/webHelper.sh ${arg}> /dev/null 2>&1" > /etc/cron.d/webhelper`

echo "Scripts installed."
