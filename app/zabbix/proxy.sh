#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/zabbix.ini
    [ -e "${install_dir}/sbin/zabbix_proxy" ] && exit 0

    . ${basedir}/app/db/mysql5.7.sh
    . ${basedir}/app/java/jdk.sh

    apt_install build-essential make libpcre3-dev libcurl4-openssl-dev libxml2-dev libsnmp-dev libevent-dev fping
    _mkdir ${install_dir} || exit 1
    id -u $user >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin $user
    [ -d ${basedir}/src/zabbix-${version} ] || _tar zabbix-${version}.tar.gz
    pushd ${basedir}/src/zabbix-${version} >/dev/null
    . /etc/profile
    ./configure --prefix=${install_dir} --enable-proxy --enable-agent --with-mysql --with-net-snmp --with-libcurl --with-libxml2
    make_install || exit 1

    rootpwd=$(get_ini mysql5.7 rootpwd)
    # 创建用户
    mysql -ulujinkai -p${rootpwd} -h${db_addr} -e "CREATE DATABASE IF NOT EXISTS zabbix_proxy_passive CHARACTER SET UTF8 COLLATE UTF8_BIN;"
    mysql -ulujinkai -p${rootpwd} -h${db_addr} -e "CREATE USER IF NOT EXISTS proxy@'%' IDENTIFIED BY \"123456\";"
    mysql -ulujinkai -p${rootpwd} -h${db_addr} -e "GRANT ALL ON zabbix_proxy_passive.* TO proxy@'%';"
    # 导入数据，proxy数据库不需要导入images.sql和data.sql
    mysql -u$proxy -p123456 -h${db_addr} zabbix_proxy_passive <database/mysql/schema.sql

    popd >/dev/null
    /bin/cp $basedir/etc/systemd/system/zabbix-proxy.service /lib/systemd/system
    /bin/cp $basedir/etc/systemd/system/zabbix-agent.service /lib/systemd/system
    sed -i "s@/usr/local/zabbix@${install_dir}@" /lib/systemd/system/zabbix-proxy.service.service
    sed -i "s@/usr/local/zabbix@${install_dir}@" /lib/systemd/system/zabbix-agent.service
    _mkdir $install_dir/run && chown -R $user:$user $install_dir/run
    sed -i "s@^# PidFile=.*@PidFile=${install_dir}/run/zabbix_agentd.pid@" ${install_dir}/etc/zabbix_agentd.conf
    # #systemctl enable --now zabbix-server zabbix-agent

    # echo_message "在 ${install_dir}/etc/zabbix_agentd.conf 中配置一下参数："
    # echo_message 'Hostname'
    # echo_message 'Server'
)

[ $? == 0 ] || exit 1
