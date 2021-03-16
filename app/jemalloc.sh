#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    version=5.2.1
    install_dir=/usr/local/jemalloc
    [ -e "/usr/local/lib/libjemalloc.so" ] && exit 0

    _mkdir ${install_dir} || exit 1
    pushd ${basedir}/src >/dev/null
    apt_install build-essential
    _tar jemalloc-${version}.tar.bz2 || exit 1
    pushd jemalloc-${version} >/dev/null
    ./configure --prefix=${install_dir} --libdir=/usr/local/lib || exit 1
    make_install || exit 1
    popd >/dev/null
    if [ -f "/usr/local/lib/libjemalloc.so" ]; then
        [ -z "$(grep /usr/local/lib /etc/ld.so.conf.d/*.conf)" ] && echo '/usr/local/lib' >/etc/ld.so.conf.d/local.conf
        ldconfig
        echo_success "jemalloc module installed successfully!"
        rm -rf ./jemalloc-${version}
    else
        echo_error "jemalloc install failed, Please contact the author!" && lsb_release -a
        exit 1
    fi
    popd >/dev/null
)
[ $? == 0 ] || exit 1
