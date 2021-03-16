#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/www.ini
    version=1.18.0
    install_dir=/usr/local/nginx

    [ -f $install_dir/sbin/nginx ] && exit 0
    _mkdir $install_dir || exit 1
    apt_install build-essential zlib1g-dev libssl-dev libpcre3-dev
    . ${basedir}/app/jemalloc.sh || exit 1
    _tar nginx-$version.tar.gz
    pushd $basedir/src/nginx-$version >/dev/null
    # close debug
    sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc
    ./configure \
        --prefix=$install_dir \
        --user=$run_user \
        --group=$run_group \
        --with-http_stub_status_module \
        --with-http_v2_module \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_realip_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-pcre-jit \
        --with-ld-opt='-ljemalloc'
    make_install
    popd >/dev/null

    [ -f "$install_dir/conf/nginx.conf" ] && {
        rm -rf $basedir/src/nginx-$version
        echo_success 'Nginx installed successfully!'
    } || {
        rm -rf $install_dir
        echo_error 'Nginx install failed, Please Contact the author!'
        exit 1
    }
    _mkdir $install_dir/run
    /bin/cp $basedir/etc/systemd/system/nginx.service /lib/systemd/system
    sed -i "s@/usr/local/nginx@${install_dir}@g" /lib/systemd/system/nginx.service

    /bin/mv $install_dir/conf/nginx.conf{,_bk}
    /bin/cp $basedir/etc/nginx/nginx.conf $install_dir/conf/nginx.conf
    sed -i "s@/usr/local/nginx@${install_dir}@g" $install_dir/conf/nginx.conf
    sed -i "s@/data/wwwroot/default@$wwwroot_dir/default@g" $install_dir/conf/nginx.conf
    sed -i "s@/data/wwwlogs@$wwwlogs_dir@g" $install_dir/conf/nginx.conf
    sed -i "s@^user www www@user $run_user $run_group@" $install_dir/conf/nginx.conf
    mkdir -p $wwwroot_dir $wwwlogs_dir

    cat >$install_dir/conf/proxy.conf <<EOF
proxy_connect_timeout 300s;
proxy_send_timeout 900;
proxy_read_timeout 900;
proxy_buffer_size 32k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_redirect off;
proxy_hide_header Vary;
proxy_set_header Accept-Encoding '';
proxy_set_header Referer \$http_referer;
proxy_set_header Cookie \$http_cookie;
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
EOF

    # logrotate nginx log
    cat >/etc/logrotate.d/nginx <<EOF
${wwwlogs_dir}/*nginx.log {
  daily
  rotate 5
  missingok
  dateext
  compress
  notifempty
  sharedscripts
  postrotate
    [ -f ${install_dir}/run/nginx.pid ] && kill -USR1 \`cat ${install_dir}/run/nginx.pid\`
  endscript
}
EOF
    id -g $run_group >/dev/null 2>&1 || groupadd $run_group
    id -u $run_user >/dev/null 2>&1 || useradd -g $run_group -r -s /usr/sbin/nologin $run_user
    add_bin_path $install_dir/bin
    systemctl enable nginx
)
[ $? == 0 ] || exit 1
