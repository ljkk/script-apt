#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/www.ini
    version=7.4.12
    install_dir=/usr/local/php

    [ -f $install_dir/bin/php ] && exit 0

    # 解决依赖
    apt_install build-essential libxml2-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev \
        libpng-dev libjpeg-dev libonig-dev libargon2-0-dev libxslt1-dev
    . ${basedir}/app/libzip.sh
    . ${basedir}/app/libiconv.sh
    . ${basedir}/app/freetype.sh
    . ${basedir}/app/libsodium.sh # apt install libsodium-dev 也可以

    local libiconv_install_dir=$(get_ini libiconv install_dir)
    _mkdir $install_dir
    # _tar php-$version.tar.gz
    export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/
    pushd $basedir/src/php-$version >/dev/null
    ./configure \
        --prefix=$install_dir \
        --with-config-file-path=$install_dir/etc \
        --with-config-file-scan-dir=$install_dir/etc/php.d \
        --with-fpm-user=$run_user \
        --with-fpm-group=$run_group \
        --enable-fpm \
        --enable-opcache \
        --disable-fileinfo \
        --enable-mysqlnd \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --with-freetype \
        --with-jpeg \
        --with-zlib \
        --with-iconv-dir=$libiconv_install_dir \
        --enable-xml \
        --disable-rpath \
        --enable-bcmath \
        --enable-shmop \
        --enable-exif \
        --enable-sysvsem \
        --enable-inline-optimization \
        --with-curl \
        --enable-mbregex \
        --enable-mbstring \
        --with-password-argon2 \
        --with-sodium \
        --enable-gd \
        --with-openssl \
        --with-mhash \
        --enable-pcntl \
        --enable-sockets \
        --with-xmlrpc \
        --enable-ftp \
        --enable-intl \
        --with-xsl \
        --with-gettext \
        --with-zip \
        --enable-soap \
        --disable-debug
    make ZEND_EXTRA_LIBS='-liconv' -j $(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
    make install
    /bin/cp php.ini-production $install_dir/etc/php.ini
    popd >/dev/null

)

[ $? == 0 ] || exit 1
