#!/bin/bash
# Corallium Masternode Setup Script V1.4 for Ubuntu 16.04 LTS
# (c) 2018 by npq7721 for Corallium Coin
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash corallium-setup.sh 
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#XGCS TCP port
PORT=10233
RPC=23057

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'coralliumd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop coralliumd${NC}"
        corallium-cli stop
        delay 30
        if pgrep -x 'corallium' > /dev/null; then
            echo -e "${RED}coralliumd daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            pkill coralliumd
            delay 30
            if pgrep -x 'coralliumd' > /dev/null; then
                echo -e "${RED}Can't stop coralliumd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}
#Function detect_ubuntu

 if [[ $(lsb_release -d) == *16.04* ]]; then
   UBUNTU_VERSION=16
else
   echo -e "${RED}You are not running Ubuntu 16.04, Installation is cancelled.${NC}"
   exit 1

fi

#Process command line parameters
genkey=$1
rm -rf .corallium
clear

echo -e "${YELLOW}Corallium Masternode Setup Script V1.5 for Ubuntu 16.04 LTS${NC}"
echo "Do you want me to generate a masternode private key for you?[y/n]"
read DOSETUP

if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
    fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a" 
else 
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
#Check Deps
if [ -d "/var/lib/fail2ban/" ]; 
then
    echo -e "${GREEN}Dependencies already installed...${NC}"
else
    echo -e "${GREEN}Updating system and installing required packages...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev
sudo apt-get instal unzip
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev
sudo apt-get install unzip
sudo apt-get -y install libminiupnpc-dev
sudo apt-get -y install fail2ban
sudo service fail2ban restart
sudo apt-get install libdb5.3++-dev libdb++-dev libdb5.3-dev libdb-dev && ldconfig
sudo apt-get install -y unzip libzmq3-dev build-essential libssl-dev libboost-all-dev libqrencode-dev libminiupnpc-dev libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5
   fi

#Network Settings
echo -e "${GREEN}Installing Network Settings...${NC}"
{
sudo apt-get install ufw -y
} &> /dev/null
echo -ne '[##                 ]  (10%)\r'
{
sudo apt-get update -y
} &> /dev/null
echo -ne '[######             ] (30%)\r'
{
sudo ufw default deny incoming
} &> /dev/null
echo -ne '[#########          ] (50%)\r'
{
sudo ufw default allow outgoing
sudo ufw allow ssh
} &> /dev/null
echo -ne '[###########        ] (60%)\r'
{
sudo ufw allow $PORT/tcp
sudo ufw allow $RPC/tcp
} &> /dev/null
echo -ne '[###############    ] (80%)\r'
{
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
} &> /dev/null
echo -ne '[#################  ] (90%)\r'
{
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"
} &> /dev/null
echo -ne '[###################] (100%)\n'

#Generating Random Password for coralliumd JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${RED}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi

#KILL THE MFER
pkill coralliumd
rm -r .corallium 
rm -rf /usr/bin/corallium*
 
#Installing Daemon
 cd ~
wget https://github.com/npq7721/Corallium2/releases/download/beta-6/corallium_beta_6_linux.tar.gz
tar -xzf corallium_beta_6_linux.tar.gz -C ~/CoralliumMasternodeSetup
rm -rf corallium_beta_6_linux.tar.gz

  stop_daemon
 
 # Deploy binaries to /usr/bin
 sudo cp ~/CoralliumMasternodeSetup/corallium_beta_6_linux/corallium* /usr/bin/
 sudo chmod 755 -R ~/CoralliumMasternodeSetup
 sudo chmod 755 /usr/bin/corallium* 
 # Deploy masternode monitoring script
 cp ~/CoralliumMasternodeSetup/coralliummon.sh /usr/local/bin
 sudo chmod 711 /usr/local/bin/coralliummon.sh
 # Deploy restart script 
 cp ~/CoralliumMasternodeSetup/corallium-restart.sh /usr/local/bin
 sudo chmod 711 /usr/local/bin/corallium-restart.sh
 
 #Create corallium datadir
 if [ ! -f ~/.corallium/corallium.conf ]; then 
 	sudo mkdir ~/.corallium
 fi

echo -e "${YELLOW}Creating corallium.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.corallium/corallium.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.corallium/corallium.conf

    #Starting daemon first time just to generate masternode private key
    coralliumd -daemon
echo -ne '[##                 ] (15%)\r'
sleep 6
echo -ne '[######             ] (30%)\r'
sleep 6
echo -ne '[########           ] (45%)\r'
sleep 6
echo -ne '[##############     ] (72%)\r'
sleep 10
echo -ne '[###################] (100%)\r'
echo -ne '\n'

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(corallium-cli masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR: Can not generate masternode private key.${NC} \a"
        echo -e "${RED}ERROR: Reboot VPS and try again or supply existing genkey as a parameter.${NC}"
        exit 1
    fi
    
    #Stopping daemon to create corallium.conf
    stop_daemon
fi

# Create corallium.conf
cat <<EOF > ~/.corallium/corallium.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcport=$RPC
rpcallowip=127.0.0.1
onlynet=ipv4
listen=1
server=1
daemon=1
maxconnections=200
externalip=$publicip:$PORT
masternode=1
masternodeprivkey=$genkey

EOF

#Finally, starting corallium daemon with new corallium.conf
coralliumd --daemon
delay 5

#Setting auto start cron job for coralliumd
cronjob="@reboot sleep 30 && coralliumd"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "${GREEN}Configuring crontab job...${NC}"
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron

echo -e "========================================================================
${YELLOW}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${YELLOW}$publicip${NC}
Masternode Private Key: ${YELLOW}$genkey${NC}
Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your XGCSCOIN collateral funds):
======================================================================== \a"
echo -e "${YELLOW}mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}masternode.conf${NC} file and replace:
    ${YELLOW}mn1${NC} - with your desired masternode name (alias)
    ${YELLOW}TxId${NC} - with Transaction Id from masternode outputs
    ${YELLOW}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the Itis network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in masternode list${NC}, which is normal and expected.
2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}masternode start-alias mn1${NC}
    where ${YELLOW}mn1${NC} is the name of your masternode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    Masternodes -> Select masternode -> RightClick -> ${YELLOW}start alias${NC}
Once completed step (2), return to this VPS console and wait for the
Masternode Status to change to: 'Masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!
Currently your masternode is syncing with the XGCS network...
The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in corallium.conf:
${YELLOW}cat ~/.corallium/corallium.conf${NC}
Here is your corallium.conf generated by this script:
-------------------------------------------------${YELLOW}"
cat ~/.corallium/corallium.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit corallium.conf, first stop the coralliumd daemon,
then edit the corallium.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the coralliumd daemon back up:
             to stop:   ${YELLOW}corallium-cli stop${NC}
             to edit:   ${YELLOW}nano ~/.corallium/corallium.conf${NC}
             to start:  ${YELLOW}coralliumd${NC}
========================================================================
To view Itis debug log showing all MN network activity in realtime:
             ${YELLOW}tail -f ~/.corallium/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${YELLOW}htop${NC}
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the nodemon.sh script:
                 ${YELLOW}nodemon.sh${NC}
or just type 'node' and hit <TAB> to autocomplete script name.
========================================================================
Enjoy your XGCS Masternode and thanks for using this setup script!

If you found this script useful, please donate to : 
${GREEN}CRU3ZieGKjLiKMhgXtsndRwmLgDoEWqUh5${NC}
...and make sure to check back for updates!
Author: npq7721
"
delay 30
# Run nodemon.sh
coralliummon.sh

# EOF
