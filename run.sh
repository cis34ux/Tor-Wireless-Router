if [ $? != 0 ] 
then
  echo "This program must be run as root. run again as root"
  exit 1
fi

echo "[*] Cleaning /etc/resolv.conf entry ..."
sh -c 'echo "nameserver 172.16.0.1" > /etc/resolv.conf'

echo "[*] Restarting Tor  ..."
systemctl restart tor

echo "[OK] Done ..."
tail -f /var/log/tor/notices.log
