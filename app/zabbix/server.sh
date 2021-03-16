#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(

    . ${basedir}/config/zabbix.ini
    [ -e "${install_dir}/sbin/zabbix_server" ] && exit 0

    . ${basedir}/app/db/mysql5.7.sh
    . ${basedir}/app/java/jdk.sh

    apt_install libcurl4-openssl-dev libxml2-dev libsnmp-dev libevent-dev fping
    id -u $user >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin $user
    chown root:zabbix /usr/bin/fping && chmod 4710 /usr/bin/fping
    _mkdir ${install_dir} || exit 1
    . /etc/profile
    _tar src/zabbix-${version}.tar.gz || exit 1
    pushd ${basedir}/src/zabbix-${version} >/dev/null
    # server 和 proxy 不同时安装
    # mysql_install_dir=$(get_ini mysql5.7 install_dir)    # ${mysql_install_dir}/bin/mysql_config
    ./configure --prefix=${install_dir} \
        --enable-server \
        --enable-agent \
        --with-mysql \
        --with-net-snmp \
        --with-libcurl \
        --with-libxml2 \
        --enable-java
    make_install || exit 1

    rootpwd=$(get_ini mysql5.7 rootpwd)
    # 创建用户
    mysql -ulujinkai -p${rootpwd} -h${db_addr} -e "CREATE DATABASE IF NOT EXISTS ${db_name} CHARACTER SET UTF8 COLLATE UTF8_BIN;"
    mysql -ulujinkai -p${rootpwd} -h${db_addr} -e "CREATE USER IF NOT EXISTS ${db_user}@'%' IDENTIFIED BY \"${db_pwd}\";"
    mysql -ulujinkai -p${rootpwd} -h${db_addr} -e "GRANT ALL ON ${db_name}.* TO ${db_user}@'%';"
    # 导入数据
    mysql -u${db_user} -p${db_pwd} -h${db_addr} ${db_name} <database/mysql/schema.sql
    mysql -u${db_user} -p${db_pwd} -h${db_addr} ${db_name} <database/mysql/images.sql
    mysql -u${db_user} -p${db_pwd} -h${db_addr} ${db_name} <database/mysql/data.sql

    sed -i "s/^# DBHost=localhost$/DBHost=${db_addr}/" ${install_dir}/etc/zabbix_server.conf
    sed -i "s/^DBName=zabbix$/DBName=${db_name}/" ${install_dir}/etc/zabbix_server.conf
    sed -i "s/^DBUser=zabbix$/DBUser=${db_user}/" ${install_dir}/etc/zabbix_server.conf
    sed -i "s/^# DBPassword=$/DBPassword=${db_pwd}/" ${install_dir}/etc/zabbix_server.conf

    . $basedir/app/nginx/nginx.sh
    . $basedir/app/php/php7.4.sh

    php_install_dir=$(get_ini php install_dir)
    sed -i "s/^max_input_time = .*/max_input_time = 300/" $php_install_dir/etc/php.ini
    # 安装 php ldap 扩展
    . $basedir/app/php/ldap.sh
    /bin/cp -r frontends/php $(get_ini www wwwroot_dir)/default/zabbix
    popd >/dev/null

    /bin/cp $basedir/etc/systemd/system/zabbix-server.service /lib/systemd/system
    /bin/cp $basedir/etc/systemd/system/zabbix-agent.service /lib/systemd/system
    /bin/cp $basedir/etc/systemd/system/zabbix-java-gateway.service /lib/systemd/system
    sed -i "s@/usr/local/zabbix@${install_dir}@" /lib/systemd/system/zabbix-server.service
    sed -i "s@/usr/local/zabbix@${install_dir}@" /lib/systemd/system/zabbix-agent.service
    sed -i "s@User=zabbix@User=$user@" /lib/systemd/system/zabbix-agent.service
    sed -i "s@Group=zabbix@Group=$user@" /lib/systemd/system/zabbix-agent.service
    sed -i "s@/usr/local/zabbix@${install_dir}@" /lib/systemd/system/zabbix-java-gateway.service
    sed -i "s@User=zabbix@User=$user@" /lib/systemd/system/zzabbix-java-gateway.service
    sed -i "s@Group=zabbix@Group=$user@" /lib/systemd/system/zzabbix-java-gateway.service

    _mkdir $install_dir/run && chown -R $user:$user $install_dir/run
    sed -i "s@^# PidFile=.*@PidFile=${install_dir}/run/zabbix_server.pid@" ${install_dir}/etc/zabbix_server.conf
    sed -i "s@^# PidFile=.*@PidFile=${install_dir}/run/zabbix_agentd.pid@" ${install_dir}/etc/zabbix_agentd.conf
    cat >${install_dir}/sbin/zabbix_java/settings.sh <<EOF
LISTEN_IP="0.0.0.0"
LISTEN_PORT=10052
PID_FILE="${install_dir}/run/zabbix_java_gateway.pid"
START_POLLERS=4
TIMEOUT=30
EOF
    systemctl enable --now zabbix-server zabbix-agent
)

[ $? == 0 ] || exit 1

# ./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --with-mysql --with-net-snmp --with-libcurl --with-libxml2 --enable-java
