#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com

(
    . ${basedir}/config/www.ini
    . ${basedir}/config/php.ini
    version=7.4.15
    [ -f $install_dir/bin/php ] && exit 0

    . ${basedir}/app/php/base.sh

    # 解决依赖
    apt_install build-essential libxml2-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev libpng-dev libjpeg-dev libonig-dev libargon2-0-dev libxslt1-dev libsodium-dev
    . ${basedir}/app/libzip.sh
    . ${basedir}/app/libiconv.sh
    . ${basedir}/app/freetype.sh

    libiconv_install_dir=$(get_ini libiconv install_dir)
    _mkdir $install_dir
    _tar php-$version.tar.gz
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

    if [ -e "$install_dir/bin/phpize" ]; then
        echo_success "PHP installed successfully!"
    else
        rm -rf $install_dir
        echo_error "PHP install failed, Please Contact the author!"
        exit 1
    fi
    mkdir -p $install_dir/etc/php.d

    sed -i "s@^memory_limit.*@memory_limit = $(memory_limit)M@" $install_dir/etc/php.ini
    sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' $install_dir/etc/php.ini
    sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' $install_dir/etc/php.ini
    sed -i 's@^expose_php = On@expose_php = Off@' $install_dir/etc/php.ini
    sed -i 's@^request_order.*@request_order = "CGP"@' $install_dir/etc/php.ini
    sed -i "s@^;date.timezone.*@date.timezone = Asia/Shanghai@" $install_dir/etc/php.ini
    sed -i 's@^post_max_size.*@post_max_size = 100M@' $install_dir/etc/php.ini
    sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' $install_dir/etc/php.ini
    sed -i 's@^max_execution_time.*@max_execution_time = 600@' $install_dir/etc/php.ini
    sed -i 's@^;realpath_cache_size.*@realpath_cache_size = 2M@' $install_dir/etc/php.ini
    sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' $install_dir/etc/php.ini
    [ -e /usr/sbin/sendmail ] && sed -i 's@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i@' $install_dir/etc/php.ini

    cat >$install_dir/etc/php.d/opcache.ini <<EOF
[opcache]
zend_extension=opcache.so
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=$(memory_limit)
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=100000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
;opcache.save_comments=0
opcache.consistency_checks=0
;opcache.optimization_level=0
EOF

    cat >$install_dir/etc/php-fpm.conf <<EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = run/php-fpm.pid
error_log = log/php-fpm.log
log_level = warning

emergency_restart_threshold = 30
emergency_restart_interval = 60s
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[${run_user}]
listen = /dev/shm/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = ${run_user}
listen.group = ${run_group}
listen.mode = 0666
user = ${run_user}
group = ${run_group}

pm = dynamic
pm.max_children = 12
pm.start_servers = 8
pm.min_spare_servers = 6
pm.max_spare_servers = 12
pm.max_requests = 2048
pm.process_idle_timeout = 10s
request_terminate_timeout = 120
request_slowlog_timeout = 0

pm.status_path = /php-fpm_status
slowlog = var/log/slow.log
rlimit_files = 51200
rlimit_core = 0

catch_workers_output = yes
;env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF
    Mem=$(mem)
    if [ $Mem -le 3000 ]; then
        sed -i "s@^pm.max_children.*@pm.max_children = $(($Mem / 3 / 20))@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = $(($Mem / 3 / 30))@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = $(($Mem / 3 / 40))@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = $(($Mem / 3 / 20))@" $install_dir/etc/php-fpm.conf
    elif [ $Mem -gt 3000 -a $Mem -le 4500 ]; then
        sed -i "s@^pm.max_children.*@pm.max_children = 50@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = 30@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 20@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 50@" $install_dir/etc/php-fpm.conf
    elif [ $Mem -gt 4500 -a $Mem -le 6500 ]; then
        sed -i "s@^pm.max_children.*@pm.max_children = 60@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = 40@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 30@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 60@" $install_dir/etc/php-fpm.conf
    elif [ $Mem -gt 6500 -a $Mem -le 8500 ]; then
        sed -i "s@^pm.max_children.*@pm.max_children = 70@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = 50@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 40@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 70@" $install_dir/etc/php-fpm.conf
    elif [ $Mem -gt 8500 ]; then
        sed -i "s@^pm.max_children.*@pm.max_children = 80@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.start_servers.*@pm.start_servers = 60@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 50@" $install_dir/etc/php-fpm.conf
        sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 80@" $install_dir/etc/php-fpm.conf
    fi

    add_bin_path $install_dir/bin

    id -g $run_group >/dev/null 2>&1 || groupadd $run_group
    id -u $run_user >/dev/null 2>&1 || useradd -g $run_group -r -s /usr/sbin/nologin $run_user
    /bin/cp $basedir/etc/systemd/system/php-fpm.service /lib/systemd/system
    sed -i "s@/usr/local/php@${install_dir}@g" /lib/systemd/system/php-fpm.service
    # systemctl enable php-fpm.service

)
[ $? == 0 ] || exit 1
