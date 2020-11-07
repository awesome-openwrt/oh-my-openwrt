#!/usr/bin/env bash

BOLD="\033[1m"
NORM="\033[0m"
INFO="$BOLD Info: $NORM"
INPUT="$BOLD => $NORM"
ERROR="\033[31m *** Error: $NORM"
WARNING="\033[33m * Warning: $NORM"

# if error occured, then exit
set -e

######################## build dependency ########################

## for missing ncurses(libncurses.so or ncurses.h), 'unzip', Python 2.x, openssl, make, upx(for v2ray)
do_install_dep_awesome(){
    echo "install build dependency for awesome begin..."
    sudo apt update
    sudo apt install -y libncurses5-dev unzip python libssl-dev build-essential upx
    echo -e "$INFO install build dependency for awesome done!"
}

# install build dependency
## @https://github.com/coolsnowwolf/lede
do_install_dep_lean(){
    echo "install build dependency for lean begin..."
    sudo apt update
    sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync
    echo -e "$INFO install build dependency for lean done!"
}

do_install_dep(){
    do_install_dep_awesome
    do_install_dep_lean
}

do_install_dep
