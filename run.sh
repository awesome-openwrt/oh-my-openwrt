#!/usr/bin/env bash

source scripts/basic.sh

# tips
info "Welcome to Awesome OpenWrt oh-my-openwrt!"
echo
echo "        0. 更新 oh-my-openwrt"
echo "        1. 快速编译 Awesome OpenWrt (by sdk and imagebuilder)"
echo "        2. 源码编译 Awesome OpenWrt"
echo
echo "        8. 签名 ipks (此过程无需翻墙!)"
echo "        9. 安装编译所需软件包 (此过程无需翻墙!)"
echo

do_update_omo(){
    echo "update oh-my-openwrt..."
    git reset --hard
    git clean -fd
    git pull
    info "oh-my-openwrt update done!"
}

while true; do
    echo -n -e "$INPUT "
    read -p "请输入操作序号 (0-9): " yn
    echo
    case $yn in
        "" ) info "Exit!"; exit;;
        0 ) do_update_omo; exit;;

        1 ) bash scripts/build_by_quick.sh; break;;
        2 ) bash scripts/build_by_source.sh; break;;

        8 ) bash scripts/sign.sh; exit;;
        9 ) bash scripts/dependency.sh; break;;
        * ) echo "输入 0-9 以确认";;
    esac
done

echo
