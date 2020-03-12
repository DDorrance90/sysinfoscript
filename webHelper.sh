#!/bin/bash

#
# webHelper.sh 
# Made by: Derek Dorrance
# Date: 3-9-2020
# Version: 1.0
# Desctiption: This script generates an Index.html for a Linux server running Apache2
#               It is assumed that the dir, /var/www/html, is being served by Apache              
####################################################################################

# Index.html will look like this: 
# <html>
#     <head>
#         <title> Sys Info Viewer </title>
#     </head>
#     <body>
#         <img src=diskusage.png> 
#         <img src=cpuusage.png>
#         <img src=cputemp.png>
#         <img src=connectivity.png>
#         <img src=networkspeed.png>
#     </body>
# </html>


#Depending on the flags this script is called with, generate img tags for 
# d - Disk usage 
# c - CPU Usage and CPU Temp
# n - Network bandwidth and Latency

imgTags=""
while getopts ":dcn" opt; do
  case ${opt} in
    d ) 
        imgTags="${imgTags} <img src=diskusage.png>"
        ;;
    c ) 
        imgTags="${imgTags} <img src=cpuusage.png> <img src=cputemp.png>"
        ;;
    n )
        imgTags="${imgTags} <img src=networkspeed.png> <img src=connectivity.png>"
        ;;
    \? ) echo "Usage: cmd [-d] [-c] [-n]"
        ;;
  esac
done

# Write the index.html file, which apache2 will serve
{
    echo -e "<html>\n<head>\n<title>Sys Info Viewer</title>\n</head>"
    echo -e "<body> ${imgTags} </body> </html>"
} > /var/www/html/index.html

#Remove graphs, if there are any
if [ -f /var/www/html/diskusage.png ]; then
    rm -rf /var/www/html/diskusage.png
    rm -rf /var/www/html/connectivity.png
    rm -rf /var/www/html/cputemp.png
    rm -rf /var/www/html/cpuusage.png
    rm -rf /var/www/html/networkspeed.png
fi

# Execute the graphmaker script
./graphmaker.gp