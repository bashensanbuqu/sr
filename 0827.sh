#!/bin/bash
# shadowsocksR/SSR涓€閿畨瑁呮暀绋�
# Author: 姊瓙鍗氬<https://tizi.blog>


RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

V6_PROXY=""
IP=`curl -sL -4 ip.sb`
if [[ "$?" != "0" ]]; then
    IP=`curl -sL -6 ip.sb`
    V6_PROXY="https://gh.hijk.art/"
fi

FILENAME="ShadowsocksR-v3.2.2"
URL="${V6_PROXY}https://github.com/shadowsocksrr/shadowsocksr/archive/3.2.2.tar.gz"
BASE=`pwd`

OS=`hostnamectl | grep -i system | cut -d: -f2`

CONFIG_FILE="/etc/shadowsocksR.json"
SERVICE_FILE="/etc/systemd/system/shadowsocksR.service"
NAME="shadowsocksR"

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}


checkSystem() {
    result=$(id | awk '{print $1}')
    if [[ $result != "uid=0(root)" ]]; then
        colorEcho $RED " 璇蜂互root韬唤鎵ц璇ヨ剼鏈�"
        exit 1
    fi

    res=`which yum 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        res=`which apt 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " 涓嶅彈鏀寔鐨凩inux绯荤粺"
            exit 1
        fi
        PMT="apt"
        CMD_INSTALL="apt install -y "
        CMD_REMOVE="apt remove -y "
        CMD_UPGRADE="apt update && apt upgrade -y; apt autoremove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
        CMD_REMOVE="yum remove -y "
        CMD_UPGRADE="yum update -y"
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " 绯荤粺鐗堟湰杩囦綆锛岃鍗囩骇鍒版渶鏂扮増鏈�"
        exit 1
    fi
}

