#!/bin/bash

# haproxy依赖lua
wget http://www.lua.org/ftp/lua-5.4.2.tar.gz
mkdir /usr/local/lua
tar zxvf lua-5.4.2.tar.gz -C /usr/local/lua --strip-components 1
cd /usr/local/lua
make all test
./src/lua -v

apt install make build-essential libssl-dev zlib1g-dev libpcre3 libpcre3-dev libsystemd-dev libreadline-dev -y

useradd -r -s /usr/sbin/nologin haproxy
