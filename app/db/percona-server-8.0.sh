#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/percona-server-8.0.ini

    [ -f $install_dir/bin/mysql ] && exit 0
    command -v mysql && {
        echo_warning 'you are alreay installed mysql'
        exit 0
    }

    . ${basedir}/app/db/base.sh
    install
    my_cnf
    sed -i 's/expire-logs-days/binlog_expire_logs_seconds/' /etc/my.cnf
    init

)
[ $? == 0 ] || exit 1

# 二进制安装成功后总是无法启动，提示 . * The server quit without updating PID file，但是查看日志却没有报错，不知道为什么，源码编译安装就没有问题
