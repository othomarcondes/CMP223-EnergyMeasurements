#!/bin/bash

# usage: ./snmp_energy_monitor.sh <PDU_number>
#	<PDU_number>: the last 3 digits of the PDU ip address (192.168.30.124 -> 124)
#	ex: ./snmp_energy_monitor.sh 124

# output: date,Energy,ActivePower
#	date: YYYY-MM-DD hh:mm:ss
#	Energy: cumulative value. integer, Wh
#	Active Power: the usable or consumed electrical energy in an AC circuit. integer, W

while true ; do
        echo -n `date "+%F %T"`"," 
        energy=`snmpget -Ov -v3 -l authPriv -u apc -a SHA -A "APCAUTHKEY" -x AES -X "APCPRIVKEY" 192.168.30.$1 PowerNet-MIB::ePDUDeviceStatusEnergy.1 2>/dev/null | awk '{print $2}'`
        echo -n "$energy,"
        snmpget -Ov -v3 -l authPriv -u apc -a SHA -A "APCAUTHKEY" -x AES -X "APCPRIVKEY" 192.168.30.$1 PowerNet-MIB::ePDUDeviceStatusActivePower.1 2>/dev/null | awk '{print $2}'
done

