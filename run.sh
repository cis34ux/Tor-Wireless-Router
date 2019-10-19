if [ $? != 0 ] 
then
  echo "This program must be run as root. run again as root"
  exit 1
fi

echo "[*] Cleaning /etc/resolv.conf entry ..."
sh -c 'echo "nameserver 172.16.0.1" > /etc/resolv.conf'

echo "[*] Restarting Tor  ..."
systemctl restart tor

# iptables rules
# Clean iptables rules
iptables -F
iptables -t nat -F
# Route all trafic through Tor
iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 22 -j REDIRECT --to-ports 22
iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 9040

echo "[OK] Done ..."
