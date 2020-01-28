echo "Commands will be run as root"

echo "[*] Cleaning /etc/resolv.conf entry ..."
sudo sh -c 'echo "nameserver 172.16.0.1" > /etc/resolv.conf'

echo "[*] Restarting Tor  ..."
sudo systemctl restart tor

# iptables rules
# Clean iptables rules
sudo iptables -F
sudo iptables -t nat -F
# Route all trafic through Tor
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 2022 -j REDIRECT --to-ports 2022
sudo iptables -t nat -A PREROUTING -i wlan0 -p udp --dport 53 -j REDIRECT --to-ports 53
sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --syn -j REDIRECT --to-ports 9040

echo "[OK] Done ..."
