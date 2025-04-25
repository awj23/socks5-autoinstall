#!/bin/bash

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN="\033[0m"

# 检查是否为root用户
if [ $EUID -ne 0 ]; then
    echo -e "${RED}错误：请使用root用户运行此脚本${PLAIN}"
    exit 1
fi

# 检测系统
check_sys(){
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"; then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
        release="centos"
    fi
}

# 安装依赖
install_dependencies(){
    if [[ ${release} == "centos" ]]; then
        yum install -y gcc make curl wget
    else
        apt-get update
        apt-get install -y gcc make curl wget
    fi
}

# 安装3proxy
install_3proxy(){
    echo -e "${GREEN}开始安装3proxy...${PLAIN}"
    cd /tmp
    wget https://github.com/z3APA3A/3proxy/archive/0.9.3.tar.gz
    tar xzf 0.9.3.tar.gz
    cd 3proxy-0.9.3
    make -f Makefile.Linux
    mkdir -p /usr/local/3proxy
    cp bin/3proxy /usr/local/3proxy/
    cd ..
    rm -rf 3proxy-0.9.3
    rm -f 0.9.3.tar.gz
}

# 配置3proxy
configure_3proxy(){
    echo -e "${GREEN}配置3proxy...${PLAIN}"
    mkdir -p /usr/local/3proxy/conf
    cat > /usr/local/3proxy/conf/3proxy.cfg << EOF
daemon
maxconn 1000
nserver 8.8.8.8
nserver 8.8.4.4
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456
flush
auth strong
users user:CL:pass
allow user
socks -p2000
EOF

    # 创建systemd服务
    cat > /etc/systemd/system/3proxy.service << EOF
[Unit]
Description=3proxy Proxy Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/3proxy/3proxy /usr/local/3proxy/conf/3proxy.cfg
RemainAfterExit=yes
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable 3proxy
    systemctl start 3proxy
}

# 配置防火墙
configure_firewall(){
    echo -e "${GREEN}配置防火墙...${PLAIN}"
    if [[ ${release} == "centos" ]]; then
        firewall-cmd --permanent --add-port=2000/tcp
        firewall-cmd --reload
    else
        ufw allow 2000/tcp
        ufw reload
    fi
}

# 主函数
main(){
    check_sys
    echo -e "${GREEN}系统检测完成，开始安装...${PLAIN}"
    install_dependencies
    install_3proxy
    configure_3proxy
    configure_firewall
    
    echo -e "${GREEN}安装完成！${PLAIN}"
    echo -e "${YELLOW}Socks5代理服务器信息：${PLAIN}"
    echo -e "IP地址：$(curl -s ifconfig.me)"
    echo -e "端口：2000"
    echo -e "用户名：user"
    echo -e "密码：pass"
    echo -e "\n${YELLOW}使用以下命令管理服务：${PLAIN}"
    echo -e "启动：systemctl start 3proxy"
    echo -e "停止：systemctl stop 3proxy"
    echo -e "重启：systemctl restart 3proxy"
    echo -e "状态：systemctl status 3proxy"
}

main 
