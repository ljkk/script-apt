#!/bin/bash
# Author: 半岛铁锤 441757636@qq.com

memory_limit() {
    local Mem=$(mem)
    if [ $Mem -le 640 ]; then
        local Mem_level=512M
        local Memory_limit=64
    elif [ $Mem -gt 640 -a $Mem -le 1280 ]; then
        local Mem_level=1G
        local Memory_limit=128
    elif [ $Mem -gt 1280 -a $Mem -le 2500 ]; then
        local Mem_level=2G
        local Memory_limit=192
    elif [ $Mem -gt 2500 -a $Mem -le 3500 ]; then
        local Mem_level=3G
        local Memory_limit=256
    elif [ $Mem -gt 3500 -a $Mem -le 4500 ]; then
        local Mem_level=4G
        local Memory_limit=320
    elif [ $Mem -gt 4500 -a $Mem -le 8000 ]; then
        local Mem_level=6G
        local Memory_limit=384
    elif [ $Mem -gt 8000 ]; then
        local Mem_level=8G
        local Memory_limit=448
    fi
    echo $Memory_limit
}
