#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com

function ssh_push_key() {
    ips=(
        10.0.0.71
        10.0.0.72
        10.0.0.73
    )
    [ "$1" ] && ips=($@)
    apt_install sshpass
    [ -f ~/.ssh/id_rsa ] || ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' >/dev/null 2>&1
    export SSHPASS=ljkk
    for ip in ${ips[@]}; do
        (
            timeout 5 ssh $ip echo "$ip: SSH has passwordless access!"
            if [ $? != 0 ]; then
                sshpass -e ssh-copy-id -o StrictHostKeyChecking=no root@$ip >/dev/null 2>&1
                timeout 5 ssh $ip echo "$ip: SSH has passwordless access!" || echo "$ip: SSH has no passwordless access!"
            fi
        ) &
    done
    wait
}
