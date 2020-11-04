# shadowsocks-rust_server_installer_for_ubuntu


1. Fetures

1.1 Install binaries from shadowsocks-rust and v2ray-plugin.

1.2 Create a service for management ssserver.

1.3 Enable tcp-bbr.

1.4 Install rng-tools for better random number gen.

1.5 Add a shedule for automatic update for shadowsocks-rust and v2ray-plugin from github releases.


2. Install:

`wget https://github.com/freakinyy/shadowsocks-rust_server_installer_for_ubuntu/raw/main/shadowsocks-rust_server_installer_for_ubuntu.sh`
`chmod +x shadowsocks-rust_server_installer_for_ubuntu.sh`
`./shadowsocks-rust_server_installer_for_ubuntu.sh install`


3. Uinstall:

`./shadowsocks-rust_server_installer_for_ubuntu.sh uninstall`

4. Usage:

4.1 Edit config:

Edit default.json in /etc/init.d/shadowsocks-rust_server, or create one or more .json file(s) in the folder.

4.2 Service control

`service shadowsocks-rust_server start|stop|restart|status`

4.3 Edit update shedule

`crontab -e`