getData() {
    echo ""
    read -p " 璇疯缃甋SR鐨勫瘑鐮侊紙涓嶈緭鍏ュ垯闅忔満鐢熸垚锛�:" PASSWORD
    [[ -z "$PASSWORD" ]] && PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    echo ""
    colorEcho $BLUE " 瀵嗙爜锛� $PASSWORD"

    echo ""
    while true
    do
        read -p " 璇疯缃甋SR鐨勭鍙ｅ彿[1-65535]:" PORT
        [[ -z "$PORT" ]] && PORT=`shuf -i1025-65000 -n1`
        if [[ "${PORT:0:1}" = "0" ]]; then
            echo -e " ${RED}绔彛涓嶈兘浠�0寮€澶�${PLAIN}"
            exit 1
        fi
        expr $PORT + 0 &>/dev/null
        if [[ $? -eq 0 ]]; then
            if [ $PORT -ge 1 ] && [ $PORT -le 65535 ]; then
                echo ""
                colorEcho $BLUE " 绔彛鍙凤細 $PORT"
                break
            else
                colorEcho $RED " 杈撳叆閿欒锛岀鍙ｅ彿涓�1-65535鐨勬暟瀛�"
            fi
        else
            colorEcho $RED " 杈撳叆閿欒锛岀鍙ｅ彿涓�1-65535鐨勬暟瀛�"
        fi
    done

    echo ""
    colorEcho $BLUE " 璇烽€夋嫨SSR鐨勫姞瀵嗘柟寮�:" 
    echo "  1)aes-256-cfb"
    echo "  2)aes-192-cfb"
    echo "  3)aes-128-cfb"
    echo "  4)aes-256-ctr"
    echo "  5)aes-192-ctr"
    echo "  6)aes-128-ctr"
    echo "  7)aes-256-cfb8"
    echo "  8)aes-192-cfb8"
    echo "  9)aes-128-cfb8"
    echo "  10)camellia-128-cfb"
    echo "  11)camellia-192-cfb"
    echo "  12)camellia-256-cfb"
    echo "  13)chacha20-ietf"
    read -p " 璇烽€夋嫨鍔犲瘑鏂瑰紡锛堥粯璁es-256-cfb锛�" answer
    if [[ -z "$answer" ]]; then
        METHOD="aes-256-cfb"
    else
        case $answer in
        1)
            METHOD="aes-256-cfb"
            ;;
        2)
            METHOD="aes-192-cfb"
            ;;
        3)
            METHOD="aes-128-cfb"
            ;;
        4)
            METHOD="aes-256-ctr"
            ;;
        5)
            METHOD="aes-192-ctr"
            ;;
        6)
            METHOD="aes-128-ctr"
            ;;
        7)
            METHOD="aes-256-cfb8"
            ;;
        8)
            METHOD="aes-192-cfb8"
            ;;
        9)
            METHOD="aes-128-cfb8"
            ;;
        10)
            METHOD="camellia-128-cfb"
            ;;
        11)
            METHOD="camellia-192-cfb"
            ;;
        12)
            METHOD="camellia-256-cfb"
            ;;
        13)
            METHOD="chacha20-ietf"
            ;;
        *)
            colorEcho $RED " 鏃犳晥鐨勯€夋嫨锛屼娇鐢ㄩ粯璁ゅ姞瀵嗘柟寮�"
            METHOD="aes-256-cfb"
        esac
    fi
    echo ""
    colorEcho $BLUE " 鍔犲瘑鏂瑰紡锛� $METHOD"

    echo ""
    colorEcho $BLUE " 璇烽€夋嫨SSR鍗忚锛�"
    echo "   1)origin"
    echo "   2)verify_deflate"
    echo "   3)auth_sha1_v4"
    echo "   4)auth_aes128_md5"
    echo "   5)auth_aes128_sha1"
    echo "   6)auth_chain_a"
    echo "   7)auth_chain_b"
    echo "   8)auth_chain_c"
    echo "   9)auth_chain_d"
    echo "   10)auth_chain_e"
    echo "   11)auth_chain_f"
    read -p " 璇烽€夋嫨SSR鍗忚锛堥粯璁rigin锛�" answer
    if [[ -z "$answer" ]]; then
        PROTOCOL="origin"
    else
        case $answer in
        1)
            PROTOCOL="origin"
            ;;
        2)
            PROTOCOL="verify_deflate"
            ;;
        3)
            PROTOCOL="auth_sha1_v4"
            ;;
        4)
            PROTOCOL="auth_aes128_md5"
            ;;
        5)
            PROTOCOL="auth_aes128_sha1"
            ;;
        6)
            PROTOCOL="auth_chain_a"
            ;;
        7)
            PROTOCOL="auth_chain_b"
            ;;
        8)
            PROTOCOL="auth_chain_c"
            ;;
        9)
            PROTOCOL="auth_chain_d"
            ;;
        10)
            PROTOCOL="auth_chain_e"
            ;;
        11)
            PROTOCOL="auth_chain_f"
            ;;
        *)
            colorEcho $RED " 鏃犳晥鐨勯€夋嫨锛屼娇鐢ㄩ粯璁ゅ崗璁�"
            PROTOCOL="origin"
        esac
    fi
    echo ""
    colorEcho $BLUE " SSR鍗忚锛� $PROTOCOL"

    echo ""
    colorEcho $BLUE " 璇烽€夋嫨SSR娣锋穯妯″紡锛�"
    echo "   1)plain"
    echo "   2)http_simple"
    echo "   3)http_post"
    echo "   4)tls1.2_ticket_auth"
    echo "   5)tls1.2_ticket_fastauth"
    read -p " 璇烽€夋嫨娣锋穯妯″紡锛堥粯璁lain锛�" answer
    if [[ -z "$answer" ]]; then
        OBFS="plain"
    else
        case $answer in
        1)
            OBFS="plain"
            ;;
        2)
            OBFS="http_simple"
            ;;
        3)
            OBFS="http_post"
            ;;
        4)
            OBFS="tls1.2_ticket_auth"
            ;;
        5)
            OBFS="tls1.2_ticket_fastauth"
            ;;
        *)
            colorEcho $RED " 鏃犳晥鐨勯€夋嫨锛屼娇鐢ㄩ粯璁ゆ贩娣嗘ā寮�"
            OBFS="plain"
        esac
    fi
    echo ""
    colorEcho $BLUE " 娣锋穯妯″紡锛� $OBFS"
}

