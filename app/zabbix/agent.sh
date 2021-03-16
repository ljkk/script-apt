#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/zabbix.ini
    [ -e "${install_dir}/sbin/zabbix_agentd" ] && exit 0
    apt_install build-essential make libpcre3-dev fping
    _mkdir ${install_dir} || exit 1
    id -u $user >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin $user
    [ -d ${basedir}/src/zabbix-${version} ] || _tar zabbix-${version}.tar.gz
    pushd ${basedir}/src/zabbix-${version} >/dev/null
    ./configure --prefix=${install_dir} --enable-agent
    make_install || exit 1
    popd >/dev/null
    /bin/cp $basedir/etc/systemd/system/zabbix-agent.service /lib/systemd/system
    sed -i "s@/usr/local/zabbix@${install_dir}@" /lib/systemd/system/zabbix-agent.service
    _mkdir $install_dir/run && chown -R $user:$user $install_dir/run
    sed -i "s@^# PidFile=.*@PidFile=${install_dir}/run/zabbix_agentd.pid@" ${install_dir}/etc/zabbix_agentd.conf
    #systemctl enable --now zabbix-server zabbix-agent

    echo_message "在 ${install_dir}/etc/zabbix_agentd.conf 中配置一下参数："
    echo_message 'Hostname'
    echo_message 'Server'
)

[ $? == 0 ] || exit 1
