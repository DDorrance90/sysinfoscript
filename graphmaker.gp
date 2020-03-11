#!/usr/bin/gnuplot

# graphmaker.gp
#  
# Made by: Derek Dorrance
# Date: 3-9-2020
# Version: 1.0
# Desctiption: This script creates gnuplot graphs from a CSV file with sysinfo.         
####################################################################################

CSV_PATH="/home/derek/sysinfo.csv" 
OUT_PATH="/var/www/html/"

set term png
set output "/var/www/html/diskusage.png"
set key off
set datafile separator ','
set xdata time
set timefmt "%H-%M-%S"
set title "Disk Usage (Percentage over Time)"
set ylabel "%" 
set xlabel 'Time'
plot CSV_PATH using 2:6 with lines

set output "/var/www/html/cpuusage.png"
set title "CPU Usage (Percentage over Time)"
set ylabel "%" 
set xlabel 'Time'
plot CSV_PATH using 2:7 with lines

set output "/var/www/html/cputemp.png"
set title "CPU Temp"
set ylabel "F" 
set xlabel 'Time'
plot CSV_PATH using 2:8 with lines

set output "/var/www/html/connectivity.png"
set title "Latency (Ping)"
set ylabel "ms" 
set xlabel 'Time'
plot CSV_PATH using 2:9 with lines

set output "/var/www/html/networkspeed.png"
set title "Network Speed (Bandwidth)"
set ylabel "%" 
set xlabel 'Time'
plot CSV_PATH using 2:10 with lines, '' using 2:11 with lines
