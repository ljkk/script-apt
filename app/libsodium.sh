#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com

# 此脚本测试安装失败，报错：
# libtool: warning: '-version-info/-version-number' is ignored for convenience libraries
# ar: `u' modifier ignored since `D' is the default (see `U')

(
    version=1.0.18
    install_dir=/usr/local/libsodium
    [ -e "${install_dir}/lib/libsodium.la" ] && exit 0

    _mkdir ${install_dir} || exit 1
    apt_install build-essential
    _tar ${basedir}/src/libsodium-${version}.tar.gz || exit 1
    pushd ${basedir}/src/libsodium-${version} >/dev/null
    ./configure --disable-dependency-tracking --enable-minimal || exit 1
    # make_install || exit 1
    popd >/dev/null
    # rm -rf $basedir/src/libsodium-${version}
)
[ $? == 0 ] || exit 1
