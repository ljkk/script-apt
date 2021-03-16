#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    version=2.10.4
    install_dir=/usr/local/freetype
    [ -e "${install_dir}/lib/libfreetype.la" ] && exit 0

    _mkdir ${install_dir} || exit 1
    apt_install build-essential
    _tar ${basedir}/src/freetype-${version}.tar.gz || exit 1
    pushd ${basedir}/src/freetype-${version} >/dev/null
    ./configure --prefix=${install_dir} --enable-freetype-config || exit 1
    make_install || exit 1
    popd >/dev/null
    ln -sf ${install_dir}/include/freetype2/* /usr/include/
    [ -d /usr/lib/pkgconfig ] && /bin/cp ${install_dir}/lib/pkgconfig/freetype2.pc /usr/lib/pkgconfig/
    rm -rf $basedir/src/freetype-${version}
)
[ $? == 0 ] || exit 1
