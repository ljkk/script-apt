#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com

# https://nodejs.org/en/
# 选择LTS版本，.tar.gz源码包，.tar.xz是编译好的二进制包
(
    version=14.16.0
    install_dir=/usr/local/node

    [ -e $install_dir/bin/node ] && exit 0

    _tar node-v$version-linux-x64.tar.xz -C /usr/local/node-v$version
    ln -s /usr/local/node-v$version $install_dir
    add_bin_path ${install_dir}/bin
    cd $install_dir
    _mkdir node_global
    _mkdir node_cache
    npm config set prefix "node_global"
    npm config set cache "node_cache"

    npm config set registry https://registry.npm.taobao.org
)

[ $? == 0 ] || exit 1
