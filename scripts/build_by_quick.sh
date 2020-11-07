#!/usr/bin/env bash

source scripts/basic.sh

# if error occured, then exit
set -e

# 选择设备
# device_type:
# 1 软路由
# 2 小米路由器青春版
# 3 Newifi3
info "Awesome OpenWrt oh-my-openwrt 当前支持以下路由器设备:"
echo
echo "        1. 软路由"
echo "        2. 小米路由器青春版"
echo "        3. Newifi3"
echo
echo "        0. 取消"
echo

while true; do
    echo -n -e "$INPUT "
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
# 1、19.07.4
# 2、19.07.3
# 3、18.06.8
info "Awesome OpenWrt oh-my-openwrt 当前支持编译以下版本:"
echo
echo "        1. 19.07.4"
echo "        2. 19.07.3"
# echo "        3. 18.06.8"
echo
echo "        0. 取消"
echo

while true; do
    echo -n -e "$INPUT "
    read -p "请选择编译版本: " yn
    echo
    case $yn in
        1 ) openwrt_version=1; break;;
        2 ) openwrt_version=2; break;;
        # 3 ) openwrt_version=3; break;;
        0  | "") echo -e "$INFO End!"; exit;;
        * ) echo "输入 0-9 以确认";;
    esac
done

gen_version_desc(){
    if [ $openwrt_version -eq 1 ]; then
        version="19.07.4"
        gcc_version="7.5.0"
    elif [ $openwrt_version -eq 2 ]; then
        version="19.07.3"
        gcc_version="7.5.0"
    elif [ $openwrt_version -eq 3 ]; then
        version="18.06.8"
        gcc_version="7.3.0"
    else
        echo -e "$INFO End!"
        exit
    fi
}
gen_version_desc

gen_device_desc(){
    if [ $device_type -eq 1 ]; then
        device="x86_64"
        cpu1="x86"
        cpu2="64"
        cpu_arch="x86_64"
        device_profile="Generic"
        img_ext=".img.gz"
    elif [ $device_type -eq 2 ]; then
        device="xiaomi"
        cpu1="ramips"
        cpu2="mt76x8"
        cpu_arch="mipsel_24kc"
        device_profile="miwifi-nano"
        img_ext=".bin"
    elif [ $device_type -eq 3 ]; then
        device="newifi3"
        cpu1="ramips"
        cpu2="mt7621"
        cpu_arch="mipsel_24kc"
        device_profile="d-team_newifi-d2"
        img_ext=".bin"
    else
        echo -e "$INFO End!"
        exit
    fi
}
gen_device_desc

# OpenWrt 官方
# base_url="http://downloads.openwrt.org"
# 清华大学镜像站
# base_url="https://mirrors.tuna.tsinghua.edu.cn/openwrt"
# 中科大镜像站
# base_url="https://mirrors.ustc.edu.cn/lede"
# 中科大 - 日本大阪镜像站
# base_url="https://openwrt.proxy.ustclug.org"
# 北京外国语学院镜像站(推荐)
base_url="https://mirrors.bfsu.edu.cn/openwrt"
# imagebuilder and sdk url
imagebuilder_url="$base_url/releases/$version/targets/$cpu1/$cpu2/openwrt-imagebuilder-$version-$cpu1-$cpu2.Linux-x86_64.tar.xz"
sdk_url="$base_url/releases/$version/targets/$cpu1/$cpu2/openwrt-sdk-$version-$cpu1-${cpu2}_gcc-${gcc_version}_musl.Linux-x86_64.tar.xz"

# prepare basic path
script_root_path=`pwd`
build_root_path="$script_root_path/build"
device_path="$build_root_path/$device"
if [ ! -d $build_root_path ]; then
    mkdir -p $build_root_path
fi
if [ ! -d $device_path ]; then
    mkdir -p $device_path
fi

######################## set env ########################
# image-builder
imagebuilder_path="$device_path/$version/imagebuilder"
if [ ! -d $imagebuilder_path ]; then
    mkdir -p $imagebuilder_path
