#!/bin/bash

TMP_DIR="/tmp"

Add_To_New_Line(){
	if [ "$(tail -n1 $1 | wc -l)" == "0"  ];then
		echo "" >> "$1"
	fi
	echo "$2" >> "$1"
}

Check_And_Add_Line(){
	if [ -z "$(cat "$1" | grep "$2")" ];then
		Add_To_New_Line "$1" "$2"
	fi
}

Update_Upgrade_Packages(){
	echo "#############################################"
	echo "Update Packages..."
	apt-get update
	apt-get upgrade -y
	apt-get dist-upgrade -y
	apt-get autoremove -y
	apt-get autoclean -y
	echo "Update Packages Done."
	if [ -f /var/run/reboot-required ];then 
		echo "Will Reboot in 5s!!!"
		sleep 5
		reboot
	fi
	echo "Install Packages Done."
	echo "#############################################"
}

Install_Bin(){
	wget https://github.com/freakinyy/shadowsocks-rust_server_installer_for_ubuntu/raw/main/shadowsocks-rust_bin_installer.sh%40amd64 -O shadowsocks-rust_bin_installer.sh
	mv shadowsocks-rust_bin_installer.sh /usr/bin
	chmod +x /usr/bin/shadowsocks-rust_bin_installer.sh
	shadowsocks-rust_bin_installer.sh install
}

Uninstall_Bin(){
	shadowsocks-rust_bin_installer.sh uninstall
	rm -f /usr/bin/shadowsocks-rust_bin_installer.sh
}

Install_Rng_tools(){
	echo "#############################################"
	echo "Install Rng-tools..."
	apt-get install --no-install-recommends virt-what -y
	echo "Your Virtualization type is $(virt-what)"
	if [ "$(virt-what)" != "kvm" && "$(virt-what)" != "hyperv" ];then
		echo "Rng-tools can not be used."
		echo "#############################################"
		return 1
	fi
	apt install rng-tools -y
	Check_And_Add_Line "/etc/default/rng-tools" "HRNGDEVICE=/dev/urandom"
	service rng-tools stop
	service rng-tools start
	echo "Install Rng-tools Done."
	echo "#############################################"
}

Install_BBR(){
	echo "#############################################"
	echo "Install TCP_BBR..."
	if [ -n "$(lsmod | grep bbr)" ];then
		echo "TCP_BBR already installed."
		echo "#############################################"
		return 1
	fi
	kernel_version=$(uname -r | grep -oE '[0-9]\.[0-9]' | sed -n 1p)
	can_use_BBR="0"
	if [ "echo $kernel_version | cut -d"." -f1" > "4" ];then
		can_use_BBR="1"
	elif [ "echo $kernel_version | cut -d"." -f1" == "4" ];then
		if [ "echo $kernel_version | cut -d"." -f2" >= "9" ];then
			can_use_BBR="1"
		fi
	fi
	if [ "$can_use_BBR" == "1" ];then
		echo "Your Kernel Version $(uname -r) >= 4.9"
	else
		echo "Your Kernel Version $(uname -r) < 4.9"
		echo "TCP_BBR can not be used."
		echo "#############################################"
		return 1
	fi
	apt-get install --no-install-recommends virt-what -y
	echo "Your Virtualization type is $(virt-what)"
	if [ "$(virt-what)" != "kvm"  && "$(virt-what)" != "hyperv" ];then
		echo "TCP_BBR can not be used."
		echo "#############################################"
		return 1
	fi
	echo "TCP_BBR can be used."
	echo "Start to Install TCP_BBR..."
	modprobe tcp_bbr
	Add_To_New_Line "/etc/modules-load.d/modules.conf" "tcp_bbr"
	Add_To_New_Line "/etc/sysctl.conf" "net.core.default_qdisc = fq"
	Add_To_New_Line "/etc/sysctl.conf" "net.ipv4.tcp_congestion_control = bbr"
	sysctl -p
	if [ -n "$(sysctl net.ipv4.tcp_available_congestion_control | grep bbr)" ] && [ -n "$(sysctl net.ipv4.tcp_congestion_control | grep bbr)" ] && [ -n "$(lsmod | grep "tcp_bbr")" ];then
		echo "TCP_BBR Install Success."
	else
		echo "Fail to Install TCP_BBR."
	fi
	echo "#############################################"
}

