#!/bin/bash
#
# System-wide VPN via SOCKS5 Proxy
# https://github.com/[YourUsername]/[YourRepoName]

set -e

# --- CONFIGURATION ---
# 1. IP address of your remote proxy server (e.g., VLESS, Shadowsocks).
#    Find it by running: ping your-server-domain.com
VLESS_SERVER_IP="1.2.3.4" 

# 2. Path to the go-tun2socks binary.
TUN2SOCKS_BIN="./go-tun2socks"

# 3. Local SOCKS5 proxy address and port.
PROXY_ADDR="127.0.0.1:2081"

# --- DO NOT EDIT BELOW THIS LINE ---
TUN_DEVICE="tun0"
TUN_IP="198.18.0.1/24"
TUN_GW="198.18.0.1"    
ROUTE_INFO_FILE="/tmp/tun2socks_route_info"
PID_FILE="/tmp/tun2socks_pid"

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

if [ "$VLESS_SERVER_IP" = "1.2.3.4" ]; then
  echo "ERROR: Please edit this script and set the VLESS_SERVER_IP variable." >&2
  exit 1
fi

echo "==> Starting System-Wide VPN..."

$TUN2SOCKS_BIN -device $TUN_DEVICE -proxy socks5://$PROXY_ADDR &
TUN2SOCKS_PID=$!
echo $TUN2SOCKS_PID > $PID_FILE
echo "--> SOCKS5 forwarder started (PID: $TUN2SOCKS_PID)"

sleep 2

ip addr add $TUN_IP dev $TUN_DEVICE
ip link set dev $TUN_DEVICE up
echo "--> Virtual network device '$TUN_DEVICE' is up"

ip route | grep default | head -n1 > $ROUTE_INFO_FILE
ORIG_GATEWAY=$(cat $ROUTE_INFO_FILE | awk '{print $3}')
ORIG_DEVICE=$(cat $ROUTE_INFO_FILE | awk '{print $5}')
echo "--> Original gateway saved ($ORIG_GATEWAY via $ORIG_DEVICE)"

echo "--> Rerouting traffic..."
ip route add $VLESS_SERVER_IP via $ORIG_GATEWAY dev $ORIG_DEVICE 2>/dev/null || true
ip route replace default via $TUN_GW dev $TUN_DEVICE

for range in 127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16; do
    ip route add $range via $ORIG_GATEWAY dev $ORIG_DEVICE 2>/dev/null || true
done

echo "✅ VPN is now ACTIVE. All system traffic is being routed."
