#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
(
    install_dir=/usr/local/jdk
    run_user=www
    run_group=www

    id -u www >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin www
    install_jdk8() {
        package=jdk-8u271-linux-x64.tar.gz
        [ $($install_dir/bin/java -version 2>&1 | awk 'NR==1{gsub(/"/,"");print $3}') == '1.8.0_271' ] && exit 0
        _tar $package -C "$install_dir-8" || exit 1
        chown -R $run_user:$run_group "$install_dir-8"
        rm -f $install_dir
        ln -s "$install_dir-8" $install_dir
        /bin/cp $install_dir/jre/lib/security/cacerts /etc/ssl/certs/java
    }
    install_jdk11() {
        package=jdk-11.0.10_linux-x64_bin.tar.gz
        [ $($install_dir/bin/java -version 2>&1 | awk 'NR==1{gsub(/"/,"");print $3}') == '11.0.10' ] && exit 0
        _tar $package -C "$install_dir-11" || exit 1
        chown -R $run_user:$run_group "$install_dir-11"
        rm -f $install_dir
        ln -s "$install_dir-11" $install_dir
        /bin/cp $install_dir/lib/security/cacerts /etc/ssl/certs/java
    }

    case $1 in
    8)
        install_jdk8
        ;;
    11)
        install_jdk11
        ;;
    *)
        echo_error "sorry"
        ;;
    esac

    add_bin_path ${install_dir}/bin
    # JAVA_HOME 位于PATH之前
    _export "JAVA_HOME=$install_dir" +PATH || exit 1
    # CLASSPATH 位于JAVA_HOME之后
    _export "CLASSPATH=\$JAVA_HOME/lib" -JAVA_HOME || exit 1
    echo_success "jdk$1 installed successfully!"
    java -version

)

[ $? == 0 ] || exit 1