Optimize_Parameters(){
	echo "#############################################"
	echo "Optimize Parameters..."
	Check_And_Add_Line "/etc/security/limits.conf" "* soft nofile 51200"
	Check_And_Add_Line "/etc/security/limits.conf" "* hard nofile 51200"
	Check_And_Add_Line "/etc/security/limits.conf" "root soft nofile 51200"
	Check_And_Add_Line "/etc/security/limits.conf" "root hard nofile 51200"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.icmp_echo_ignore_all = 1"
	Check_And_Add_Line "/etc/sysctl.conf" "fs.file-max = 51200"
	Check_And_Add_Line "/etc/sysctl.conf" "net.core.rmem_max = 67108864"
	Check_And_Add_Line "/etc/sysctl.conf" "net.core.wmem_max = 67108864"
	Check_And_Add_Line "/etc/sysctl.conf" "net.core.netdev_max_backlog = 250000"
	Check_And_Add_Line "/etc/sysctl.conf" "net.core.somaxconn = 4096"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_syncookies = 1"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_tw_reuse = 1"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_tw_recycle = 0"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_fin_timeout = 30"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_keepalive_time = 1200"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.ip_local_port_range = 10000 65000"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_max_syn_backlog = 8192"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_max_tw_buckets = 5000"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_fastopen = 3"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_mem = 25600 51200 102400"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_rmem = 4096 87380 67108864"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_wmem = 4096 65536 67108864"
	Check_And_Add_Line "/etc/sysctl.conf" "net.ipv4.tcp_mtu_probing = 1"
	echo "Optimize Parameters Done."
	echo "#############################################"
}

Create_Json(){
	echo "#############################################"
	echo "Create json path and file..."
	if [ -d /etc/shadowsocks-rust_server/ ];then
		json_files=$(ls /etc/shadowsocks-rust_server/ | grep ".json$" )
		if [ -n "$json_files" ];then
			echo "Json path and file already exit, abort."
			echo "#############################################"
			return 1
		else
			rm -rf /etc/shadowsocks-rust_server/
		fi
	fi
	mkdir -p /etc/shadowsocks-rust_server/
	your_password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c128 | sha1sum | cut -d " " -f1)
	touch /etc/shadowsocks-rust_server/default.json
	cat >> /etc/shadowsocks-rust_server/default.json <<EOF
{
	"server":"::",
	"server_port":443,
	"password":"$your_password",
	"method":"chacha20-ietf-poly1305",
	"timeout":300,
	"plugin":"/usr/bin/v2ray-plugin",
	"plugin_opts":"server;host=cloudflare.com",
	"fast_open":true,
	"mode":"tcp_and_udp",
	"udp_timeout": 5,
	"udp_max_associations": 2048,
	"user":"root",
	"nofile": 51200
}
EOF
	echo "Create json path and file Done."
	echo "#############################################"
}

Remove_Json(){
	echo "#############################################"
	echo "Remove json path and file..."
	rm -rf /etc/shadowsocks-rust_server/
	echo "Remove json path and file Done."
	echo "#############################################"
}

Create_Service(){
	echo "#############################################"
	echo "Create Service..."
	if [ -f /etc/init.d/shadowsocks-rust_server ];then
		service shadowsocks-rust_server stop
		update-rc.d -f shadowsocks-rust_server remove
		rm -f /etc/init.d/shadowsocks-rust_server
	fi
	wget https://github.com/freakinyy/shadowsocks-rust_server_installer_for_ubuntu/raw/main/shadowsocks-rust_server.service%40ubuntu -O shadowsocks-rust_server.service@ubuntu
	mv shadowsocks-rust_server.service@ubuntu /etc/init.d/shadowsocks-rust_server
	chmod +x /etc/init.d/shadowsocks-rust_server
	update-rc.d -f shadowsocks-rust_server defaults 95
	echo "Create Service Done."
	echo "#############################################"
}

Remove_Service(){
	echo "#############################################"
	echo "Remove Service..."
	service shadowsocks-rust_server stop
	update-rc.d -f shadowsocks-rust_server remove
	rm -f /etc/init.d/shadowsocks-rust_server
	echo "Remove Service Done."
	echo "#############################################"
}

