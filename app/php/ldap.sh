#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/php.ini
    version=$($install_dir/bin/php -v | head -n 1 | cut -d ' ' -f 2)

    [ -d ${basedir}/src/php-$version/ext/ldap ] || _tar php-$version.tar.gz
    pushd ${basedir}/src/php-$version/ext/ldap >/dev/null
    $install_dir/bin/phpize
    ./configure --with-php-config=$install_dir/bin/php-config
    make_install || exit 1
    popd >/dev/null
    echo 'extension=ldap.so' >/usr/local/php/etc/php.d/ldap.ini
)

[ $? == 0 ] || exit 1
