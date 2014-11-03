dosmon
======

DDoS monitoring &amp; reporting scripts for Linux

Usage
===

To listen for DDoS attacks on the configured interface, simply run monitor.sh inside of a screen session (sorry it doesn't go into the background).
example: screen -dmS dosmon ./monitor.sh
This script will need to be run as root or will not work as intended.

When monitor.sh detects an attack it will create a tcpdump inside of the configured directory, the file name is formatted like: hostname.year-month-day.hour-minute-second.pcap
You can use report.sh to report the offending IP addresses, it accepts one parameter which is the path, or partial path, to the pcap file you would like to report from. Monitor has already placed the IP addresses into the MySQL database, and we simply run a query to obtain the abusive addresses from the database. The pcap file path is already stored in the database. We could, for example run a report for a specific attack like so:
./report.sh /path/to/hostname.2014-11-02.14-06-13.pcap
Or we could run a report for the entire day like this:
./report.sh 2014-11-02

Submit an issue if you need any further clarification.
