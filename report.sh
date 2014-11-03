#!/bin/bash
# USAGE: ./report.sh /path/to/pcap/dump.pcap
# You may also use a partial match for your pcap file names, such as the date stamp inside of the file name for the pcap dump. eg - ./report.sh 2014-11-01
MYSQL_USERNAME='' # Username for the MySQL database
MYSQL_PASSWORD='' # Password for the MySQL database
MYSQL_DATABASE='' # Name of the MySQL database

MY_EMAIL_ADDRESS='' # SMTP Username / Email address to contact abuse departments from
MY_EMAIL_PASSWORD='' # SMTP password
MAILSERVER='' # SMTP Server
REPLYTO='' # Reply-to address, be careful as this email may get a lot of automated replies.

mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD -Bse "USE $MYSQL_DATABASE; SELECT ip_address,pcap_file_path FROM offenders WHERE pcap_file_path like '%$1%'" | \
while read line; do
        IP_ADDRESS=$(echo $line | cut -d ' ' -f 1)
        LOGFILE=$(echo $line | cut -d ' ' -f 2)
        ABUSE_CONTACT=$(whois $IP_ADDRESS | grep 'AbuseEmail' | tail -n 1 | sed 's/ \+/ /g' | cut -d ' ' -f 2)
        LOGSAMPLE=$(/usr/sbin/tcpdump -qns 0 src host $IP_ADDRESS -c 5 -A -r $LOGFILE)
        EMAIL_BODY='Hello,\n
                This is an automated message to let you know that a computer on your network with the IP address '$IP_ADDRESS' may have been involved in a distributed denial of service attack.\n
                The following is a snippet from the TCPDump taken during the attack which shows the exact involvement of this network address in the attack.\n
                Please review these logs and take necessary action to stop this abusive network activity.\n
                Please do NOT reply to this email address, send any replies to '$REPLYTO' instead.\n
                --- TCPDump Logs for '$IP_ADDRESS' ---\n
                '$LOGSAMPLE


		from=$MY_EMAIL_ADDRESS
        to=$ABUSE_CONTACT
        domain=$MAILSERVER
        mailserver=$MAILSERVER
        mailtext=$EMAIL_BODY
        #authemail=$(echo $MY_EMAIL_ADDRESS | openssl enc -base64 | awk 'sub("..$", "")')
        #authpass=$(echo $MY_EMAIL_PASSWORD | openssl enc -base64 | awk 'sub("..$", "")')
        authemail=$MY_EMAIL_ADDRESS
        authpass=$MY_EMAIL_PASSWORD

        exec 9<>/dev/tcp/$mailserver/25
        echo "HELO $mailserver" >&9
        read -r temp <&9
        echo "$temp"
        echo "auth login" >&9
        read -r temp <&9
        echo "$authemail" >&9
        read -r temp <&9
        echo "$authpass" >&9
        read -r temp <&9
        echo "Mail From: $from" >&9
        read -r temp <&9
        echo "$temp"
        echo "Rcpt To: "$ABUSE_CONTACT >&9
        read -r temp <&9
        echo "$temp"
        echo "Data" >&9
        read -r temp <&9
        echo "$temp"
        echo "To: "$ABUSE_CONTACT >&9
        echo "From: Automated Abuse Reporting <"$MY_EMAIL_ADDRESS">\r\n" >&9
        echo "MIME-Version: 1.0\r\n" >&9
        echo "Content-Type: text/plain; charset=\"utf-8\"\r\n" >&9
        echo "Subject: Denial of Service Attack originating from "$IP_ADDRESS"\r\n" >&9
        echo $mailtext >&9
        echo "." >&9
        read -r temp <&9
        echo "$temp"
        echo "quit" >&9
        read -r temp <&9
        echo "$temp"
        9>&-
        9<&-
        echo "Email sent to "$ABUSE_CONTACT" Regarding "$IP_ADDRESS". Please check above output for any errors."
done