status() {
    res=`which python 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        echo 0
        return
    fi
    if [[ ! -f $CONFIG_FILE ]]; then
        echo 1
        return
    fi
    port=`grep server_port $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep python`
    if [[ -z "$res" ]]; then
        echo 2
    else
        echo 3
    fi
}

statusText() {
    res=`status`
    case $res in
        2)
            echo -e ${GREEN}宸插畨瑁�${PLAIN} ${RED}鏈繍琛�${PLAIN}
            ;;
        3)
            echo -e ${GREEN}宸插畨瑁�${PLAIN} ${GREEN}姝ｅ湪杩愯${PLAIN}
            ;;
        *)
            echo -e ${RED}鏈畨瑁�${PLAIN}
            ;;
    esac
}

preinstall() {
    $PMT clean all
    [[ "$PMT" = "apt" ]] && $PMT update
    #echo $CMD_UPGRADE | bash
    echo ""
    colorEcho $BLUE " 瀹夎蹇呰杞欢"
    if [[ "$PMT" = "yum" ]]; then
        $CMD_INSTALL epel-release
    fi
    $CMD_INSTALL curl wget vim net-tools libsodium* openssl unzip tar qrencode
    res=`which wget 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL wget
    res=`which netstat 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL net-tools
    res=`which python 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        ln -s /usr/bin/python3 /usr/bin/python
    fi

    if [[ -s /etc/selinux/config ]] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

installSSR() {
    if [[ ! -d /usr/local/shadowsocks ]]; then
        colorEcho $BLUE " 涓嬭浇瀹夎鏂囦欢"
        if ! wget --no-check-certificate -O ${FILENAME}.tar.gz ${URL}; then
            echo -e " [${RED}Error${PLAIN}] 涓嬭浇鏂囦欢澶辫触!"
            exit 1
        fi

        tar -zxf ${FILENAME}.tar.gz
        mv shadowsocksr-3.2.2/shadowsocks /usr/local
        if [[ ! -f /usr/local/shadowsocks/server.py ]]; then
            colorEcho $RED " $OS 瀹夎澶辫触锛岃鍒� https://tizi.blog 缃戠珯鍙嶉"
            cd ${BASE} && rm -rf shadowsocksr-3.2.2 ${FILENAME}.tar.gz
            exit 1
        fi
        cd ${BASE} && rm -rf shadowsocksr-3.2.2 ${FILENAME}.tar.gz
    fi

cat > $SERVICE_FILE <<-EOF
[Unit]
Description=shadowsocksR
Documentation=https://tizi.blog/
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
LimitNOFILE=32768
ExecStart=/usr/local/shadowsocks/server.py -c $CONFIG_FILE -d start
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable shadowsocksR
}

configSSR() {
    cat > $CONFIG_FILE<<-EOF
{
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "server_port":${PORT},
    "local_port":1080,
    "password":"${PASSWORD}",
    "timeout":600,
    "method":"${METHOD}",
    "protocol":"${PROTOCOL}",
    "protocol_param":"",
    "obfs":"${OBFS}",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
}

setFirewall() {
    res=`which firewall-cmd 2>/dev/null`
    if [[ $? -eq 0 ]]; then
        systemctl status firewalld > /dev/null 2>&1
        if [[ $? -eq 0 ]];then
            firewall-cmd --permanent --add-port=${PORT}/tcp
            firewall-cmd --permanent --add-port=${PORT}/udp
            firewall-cmd --reload
        else
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
            fi
        fi
    else
        res=`which iptables 2>/dev/null`
        if [[ $? -eq 0 ]]; then
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
            fi
        else
            res=`which ufw 2>/dev/null`
            if [[ $? -eq 0 ]]; then
                res=`ufw status | grep -i inactive`
                if [[ "$res" = "" ]]; then
                    ufw allow ${PORT}/tcp
                    ufw allow ${PORT}/udp
                fi
            fi
        fi
    fi
}

installBBR() {
    result=$(lsmod | grep bbr)
    if [[ "$result" != "" ]]; then
        colorEcho $GREEN " BBR妯″潡宸插畨瑁�"
        INSTALL_BBR=false
        return
    fi
    res=`hostnamectl | grep -i openvz`
    if [ "$res" != "" ]; then
        colorEcho $YELLOW " openvz鏈哄櫒锛岃烦杩囧畨瑁�"
        INSTALL_BBR=false
        return
    fi
    
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    result=$(lsmod | grep bbr)
    if [[ "$result" != "" ]]; then
        colorEcho $GREEN " BBR妯″潡宸插惎鐢�"
        INSTALL_BBR=false
        return
    fi

    colorEcho $BLUE " 瀹夎BBR妯″潡..."
    if [[ "$PMT" = "yum" ]]; then
        if [[ "$V6_PROXY" = "" ]]; then
            rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
            rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
            $CMD_INSTALL --enablerepo=elrepo-kernel kernel-ml
            $CMD_REMOVE kernel-3.*
            grub2-set-default 0
            echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
            INSTALL_BBR=true
        fi
    else
        $CMD_INSTALL --install-recommends linux-generic-hwe-16.04
        grub-set-default 0
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        INSTALL_BBR=true
    fi
}

showInfo() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSR鏈畨瑁咃紝璇峰厛瀹夎锛�${PLAIN}"
        return
    fi
    port=`grep server_port $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep python`
    [[ -z "$res" ]] && status="${RED}宸插仠姝�${PLAIN}" || status="${GREEN}姝ｅ湪杩愯${PLAIN}"
    password=`grep password $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    method=`grep method $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    protocol=`grep protocol $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    obfs=`grep obfs $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    
    p1=`echo -n ${password} | base64 -w 0`
    p1=`echo -n ${p1} | tr -d =`
    res=`echo -n "${IP}:${port}:${protocol}:${method}:${obfs}:${p1}/?remarks=&protoparam=&obfsparam=" | base64 -w 0`
    res=`echo -n ${res} | tr -d =`
    link="ssr://${res}"

    echo ""
    echo ============================================
    echo -e " ${BLUE}ssr杩愯鐘舵€侊細${PLAIN}${status}"
    echo -e " ${BLUE}ssr閰嶇疆鏂囦欢锛�${PLAIN}${RED}$CONFIG_FILE${PLAIN}"
    echo ""
    echo -e " ${RED}ssr閰嶇疆淇℃伅锛�${PLAIN}"
    echo -e "   ${BLUE}IP(address):${PLAIN}  ${RED}${IP}${PLAIN}"
    echo -e "   ${BLUE}绔彛(port)锛�${PLAIN}${RED}${port}${PLAIN}"
    echo -e "   ${BLUE}瀵嗙爜(password)锛�${PLAIN}${RED}${password}${PLAIN}"
    echo -e "   ${BLUE}鍔犲瘑鏂瑰紡(method)锛�${PLAIN} ${RED}${method}${PLAIN}"
    echo -e "   ${BLUE}鍗忚(protocol)锛�${PLAIN} ${RED}${protocol}${PLAIN}"
    echo -e "   ${BLUE}娣锋穯(obfuscation)锛�${PLAIN} ${RED}${obfs}${PLAIN}"
    echo
    echo -e " ${BLUE}ssr閾炬帴:${PLAIN} $link"
    #qrencode -o - -t utf8 $link
}

showQR() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSR鏈畨瑁咃紝璇峰厛瀹夎锛�${PLAIN}"
        return
    fi
    port=`grep server_port $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep python`
    [[ -z "$res" ]] && status="${RED}宸插仠姝�${PLAIN}" || status="${GREEN}姝ｅ湪杩愯${PLAIN}"
    password=`grep password $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    method=`grep method $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    protocol=`grep protocol $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    obfs=`grep obfs $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    
    p1=`echo -n ${password} | base64 -w 0`
    p1=`echo -n ${p1} | tr -d =`
    res=`echo -n "${IP}:${port}:${protocol}:${method}:${obfs}:${p1}/?remarks=&protoparam=&obfsparam=" | base64 -w 0`
    res=`echo -n ${res} | tr -d =`
    link="ssr://${res}"
    qrencode -o - -t utf8 $link
}

