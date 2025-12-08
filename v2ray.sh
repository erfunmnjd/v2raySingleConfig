#!/bin/bash

set -e

echo "=== Installing V2Ray Core ==="
apt update -y
apt install -y curl unzip

# Install official script
bash <(curl -L https://github.com/v2fly/fhs-install-v2ray/raw/master/install-release.sh)

echo "=== Generating UUID ==="
UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=443

cat <<EOF >/usr/local/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": ""
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

echo "=== Restarting V2Ray ==="
systemctl enable v2ray
systemctl restart v2ray

IP=$(curl -s ipv4.icanhazip.com)

echo ""
echo "=============================="
echo "     V2RAY VLESS CONFIG"
echo "=============================="
echo ""
echo "vless://$UUID@$IP:$PORT?encryption=none&type=tcp#$IP"
echo ""
echo "=============================="
echo "Done!"
