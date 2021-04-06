#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com

check_reply() {
    apt_install build-essential make cmake autoconf libssl-dev libncurses5-dev pkg-config libaio1 libreadline-dev zlib1g-dev libcurl4-openssl-dev libldap2-dev
}

# 二进制安装
install_bin() {
    _tar $package_1 -C $install_dir || exit 1
    if [ -d ${install_dir}/support-files ]; then
        sed -i "s@/usr/local/mysql@${install_dir}@g" ${install_dir}/bin/mysqld_safe
        sed -i "s@^basedir=.*@basedir=${install_dir}@" ${install_dir}/support-files/mysql.server
        sed -i "s@^datadir=.*@datadir=${data_dir}@" ${install_dir}/support-files/mysql.server
    fi
    echo "$install_dir/lib" >/etc/ld.so.conf.d/mysql.conf
}

# 编译安装
install_com() {
    boost_version=$(echo ${boost_version} | awk -F. '{print $1"_"$2"_"$3}')
    _tar boost_${boost_version}.tar.gz
    local package_2_dir="$db-$version"
    _tar $package_2 -C $package_2_dir || exit 1
    pushd $package_2_dir >/dev/null
    _mkdir build
    pushd ./build >/dev/null
    cmake_options="-DCMAKE_INSTALL_PREFIX=${install_dir} \
    -DMYSQL_DATADIR=${data_dir} \
    -DDOWNLOAD_BOOST=1 \
    -DWITH_BOOST=../../boost_${boost_version}  \
    -DSYSCONFDIR=/etc \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_PARTITION_STORAGE_ENGINE=1 \
    -DWITH_FEDERATED_STORAGE_ENGINE=1 \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
    -DWITH_MYISAM_STORAGE_ENGINE=1 \
    -DENABLED_LOCAL_INFILE=1 \
    -DDEFAULT_CHARSET=utf8mb4 \
    -DDEFAULT_COLLATION=utf8mb4_general_ci \
    -DEXTRA_CHARSETS=all"
    [ $db != 'mysql80' ] && cmake_options+=" -DENABLE_DTRACE=0"
    cmake .. $cmake_options
    make_install
    popd >/dev/null
    popd >/dev/null
    rm -rf ./${package_2_dir} ./boost_${boost_version}
}

install() {
    _mkdir ${install_dir} ${data_dir} || exit 1
    check_reply
    . ${basedir}/app/jemalloc.sh
    [ $? != 0 ] && exit 1
    pushd ${basedir}/src >/dev/null
    if [ $install_type == 1 ]; then
        install_bin
    elif [ $install_type == 2 ]; then
        install_com
    fi
    if [ -d ${install_dir}/support-files ]; then
        chown -R root:root ${install_dir}
        export LD_PRELOAD=/usr/local/lib/libjemalloc.so
        sed -i 's@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=/usr/local/lib/libjemalloc.so@' ${install_dir}/bin/mysqld_safe
        echo_success "$db installed successfully!"
    else
        rm -rf ${install_dir}
        echo_error "$db install fail to install"
        exit 1
    fi
    popd >/dev/null
}

