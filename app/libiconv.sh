#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/libiconv.ini

    [ -f "$install_dir/lib/libiconv.la" ] && exit 0
    _mkdir $install_dir || exit 1
    _tar libiconv-$version.tar.gz
    pushd $basedir/src/libiconv-$version >/dev/null
    ./configure --prefix=$install_dir
    make_install
    popd >/dev/null
    rm -rf $basedir/src/libiconv-$version
)
[ $? == 0 ] || exit 1
