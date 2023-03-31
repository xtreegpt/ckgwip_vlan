# ckgwip_vlan
Verizon FIOS 3 router setup using vyos as the mid router. This script updates config if gateway IP changes on main router
you have to forward Verizon ports from main router to WAN side of Vyos. Vyos will pass the data to the FIOS router. This is so you can remotely control your DVR. See http://www.dslreports.com/faq/16858
command needs to be run as a non-root user or configuration will be locked. use sg vyattacfg -c /home/vyos/ckgwip_vlan.sh 
scheduled tast sets this up for you. 
setup a scheduled tast for this to run. I run it once at 4am every morning. 
set system task-scheduler task testSetGW crontab-spec '0 4 * * *'
set system task-scheduler task testSetGW executable path '/home/vyos/ckgwip_vlan.sh'