fi
pre_imagebuilder(){
    if [ "$(ls -A $imagebuilder_path)" ]; then
        echo -e "$INFO imagebuilder already set done!"
    else
        cd $device_path
        echo "download imagebuilder..."
        wget -O imagebuilder.tar.xz -t 5 -T 60 $imagebuilder_url
        echo "download imagebuilder done."
        echo "extract imagebuilder..."
        tar -xvf imagebuilder.tar.xz 1>/dev/null 2>&1
        rm -rf $imagebuilder_path
        mv openwrt-imagebuilder-$version-*/ $imagebuilder_path/
        rm -f imagebuilder.tar.xz
        echo -e "$INFO imagebuilder set done."
    fi
}
pre_imagebuilder

# sdk
sdk_path="$device_path/$version/sdk"
if [ ! -d $sdk_path ]; then
    mkdir -p $sdk_path
fi
pre_sdk(){
    if [ "$(ls -A $sdk_path)" ]; then
        echo -e "$INFO sdk already set done!"
    else
        cd $device_path
        echo "download sdk..."
        wget -O sdk.tar.xz -t 5 -T 60 $sdk_url
        echo "download sdk done."
        echo "extract sdk..."
        tar -xvf sdk.tar.xz 1>/dev/null 2>&1
        rm -rf $sdk_path
        mv openwrt-sdk-$version-*/ $sdk_path/
        rm -f sdk.tar.xz
        echo -e "$INFO sdk set done."
    fi
}
pre_sdk

# artifact
ipk_path="$sdk_path/bin/packages/$cpu_arch"
bin_path="$imagebuilder_path/bin/targets/$cpu1/$cpu2"
artifact_root_path="$build_root_path/artifacts/$version"
artifact_bin_path="$artifact_root_path/targets/$device"
artifact_ipk_path="$artifact_root_path/packages"
pre_archive_dir(){
    ## dir bins
    if [ ! -d $bin_path ]; then
        mkdir -p $bin_path
    fi
    # 归档构建产物 bin
    if [ ! -d $artifact_bin_path ]; then
        mkdir -p $artifact_bin_path
    fi
    ## dir ipks
    if [ ! -d $ipk_path/awesome ]; then
        mkdir -p $ipk_path/awesome
    fi
    # 归档构建产物 ipk
    if [ ! -d $artifact_ipk_path ]; then
        mkdir -p $artifact_ipk_path
    fi
    if [ ! -d $artifact_ipk_path/luci ]; then
        mkdir -p $artifact_ipk_path/luci
    fi
    if [ ! -d $artifact_ipk_path/base/$cpu_arch ]; then
        mkdir -p $artifact_ipk_path/base/$cpu_arch
    fi
    echo -e "$INFO archive dir already set done!"
}
pre_archive_dir

######################## feeds update and install ########################
# add packages to feeds.conf
my_packages_url="https://github.com/awesome-openwrt/openwrt-packages"
add_packages2feeds(){
    # import awesome code to sdk
    if [ `grep -c "src-git awesome $my_packages_url" $sdk_path/feeds.conf.default` -eq 0 ]; then
        echo "add packages to feeds..."
        echo "src-git awesome $my_packages_url">>$sdk_path/feeds.conf.default
        echo -e "$INFO add packages to feeds done!"
    fi
}
add_packages2feeds

# 修复 go 版本过低无法编译 v2ray-core 的问题 @https://github.com/coolsnowwolf/lede/issues/5719
fix_v2ray_version(){
    pushd feeds/packages/lang
    rm -fr golang
    svn co https://github.com/coolsnowwolf/packages/trunk/lang/golang
    popd
}

# 修复 kcptun 版本过低的问题
fix_kcptun_version(){
    pushd feeds/packages/net
    rm -fr kcptun
    svn co https://github.com/coolsnowwolf/packages/trunk/net/kcptun
    popd
}

# prepare feeds (update and install)
do_pre_feeds(){
    echo "update/install feeds..."
    cd $sdk_path
    # rm -rf feeds/awesome*
    ./scripts/feeds update -a
    fix_v2ray_version
    fix_kcptun_version
    ./scripts/feeds install -a
    # ./scripts/feeds update awesome && ./scripts/feeds install -a -p awesome
    echo -e "$INFO update/install feeds done!"
}
pre_feeds(){
    cd $sdk_path
    if [ -d staging_dir/host/bin  ]; then
        result=`ls staging_dir/host/bin`
        if [ -z "$result" ]; then
            do_pre_feeds
            return
        fi
    else
        do_pre_feeds
        return
    fi
    echo
    while true; do
        echo -n -e "$INPUT"
        read -p "是否 安装/更新 feeds (y/n) ? " yn
        echo
        case $yn in
            [Yy]* ) do_pre_feeds; break;;
            [Nn]* | "" ) break;;
            * ) echo "输入 y 或 n 以确认";;
        esac
    done
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

