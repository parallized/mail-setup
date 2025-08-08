#!/bin/bash
set -e

# ===== 配置部分 =====
MAIL_DOMAIN="mail.parallized.cn" # 邮件域名
MAIL_UID=5000                    # 虚拟用户 UID
MAIL_GID=5000                    # 虚拟用户 GID
MAIL_DIR="/var/mail/vhosts"

# ===== 安装依赖 =====
apt update
apt install -y dovecot-core dovecot-imapd dovecot-pop3d certbot

# ===== 创建虚拟用户目录和用户组 =====
mkdir -p ${MAIL_DIR}
groupadd -g ${MAIL_GID} vmail || true
useradd -g ${MAIL_GID} -u ${MAIL_UID} vmail || true
chown -R vmail:vmail ${MAIL_DIR}

# ===== 申请 SSL 证书 =====
certbot certonly --standalone -d ${MAIL_DOMAIN} --non-interactive --agree-tos -m admin@parallized.cn

# ===== 配置 Dovecot =====
cat >/etc/dovecot/dovecot.conf <<EOF
disable_plaintext_auth = yes
mail_location = maildir:${MAIL_DIR}/%d/%n
passdb {
  driver = passwd-file
  args = /etc/dovecot/passwd
}
userdb {
  driver = static
  args = uid=${MAIL_UID} gid=${MAIL_GID} home=${MAIL_DIR}/%d/%n
}
protocols = imap pop3
ssl = required
ssl_cert = </etc/letsencrypt/live/${MAIL_DOMAIN}/fullchain.pem
ssl_key = </etc/letsencrypt/live/${MAIL_DOMAIN}/privkey.pem
EOF

# ===== 初始化密码文件 =====
touch /etc/dovecot/passwd
chmod 600 /etc/dovecot/passwd

# ===== 启动服务 =====
systemctl enable dovecot
systemctl restart dovecot

echo "=================================="
echo "邮件接收服务器已安装完成"
echo "域名: ${MAIL_DOMAIN}"
echo "可以使用 add_mail_user.sh 新增邮箱账号"
echo "=================================="
