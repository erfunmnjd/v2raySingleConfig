#!/bin/bash
set -e

echo "=== Installing V2Ray Core ==="
apt update -y
apt install -y curl unzip ufw

bash <(curl -L https://github.com/v2fly/fhs-install-v2ray/raw/master/install-release.sh)

# Generate random values
UUID_VLESS=$(cat /proc/sys/kernel/random/uuid)
UUID_VMESS=$(cat /proc/sys/kernel/random/uuid)
TROJAN_PASS=$(openssl rand -hex 12)

PORT_VLESS=$(shuf -i 20000-40000 -n 1)
PORT_VMESS=$(shuf -i 20000-40000 -n 1)
PORT_TROJAN=$(shuf -i 20000-40000 -n 1)

PATH_VLESS="/vlessws"
PATH_VMESS="/vmessws"
PATH_TROJAN="/trojanws"

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
    },
    {
      "port": $PORT_TROJAN,
      "protocol": "trojan",
      "settings": {
        "clients": [{ "password": "$TROJAN_PASS" }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "$PATH_TROJAN" }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
EOF

echo "=== Opening firewall ports ==="
ufw allow $PORT_VLESS
ufw allow $PORT_VMESS
ufw allow $PORT_TROJAN
ufw reload || true

echo "=== Restarting V2Ray ==="
systemctl enable v2ray
systemctl restart v2ray

IP=$(curl -s ipv4.icanhazip.com)

echo ""
echo "=============================="
echo "      V2RAY WS CONFIGS"
echo "=============================="
echo ""
echo "VLESS WS:"
echo "vless://$UUID_VLESS@$IP:$PORT_VLESS?encryption=none&type=ws&path=$PATH_VLESS#$IP-VLESS"
echo ""
echo "VMESS WS:"
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
echo "vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
echo ""
echo "TROJAN WS:"
echo "trojan://$TROJAN_PASS@$IP:$PORT_TROJAN?type=ws&path=$PATH_TROJAN#$IP-TROJAN"
echo ""
echo "=============================="
echo "Done!"