# 修复 v2ray 依赖问题
fix_v2ray_dep(){
    if [ ! -e $sdk_path/staging_dir/host/bin/upx ]; then
        result=`which upx`
        if [ -n "$result" ]; then
            ln -s $result $sdk_path/staging_dir/host/bin/upx
        fi
    fi
    if [ ! -e $sdk_path/staging_dir/host/bin/upx-ucl ]; then
        result=`which upx-ucl`
        if [ -n "$result" ]; then
            ln -s $result $sdk_path/staging_dir/host/bin/upx-ucl
        fi
    fi
}
fix_v2ray_dep

######################## pre build ########################
# gen diffconfig
update_diffconfig(){
    cd $sdk_path
    ./scripts/diffconfig.sh >.config.diff
}
# make menuconfig
do_make_menuconfig(){
    cd $sdk_path
    make menuconfig
    update_diffconfig
}
default_config(){
    cd $sdk_path
    if [ ! -e .config ]; then
        diffconfig_file_path="$script_root_path/devices/$device/.config.diff"
        if [ -e $diffconfig_file_path ]; then
            cp -f $diffconfig_file_path .config
            make defconfig
        fi
    fi
}
edit_config(){
    cd $sdk_path
    default_config
    while true; do
        echo -n -e "$INPUT"
        read -p "是否需要修改编译配置 (y/n) ? " yn
        echo
        case $yn in
            [Yy]* ) do_make_menuconfig; break;;
            [Nn]* | "" ) break;;
            * ) echo "输入 y 或 n 以确认";;
        esac
    done
}
edit_config

# # make download
do_make_download(){
    cd $sdk_path
    if [ -d dl ]; then
        # @https://p3terx.com/archives/openwrt-compilation-steps-and-commands.html
        # 查找 dl 目录下文件是否下载正常，小于 1k 的文件，说明下载可能不完整
        result=`find dl -size -1024c -exec ls -l {} \;`
        if [ -n "$result" ]; then
            # 删除 dl 目录下小于 1k 的文件
            find dl -size -1024c -exec rm -f {} \;
            make download -j8 V=s
        fi
    else
        make download -j8 V=s
    fi
}
do_make_download

######################## build ########################