Add_to_Crontab(){
	echo "#############################################"
	echo "Add updates-and-upgrades to crontab, you should modify these items and their schedules at your own favor..."
	rm -f $TMP_DIR/crontab.bak
	touch $TMP_DIR/crontab.bak
	crontab -l >> $TMP_DIR/crontab.bak
	
	start_line_num=$(grep -n "#shadowsocks-rust_server modifies start" $TMP_DIR/crontab.bak | cut -d":" -f1)
	end_line_num=$(grep -n "#shadowsocks-rust_server modifies end" $TMP_DIR/crontab.bak | cut -d":" -f1)
	if [ -n "$start_line_num" ] || [ -n "$end_line_num" ];then
		echo "It seems that crontab has already modified by this scprit, abort."
		echo "Please Check Crontab!!!"
		echo "#############################################"
		return 1
	fi
	
	cat >> $TMP_DIR/crontab.bak <<EOF
#shadowsocks-rust_server modifies start
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
20 04 * * * apt update && apt upgrade -y && apt dist-upgrade -y && apt autoremove -y && apt autoclean
40 04 * * * [ -f /var/run/reboot-required ] && reboot
50 04 * * * shadowsocks-rust_bin_installer.sh update
#shadowsocks-rust_server modifies end
EOF
	crontab $TMP_DIR/crontab.bak
	echo "Add updates-and-upgrades to crontab Done."
	echo "#############################################"
}

Remove_from_Crontab(){
	echo "#############################################"
	echo "Remove updates-and-upgrades from crontab..."
	rm -f $TMP_DIR/crontab.bak
	touch $TMP_DIR/crontab.bak
	crontab -l >> $TMP_DIR/crontab.bak
	start_line_num=$(grep -n "#shadowsocks-rust_server modifies start" $TMP_DIR/crontab.bak | cut -d":" -f1)
	end_line_num=$(grep -n "#shadowsocks-rust_server modifies end" $TMP_DIR/crontab.bak | cut -d":" -f1)
	[ -n "$start_line_num" ] && [ -n "$end_line_num" ] && sed -i ''"$start_line_num"','"$end_line_num"'d' $TMP_DIR/crontab.bak
	crontab $TMP_DIR/crontab.bak
	echo "Remove updates-and-upgrades from crontab Done."
	echo "#############################################"
}

Show_Json(){
	echo "#############################################"
	echo "Your json file is located in: /etc/shadowsocks-rust_server/"
	json_files=$(ls /etc/shadowsocks-rust_server/ | grep ".json$" )
	echo "Here is your config:"
	for json_file in $json_files; do
		echo "###########################"
		echo "$json_file:"
		cat /etc/shadowsocks-rust_server/$json_file
	done
	echo "#############################################"
}

Do_Install(){
	echo "#########################################################################"
	echo "Start Install Shadowsocks-rust_server..."
	service shadowsocks-rust_server stop
	Update_Upgrade_Packages
	apt install jq -y
	Install_Bin
	Install_Rng_tools
	Install_BBR
	Optimize_Parameters
	Create_Json
	Create_Service
	Add_to_Crontab
	service shadowsocks-rust_server start
	Show_Json
	echo "All Install Done!"
	echo "#########################################################################"
}

Do_Uninstall(){
	echo "#########################################################################"
	echo "Start Uninstall Shadowsocks-rust_server..."
	service shadowsocks-rust_server stop
	Remove_from_Crontab
	Remove_Service
	Remove_Json
	Uninstall_Bin
	echo "All Uninstall Done!"
	echo "#########################################################################"
}

Do_Re_InstallService(){
	echo "#########################################################################"
	echo "Start Re-Install Shadowsocks-rust_server Service..."
	service shadowsocks-rust_server stop
	Remove_Service
	Create_Service
	service shadowsocks-rust_server start
	echo "Re-Install Service Done!"
	echo "#########################################################################"
}

case "$1" in
install)			Do_Install
					;;
uninstall)			Do_Uninstall
					;;
optimizeparameters)	Optimize_Parameters
					;;
reinstallservice)	Do_Re_InstallService
					;;
*)					echo "Usage: install|uninstall|optimizeparameters|reinstallservice"
					exit 2
					;;
esac
exit 0
