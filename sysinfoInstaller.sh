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

installScripts () {
    read -p "Would you like to collect Disk Usage info? [Y/N]" bDisk
    read -p "Would you like to collect CPU info? [Y/N]" bCPU
    read -p "Would you like to collect Network info? [Y/N]" bNet 

    # Adds on the necessary flags to add to the script execution line in cron
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

    # Get user input for when to run the script with cron, accepts a 'cron string'
    read -p "Enter cron string for scheduling, ex: '* * * * *' (Every Minute), '0 * * * *' (Every Hour): " cronString
    echo "$cronString root /bin/bash $(pwd)/sysInfo.sh ${arg} > /dev/null 2>&1" > /etc/cron.d/sysinfo

    # Replace the placeholder text {{SERVERIP}} with the actual IP to use
    sed -i "s/{{SERVERIP}}/${serverIP}/g" sysInfo.sh
    # Replace the {{USERNAME}} in sysInfo.sh with the actual username to use
    sed -i "s/{{USERNAME}}/${userName}/g" sysInfo.sh
    sed -i "s/{{USERNAME}}/${userName}/g" graphmaker.gp

    # Check if ssh keys are already generated, if not, create them.
    # Set the permissions on the public key (rw,r,r) and copy it to the serverIP
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
        chmod 644 ~/.ssh/id_rsa.pub
        ssh-copy-id -i ~/.ssh/id_rsa.pub ${userName}@$serverIP # This will require the userName password input from the user.
    fi

    # Set execution permissions on sysInfo.sh, webHelper.sh and graphmaker.gp
    chmod +x graphmaker.gp
    chmod +x sysInfo.sh
    chmod +x webHelper.sh

    # Send the graphmaker.gp and webHelper.sh scripts to the serverIP (Web Server), using the ssh keys we just added to the 
    # authorized_hosts file on serverIP (Web Server)
    rsync -av -e "ssh -i $HOME/.ssh/id_rsa" graphmaker.gp webHelper.sh ${userName}@$serverIP:/home/${userName}/
    # SSH into the serverIP (Web Server) and add a cron entry to run the webHelper.sh script on a schedule 
    ssh -t ${userName}@$serverIP -i ~/.ssh/id_rsa "sudo echo '$cronString root /bin/bash /home/${userName}/webHelper.sh ${arg}' | sudo tee -a /etc/cron.d/webhelper > /dev/null"




    # Give user feedback on success or error of the last command (ssh)
    if [ $? == 0 ]; then
        echo "Scripts installed."
    else
        echo "Something went wrong."
    fi
}

if [ "$(id --user)" != "0" ]; then
    echo "You must have root privs to run this script."
    echo "Try again as root, or with sudo"
    exit 1
fi

echo "=== sysinfo Installer ==="
echo "Info will be collected from this server: $(hostname)@[$(hostname -I)], "
read -p "Enter the IP address of the web server that will display the graphs: " serverIP
read -p "Enter the username for the Webserver. This user must have sudo rights: " userName

if [[ $serverIP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    if [ -z $userName ]; then
        echo "user cannot be empty, exiting"
        exit 1
    fi 

    echo "using $userName@$serverIP as the Webserver"
    installScripts 
else 
    echo "$serverIP is not a valid IP address, exiting"
    exit 1
fi