# build ipks
do_build_ipks(){
    echo "build ipks begin..."

    cd $sdk_path

    # clean dir
    rm -rf $ipk_path/awesome
    mkdir -p $ipk_path/awesome

    ################# start build for detail ######################

    # 查看自定义软件包 ./scripts/feeds list -r awesome

    # make package/luci-app-adbyby-plus/compile V=s
    # make package/luci-app-aliddns/compile V=s
    # make package/luci-app-arpbind/compile V=s
    # make package/luci-app-autoreboot/compile V=s
    # make package/luci-app-clash/compile V=s
    # make package/luci-app-control-mia/compile V=s
    # make package/luci-app-control-timewol/compile V=s
    # make package/luci-app-control-webrestriction/compile V=s
    # make package/luci-app-control-weburl/compile V=s
    # make package/luci-app-fileassistant/compile V=s
    # make package/luci-app-flowoffload/compile V=s
    # make package/luci-app-ipsec-vpnserver/compile V=s
    # make package/luci-app-netdata/compile V=s
    # make package/luci-app-openclash/compile V=s
    # make package/luci-app-passwall/compile V=s
    # make package/luci-app-passwall-mini/compile V=s
    # make package/luci-app-pptp-vpnserver/compile V=s
    # make package/luci-app-ramfree/compile V=s
    # make package/luci-app-smartdns/compile V=s
    # make package/luci-app-ssr-plus/compile V=s
    # make package/luci-app-ssr-plus-mini/compile V=s
    # make package/luci-app-syncthing/compile V=s
    # make package/luci-app-usb-printer/compile V=s
    # make package/luci-app-vlmcsd/compile V=s
    # make package/luci-app-webadmin/compile V=s
    # make package/luci-app-xlnetacc/compile V=s

    # make package/adbyby/compile V=s
    # make package/brook/compile V=s
    # make package/chinadns-ng/compile V=s
    # make package/ddns-scripts_aliyun/compile V=s
    # make package/dns2socks/compile V=s
    # make package/ipt2socks/compile V=s
    # make package/kcptun/compile V=s
    # make package/luci-i18n-sqm/compile V=s
    # make package/microsocks/compile V=s
    # make package/pdnsd-alt/compile V=s
    # make package/redsocks2/compile V=s
    # make package/shadowsocksr-libev/compile V=s
    # make package/simple-obfs/compile V=s
    # make package/smartdns/compile V=s
    # make package/syncthing/compile V=s
    # make package/tcping/compile V=s
    # make package/tcpping/compile V=s
    # make package/trojan/compile V=s
    # make package/v2ray/compile V=s
    # make package/v2ray-plugin/compile V=s
    # make package/vlmcsd/compile V=s

    ################# end build for detail ######################

    echo -e "$INFO build ipks done!"

    ## factory ##
    make package/luci-app-autoreboot/compile V=s
    make package/luci-app-ramfree/compile V=s
    make package/luci-app-ssr-plus/compile V=s
    make package/luci-app-passwall/compile V=s

    ## test ##
    # 
    # make package/luci-app-ssr-plus-mini/compile V=s
    # make package/luci-app-passwall-mini/compile V=s
    # 
    # make package/luci-app-ssr-plus/compile V=s
    # make package/luci-app-passwall/compile V=s
    # make package/luci-app-adbyby-plus/compile V=s
    # make package/luci-app-smartdns/compile V=s
    # make package/luci-app-netdata/compile V=s

}
build_ipks(){
    while true; do
        echo -n -e "$INPUT"
        read -p "是否编译 Awesome OpenWrt 软件包 (y/n) ? " yn
        echo
        case $yn in
            [Yy]* ) do_build_ipks; break;;
            [Nn]* | "" ) break;;
            * ) echo "输入 y 或 n 以确认";;
        esac
    done
}
build_ipks

# 归档 ipks
do_archive_ipks(){
    cd $ipk_path/awesome
    local result=`ls | grep 'all.ipk'`
    if [ -n "$result" ]; then
        cp -f *_all.ipk $artifact_ipk_path/luci
    fi
    local result2=`ls | grep "$cpu_arch.ipk"`
    if [ -n "$result2" ]; then
        cp -f *_$cpu_arch.ipk $artifact_ipk_path/base/$cpu_arch
    fi
}
archive_ipks(){
    while true; do
        echo -n -e "$INPUT"
        read -p "是否归档 ipks 软件包 (y/n) ? " yn
        echo
        case $yn in
            [Yy]* | "" ) do_archive_ipks; break;;
            [Nn]* ) break;;
            * ) echo "输入 y 或 n 以确认";;
        esac
    done
}
archive_ipks

# build img
# 设置仓库
set_repo(){
    cd $imagebuilder_path
    if [ ! -e repositories.conf ]; then
        return
    fi

    # 替换官方仓库地址为国内镜像站点
    org_url="http://downloads.openwrt.org"
    # 北京外国语学院镜像站(推荐)
    mirror_url="https://mirrors.bfsu.edu.cn/openwrt"
    if [ `grep -c "$mirror_url" repositories.conf` -eq 0 ]; then
        sed -i "s@$org_url@$mirror_url@g" repositories.conf
    fi
    
    # 增加自定义包仓库地址
    my_packages_repo="$artifact_ipk_path/luci"
    my_packages_repo_base="$artifact_ipk_path/base/$cpu_arch"
    if [ `grep -c "src awesome file://$my_packages_repo" $imagebuilder_path/repositories.conf` -eq 0 ]; then
        echo "add packages to repo..."
        echo "src awesome file://$my_packages_repo">>$imagebuilder_path/repositories.conf
        echo "src awesome_base file://$my_packages_repo_base">>$imagebuilder_path/repositories.conf
        echo -e "$INFO add packages to repo done!"
    fi
}