bbrReboot() {
    if [[ "${INSTALL_BBR}" == "true" ]]; then
        echo  
        colorEcho $BLUE  " 涓轰娇BBR妯″潡鐢熸晥锛岀郴缁熷皢鍦�30绉掑悗閲嶅惎"
        echo  
        echo -e " 鎮ㄥ彲浠ユ寜 ctrl + c 鍙栨秷閲嶅惎锛岀◢鍚庤緭鍏� ${RED}reboot${PLAIN} 閲嶅惎绯荤粺"
        sleep 30
        reboot
    fi
}


install() {
    getData
    preinstall
    installBBR
    installSSR
    configSSR
    setFirewall

    start
    showInfo
    
    bbrReboot
}

reconfig() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSR鏈畨瑁咃紝璇峰厛瀹夎锛�${PLAIN}"
        return
    fi
    getData
    configSSR
    setFirewall
    restart

    showInfo
}

uninstall() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSR鏈畨瑁咃紝璇峰厛瀹夎锛�${PLAIN}"
        return
    fi

    echo ""
    read -p " 纭畾鍗歌浇SSR鍚楋紵(y/n)" answer
    [[ -z ${answer} ]] && answer="n"

    if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]]; then
        rm -f $CONFIG_FILE
        rm -f /var/log/shadowsocksr.log
        rm -rf /usr/local/shadowsocks
        systemctl disable shadowsocksR && systemctl stop shadowsocksR && rm -rf $SERVICE_FILE
    fi
    echo -e " ${RED}鍗歌浇鎴愬姛${PLAIN}"
}

start() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SS鏈畨瑁咃紝璇峰厛瀹夎锛�${PLAIN}"
        return
    fi
    systemctl restart ${NAME}
    sleep 2
    port=`grep server_port $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep python`
    if [[ "$res" = "" ]]; then
        colorEcho $RED " SSR鍚姩澶辫触锛岃妫€鏌ョ鍙ｆ槸鍚﹁鍗犵敤锛�"
    else
        colorEcho $BLUE " SSR鍚姩鎴愬姛锛�"
    fi
}

restart() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSR鏈畨瑁咃紝璇峰厛瀹夎锛�${PLAIN}"
        return
    fi

    stop
    start
}

stop() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSR鏈畨瑁咃紝璇峰厛瀹夎锛�${PLAIN}"
        return
    fi
    systemctl stop ${NAME}
    colorEcho $BLUE " SSR鍋滄鎴愬姛"
}

showLog() {
    tail /var/log/shadowsocksr.log
}

menu() {
    clear
    echo "#############################################################"
    echo -e "#             ${RED}ShadowsocksR/SSR 涓€閿畨瑁呰剼鏈�${PLAIN}               #"
    echo -e "# ${GREEN}浣滆€�${PLAIN}: 姊瓙鍗氬                                        #"
    echo -e "# ${GREEN}缃戝潃${PLAIN}: https://tizi.blog                                    #"
    echo -e "# ${GREEN}璁哄潧${PLAIN}: https://tizi.blog                                   #"
    echo "#############################################################"
    echo ""

    echo -e "  ${GREEN}1.${PLAIN}  瀹夎SSR"
    echo -e "  ${GREEN}2.  ${RED}鍗歌浇SSR${PLAIN}"
    echo " -------------"
    echo -e "  ${GREEN}4.${PLAIN}  鍚姩SSR"
    echo -e "  ${GREEN}5.${PLAIN}  閲嶅惎SSR"
    echo -e "  ${GREEN}6.${PLAIN}  鍋滄SSR"
    echo " -------------"
    echo -e "  ${GREEN}7.${PLAIN}  鏌ョ湅SSR閰嶇疆"
    echo -e "  ${GREEN}8.${PLAIN}  鏌ョ湅閰嶇疆浜岀淮鐮�"
    echo -e "  ${GREEN}9.  ${RED}淇敼SSR閰嶇疆${PLAIN}"
    echo -e "  ${GREEN}10.${PLAIN} 鏌ョ湅SSR鏃ュ織"
    echo " -------------"
    echo -e "  ${GREEN}0.${PLAIN} 閫€鍑�"
    echo 
    echo -n " 褰撳墠鐘舵€侊細"
    statusText
    echo 

    read -p " 璇烽€夋嫨鎿嶄綔[0-10]锛�" answer
    case $answer in
        0)
            exit 0
            ;;
        1)
            install
            ;;
        2)
            uninstall
            ;;
        4)
            start
            ;;
        5)
            restart
            ;;
        6)
            stop
            ;;
        7)
            showInfo
            ;;
        8)
            showQR
            ;;
        9)
            reconfig
            ;;
        10)
            showLog
            ;;
        *)
            echo -e "$RED 璇烽€夋嫨姝ｇ‘鐨勬搷浣滐紒${PLAIN}"
            exit 1
            ;;
    esac
}

checkSystem

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
    menu|install|uninstall|start|restart|stop|showInfo|showQR|showLog)
        ${action}
        ;;
    *)
        echo " 鍙傛暟閿欒"
        echo " 鐢ㄦ硶: `basename $0` [menu|install|uninstall|start|restart|stop|showInfo|showQR|showLog]"
        ;;
esac
