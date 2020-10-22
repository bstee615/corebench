#!/bin/bash
# This script installs deps for corebench.

if [ "$EUID" -ne 0 ]
then
	echo "Please run as root"
	exit
fi

# autopoint => autopoint-devel
# skip lcov
dnf install autoconf        \
    autogen         \
    gettext-autopoint       \
    automake        \
    bison           \
    clang           \
    cvs             \
    gettext         \
    gcc             \
    git             \
    gnuplot         \
    gperf           \
    gzip            \
    libtool         \
    make            \
    nasm            \
    patch           \
    perl            \
    rsync           \
    tar             \
    texinfo         \
    subversion      \
    unzip           \
    vim             \
    wget \
  || exit

# Install pkg-config
PKGCONFIG='pkg-config-0.28'
wget "http://pkgconfig.freedesktop.org/releases/$PKGCONFIG.tar.gz"
tar -zxvf "$PKGCONFIG.tar.gz"
pushd $PKGCONFIG
./configure --with-internal-glib && make && make install || exit
popd

