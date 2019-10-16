if [ $? != 0 ] 
then
  echo "This program must be run as root. run again as root"
  exit 1
fi

read -p "[?] Do you want update your system (yY/N)?" ans

if [ $ans = "y" ] || [ $ans = "Y" ]
then
  echo "[*] Updating ..."
  apt-get update -y && apt-get -y upgrade
fi

echo "[*] Downloading and installing necessary packages ..."
apt install -y hostapd dnsmasq tor 
if [ ! -f /etc/tor/torrc ]
        then
                apt-get update --fix-missing
                apt-get install -y hostapd dnsmasq tor 
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

systemctl stop hostapd
systemctl stop dnsmasq
systemctl stop tor

mv hostapd.conf /etc/hostapd/hostapd.conf
repl2="DAEMON_CONF\=\"\/etc\/hostapd\/hostapd\.conf\""
sed -i "/#DAEMON_CONF=\"\"/ s/#DAEMON_CONF=\"\"/$repl2/" /etc/default/hostapd 
repl1="DAEMON_CONF\=\/etc\/hostapd\/hostapd.conf"
sed -i "/$repl1/! s/DAEMON_CONF=/$repl1/" /etc/init.d/hostapd
if [ ! -f /etc/dhcpcd.conf.oldtc ]
        then
        mv /etc/dhcpcd.conf /etc/dhcpcd.conf.oldtc
        else
        rm /etc/dhcpcd.conf
fi

cp config/dhcpcd.conf /etc/
systemctl restart dhcpcd
if [ ! -f /etc/dnsmasq.conf.oldtc ]
        then
        mv /etc/dnsmasq.conf /etc/dnsmasq.conf.oldtc
        else
        rm /etc/dnsmasq.conf
fi

cp config/dnsmasq.conf /etc/dnsmasq.conf
if [ ! -f /etc/sysctl.conf.oldtc ]
        then
        cp /etc/sysctl.conf /etc/sysctl.conf.oldtc
fi

repl3="net\.ipv4\.ip_forward=1"
sed -i "/#$repl3/ s/#$repl3/$repl3/" /etc/sysctl.conf
repl="iptables-restore \< \/etc\/iptables\.ipv4\.nat"
sed -i "20 s/exit 0/$repl\nexit 0/" /etc/rc.local
if [ ! -f /etc/tor/torrc.oldtc ]
        then
        mv /etc/tor/torrc /etc/tor/torrc.oldtc
        else
        rm /etc/tor/torrc
fi

cat /etc/tor/torrc.oldtc config/torrc.conf >> torrc
mv torrc /etc/tor/torrc
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

# iptables rules
# Give internet access to connected host
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# Clean iptables rules
iptables -F
iptables -t nat -F
# Route all trafic through Tor
iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 22 -j REDIRECT --to-ports 22
iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 9040
# Save iptables rules
sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Create a log file
touch /var/log/tor/notices.log
chown debian-tor /var/log/tor/notices.log
chmod 644 /var/log/tor/notices.log

# Start the services
systemctl start hostapd
systemctl start dnsmasq
systemctl start tor

# Add services to startup
systemctl enable hostapd
systemctl enable dnsmasq
systemctl enable tor

read -p "[?] Press [Enter] to reboot or terminate otherwise press (ctrl+c) ..." chk
reboot

