echo "Commands will be run as root"

echo "[*] Stopping Tor  ..."
sudo systemctl stop tor

# iptables rules
# Clean iptables rules
sudo iptables -F
sudo iptables -t nat -F
# Give internet access to connected host
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "[OK] Done ..."

