#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    . ${basedir}/config/postgresql.ini

    [ -e "$install_dir/bin/psql" ] && exit 0

    apt_install libreadline-dev build-essential make zlib1g-dev || exit 1
    group=$user
    id -u $user >/dev/null 2>&1 || useradd -d $install_dir -r -s /bin/bash $user
    [ -d $basedir/src/postgresql-$version ] || _tar postgresql-$version.tar.gz
    pushd $basedir/src/postgresql-$version
    _mkdir $install_dir $data_dir $install_dir/logs || exit 1
    ./configure --prefix=$install_dir || exit 1
    make_install
    chown -R $group.$user $data_dir
    chmod 755 $install_dir
    chown -R $group.$user $install_dir
    popd
    /bin/cp $basedir/etc/systemd/system/postgresql.service /lib/systemd/system/
    sed -i "s@/usr/local/pgsql@$install_dir@g" /lib/systemd/system/postgresql.service
    sed -i "s@PGDATA=.*@PGDATA=$data_dir@" /lib/systemd/system/postgresql.service
    add_bin_path $install_dir/bin
    su - $user -c "$install_dir/bin/initdb -D $data_dir"
    # sleep 5
    systemctl enable --now postgresql.service
    su - postgres -c "$install_dir/bin/psql -c \"ALTER USER postgres WITH ENCRYPTED PASSWORD '$pwd';\""

    sed -i 's@^host.*@#&@g' $data_dir/pg_hba.conf
    sed -i 's@^local.*@#&@g' $data_dir/pg_hba.conf
    echo -ne "\n" >>$data_dir/pg_hba.conf
    echo 'local   all             all                                     md5' >>$data_dir/pg_hba.conf
    echo 'host    all             all             0.0.0.0/0               md5' >>$data_dir/pg_hba.conf
    sed -i "s@^#listen_addresses.*@listen_addresses = '0.0.0.0'@" $data_dir/postgresql.conf
    systemctl restart postgresql.service

    if [ -e "$install_dir/bin/psql" ]; then
        echo "PostgreSQL installed successfully!"
    else
        rm -rf $install_dir $data_dir
        echo "PostgreSQL install failed, Please contact the author!"
    fi
)

[ $? == 0 ] || exit 1
