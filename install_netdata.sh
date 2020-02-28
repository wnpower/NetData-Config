#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TYPE="default"
if [ -d /usr/local/cpanel ]; then
	echo "cPanel detectado."
	TYPE="cpanel"
fi

if [ "$1" = "--uninstall" ]; then
	if [ ! -f /usr/libexec/netdata/netdata-uninstaller.sh ]; then
		echo "Netdata no se encuentra instalado, abortando."
		exit 1
	fi

	/usr/libexec/netdata/netdata-uninstaller.sh --yes --env /etc/netdata/.environment

	if [ "$TYPE" = "cpanel" ]; then
		mysql -f -e "SET GLOBAL validate_password_policy = LOW; drop user 'netdata'@'localhost'; revoke usage on *.* from 'netdata'@'localhost'; flush privileges;"
	else
		echo "#### Si tenías mysql configurado con Netdata, elimina usuario 'netdata' ####"
	fi
	
	exit 0
fi

if [ ! -d /etc/netdata ]; then
	echo "Instalando Netdata..."
	bash <(curl -Ss https://my-netdata.io/kickstart.sh) --disable-telemetry --auto-update
fi

echo "Configurando Netdata..."

if grep -i "Cloudlinux" /etc/redhat-release > /dev/null; then
	echo "CloudLinux detectado, configurando..."
	usermod -aG clsupergid netdata
	cagefsctl --disable netdata
	echo "netdata" > /etc/cagefs/exclude/netdata
fi

echo "Configurando Plugins..."

echo "Configurando Apache..."
if [ "$TYPE" = "default" ]; then
	/bin/cp -af /usr/lib/netdata/conf.d/python.d/apache.conf /etc/netdata/python.d
elif [ "$TYPE" = "cpanel" ]; then

cat > /etc/netdata/python.d/apache.conf << EOF
localhost:
  name : 'local'
  url  : 'http://127.0.0.1/whm-server-status?auto'
EOF

fi

if [ -d /etc/nginx ]; then
	echo "Configurando Nginx..."

	if [ "$TYPE" = "default" ]; then
	        /bin/cp -af /usr/lib/netdata/conf.d/python.d/nginx.conf /etc/netdata/python.d
	elif [ "$TYPE" = "cpanel" ]; then

cat > /etc/netdata/python.d/nginx.conf << EOF
localhost:
  name : 'local'
  url  : 'http://127.0.0.1/nginx_status'
EOF

	fi

fi

echo "Configurando web_log..."

if [ "$TYPE" = "default" ]; then
	/bin/cp -af /usr/lib/netdata/conf.d/python.d/web_log.conf /etc/netdata/python.d
elif [ "$TYPE" = "cpanel" ]; then
	# EN CPANEL APACHE NO TIENE LOS LOGS CENTRALIZADOS, NO SE USA
	if [ -d /etc/nginx ]; then
cat > /etc/netdata/python.d/web_log.conf << EOF
nginx_log:
  name : 'nginx'
  path : '/var/log/nginx/access.log'

EOF

	usermod -aG nginx netdata
	chown :nginx /var/log/nginx/access.log

	fi
fi

echo "Configurando MySQL..."
if [ "$TYPE" = "default" ]; then
        /bin/cp -af /usr/lib/netdata/conf.d/python.d/mysql.conf /etc/netdata/python.d
elif [ "$TYPE" = "cpanel" ]; then
	if grep -i "CentOS 6" /etc/redhat-release > /dev/null; then
		echo "CentOS 6 detectado, instalando MySQL-python mediante pip..."
		yum install python-pip -y
		pip install --upgrade pip
		pip install MySQL-python
	else
		yum install MySQL-python -y
	fi

	mysql -f -e "SET GLOBAL validate_password_policy = LOW; create user 'netdata'@'localhost' identified by 'NetDataDB'; grant usage on *.* to 'netdata'@'localhost'; flush privileges;"

	cat > /etc/netdata/python.d/mysql.conf << EOF
local:
  name     : 'local'
  'my.cnf' : '/etc/my.cnf'
  socket   : '/var/lib/mysql/mysql.sock'
  user     : 'netdata'
  pass     : 'NetDataDB'
EOF

fi

service netdata restart

echo "Listo!, ingresa mediante https://<IP_SERVIDOR>:19999"

exit 0
