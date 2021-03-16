#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    version=7.11.1
    user=elasticsearch
    install_dir=/usr/local/elasticsearch
    data_dir=/data/elasticsearch

    [ -f $install_dir/bin/elasticsearch ] && exit 0

    group=$user
    id -u $user >/dev/null 2>&1 || useradd -s /usr/sbin/nologin $user
    [ -d $install_dir ] && {
        echo_error "$install_dir directory already exists"
        exit 1
    }

    _tar elasticsearch-$version-linux-x86_64.tar.gz && /bin/mv $basedir/src/elasticsearch-$version $install_dir
    sed -i 's/^#cluster\.name:.*/cluster.name: ELK-Cluster/' $install_dir/config/elasticsearch.yml
    sed -ri 's/^#(node\.name:.*)/\1/' $install_dir/config/elasticsearch.yml
    sed -i "s@^#path\.data:.*@path.data: $data_dir/data@" $install_dir/config/elasticsearch.yml
    sed -i "s@^#path\.logs:.*@path.logs: $install_dir/logs@" $install_dir/config/elasticsearch.yml
    sed -ri 's/^#(bootstrap.memory_lock: true)$/\1/' $install_dir/config/elasticsearch.yml
    sed -i "s/^#network\.host:.*/network.host: $(hostname -I)/" $install_dir/config/elasticsearch.yml
    sed -ri 's/^#(http.port: 9200)$/\1/' $install_dir/config/elasticsearch.yml
    sed -i "s/^#gateway.recover_after_nodes:.*/gateway.recover_after_nodes: 2/" $install_dir/config/elasticsearch.yml
    sed -ri 's/^#(action.destructive_requires_name: true)$/\1/' $install_dir/config/elasticsearch.yml
    # sed -i 's/^#discovery.seed_hosts:.*/discovery.seed_hosts: ["elk1-ljk.local", "elk2-ljk.local"]/' $install_dir/config/elasticsearch.yml
    # sed -i 's/^#cluster.initial_master_nodes:.*/cluster.initial_master_nodes: ["node-1", "node-2"]/' $install_dir/config/elasticsearch.yml

    grep '^[a-Z]' $install_dir/config/elasticsearch.yml

    sed -i 's/^## -Xms4g/-Xms1g/' $install_dir/config/jvm.options
    sed -i 's/^## -Xmx4g/-Xmx1g/' $install_dir/config/jvm.options

    /bin/cp $basedir/etc/systemd/system/elasticsearch.service /usr/lib/systemd/system/
    sed -i "s@/usr/local/elasticsearch@$install_dir@" /usr/lib/systemd/system/elasticsearch.service

    _mkdir $data_dir $install_dir/run
    chown -R $group.$user $data_dir
    chown -R $group.$user $install_dir/logs
    chown -R $group.$user $install_dir/run

)

[ $? == 0 ] || exit 1
