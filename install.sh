#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com

# check if use bash shell
readlink /proc/$$/exe | grep -q "dash" && {
    echo -e "\e[31mError: you should use bash shell, not sh\e[0m"
    exit 1
}
# 检查是否为root用户
[[ "$EUID" -ne 0 ]] && {
    echo -e "\e[31mError: You must be root to run this script\e[0m"
    exit 1
}

timestamp_start=$(date "+%s")
export PATH=$PATH:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:~/bin
basedir=$(dirname "$(readlink -f $0)")
pushd $basedir >/dev/null
find . -regex .*\.sh | xargs -n1 chmod +x
. $basedir/common.sh
show_logo

# 检查是否联网
_fping || {
    echo_error 'no Internet'
    exit 1
}
# 安装常用软件
install_common
# 检查系统类型、版本、架构
if OS_ver=$(ubuntu_version); then
    [ $OS_ver -lt 18 ] && {
        echo_error 'Error: Your os version is too low'
        exit 1
    }
    is_x86_64 || {
        echo_error 'Error: Only support x86_64'
        exit 1
    }
else
    echo_error "Error: This script only support Ubuntu"
    exit 1
fi

# . $basedir/app/ansible/ansible.sh
# . $basedir/app/openvpn/openvpn.sh install
# . $basedir/app/python/python3.sh
# . $basedir/app/db/pxc.sh install_pxc
# . $basedir/app/db/db.sh install_db ps57
# . $basedir/app/db/db.sh install_db mariadb105
# . $basedir/app/db/db.sh install_db mysql80
# . $basedir/app/db/db.sh install_db mysql57

popd >/dev/null
timestamp_end=$(date "+%s")
seconds=$(($timestamp_end - $timestamp_start))
echo_message "$(TZ='UTC' date --date=@$seconds "+脚本运行: %H小时%M分钟%S秒")"
