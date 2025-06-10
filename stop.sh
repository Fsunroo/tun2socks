#!/bin/bash
#
# System-wide VPN via SOCKS5 Proxy
# https://github.com/[YourUsername]/[YourRepoName]

set -e

# --- DO NOT EDIT ---
TUN_DEVICE="tun0"
ROUTE_INFO_FILE="/tmp/tun2socks_route_info"
PID_FILE="/tmp/tun2socks_pid"

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

echo "==> Stopping System-Wide VPN..."

ip link set dev $TUN_DEVICE down 2>/dev/null || true
echo "--> Virtual network device '$TUN_DEVICE' is down"

if [ -f $PID_FILE ]; then
    PID_TO_KILL=$(cat $PID_FILE)
    kill $PID_TO_KILL 2>/dev/null || true
    rm $PID_FILE
    echo "--> SOCKS5 forwarder stopped (PID: $PID_TO_KILL)"
else
    pkill go-tun2socks 2>/dev/null || true
fi

sleep 1

if [ -f $ROUTE_INFO_FILE ]; then
    ORIG_GATEWAY_INFO=$(cat $ROUTE_INFO_FILE)
    ip route replace $ORIG_GATEWAY_INFO
    rm $ROUTE_INFO_FILE
    echo "--> Original gateway restored"
else
    echo "WARNING: Original route info not found. You may need to restart your network service."
fi

echo "🛑 VPN is now INACTIVE. System traffic is back to normal."
