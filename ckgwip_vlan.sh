#!/bin/vbash
#set variables for wan interface, lan interface and destination MAC address
WANIF=eth0.100
LANIF=eth0.173
LANVIF="eth0 vif 173"
DMAC=78:67:0E:B5:5B:45

logger -t ckgwip_vlan.sh  "Checking Gateway IP, changing if needed"
#get gateway IP address from changeip and set it to variable IP
IP=$(curl --silent ip.changeip.com |grep -oE -m1 '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
#printf "\nGW IP = $IP\n"

#Set up to run vyos config and show commands
source /opt/vyatta/etc/functions/script-template
configure

#Get the Subnet address
SUBNET=$(show service dhcp-server shared-network-name LAN subnet |grep -oE -m1 '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+')
#printf "subnet = $SUBNET\\n\n"

#Get the current configured IP address for the VZ Router
SUBNET=$(show service dhcp-server shared-network-name LAN subnet |grep -oE -m1 '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+')
#printf "subnet = $SUBNET\\n\n"

#Get the current configured IP address for the VZ Router
ping VZ-ROUTER ip-address | grep -oE -m1 '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

#printf "Current defined IP address = $IP1\n"

#test to see if gateway address has changed
if [ "$IP" !=  "$IP1" ];
        then
                logger -t ckwip "gateway ip address changed reset lan to new address"
                #Grab last octect to setup DHCP range
                IPOCT4=$(echo $IP | tr "." " " |awk '{ print $4 }')
                #printf "\nlast octect = $IPOCT4\n"

                #set last octet in the DHCP start and stop range
                STARTOCT4=$(expr $IPOCT4 - 5)
                STOPOCT4=$(expr $IPOCT4 + 5)
                #printf "\noctet4 start = $STARTOCT4, octect4 stop = $STOPOCT4\n"

                #Create start,stop and subnet IP addresses
                STARTIP=$(echo $IP | awk  '{split($1,a,"."); a[4] = '$STARTOCT4'; print a[1]"."a[2]"."a[3]"."a[4]}')
                STOPIP=$(echo $IP | awk  '{split($1,a,"."); a[4] = '$STOPOCT4'; print a[1]"."a[2]"."a[3]"."a[4]}')
                SUBNETIP=$(echo $IP | awk  '{split($1,a,"."); a[4] = "0/24"; print a[1]"."a[2]"."a[3]"."a[4]}')
                INSIDEIP=$(echo $IP | awk  '{split($1,a,"."); a[4] = "1"; print a[1]"."a[2]"."a[3]"."a[4]}')
                INTERFACEIP=$(echo $IP | awk  '{split($1,a,"."); a[4] = "1/24"; print a[1]"."a[2]"."a[3]"."a[4]}')
                #printf "\ngateway ip address = $IP, DHCP start ip address = $STARTIP, DHCP stop ip address = $STOPIP, subnet = $SUBNETIP\n\n"
                #printf "inside interface ip address = $INSIDEIP, interface ip address = $INTERFACEIP\n\n"

                #remove old configuration
                        del service dhcp-server
                        del service dns forwarding
                        del interfaces ethernet $LANVIF address
                        del nat destination rule 10
                        del nat destination rule 12
                        del nat destination rule 15
                        del nat destination rule 20
                        del nat destination rule 25
                        del nat destination rule 30
                        del nat destination rule 35
                        del nat source rule 100

                #remove old configuration
                        del service dhcp-server
                        del service dns forwarding
                        del interfaces ethernet $LANVIF address
                        del nat destination rule 10
                        del nat destination rule 12
                        del nat destination rule 15
                        del nat destination rule 20
                        del nat destination rule 25
                        del nat destination rule 30
                        del nat destination rule 35
                        del nat source rule 100

                #add new configuration
                        set interfaces ethernet $LANVIF address $INTERFACEIP
                        set nat destination rule 10 description 'Port Forward: VZ Tech Port 4567 to '$IP
                        set nat destination rule 10 destination port '4567'
                        set nat destination rule 10 inbound-interface $WANIF
                        set nat destination rule 10 protocol 'tcp'
                        set nat destination rule 10 translation address $IP
                        set nat destination rule 12 description 'Port Forward: VZ Tech Port 4577 to '$IP
                        set nat destination rule 12 destination port '4577'
                        set nat destination rule 12 inbound-interface $WANIF
                        set nat destination rule 12 protocol 'tcp'
                        set nat destination rule 12 translation address $IP
                        set nat destination rule 15 description 'Port Forward: VZ DVR Access Port'
                        set nat destination rule 15 destination port '63145'
                        set nat destination rule 15 inbound-interface $WANIF
                        set nat destination rule 15 protocol 'udp'
                        set nat destination rule 15 translation address $IP
                        set nat destination rule 20 description 'Port Forward: VZ CID Port VMS
                        set nat destination rule 20 destination port '35000'
                        set nat destination rule 20 inbound-interface $WANIF
                        set nat destination rule 20 protocol 'udp'
                        set nat destination rule 20 translation address $IP
                        set nat destination rule 25 description 'Port Forward: VZ CID Port VMC1' 
                        set nat destination rule 25 destination port '35001'
                        set nat destination rule 25 inbound-interface $WANIF
                        set nat destination rule 25 protocol 'udp'
                        set nat destination rule 25 translation address $IP
                        set nat destination rule 30 description 'Port Forward: VZ CID Port VMC2'
                        set nat destination rule 30 destination port '35002'
                        set nat destination rule 30 inbound-interface $WANIF
                        set nat destination rule 30 protocol 'udp'
                        set nat destination rule 30 translation address $IP
                        set nat destination rule 35 description 'Port Forward: VZ CID Port VMC3'
                        set nat destination rule 35 destination port '35003'
                        set nat destination rule 35 inbound-interface $WANIF
                        set nat destination rule 35 protocol 'udp'
                        set nat destination rule 35 translation address $IP
                        set nat source rule 100 outbound-interface $WANIF
                        set nat source rule 100 source address $SUBNETIP
                        set nat source rule 100 translation address 'masquerade'
#                       set service dhcp-server disabled 'false'
#                       set service dhcp-server disabled 'false'
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP default-router $INSIDEIP
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP name-server $INSIDEIP
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP domain-name 'photis.net'
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP name-server $INSIDEIP
#                       set service dhcp-server shared-network-name LAN subnet $SUBNETIP name-server 1.1.1.1
#                       set service dhcp-server shared-network-name LAN subnet $SUBNETIP name-server 9.9.9.9
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP lease '3600'
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP range 10 start $STARTIP
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP range 10 stop $STOPIP
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP static-mapping VZ-ROUTER ip-address $IP
                        set service dhcp-server shared-network-name LAN subnet $SUBNETIP static-mapping VZ-ROUTER mac-address $DMAC
                        set service dns forwarding allow-from $SUBNETIP
                        set service dns forwarding listen-address $INSIDEIP
#                       set service dns cache-size 150
                        commit
                        save

        else
                logger -t ckwip "daily gateway check, no change"
fi                        
