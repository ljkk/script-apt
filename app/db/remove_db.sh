#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(

    command -v mysql || {
        echo_warning '没有mysql命令'
        return 1
    }
    # declare db_ver=$(mysql --version | awk '{print $3}')
    systemctl stop mysql.service

    [ -d /usr/local/mysql ] && {
        rm -rf /usr/local/mysql
        rm -rf /data/mysql
        remove_bin_path /usr/local/mysql/bin
    }
    [ -d /usr/local/mariadb ] && {
        rm -rf /usr/local/mariadb
        rm -rf /data/mariadb
        remove_bin_path /usr/local/mariadb/bin
    }
    [ -d /usr/local/percona ] && {
        rm -rf /usr/local/percona
        rm -rf /data/percona
        remove_bin_path /usr/local/percona/bin
    }

    [ -f /etc/ld.so.conf.d/mysql57.conf ] && rm -f /etc/ld.so.conf.d/mysql57.conf
    [ -f /etc/ld.so.conf.d/mysql80.conf ] && rm -f /etc/ld.so.conf.d/mysql80.conf
    [ -f /etc/ld.so.conf.d/mariadb105.conf ] && rm -f /etc/ld.so.conf.d/mariadb105.conf
    [ -f /etc/ld.so.conf.d/ps57.conf ] && rm -f /etc/ld.so.conf.d/ps57.conf
    [ -f /etc/ld.so.conf.d/ps80.conf ] && rm -f /etc/ld.so.conf.d/ps80.conf
    ldconfig

    [ -f /etc/my.cnf ] && rm -f /etc/my.cnf
    [ -f ~/.mysql_history ] && rm -f ~/.mysql_history
    [ -f /etc/init.d/mysql ] && rm -f /etc/init.d/mysql
    [ -f /lib/systemd/system/mysql.service ] && rm -f /lib/systemd/system/mysql.service
    systemctl daemon-reload
    userdel mysql
    echo_success "删除成功"

)
[ $? == 0 ] || exit 1
