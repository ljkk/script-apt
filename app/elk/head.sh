#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . $basedir/app/elk/elasticsearch.sh
    . $basedir/app/node/node.sh
)

[ $? == 0 ] || exit 1
