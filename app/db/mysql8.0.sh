#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/mysql8.0.ini

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
