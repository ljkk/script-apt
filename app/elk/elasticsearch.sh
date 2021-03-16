#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    version=7.11.1

    [ -f /usr/share/elasticsearch/bin/elasticsearch ] && exit 0

    dpkg -i $basedir/src/elasticsearch-$version-amd64.deb

    # 修改hosts，手动修改，略...

    _mkdir /data/elasticsearch
    chown -R elasticsearch.elasticsearch /data/elasticsearch

    sed -i 's/^#cluster\.name:.*/cluster.name: es-cluster/' /etc/elasticsearch/elasticsearch.yml
    sed -ri 's/^#(node\.name:.*)/\1/' /etc/elasticsearch/elasticsearch.yml
    sed -i "s@^path\.data:.*@path.data: /data/elasticsearch/data@" /etc/elasticsearch/elasticsearch.yml
    sed -i "s@^path\.logs:.*@path.logs: /data/elasticsearch/logs@" /etc/elasticsearch/elasticsearch.yml
    sed -ri 's/^#(bootstrap.memory_lock: true)$/\1/' /etc/elasticsearch/elasticsearch.yml
    sed -i "s/^#network\.host:.*/network.host: $(hostname -I)/" /etc/elasticsearch/elasticsearch.yml
    sed -ri 's/^#(http.port: 9200)$/\1/' /etc/elasticsearch/elasticsearch.yml
    sed -i "s/^#gateway.recover_after_nodes:.*/gateway.recover_after_nodes: 2/" /etc/elasticsearch/elasticsearch.yml
    sed -ri 's/^#(action.destructive_requires_name: true)$/\1/' /etc/elasticsearch/elasticsearch.yml
    sed -i 's/^#discovery.seed_hosts:.*/discovery.seed_hosts: ["elk1-ljk.local", "elk2-ljk.local", "elk3-ljk.local"]/' /etc/elasticsearch/elasticsearch.yml
    sed -i 's/^#cluster.initial_master_nodes:.*/cluster.initial_master_nodes: ["node-1", "node-2", "node-3"]/' /etc/elasticsearch/elasticsearch.yml
    echo -ne "\n# ------------------------- 跨域 -----------------------\n" >>/etc/elasticsearch/elasticsearch.yml
    echo 'http.cors.enabled: true' >>/etc/elasticsearch/elasticsearch.yml
    echo 'http.cors.allow-origin: "*"' >>/etc/elasticsearch/elasticsearch.yml

    grep '^[a-Z]' /etc/elasticsearch/elasticsearch.yml

    sed -i 's/^## -Xms4g/-Xms1g/' /etc/elasticsearch/jvm.options
    sed -i 's/^## -Xmx4g/-Xmx1g/' /etc/elasticsearch/jvm.options

    echo -ne "\nLimitMEMLOCK=infinity" >>/usr/lib/systemd/system/elasticsearch.service
    systemctl daemon-reload

)

[ $? == 0 ] || exit 1
