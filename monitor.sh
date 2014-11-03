#!/bin/bash
MONDEVICE='enp2s1' # The interface that monitor.sh should listen on.
TRIGGERMBPS=50 # The amount of bandwidth in Megabits that you want to record, this should be more than your typical throughput, but less than your max throughput.
STORAGEFOLDER='' # Absolute path to where you want to store TCP dumps. No trailing /!
PACKETS=100000 # The number of packets you want to capture, generally between 10000-100000 is good, you may end up with several logs depending on how long the attack lasts.
NORMALWAITPERIOD=5 # How long to wait before checking traffic rates if we did not detect an attack
ATTACKWAITPERIOD=120 # How long to wait before checking traffic rates if we have logged an attack.
MYSQL_USERNAME='' # Username for the MySQL database
MYSQL_PASSWORD='' # Password for the MySQL database
MYSQL_DATABASE='' # Name of the MySQL database
# Notice that we do not have a mysql database server setting, this is because if you are being attacked we can't connect to a remote database. This script will use the local MySQL server.

while [ 1 -eq 1 ]; do
        INA=$(cat /proc/net/dev | grep $MONDEVICE | echo $(($(cut -d \  -f 2) / 125000)))
        sleep 1
        INB=$(cat /proc/net/dev | grep $MONDEVICE | echo $(($(cut -d \  -f 2) / 125000)))
        INSPEED=$(($INB - $INA))

        OUTA=$(cat /proc/net/dev | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | grep $MONDEVICE | echo $(($(cut -d \  -f 10) / 125000)))
        sleep 1
        OUTB=$(cat /proc/net/dev | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | sed 's/  / /g' | grep $MONDEVICE | echo $(($(cut -d \  -f 10) / 125000)))
        OUTSPEED=$(($OUTB - $OUTA))

        TOTALTRANSFER=$(($INSPEED + $OUTSPEED))

        echo 'Incoming transfer is:' $INSPEED 'mbps'
        echo 'Outgoing transfer is:' $OUTSPEED 'mbps'
        echo 'Total:' $TOTALTRANSFER

        if [ $TOTALTRANSFER -ge $TRIGGERMBPS ]; then
                echo "Houston, we have a problem! Capturating the attack now!"
                FILENAME=$(date +$(hostname).%Y-%m-%d.%H-%M-%S.pcap)
                /usr/sbin/tcpdump -nn -i $MONDEVICE -s 0 -c $PACKETS -w $STORAGEFOLDER/$FILENAME

                /usr/sbin/tcpdump -qns 0 -A -r $STORAGEFOLDER/$FILENAME | \
                grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | \
                sort | \
                uniq -c | \
                sed 's/  / /g' | \
                sed 's/  / /g' | \
                sed 's/  / /g' | \
                sed -u 's/^  / /g' | \
                grep -e '[0-9]\{2,99\} ' | \
                cut -d ' ' -f 3 | \
                grep -v '^192\.168' | \
                grep -v '^10\.' > $STORAGEFOLDER/$FILENAME'.top-offenders.txt'

                cat $STORAGEFOLDER/$FILENAME'.top-offenders.txt' | \
                while read IP_ADDRESS; do
                        mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -Bse "USE $MYSQL_DATABASE; INSERT INTO offenders (ip_address,pcap_file_path) VALUES ('$IP_ADDRESS','$STORAGEFOLDER/$FILENAME');"
                        echo 'Added address '$IP_ADDRESS' to database.'
                done
                echo 'Logged offending IP addresses to MySQL DB'
                sleep $ATTACKWAITPERIOD
        else
                sleep $NORMALWAITPERIOD
        fi
done;