do_build_bin(){
    echo "build $build_type bin begin..."

    cd $imagebuilder_path

    # clean
    rm -rf $bin_path
    mkdir -p $bin_path
    # rm -rf $imagebuilder_path/packages/awesome

    # add ipks to imagebuilder
    # mkdir -p $imagebuilder_path/packages/awesome
    # local result=`ls $artifact_ipk_path/luci | grep '.ipk'`
    # if [ -n "$result" ]; then
    #     cp -f $artifact_ipk_path/luci/* $imagebuilder_path/packages/awesome/
    # fi
    # local result2=`ls $artifact_ipk_path/base/$cpu_arch | grep "$cpu_arch.ipk"`
    # if [ -n "$result2" ]; then
    #     cp -f $artifact_ipk_path/base/$cpu_arch/* $imagebuilder_path/packages/awesome/
    # fi
    # rm -rf $imagebuilder_path/packages/awesome/Packages*

    set_repo

    # fix Imagebuilder: "opkg_install_pkg: Package size mismatch" error
    # @https://bugs.openwrt.org/index.php?do=details&task_id=2690&status%5B0%5D=
    for f in dl/openwrt_*; do
        zcat $f | sed -ne '/^Filename:/s/.* //p' -e '/^SHA256sum:/s/.* //p' | while read file; do
            read sum
            if [ -f dl/$file ]; then
                read sum1 junk < <(sha256sum dl/$file)
                if [ $sum != $sum1 ]; then
                    rm -f dl/$file
                fi
            fi
        done
    done

    # 查看固件已安装软件包 echo $(opkg list_installed | awk '{ print $1 }')
    if [ $device == "xiaomi" ]; then
        org_original_pkgs="base-files busybox cgi-io dnsmasq dropbear firewall fstools fwtool getrandom hostapd-common ip6tables iptables iw iwinfo jshn jsonfilter kernel kmod-cfg80211 kmod-gpio-button-hotplug kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-nat kmod-ipt-offload kmod-leds-gpio kmod-lib-crc-ccitt kmod-mac80211 kmod-mt76-core kmod-mt7603 kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-slhc kmod-usb-core kmod-usb-ehci kmod-usb-ledtrig-usbport kmod-usb-ohci kmod-usb2 libblobmsg-json libc libgcc1 libip4tc2 libip6tc2 libiwinfo-lua libiwinfo20181126 libjson-c2 libjson-script liblua5.1.5 liblucihttp-lua liblucihttp0 libnl-tiny libpthread libubox20191228 libubus-lua libubus20191227 libuci20130104 libuclient20160123 libxtables12 logd lua luci luci-app-firewall luci-app-opkg luci-base luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-theme-bootstrap mtd netifd odhcp6c odhcpd-ipv6only openwrt-keyring opkg ppp ppp-mod-pppoe procd rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns swconfig ubox ubus ubusd uci uclient-fetch uhttpd urandom-seed urngd usign wireless-regdb wpad-basic"
        org_custom_pkgs="-kmod-usb-core -kmod-usb2 -kmod-usb-ohci -kmod-usb-ledtrig-usbport luci-compat luci-lib-ipkg luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn ca-certificates ca-bundle wget -dnsmasq dnsmasq-full"
    elif [ $device == "newifi3" ]; then
        org_original_pkgs="base-files busybox cgi-io dnsmasq dropbear firewall fstools fwtool getrandom hostapd-common ip6tables iptables iw iwinfo jshn jsonfilter kernel kmod-cfg80211 kmod-gpio-button-hotplug kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-nat kmod-ipt-offload kmod-leds-gpio kmod-lib-crc-ccitt kmod-mac80211 kmod-mt76-core kmod-mt7603 kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-nls-base kmod-ppp kmod-pppoe kmod-pppox kmod-slhc kmod-usb-core kmod-usb-ehci kmod-usb-ledtrig-usbport kmod-usb-ohci kmod-usb2 libblobmsg-json libc libgcc1 libip4tc2 libip6tc2 libiwinfo-lua libiwinfo20181126 libjson-c2 libjson-script liblua5.1.5 liblucihttp-lua liblucihttp0 libnl-tiny libpthread libubox20191228 libubus-lua libubus20191227 libuci20130104 libuclient20160123 libxtables12 logd lua luci luci-app-firewall luci-app-opkg luci-base luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-theme-bootstrap mtd netifd odhcp6c odhcpd-ipv6only openwrt-keyring opkg ppp ppp-mod-pppoe procd rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns swconfig ubox ubus ubusd uci uclient-fetch uhttpd urandom-seed urngd usign wireless-regdb wpad-basic"
        org_custom_pkgs="luci-compat luci-lib-ipkg luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn ca-certificates ca-bundle wget -dnsmasq dnsmasq-full"
    elif [ $device == "x86_64" ]; then
        org_original_pkgs="base-files bnx2-firmware busybox cgi-io dnsmasq dropbear e2fsprogs firewall fstools fwtool getrandom ip6tables iptables jshn jsonfilter kernel kmod-bnx2 kmod-button-hotplug kmod-e1000 kmod-e1000e kmod-hwmon-core kmod-i2c-algo-bit kmod-i2c-core kmod-igb kmod-input-core kmod-ip6tables kmod-ipt-conntrack kmod-ipt-core kmod-ipt-nat kmod-ipt-offload kmod-lib-crc-ccitt kmod-mii kmod-nf-conntrack kmod-nf-conntrack6 kmod-nf-flow kmod-nf-ipt kmod-nf-ipt6 kmod-nf-nat kmod-nf-reject kmod-nf-reject6 kmod-ppp kmod-pppoe kmod-pppox kmod-pps kmod-ptp kmod-r8169 kmod-slhc libblkid1 libblobmsg-json libc libcomerr0 libext2fs2 libf2fs6 libgcc1 libip4tc2 libip6tc2 libiwinfo-lua libiwinfo20181126 libjson-c2 libjson-script liblua5.1.5 liblucihttp-lua liblucihttp0 libnl-tiny libpthread librt libsmartcols1 libss2 libubox20191228 libubus-lua libubus20191227 libuci20130104 libuclient20160123 libuuid1 libxtables12 logd lua luci luci-app-firewall luci-app-opkg luci-base luci-lib-ip luci-lib-jsonc luci-lib-nixio luci-mod-admin-full luci-mod-network luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-theme-bootstrap mkf2fs mtd netifd odhcp6c odhcpd-ipv6only openwrt-keyring opkg partx-utils ppp ppp-mod-pppoe procd r8169-firmware rpcd rpcd-mod-file rpcd-mod-iwinfo rpcd-mod-luci rpcd-mod-rrdns ubox ubus ubusd uci uclient-fetch uhttpd urandom-seed urngd usign"
        org_custom_pkgs="luci-compat luci-lib-ipkg luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn ca-certificates ca-bundle wget -dnsmasq dnsmasq-full"
    fi

    # 查看自定义软件包 ./scripts/feeds list -r awesome
    #awesome_factory_pkgs="luci-app-ramfree luci-app-autoreboot luci-i18n-autoreboot-zh-cn"
    awesome_factory_pkgs=""

    # make args setting
    image_pkgs="$org_original_pkgs $org_custom_pkgs $awesome_factory_pkgs"
    files_path="$script_root_path/devices/$device/factory"

    # make image
    make image PROFILE=$device_profile PACKAGES="${image_pkgs}" FILES=$files_path
    
    echo -e "$INFO build $build_type bin done!"
}
build_bin(){
    while true; do
        echo -n -e "$INPUT"
        read -p "是否编译 Awesome OpenWrt 固件 (y/n) ? " yn
        echo
        case $yn in
            [Yy]* ) do_build_bin; break;;
            [Nn]* | "" ) break;;
            * ) echo "输入 y 或 n 以确认";;
        esac
    done
}
build_bin

# 归档 bins
do_archive_bins(){
    cd $bin_path
    result=`find . -name "openwrt-${version}*combined-squashfs${img_ext}"`
    if [ -n "$result" ]; then
        cp -f openwrt-${version}*combined-squashfs${img_ext} $artifact_bin_path
    fi
}
archive_bins(){
    while true; do
        echo -n -e "$INPUT"
        read -p "是否归档固件 (y/n) ? " yn
        echo
        case $yn in
            [Yy]* | "" ) do_archive_bins; break;;
            [Nn]* ) break;;
            * ) echo "输入 y 或 n 以确认";;
        esac
    done
}
archive_bins

echo -e "$INFO End!"