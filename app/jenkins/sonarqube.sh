#!/bin/bash

version=7.9.5
install_dir=/usr/local/sonarqube
user=sonarqube
group=$user

. $basedir/app/java/jdk.sh 11
. $basedir/app/db/postgresql.sh

id -u $user >/dev/null 2>&1 || useradd -d $install_dir -r -s /bin/bash $user

cat >/etc/sysctl.d/sonarqube.conf <<EOF
vm.max_map_count=262144
fs.file-max=65536
EOF
sysctl -p /etc/sysctl.d/sonarqube.conf

ulimit -n 65536
ulimit -u 4096
cat >/etc/security/limits.d/sonarqube.conf <<EOF
sonarqube - nofile 65536
sonarqube - nproc 4096
EOF

cd $basedir/src
unzip sonarqube-$version.zip
mv sonarqube-$version $install_dir
chown -R $group.$user $install_dir

cd $install_dir
#修改配置
# [root@SonarQube-Server ~]#vim /usr/local/sonarqube/conf/sonar.properties
# sonar.jdbc.username=sonar
# sonar.jdbc.password=123456    # get_ini postgresql pwd
# sonar.jdbc.url=jdbc:postgresql://10.0.1.104/sonarqube
# sonar.web.host=0.0.0.0
# sonar.web.port=9000

# 必须以普通的身份启动
# su - $user -c "$install/bin/linux-x86-64/sonar.sh start"

/bin/cp $basedir/etc/systemd/system/sonarqube.service /lib/systemd/system
