if [ $? != 0 ] 
then
  echo "This program must be run as root. run again as root"
  exit 1
fi

echo "[*] Stopping Tor  ..."
systemctl stop tor

# iptables rules
# Clean iptables rules
iptables -F
iptables -t nat -F
# Give internet access to connected host
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "[OK] Done ..."

