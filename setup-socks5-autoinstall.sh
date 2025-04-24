#!/bin/bash

# 创建 Socks5 安装脚本
cat << 'EOF' > /usr/local/bin/install-socks5.sh
#!/bin/bash
if [ ! -f /usr/local/bin/socks5_installed.flag ]; then
  apt update
  apt install -y wget
  wget -q -N --no-check-certificate https://raw.githubusercontent.com/wyx176/Socks5/master/install.sh
  bash install.sh
  touch /usr/local/bin/socks5_installed.flag
fi
EOF

# 设置执行权限
chmod +x /usr/local/bin/install-socks5.sh

# 创建 systemd 服务
cat << 'EOF' > /etc/systemd/system/socks5-install.service
[Unit]
Description=Auto Install Socks5 on Boot (Only Once)
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/install-socks5.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# 启用 systemd 服务
systemctl daemon-reexec
systemctl enable socks5-install.service

echo "✅ Socks5 开机自动安装服务已设置完成"
