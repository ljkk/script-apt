#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/mariadb10.5.ini

    [ -f $install_dir/bin/mysql ] && exit 0
    command -v mysql && {
        echo_warning 'you are alreay installed mysql'
        exit 0
    }

    . ${basedir}/app/db/base.sh
    install
    my_cnf
    init

    systemctl start mysql.service
    # 删除匿名账号
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "DELETE FROM mysql.global_priv WHERE User='';"
    # 删除root远程登录账号
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    # 重新生成二进制文件
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "RESET MASTER;"
    systemctl stop mysql.service

)
[ $? == 0 ] || exit 1
