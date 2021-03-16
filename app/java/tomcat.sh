#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    version=8.5.61
    install_dir=/usr/local/tomcat
    user=tomcat
    [ -f $install_dir/bin/startup.sh ] && exit 0

    . $basedir/app/java/jdk.sh 11

    id -u $user >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin $user
    _tar apache-tomcat-$version.tar.gz -C $install_dir || exit 1
    chown -R $user.$user $install_dir
    /bin/cp $basedir/etc/systemd/system/tomcat.service /lib/systemd/system
    sed -i "s@/usr/local/tomcat@$install_dir@" /lib/systemd/system/tomcat.service
    . /etc/profile
    echo "JAVA_HOME=$JAVA_HOME" >$install_dir/conf/tomcat.conf
    sed -i "/#\!\/bin\/.*/aJAVA_OPTS=\"-Djava.rmi.server.hostname=$(hostname -I | cut -d ' ' -f 1) -Dcom.sun.management.jmxremote.port=12345 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false\"" $install_dir/bin/catalina.sh

    systemctl enable --now tomcat
)

[ $? == 0 ] || exit 1
