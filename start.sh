#!/bin/bash

export MISP_URL=https://$(ip a show dev enp0s3|grep 'inet '|awk '{print $2}'|cut -d/ -f1)
export MISP_AUTH_KEY=$(awk '{print $2}' /home/misp/MISP-authkey.txt)

if [[ -e /home/misp/XFORCE-authkey.txt ]]; then
  export XFORCE_API_KEY=$(awk '{print $2}' /home/misp/XFORCE-authkey.txt|head -1)
  export XFORCE_API_PASS=$(awk '{print $2}' /home/misp/XFORCE-authkey.txt|tail -1)
else
  read -p "XForce API key: " XFORCE_API_KEY
  export XFORCE_API_KEY=$XFORCE_API_KEY
  echo "Apikey: $XFORCE_API_KEY" > /home/misp/XFORCE-authkey.txt
  read -p "XForce API password: " XFORCE_API_PASS
  export XFORCE_API_PASS=$XFORCE_API_PASS
  echo "Apipass: $XFORCE_API_PASS" >> /home/misp/XFORCE-authkey.txt
fi

python3 /home/misp/scripts/xforce.py 1>/home/misp/scripts/logs/xforce.log 2>/home/misp/scripts/logs/xforce.log &
echo -e "Started xforce.py\nLog file at ~/scripts/logs/xforce.log"
