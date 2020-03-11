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
    echo "using $serverIP as the Webserver"
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

read -p "Enter cron string for scheduling, ex: '* * * * *' (Every Minute), '0 * * * *' (Every Hour): " cronString
echo "$cronString root /bin/bash /home/derek/sysInfo.sh ${arg} > /dev/null 2>&1" > /etc/cron.d/sysinfo

sed -i "s/{{SERVERIP}}/${serverIP}/g" sysInfo.sh
chmod +x sysInfo.sh
chmod +x webHelper.sh
ssh-keygen -t rsa -N "" -f rsyncKeys.pem
chmod 644 rsyncKeys.pem.pub
ssh-copy-id -i rsyncKeys.pem.pub derek@$serverIP
rsync -av -e "ssh -i rsyncKeys.pem" graphmaker.gp webHelper.sh derek@$serverIP:/home/derek/
ssh -t derek@$serverIP -i rsyncKeys.pem "sudo echo '$cronString root /bin/bash /home/derek/webHelper.sh ${arg}' | sudo tee -a /etc/cron.d/webhelper > /dev/null"

echo "Scripts installed."
