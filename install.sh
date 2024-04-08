set -e
clear
echo "====================="
echo "Dashactyl Installer"
echo "====================="

install_options(){
    echo "Please select your installation option:"
    echo "[1] Установить Client Panel"
    echo "[2] Конфигурация сеттинга"
    echo "[0] Создать Reverse Proxy"
    echo "========================================"
    read choice
    case $choice in
        1 ) installoption=1
            dependercy_install
            file_install
            settings_configuration
            reverseproxy_configuration
            ;;
        2 ) installoption=2
            settings_configuration
            ;;
        0 ) installoption=0
            reverseproxy_configuration
            ;;
        * ) output "Неверный вариант!"
            install_options
    esac
}

dependercy_install() {
    echo "======================================================"
    echo "Starting Dependercy install."
    echo "======================================================"
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt-get install nodejs npm git -y
    echo "======================================================"
    echo "Dependency Install Completed!"
    echo "======================================================"
}
file_install() {
    echo "======================================================"
    echo "Starting File download."
    echo "======================================================"
    cd /var/www/
    sudo git clone https://github.com/Votion-Development/Dashactyl.git
    cd Dashactyl
    sudo npm install
    sudo npm install forever -g
    echo "======================================================"
    echo "Dashactyl File Download Completed!"
    echo "======================================================"
}
settings_configuration() {
    echo "======================================================"
    echo "Starting Settings Configuration."
    echo "Read the Docs for more information about the settings."
    echo "https://docs.dashactyl.com"
    echo "======================================================"
    cd /var/www/dashactyl/
    file=settings.json

    echo "На каком порту запускать Client Panel? [80]"
    read WEBPORT
    echo "Какой установить Secret Key?"
    read WEB_SECRET
    echo "Домен панели управления"
    read PTERODACTYL_DOMAIN
    echo "Secret key Панели управления"
    read PTERODACTYL_KEY
    echo "Discord Oauth2 ID?"
    read DOAUTH_ID
    echo "Discord Oauth2 Secret?"
    read DOAUTH_SECRET
    echo "Discord Oauth2 Link?"
    read DOAUTH_LINK
    echo "Callback path?" 
    read DOAUTH_CALLBACKPATH
    echo "Prompt [TRUE/FALSE] (When set to true users wont have to relogin after a session)"
    read DOAUTH_PROMPT
    sed -i -e 's/"port":.*/"port": '$WEBPORT',/' -e 's/"secret":.*/"secret": "'$WEB_SECRET'"/' -e 's/"domain":.*/"domain": "'$PTERODACTYL_DOMAIN'",/' -e 's/"key":.*/"key": "'$PTERODACTYL_KEY'"/' -e 's/"id":.*/"id": "'$DOAUTH_ID'",/' -e 's/"link":.*/"link": "'$DOAUTH_LINK'",/' -e 's/"path":.*/"path": "'$DOAUTH_CALLBACKPATH'",/' -e 's/"prompt":.*/"prompt": '$DOAUTH_PROMPT'/' -e '0,/"secret":.*/! {0,/"secret":.*/ s/"secret":.*/"secret": "'$DOAUTH_SECRET'",/}' $file
    echo "-------------------------------------------------------"
    echo "Configuration Settings Completed!"
}
reverseproxy_configuration() {
    echo "-------------------------------------------------------"
    echo "Starting Reverse Proxy Configuration."
    echo "Read the Docs for more infomration about the Configuration."
    echo "https://josh0086.gitbook.io/dashactyl/"
    echo "-------------------------------------------------------"

   echo "Select your webserver [NGINX]"
   read WEBSERVER
   echo "Protocol Type [HTTP]"
   read PROTOCOL
   if [ $PROTOCOL != "HTTP" ]; then
   echo "------------------------------------------------------"
   echo "HTTP is currently only supported on the install script."
   echo "------------------------------------------------------"
   return
   fi
   if [ $WEBSERVER != "NGINX" ]; then
   echo "------------------------------------------------------"
   echo "Aborted, only Nginx is currently supported for the reverse proxy."
   echo "------------------------------------------------------"
   return
   fi
   echo "What is your domain? [example.com]"
   read DOMAIN
   apt install nginx
   sudo wget -O /etc/nginx/conf.d/dashactyl.conf https://raw.githubusercontent.com/J0shh/dashactyl-installer/main/assets/NginxHTTPReverseProxy.conf
   sudo apt-get install jq 
   port=$(jq -r '.["website"]["port"]' /var/www/dashactyl/settings.json)
   sed -i 's/PORT/'$port'/g' /etc/nginx/conf.d/dashactyl.conf
   sed -i 's/DOMAIN/'$DOMAIN'/g' /etc/nginx/conf.d/dashactyl.conf
   sudo nginx -t
   sudo nginx -s reload
   systemctl restart nginx
   echo "-------------------------------------------------------"
   echo "Reverse Proxy Install and configuration completed."
   echo "-------------------------------------------------------"
   echo "Here is the config status:"
   sudo nginx -t
   echo "-------------------------------------------------------"
   echo "Note: if it does not say OK in the line, an error has occurred and you should try again or get help in the Dashactyl Discord Server."
   echo "-------------------------------------------------------"
   if [ $WEBSERVER = "APACHE" ]; then
   echo "Apache isn't currently supported with the install script."
   echo "------------------------------------------------------"
   return
   fi
}
update_check() {
    latest=$(wget https://raw.githubusercontent.com/J0shh/dashactyl-installer/main/assets/LATEST.json -q -O -)
    #latest='"version": "0.1.2-themes6",'
    version=$(grep -Po '"version":.*?[^\\]",' /var/www/dashactyl/settings.json) 

    if [ "$latest" =  "$version" ]; then
    echo "======================================================"
    echo "You're running the latest version of Dashactyl."
    echo "======================================================"
    else 
    echo "======================================================"
    echo "You're running an outdated version of Dashactyl."
    echo "======================================================"
    echo "Would you like to update to the latest version? [Y/N]"
    echo "Bu updating your files will be backed up in /var/www/dashactyl-backup/"
    read UPDATE_OPTION
    echo "-------------------------------------------------------"
    if [ "$UPDATE_OPTION" = "Y" ]; then
    var=`date +"%FORMAT_STRING"`
    now=`date +"%m_%d_%Y"`
    now=`date +"%Y-%m-%d"`
    if [[ ! -e /var/www/dashactyl-backup/ ]]; then
    mkdir /var/www/dashactyl-backup/
    finish_update
    elif [[ ! -d $dir ]]; then
    finish_update
    fi
    else
    echo "Update Aborted"
    echo "Restart the script if this was a mistake."
    echo "-------------------------------------------------------"
    fi
    fi
}
finish_update() {
   tar -czvf "${now}.tar.gz" /var/www/dashactyl/
   mv "${now}.tar.gz" /var/www/dashactyl-backup
   rm -R /var/www/dashactyl/
   file_install
}
install_options
