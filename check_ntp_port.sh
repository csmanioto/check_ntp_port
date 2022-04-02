#!/bin/bash
test_distro(){
    if test -f /etc/debian_version; then
        echo "DEBIAN"
    else
        echo "REDHAT"
    fi
}

setup(){
    setting_user=$1

   if [ $(test_distro) == "DEBIAN" ]; then
        echo "Configurando em ambiente debian like"
        sudo apt-get install logrotate
        sudo apt-get install nmap
        sudo apt-get install libcap2-bin
        sudo setcap cap_net_raw,cap_net_admin,cap_net_bind_service+eip $(which nmap)
        #getcap $(which nmap)
    else
        echo "Configurando em ambiente redhat like"
        sudo yum install logrotate
        sudo yum install nmap
        sudo yum install libcap
        sudo setcap cap_net_raw,cap_net_admin,cap_net_bind_service+eip $(which nmap)
    fi

    echo "Configurando log rotate"
    if [[ ! -f /etc/logrotate.d/check_ntp_port.conf ]]; then
        sudo cat << EOF > $(pwd)/check_ntp_port.conf
/var/log/check_ntp_port/* {
    daily
    rotate 7
    size 10M
    dateext
    compress
    delaycompress
    su root $setting_user
}
EOF
        sudo cp $(pwd)/check_ntp_port.conf /etc/logrotate.d/check_ntp_port.conf
        sudo chmod 0644 /etc/logrotate.d/check_ntp_port.conf
        sudo chown root:$setting_user /etc/logrotate.d/check_ntp_port.conf
        sudo mkdir -p /var/log/check_ntp_port/
        sudo chmod 755 /var/log/check_ntp_port/
        sudo chown $setting_user:$setting_user /var/log/check_ntp_port/
        sudo logrotate -v -f /etc/logrotate.d/check_ntp_port.conf
    fi
}

run(){
    ntp_server=$1
    log_name=$( echo $ntp_server | tr '.' '_' )
    log_name+=".log"
    if nmap --privileged -p 123 -sU $ntp_server |grep -i "open" >> /var/log/check_ntp_port/${log_name}; then
        echo "GOOD"
        exit 0;
    else
        echo "FAIL"
        exit 1;
    fi
}


case "$1" in
    -s|--setup)
            setup $2
        ;;

    -r|--run)
            run $2
            ;;

    --help|*)
            echo  "Para usar:"
            echo  "check_ntp_port.sh --setup user"
            echo  "check_ntp_port.sh --run ntp_server"
            ;;
esac
