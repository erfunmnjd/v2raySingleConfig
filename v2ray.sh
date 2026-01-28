#!/bin/bash
set -e

apt update -y
apt install -y curl unzip ufw

bash <(curl -L https://github.com/v2fly/fhs-install-v2ray/raw/master/install-release.sh)

UUID_VLESS=$(cat /proc/sys/kernel/random/uuid)
UUID_VMESS=$(cat /proc/sys/kernel/random/uuid)

PORT_VLESS=$(shuf -i 20000-40000 -n 1)
PORT_VMESS=$(shuf -i 20000-40000 -n 1)

PATH_VLESS="/vlessws"
PATH_VMESS="/vmessws"

cat <<EOF >/usr/local/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": $PORT_VLESS,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID_VLESS", "encryption": "none" }],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "$PATH_VLESS" }
      }
    },
    {
      "port": $PORT_VMESS,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "$UUID_VMESS", "alterId": 0 }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "$PATH_VMESS" }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

ufw allow $PORT_VLESS
ufw allow $PORT_VMESS
ufw reload || true

systemctl restart v2ray

IP=$(curl -s ipv4.icanhazip.com)

echo ""
echo "========== WORKING CONFIGS =========="
echo ""
echo "VLESS WS:"
echo "vless://$UUID_VLESS@$IP:$PORT_VLESS?encryption=none&type=ws&path=$PATH_VLESS#$IP-VLESS"
echo ""
VMESS_JSON=$(cat <<EOF
{
  "v": "2",
  "ps": "$IP-VMESS",
  "add": "$IP",
  "port": "$PORT_VMESS",
  "id": "$UUID_VMESS",
  "aid": "0",
  "net": "ws",
  "type": "none",
  "host": "",
  "path": "$PATH_VMESS",
  "tls": ""
}
EOF
)
echo "VMESS WS:"
echo "vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
echo ""
echo "====================================="
