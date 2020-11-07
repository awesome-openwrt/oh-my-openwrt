#!/usr/bin/env bash

source scripts/basic.sh

# if error occured, then exit
set -e

# info
# device_type: 1 小米路由器青春版, 2 Newifi3, 3 软路由
echo -e "$INFO Awesome OpenWrt oh-my-openwrt 当前支持以下路由器设备:"
echo
echo "        1. 软路由"
echo "        2. 小米路由器青春版"
echo "        3. Newifi3"
echo
echo "        0. 取消"
echo

while true; do
    echo -n -e "$INPUT"
    read -p "请选择路由器设备类型: " yn
    echo
    case $yn in
        1 ) device_type=1; break;;
        2 ) device_type=2; break;;
        3 ) device_type=3; break;;
        0  | "") echo -e "$INFO End!"; exit;;
        * ) echo "输入 0-9 以确认";;
    esac
done

# 选择编译版本
# openwrt_version:
# 1、18.06.8
# 2、19.07.3
# 3、19.07.4
info "Awesome OpenWrt oh-my-openwrt 当前支持编译以下版本:"
echo
# echo "        1. 18.06.8"
echo "        2. 19.07.3"
echo "        3. 19.07.4"
echo
echo "        0. 取消"
echo

while true; do
    echo -n -e "$INPUT "
    read -p "请选择编译版本: " yn
    echo
    case $yn in
        # 1 ) openwrt_version=1; break;;
        2 ) openwrt_version=2; break;;
        3 ) openwrt_version=3; break;;
        0  | "") echo -e "$INFO End!"; exit;;
        * ) echo "输入 0-9 以确认";;
    esac
done

gen_version_desc(){
    if [ $openwrt_version -eq 1 ]; then
        version="18.06.8"
        gcc_version="7.3.0"
    elif [ $openwrt_version -eq 2 ]; then
        version="19.07.3"
        gcc_version="7.5.0"
    elif [ $openwrt_version -eq 3 ]; then
        version="19.07.4"
        gcc_version="7.5.0"
    else
        echo -e "$INFO End!"
        exit
    fi
}
gen_version_desc

gen_device_desc(){
    if [ $device_type -eq 1 ]; then
        device="x86_64"
        # cpu1="x86"
        # cpu2="64"
        cpu_arch="x86_64"
        # device_profile="Generic"
        # img_ext=".img.gz"
    elif [ $device_type -eq 2 ]; then
        device="xiaomi"
        # cpu1="ramips"
        # cpu2="mt76x8"
        cpu_arch="mipsel_24kc"
        # device_profile="miwifi-nano"
        # img_ext=".bin"
    elif [ $device_type -eq 3 ]; then
        device="newifi3"
        # cpu1="ramips"
        # cpu2="mt7621"
        cpu_arch="mipsel_24kc"
        # device_profile="d-team_newifi-d2"
        # img_ext=".bin"
    else
        echo -e "$INFO End!"
        exit
    fi
}
gen_device_desc

# prepare basic path
script_root_path=`pwd`
build_root_path="$script_root_path/build"
if [ ! -d $build_root_path ]; then
    mkdir -p $build_root_path
fi

######################## set env ########################
signtool_path="$sign_root_path/sign/$version"
if [ ! -d $signtool_path ]; then
    mkdir -p $signtool_path
fi
pre_signtool(){
    if [ -d $signtool_path ]; then
        echo -e "$INFO signtool already set done!"
    else
        cd $build_root_path
        echo "set signtool..."
        wget -O sdk.tar.xz -t 5 -T 60 https://mirrors.ustc.edu.cn/lede/releases/$version/targets/ramips/mt76x8/openwrt-sdk-$version-ramips-mt76x8_gcc-${gcc_version}_musl.Linux-x86_64.tar.xz
        echo "download signtool done."
        echo "extract signtool..."
        tar -xvf sdk.tar.xz 1>/dev/null 2>&1
        rm -rf $signtool_path
        mv openwrt-sdk-$version-*/ $signtool_path/
        rm -rf sdk.tar.xz
        echo -e "$INFO set signtool done."
    fi
}
pre_signtool

######################## feeds update and install ########################
# prepare feeds (update and install)
do_pre_feeds(){
    echo "update/install feeds..."
    cd $signtool_path
    ./scripts/feeds update -a && ./scripts/feeds install -a
    # ./scripts/feeds update awesome && ./scripts/feeds install -a -p awesome
    echo -e "$INFO update/install feeds done!"
}
pre_feeds(){
    cd $signtool_path
    if [ -d staging_dir/host/bin  ]; then
        result=`find staging_dir/host/bin -name "usign"`
        if [ -z "$result" ]; then
            do_pre_feeds
            return
        fi
    else
        do_pre_feeds
        return
    fi
}
pre_feeds

######################## fix ########################
# 修复 Ubuntu 18.04 动态链接库缺失问题
fix_sys(){
    if [ ! -L /lib/ld-linux-x86-64.so.2 ]; then
        sudo ln -s /lib/x86_64-linux-gnu/ld-2.27.so /lib/ld-linux-x86-64.so.2
    fi
}
fix_sys

######################## sign ########################
do_sign(){
    tmp_dir=$1
    cd $tmp_dir
    rm -f Packages*
    $signtool_path/scripts/ipkg-make-index.sh . 2>/dev/null > Packages.manifest
    grep -vE '^(Maintainer|LicenseFiles|Source|Require)' Packages.manifest > Packages
    gzip -9nc Packages > Packages.gz
    $signtool_path/staging_dir/host/bin/usign -S -m Packages -s $build_root_path/openwrt-awesome.key
}
sign_ipks(){
    echo "sign ipks begin..."

    tmp_env=$PATH
    export PATH="$signtool_path/staging_dir/host/bin:$PATH"

    if [ ! -d $1/luci ]; then
        mkdir -p $1/luci
    fi
    if [ ! -d $1/base/$cpu_arch ]; then
        mkdir -p $1/base/$cpu_arch
    fi

    do_sign "$1/luci"
    do_sign "$1/base/$cpu_arch"

    unset PATH
    export PATH="$tmp_env"
    
    echo -e "$INFO sign ipks done."
}
artifact_root_path="$build_root_path/artifacts/$version"
artifact_bin_path="$artifact_root_path/targets/$device"
artifact_ipk_path="$artifact_root_path/packages"
sign_dir_ipks(){
    artifact_path="$build_root_path/artifacts"

    if [ $index_type -eq 1 ]; then
        artifact_root_path="$artifact_path/$version"
    else
        echo -e "$INFO End!"
        exit
    fi

    artifact_ipk_path="$artifact_root_path/packages"
    sign_ipks "$artifact_ipk_path"
}

# gen key
if [ ! -e $build_root_path/openwrt-awesome.key ]; then
    echo "openwrt-awesome.key gen..."
    $signtool_path/staging_dir/host/bin/usign -G -p $build_root_path/openwrt-awesome.pub -s $build_root_path/openwrt-awesome.key
    echo -e "$INFO openwrt-awesome.key gen done!"
fi

# while true; do
#     echo -n -e "$INPUT"
#     read -p "请选择需要索引的目录 ( 0/1 | 0 取消, 1 $version ) : " yn
#     echo
#     case $yn in
#         1 ) index_type=1; break;;
#         0  | "") echo -e "$INFO End!"; exit;;
#         * ) echo "输入 1($version) 或 0(取消) 以确认";;
#     esac
# done

index_type=1
sign_dir_ipks
