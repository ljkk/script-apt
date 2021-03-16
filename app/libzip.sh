#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    version=1.2.0

    [ -f "/usr/local/lib/libzip.la" ] && exit 0
    _tar libzip-$version.tar.gz
    pushd $basedir/src/libzip-$version >/dev/null
    ./configure
    make_install
    popd >/dev/null
    rm -rf $basedir/src/libzip-$version
    [ -z "$(grep /usr/local/lib /etc/ld.so.conf.d/*.conf)" ] && echo '/usr/local/lib' >/etc/ld.so.conf.d/local.conf
    ldconfig
)
[ $? == 0 ] || exit 1
