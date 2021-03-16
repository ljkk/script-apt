#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com
basedir=$(dirname "$(readlink -f $0)")
function show_logo() {
    clear
    printf "
#######################################################################
#             The script for Debian/Ubuntu (x86_64)                   #
#######################################################################

"
}

function color_text() {
    echo -e "\e[$2m$1\e[0m"
}
function echo_error() {
    # echo -n $(color_text " ERROR! " "31")
    echo $(color_text "$1" "31")
}
function echo_success() {
    # echo -n $(color_text " SUCCESS! " "32")
    echo $(color_text "$1" "32")
}
function echo_warning() {
    # echo -n $(color_text " WARNING: " "33")
    echo $(color_text "$1" "33")
}
function echo_message() {
    echo $(color_text "$1" "34")
}

function echo_bold() {
    echo $(color_text "$1" "1")
}

function loading() {
    (
        [ "$1" ] && echo -n $(echo_message "$1")
        local dot=0
        while :; do
            sleep 1
            (($dot < 7)) && ((dot += 1)) || dot=0
            echo -ne "\e[0;3${dot}m.\e[0m"
        done &
        echo $! >>~/.$$.pids
    )
}
function close_loading() {
    for i in $(cat ~/.$$.pids); do
        kill $i
    done
    rm -f ~/.$$.pids
}

function apt_install() {
    for app in $@; do
        dpkg -L $app >/dev/null 2>&1 || {
            loading "Installing $app"
            apt -y install $app >/dev/null 2>&1 && {
                close_loading
                echo_success "$app installed successfully"
            } || {
                close_loading
                echo_error "Failed to install $app"
            }
        }
    done
}

function is_root() {
    # [ $(id -u) != '0' ] && return 1 || return 0
    [[ "$EUID" -ne 0 ]] && return 1 || return 0
}

function _fping() {
    apt_install fping
    [ $? == 0 ] || return 1
    if [ "$1" ]; then
        echo_message "fping $1..."
        fping $1 >/dev/null 2>&1 || {
            echo_error "Failed to fping $1"
            return 1
        }
    else
        loading
        fping lujinkai.cn >/dev/null 2>&1 && close_loading || {
            close_loading
            return 1
        }
    fi
}

# 新建目录，目录可以存在但是必须为空
function _mkdir() {
    for i in $@; do
        [ -z "$i" ] && {
            echo_error "empty dir"
            return 1
        }
        if [[ -d $i && -n "$(ls -A $i)" ]]; then
            echo_error "$i exists and is not empty"
            return 1
        fi
    done
    for i in $@; do
        mkdir -p $i
    done
}

# $1 tar压缩包, 如果不指定路径，默认src
# $2 -C 参数
# $3 目标路径
function _tar() {
    if [[ $1 =~ .*\.tar\.gz || $1 =~ .*\.tgz ]]; then
        local zxvf=zxf
    elif [[ $1 =~ .*\.tar\.xz ]]; then
        local zxvf=xJf
    elif [[ $1 =~ .*\.tar\.bz2 ]]; then
        local zxvf=xjf
    else
        echo_error "don't support this tar type"
        return 1
    fi
    [[ $1 =~ ^/.* ]] && local package=$1 || local package=$basedir/src/${1##*'/'}
    [ -f $package ] || {
        echo_error "$package don't exist"
        return 1
    }
    if [ "$2" == '-C' ]; then
        [[ $3 =~ ^/.* ]] && local target_dir=$3 || local target_dir=$basedir/src/${3##*'/'}
        _mkdir $target_dir || return 1
        loading "正在解压缩 $1"
        tar $zxvf $package -C $target_dir --strip-components 1
    else
        loading "正在解压缩 $1"
        tar $zxvf $package -C $basedir/src
    fi
    echo
    close_loading
}

function make_install() {
    make -j $(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
    if [ $? != '0' ]; then
        make
    fi
    [ $? == 0 ] || return 1
    make install
}

function add_bin_path() {
    [ -z "$(grep ^'export PATH=' /etc/profile)" ] && echo "export PATH=$1:\$PATH" >>/etc/profile
    [ -n "$(grep ^'export PATH=' /etc/profile)" -a -z "$(grep $1 /etc/profile)" ] && sed -i "s@^export PATH=\(.*\)@export PATH=$1:\1@" /etc/profile
    . /etc/profile
}

function remove_bin_path() {
    path=$1
    path=${path//'/'/'\/'}
    sed -iE "/export PATH=.*${path}:.*/s@$path:@@" /etc/profile
    . /etc/profile
}

# $1
# $2: 位于哪个环境变量前面或者后面，以+开头表示之前，以-开头表示之后，默认直接追加到/etc/profile
#     位于指定变量之前，变量不存在则直接追加，位于指定变量之后，变量不存在则终止操作并return 1
#     如果$1环境变量存在，则忽略$2，直接原地修改
function _export() {
    local k=${1%%=*}
    local v=${1#*=}
    [ "$(grep ^"export $k=" /etc/profile)" ] && {
        sed -i "s@^export $k=.*@export $k=$v@" /etc/profile
        return 0
    }
    [ -z $2 ] && {
        echo "export $k=$v" >>/etc/profile
        return 0
    }
    local flag=${2:0:1}
    local exp=${2:1}
    if [ $flag == '+' ]; then
        if [ -z "$(grep ^"export\ $exp=" /etc/profile)" ]; then
            echo "export $k=$v" >>/etc/profile
        else
            sed -i "s@^export $exp=@export $k=$v\nexport $exp=@" /etc/profile
        fi
    elif [ $flag == '-' ]; then
        if [ -z "$(grep ^"export $exp=" /etc/profile)" ]; then
            echo_error "$exp 环境变量不存在"
            return 1
        else
            sed -i "s@^export $exp=.*@&\nexport $k=$v@" /etc/profile
        fi
    else
        echo_error 'Invalid parameter'
    fi
    . /etc/profile
}

# @echo ubuntu版本
function ubuntu_version() {
    if [ -e "/usr/bin/apt" ]; then
        apt_install lsb-release
        echo $(lsb_release -sr | cut -d . -f 1)
        return 0
    else
        return 1
    fi
}

function is_x86_64() {
    [[ $(getconf WORD_BIT) == '32' && $(getconf LONG_BIT) == '64' ]] && return 0 || return 1
}

function mem() {
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US:en
    echo $(free -m | awk '/Mem:/{print $2}')
}

function install_common() {
    declare -a apps=(
        build-essential
        make
        wget
        tree
        bc
        bash-completion
        lsof
        rsync
        vim
        net-tools
        zip
        unzip
        bzip2
        tcpdump
        curl
    )
    for app in ${apps[@]}; do
        apt_install $app
    done
}

function get_ini() {
    local option=$(cat $basedir/config/$1.ini | grep "^$2")
    option=$(echo ${option#*=} | awk '$1=$1')
    echo $option
}
