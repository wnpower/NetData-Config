
# NetData-Config
Script de instalación de [NetData](https://www.netdata.cloud/): Configura los [sensores](https://docs.netdata.cloud/collectors/collectors/) más utilizados (Apache, Nginx, MySQL). Si detecta una instalación cPanel, configura el monitoreo de los servicios anteriormente mencionados con la configuración específica para cPanel.

# Instalación
    wget https://raw.githubusercontent.com/wnpower/NetData-Config/master/install_netdata.sh
    bash install_netdata.sh
## Acceso
Una vez instalado, ingresar mediante https://<IP_SERVIDOR>:19999.
NOTA: NetData no tiene sistema de login, por lo que recomendamos cerrar el puerto 19999 del público en tu Firewall
## Desinstalación
    wget https://raw.githubusercontent.com/wnpower/NetData-Config/master/install_netdata.sh
    bash install_netdata.sh --uninstall
