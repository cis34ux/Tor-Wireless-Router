echo "Commands will be run as root"

read -p "[?] Do you want update your system (yY/N)?" ans

if [ $ans = "y" ] || [ $ans = "Y" ]
then
  echo "[*] Updating ..."
  sudo apt-get update -y && sudo apt-get -y upgrade
fi

echo "[*] Downloading and installing necessary packages ..."
sudo apt install -y hostapd dnsmasq tor 
if [ ! -f /etc/tor/torrc ]
        then
                sudo apt-get update --fix-missing
                sudo apt-get install -y hostapd dnsmasq tor 
fi

echo "[*] Configuration start..."
read -p "[?] Enter your router SSID: " apname
read -p "[?] Enter password: " appass
if [ ! $apname ]
then
apname="Tor"
echo "[*] SSID can't be blank now your SSID is :" $apname
fi

if [ ${#appass} -lt 8 ]
then
appass="Tor2019!"
echo "[*] Your router password is : " $appass
fi

cat > hostapd.conf <<EOF
# WiFi access point configuration
interface=wlan0
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=0
macaddr_acl=0
ignore_broadcast_ssid=1
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
ssid=$apname
wpa_passphrase=$appass

EOF

sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
sudo systemctl stop tor

sudo mv hostapd.conf /etc/hostapd/hostapd.conf
repl2="DAEMON_CONF\=\"\/etc\/hostapd\/hostapd\.conf\""
sudo sed -i "/#DAEMON_CONF=\"\"/ s/#DAEMON_CONF=\"\"/$repl2/" /etc/default/hostapd 
repl1="DAEMON_CONF\=\/etc\/hostapd\/hostapd.conf"
sudo sed -i "/$repl1/! s/DAEMON_CONF=/$repl1/" /etc/init.d/hostapd
if [ ! -f /etc/dhcpcd.conf.oldtc ]
        then
        sudo mv /etc/dhcpcd.conf /etc/dhcpcd.conf.oldtc
        else
        sudo rm /etc/dhcpcd.conf
fi

sudo cp config/dhcpcd.conf /etc/
sudo systemctl restart dhcpcd
if [ ! -f /etc/dnsmasq.conf.oldtc ]
        then
        sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.oldtc
        else
        sudo rm /etc/dnsmasq.conf
fi

sudo cp config/dnsmasq.conf /etc/dnsmasq.conf
if [ ! -f /etc/sysctl.conf.oldtc ]
        then
        sudo cp /etc/sysctl.conf /etc/sysctl.conf.oldtc
fi

repl3="net\.ipv4\.ip_forward=1"
sudo sed -i "/#$repl3/ s/#$repl3/$repl3/" /etc/sysctl.conf
repl="iptables-restore \< \/etc\/iptables\.ipv4\.nat"
sudo sed -i "20 s/exit 0/$repl\nexit 0/" /etc/rc.local
if [ ! -f /etc/tor/torrc.oldtc ]
        then
        sudo mv /etc/tor/torrc /etc/tor/torrc.oldtc
        else
        sudo rm /etc/tor/torrc
fi

cat /etc/tor/torrc.oldtc config/torrc.conf >> torrc
sudo mv torrc /etc/tor/torrc
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# iptables rules
# Give internet access to connected host
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# Clean iptables rules
sudo iptables -F
sudo iptables -t nat -F
# Route all trafic through Tor
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 2022 -j REDIRECT --to-ports 2022
sudo iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to-ports 53
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 9040
# Save iptables rules
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Create a log file
sudo touch /var/log/tor/notices.log
sudo chown debian-tor /var/log/tor/notices.log
sudo chmod 644 /var/log/tor/notices.log

# Start the services
sudo systemctl start hostapd
sudo systemctl start dnsmasq
sudo systemctl start tor

# Add services to startup
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq
sudo systemctl enable tor

read -p "[?] Press [Enter] to reboot or terminate otherwise press (ctrl+c) ..." chk
sudo reboot

