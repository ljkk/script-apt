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

. $basedir/app/java/tomcat.sh

popd >/dev/null
timestamp_end=$(date "+%s")
seconds=$(($timestamp_end - $timestamp_start))
echo_message "$(TZ='UTC' date --date=@$seconds "+脚本运行: %H小时%M分钟%S秒")"
