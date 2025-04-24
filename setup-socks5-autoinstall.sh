#!/bin/bash

FLAG_FILE="/usr/local/bin/s5_installed.flag"
if [ -f "$FLAG_FILE" ]; then
  echo "Socks5 已安装，跳过。"
  exit 0
fi

echo "开始安装 Socks5..."

# 安装必要组件
apt update
apt install -y wget gcc make libpam0g-dev libwrap0-dev

# 下载并安装 Dante Socks5
cd /tmp
wget -O dante.tar.gz https://www.inet.no/dante/files/dante-1.4.2.tar.gz
tar -xzf dante.tar.gz
cd dante-1.4.2
./configure --prefix=/usr --sysconfdir=/etc
make && make install

# 添加默认用户 admin:passwa
useradd -M -s /usr/sbin/nologin admin
echo "admin:passwa" | chpasswd

# 创建 socks5 配置文件
cat > /etc/sockd.conf <<EOF
logoutput: /var/log/sockd.log
internal: 0.0.0.0 port = 1080
external: eth0

method: username
user.notprivileged: nobody

client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: connect disconnect error
  method: username
}

socks pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: connect disconnect error
  method: username
}
EOF

# 日志文件准备
touch /var/log/sockd.log
chown nobody:nogroup /var/log/sockd.log

# 创建 systemd 服务
cat > /etc/systemd/system/sockd.service <<EOF
[Unit]
Description=Dante SOCKS5 Server
After=network.target

[Service]
ExecStart=/usr/sbin/sockd -f /etc/sockd.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启用服务
systemctl daemon-reload
systemctl enable sockd
systemctl start sockd

# 创建标志避免重复执行
touch "$FLAG_FILE"

echo "✅ Socks5 安装完成，监听端口 1080"
echo "🔐 登录账号：admin"
echo "🔐 登录密码：passwa"
