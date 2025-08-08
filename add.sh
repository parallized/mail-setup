#!/bin/bash
# 用法: ./add_mail_user.sh 邮箱地址 密码

MAIL_DIR="/var/mail/vhosts"
MAIL_UID=5000
MAIL_GID=5000

if [ $# -ne 2 ]; then
    echo "用法: $0 邮箱地址 密码"
    exit 1
fi

EMAIL="$1"
PASS="$2"
DOMAIN=$(echo $EMAIL | cut -d@ -f2)
USER=$(echo $EMAIL | cut -d@ -f1)

# 创建邮箱目录
mkdir -p ${MAIL_DIR}/${DOMAIN}/${USER}
chown -R ${MAIL_UID}:${MAIL_GID} ${MAIL_DIR}/${DOMAIN}/${USER}

# 写入 Dovecot 密码文件（如果已存在同邮箱会覆盖）
grep -v "^${EMAIL}:" /etc/dovecot/passwd > /etc/dovecot/passwd.tmp || true
mv /etc/dovecot/passwd.tmp /etc/dovecot/passwd
echo "${EMAIL}:{PLAIN}${PASS}" >> /etc/dovecot/passwd

echo "账号已创建: $EMAIL"
echo "密码: $PASS"
systemctl restart dovecot
