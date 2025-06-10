# System-Wide VPN via SOCKS5 Proxy

This project provides a pair of simple shell scripts to route all network traffic from your Linux machine through a local SOCKS5 proxy, effectively turning it into a system-wide VPN.

It is designed to work with proxy clients like **Nekoray**, V2Ray, or any application that provides a local SOCKS5 port. This is a robust alternative to `iptables` `TPROXY` methods and works on systems where TPROXY is unsupported or difficult to configure.

## Features

- **System-Wide Tunneling:** Routes all applications and terminal traffic through the proxy.
- **Intelligent Routing:** Automatically excludes the proxy server's own IP address to prevent routing loops.
- **Clean Shutdown:** Safely restores your original network configuration when stopped.
- **Minimal Dependencies:** Requires only `iproute2` (installed on most Linux systems) and a `go-tun2socks` binary.

## Prerequisites

1.  **A SOCKS5 Proxy:** You must have a proxy client like Nekoray running and configured. These scripts assume it is listening on `127.0.0.1:2081`.
2.  **`iproute2`:** A core Linux networking utility. It's almost certainly already installed on your system.
3.  **`go-tun2socks`:** A binary that creates a virtual network interface and forwards traffic. You will need to download this.

## Installation

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/fsunroo/tun2socks.git
    cd tun2socks
    ```

2.  **Download `go-tun2socks`:**
    - Go to the [**`go-tun2socks` Releases Page**](https://github.com/xjasonlyu/tun2socks/releases).
    - Download the latest `.zip` file for your system's architecture (it's usually `...-linux-amd64.zip`).
    - Unzip the file and rename the binary to `go-tun2socks`.
    - Place the `go-tun2socks` binary in the same directory as the `start.sh` and `stop.sh` scripts.
    - Make all three files executable:
      ```bash
      chmod +x go-tun2socks start.sh stop.sh
      ```
      or you can just
        ```bash
        wget https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-linux-amd64.zip
        unzip tun2socks-linux-amd64.zip
        
        mv tun2socks-linux-amd64 go-tun2socks
        chmod +x go-tun2socks
        chmod +x go-tun2socks start.sh stop.sh
        ```

## Configuration

Before you can use the scripts, you must configure the IP address of your remote proxy server.

1.  **Find your server's IP address.** If your proxy client is configured with a domain name (e.g., `my-server.com`), use the `ping` command to find its static IP address:
    ```bash
    ping my-server.com
    ```
    You will see an output like `PING my-server.com (12.34.56.78)`. The IP is `12.34.56.78`.

2.  **Edit `start.sh`:**
    - Open the `start.sh` file in a text editor.
    - Find the line `VLESS_SERVER_IP="1.2.3.4"` and replace `1.2.3.4` with the real IP address you found in the previous step.
    - If your SOCKS5 proxy uses a different port than `2081`, update the `PROXY_ADDR` variable as well.

## Usage

All commands must be run with `sudo` because they modify network settings.

-   **To Start the VPN:**
    Make sure your proxy client (e.g., Nekoray) is running. Then, execute the start script:
    ```bash
    sudo ./start.sh
    ```

-   **To Stop the VPN:**
    Execute the stop script to restore your normal internet connection:
    ```bash
    sudo ./stop.sh
    ```

## How It Works

1.  **`go-tun2socks`** starts and creates a virtual network interface called `tun0`. It listens for any traffic sent to this device.
2.  The **`start.sh`** script then manually configures `tun0` with an IP address.
3.  The script saves your current default internet route (your "gateway").
4.  It adds a specific rule telling the system that traffic to your remote proxy server's IP should use the original gateway. This is crucial to prevent a routing loop.
5.  Finally, it replaces the system's default route with a new one that points all traffic to the `tun0` device.
6.  All system traffic now goes to `tun0`, where `go-tun2socks` forwards it to your SOCKS5 proxy, which then sends it to the internet.
7.  The **`stop.sh`** script simply reverses this process, killing the `go-tun2socks` process and restoring your original default route.