my_cnf() {
    [ -d "/etc/mysql" ] && /bin/mv /etc/mysql{,_bk}
    cat >/etc/my.cnf <<EOF
    [client]
    #password=your-password
    port=3306
    socket=/tmp/mysql.sock
    default-character-set=utf8mb4

    [mysql]
    no-auto-rehash
    prompt="\\\r:\\\m:\\\s(\\\u@\\\h) [\\\d]>\\\_"

    [mysqld]
    port=3306
    socket=/tmp/mysql.sock
    basedir=${install_dir}
    datadir=${data_dir}
    pid-file=${data_dir}/mysql.pid
    user=mysql
    bind-address=0.0.0.0
    server-id=1

    sync-binlog=0

    init-connect='SET NAMES utf8mb4'
    character-set-server=utf8mb4

    skip-name-resolve
    #skip-networking
    back-log=300

    max-connections=1000
    max-connect-errors=6000
    open-files-limit=65535
    table-open-cache=128
    max-allowed-packet=500M
    binlog-cache-size=1M
    max-heap-table-size=8M
    tmp-table-size=16M

    read-buffer-size=2M
    read-rnd-buffer-size=8M
    sort-buffer-size=8M
    net-buffer-length=8K
    join-buffer-size=8M
    key-buffer-size=4M
    performance-schema-max-table-instances=500

    thread-cache-size=8

    ft-min-word-len=4

    log-bin=mysql-bin
    binlog-format=mixed
    expire-logs-days=7

    log-error=${data_dir}/mysql-error.log
    slow-query-log=1
    long-query-time=1
    slow-query-log-file=${data_dir}/mysql-slow.log

    performance-schema=0
    explicit-defaults-for-timestamp

    #lower-case-table-names=1

    skip-external-locking

    default-storage-engine=InnoDB
    #default-storage-engine=MyISAM
    innodb-file-per-table=1
    innodb-data-home-dir=${data_dir}
    innodb-data-file-path=ibdata1:12M:autoextend
    innodb-log-group-home-dir=${data_dir}
    innodb-open-files=500
    innodb-buffer-pool-size=64M
    innodb-write-io-threads=4
    innodb-read-io-threads=4
    innodb-thread-concurrency=0
    innodb-purge-threads=1
    innodb-flush-log-at-trx-commit=2
    innodb-log-buffer-size=2M
    innodb-log-file-size=32M
    innodb-log-files-in-group=3
    innodb-max-dirty-pages-pct=90
    innodb-lock-wait-timeout=120

    bulk-insert-buffer-size=8M
    myisam-sort-buffer-size=8M
    myisam-max-sort-file-size=10G
    myisam-repair-threads=1

    interactive-timeout=28800
    wait-timeout=28800

    [mysqldump]
    quick
    max-allowed-packet=500M

    [myisamchk]
    key-buffer-size=8M
    sort-buffer-size=8M
    read-buffer=4M
    write-buffer=4M
EOF
    Mem=$(mem)
    if [[ ${Mem} -gt 1024 && ${Mem} -lt 2048 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 32M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 128#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 768K#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 768K#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 8M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 16#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 16M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 32M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 128M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 32M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 1000#" /etc/my.cnf
    elif [[ ${Mem} -ge 2048 && ${Mem} -lt 4096 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 64M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 256#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 1M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 1M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 16M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 32#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 32M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 64M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 256M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 64M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 2000#" /etc/my.cnf
    elif [[ ${Mem} -ge 4096 && ${Mem} -lt 8192 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 128M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 512#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 2M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 2M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 32M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 64#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 64M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 64M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 512M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 128M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 4000#" /etc/my.cnf
    elif [[ ${Mem} -ge 8192 && ${Mem} -lt 16384 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 256M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 1024#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 4M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 4M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 64M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 128#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 128M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 128M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 1024M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 256M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 6000#" /etc/my.cnf
    elif [[ ${Mem} -ge 16384 && ${Mem} -lt 32768 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 512M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 2048#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 8M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 8M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 128M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 256#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 256M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 256M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 2048M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 512M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 8000#" /etc/my.cnf
    elif [[ ${Mem} -ge 32768 ]]; then
        sed -i "s#^key_buffer_size.*#key_buffer_size = 1024M#" /etc/my.cnf
        sed -i "s#^table_open_cache.*#table_open_cache = 4096#" /etc/my.cnf
        sed -i "s#^sort_buffer_size.*#sort_buffer_size = 16M#" /etc/my.cnf
        sed -i "s#^read_buffer_size.*#read_buffer_size = 16M#" /etc/my.cnf
        sed -i "s#^myisam_sort_buffer_size.*#myisam_sort_buffer_size = 256M#" /etc/my.cnf
        sed -i "s#^thread_cache_size.*#thread_cache_size = 512#" /etc/my.cnf
        sed -i "s#^query_cache_size.*#query_cache_size = 512M#" /etc/my.cnf
        sed -i "s#^tmp_table_size.*#tmp_table_size = 512M#" /etc/my.cnf
        sed -i "s#^innodb_buffer_pool_size.*#innodb_buffer_pool_size = 4096M#" /etc/my.cnf
        sed -i "s#^innodb_log_file_size.*#innodb_log_file_size = 1024M#" /etc/my.cnf
        sed -i "s#^performance_schema_max_table_instances.*#performance_schema_max_table_instances = 10000#" /etc/my.cnf
    fi
}

init() {
    id -u mysql >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin mysql
    chown -R mysql:mysql ${data_dir}
    /bin/cp ${install_dir}/support-files/mysql.server /etc/init.d/mysql
    chmod +x /etc/init.d/mysql
    /bin/cp ${basedir}/etc/systemd/system/mysql.service /lib/systemd/system/mysql.service
    add_bin_path ${install_dir}/bin

    loading '数据库初始化'
    if [[ $db =~ 'mariadb' ]]; then
        ${install_dir}/scripts/mysql_install_db --basedir=${install_dir} --datadir=${data_dir} --user=mysql
    else
        ${install_dir}/bin/mysqld --initialize-insecure --basedir=${install_dir} --datadir=${data_dir} --user=mysql
    fi
    close_loading

    # echo "${install_dir}/lib" >/etc/ld.so.conf.d/$db.conf
    # ldconfig

    systemctl enable --now mysql.service || {
        echo_warning '启动失败'
        exit 1
    }

    # 修改root@localhost账号密码
    ${install_dir}/bin/mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY \"${rootpwd}\";"
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "FLUSH PRIVILEGES;"
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "GRANT ALL ON *.* TO 'root'@'localhost';"
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "CREATE USER 'root'@'127.0.0.1' IDENTIFIED BY \"${rootpwd}\";"
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "GRANT ALL ON *.* TO 'root'@'127.0.0.1';"
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "CREATE USER 'lujinkai'@'%' IDENTIFIED BY \"${rootpwd}\";"
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "GRANT ALL ON *.* TO 'lujinkai'@'%' WITH GRANT OPTION;" # 赋予操作用户的权限
    # 删除测试数据库
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "DROP DATABASE IF EXISTS test;"
    # 重新生成二进制文件
    ${install_dir}/bin/mysql -uroot -p${rootpwd} -e "RESET MASTER;"

    mysqld --verbose --help | head -n9
    mysqldump --print-defaults
    mysql -uroot -p$rootpwd -e "select HOST,User,plugin,authentication_string from mysql.user\G;"

    systemctl stop mysql.service

}
