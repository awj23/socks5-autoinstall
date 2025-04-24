#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# 检查操作系统类型
if [ -n "$(grep 'Aliyun Linux release' /etc/issue)" -o -e /etc/redhat-release ];then
    OS=CentOS
    [ -n "$(grep ' 7\.' /etc/redhat-release)" ] && CentOS_RHEL_version=7
elif [ -n "$(grep bian /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Debian' ];then
    OS=Debian
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Debian_version=$(lsb_release -sr | awk -F. '{print $1}')
elif [ -n "$(grep Ubuntu /etc/issue)" -o "$(lsb_release -is 2>/dev/null)" == 'Ubuntu' ];then
    OS=Ubuntu
    [ ! -e "$(which lsb_release)" ] && { apt-get -y update; apt-get -y install lsb-release; clear; }
    Ubuntu_version=$(lsb_release -sr | awk -F. '{print $1}')
else
    echo "不支持此操作系统，请联系作者！"
    exit 1
fi

# 安装必要的依赖
if [[ ${OS} == Ubuntu || ${OS} == Debian ]]; then
    apt update -y
    apt install git unzip wget gcc g++ automake make libpam0g-dev libldap2-dev libsasl2-dev libssl-dev -y
elif [[ ${OS} == CentOS ]]; then
    yum groupinstall "Development Tools" -y
    yum install git unzip wget gcc gcc-c++ automake make pam-devel openldap-devel cyrus-sasl-devel openssl-devel -y
    yum install chkconfig -y
else
    echo "不支持此操作系统！"
    exit 1
fi

# 创建必要的目录
mkdir -p /etc/opt/ss5/
mkdir -p /etc/sysconfig/

# 下载Socks5服务
Download() {
    echo "下载Socks5服务中..."
    cd /root
    git clone https://github.com/wyx176/Socks5
}

# 安装Socks5服务程序
InstallSock5() {
    echo "解压文件中..."
    cd /root/Socks5
    tar zxvf ss5-3.8.9-8.tar.gz

    echo "安装中..."
    cd /root/Socks5/ss5-3.8.9
    ./configure
    make
    make install
}

# 安装控制面板配置
InstallPanel() {
    mv /root/Socks5/service.sh /etc/opt/ss5/
    mv /root/Socks5/user.sh /etc/opt/ss5/
    mv /root/Socks5/version.txt /etc/opt/ss5/
    mv /root/Socks5/ss5 /etc/sysconfig/
    mv /root/Socks5/s5 /usr/local/bin/
    chmod +x /usr/local/bin/s5

    # 设置默认用户名、密码及端口
    uname="admin"
    upasswd="password"
    port="1080"
    confFile=/etc/opt/ss5/ss5.conf
    echo -e "$uname $upasswd" >> /etc/opt/ss5/ss5.passwd
    sed -i '87c auth    0.0.0.0/0               -               u' $confFile
    sed -i '203c permit u	0.0.0.0/0	-	0.0.0.0/0	-	-	-	-' $confFile

    # 添加开机启动
    chmod +x /etc/init.d/ss5
    systemctl enable ss5
    systemctl start ss5

    # 确保 /var/run/ss5/ 目录存在
    if [ ! -d "/var/run/ss5/" ]; then
        mkdir /var/run/ss5/
    fi
}

# 检测安装完整性
check() {
    if [ ! -f "/usr/local/bin/s5" ] || [ ! -f "/etc/opt/ss5/service.sh" ] || [ ! -f "/etc/opt/ss5/user.sh" ] || [ ! -f "/etc/opt/ss5/ss5.conf" ]; then
        echo "缺失文件，安装失败！"
        exit 1
    else
        echo "Socks5安装完毕！"
        systemctl start ss5
        echo "默认用户名: $uname"
        echo "默认密码  : $upasswd"
        echo "默认端口  : $port"
    fi
}

# 执行各个步骤
Download
InstallSock5
InstallPanel
check
