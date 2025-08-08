#!/bin/bash
set -e

MAIL_DOMAIN="mail.parallized.cn"
DB_NAME="roundcube"
DB_USER="roundcube"
DB_PASS="roundcube_pass"
WEB_ROOT="/var/www/roundcube"

# ===== 安装依赖 =====
apt update
apt install -y nginx php-fpm php-mysql mariadb-server unzip certbot python3-certbot-nginx wget

# ===== 创建数据库 =====
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"

# ===== 下载 Roundcube =====
wget https://github.com/roundcube/roundcubemail/releases/download/1.6.6/roundcubemail-1.6.6-complete.tar.gz -O /tmp/roundcube.tar.gz
mkdir -p /var/www
tar xzf /tmp/roundcube.tar.gz -C /var/www
mv /var/www/roundcubemail-* ${WEB_ROOT}
chown -R www-data:www-data ${WEB_ROOT}

# ===== 配置 Nginx =====
cat >/etc/nginx/sites-available/roundcube <<EOF
server {
    listen 80;
    server_name ${MAIL_DOMAIN};

    root ${WEB_ROOT};
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

ln -sf /etc/nginx/sites-available/roundcube /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx php8.1-fpm

# ===== 申请 HTTPS 证书 =====
certbot --nginx -d ${MAIL_DOMAIN} --non-interactive --agree-tos -m admin@parallized.cn

# ===== Roundcube 初始配置 =====
cp ${WEB_ROOT}/config/config.inc.php.sample ${WEB_ROOT}/config/config.inc.php
sed -i "s/'sqlite',/'mysql',/" ${WEB_ROOT}/config/config.inc.php
sed -i "s#'sqlite:////var/roundcube.db'#'mysql://${DB_USER}:${DB_PASS}@localhost/${DB_NAME}'#" ${WEB_ROOT}/config/config.inc.php

cat >>${WEB_ROOT}/config/config.inc.php <<RC_END

\$config['default_host'] = 'ssl://${MAIL_DOMAIN}';
\$config['default_port'] = 993;
\$config['smtp_server'] = '';
\$config['smtp_port'] = 25;
\$config['smtp_user'] = '';
\$config['smtp_pass'] = '';
\$config['support_url'] = '';
\$config['product_name'] = 'Parallized Webmail';
\$config['des_key'] = '$(head -c 24 /dev/urandom | base64)';
\$config['plugins'] = array();
RC_END

chown -R www-data:www-data ${WEB_ROOT}

# ===== 完成 =====
echo "======================================="
echo "Roundcube 已安装完成！"
echo "访问: https://${MAIL_DOMAIN}"
echo "用 add_mail_user.sh 创建的邮箱账号登录即可收邮件"
echo "数据库: ${DB_NAME} 用户: ${DB_USER} 密码: ${DB_PASS}"
echo "======================================="
