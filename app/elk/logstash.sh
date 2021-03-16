#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
  version=7.11.1
  user=logstash
  install_dir=/usr/local/logstash

  id -u $user >/dev/null 2>&1 || useradd -r -d $install_dir -s /usr/usr/sbin/nologin -c "LogStash Service User" $user
  _tar logstash-$version-linux-x86_64.tar.gz -C $install_dir
  mkdir -p $install_dir/var/{run,log}
  mkdir $install_dir/config/conf.d
  group=$user
  chown -R $group.$user $install_dir
  /bin/cp $basedir/etc/systemd/system/logstash.service /etc/systemd/system
  grep -i "s@/usr/local/logstash@$install_dir@" /etc/systemd/system/logstash.service

  cat >>$install_dir/config/pipelines.yml <<EOF

- pipeline.id: main
  path.config: "$install_dir/config/conf.d/*.conf"
EOF

  # systemctl start logstash 可能会启动失败
  # 先用命令行启动一遍，然后 chown -R logstash:logstash /usr/local/logstash
  # 再启动试试
  # 启动成功的标志是 ss -ntl 可以看到9600端口被监听

  # 注意：systemd方式启动，会以logstash用户的身份启动，因为logstash用户是nologin的，所以不会加载/etc/profile
  # 这样就找不到 $jAVA_HOME 环境变量，默认使用logstash自带的openjdk
  # 可以在logstash.service中指定 Environment="JAVA_HOME=/usr/local/jdk"

)

[ $? == 0 ] || exit 1
