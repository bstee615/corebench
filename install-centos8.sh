#!/bin/bash
# This script installs deps for corebench.

if [ "$EUID" -ne 0 ]
then
	echo "Please run as root"
	exit
fi

dnf install autoconf        \
    autogen         \
    autopoint       \
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
    lcov            \
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

export ACLOCAL_PATH=/usr/share/aclocal # This might be needed every time we build
wget http://pkgconfig.freedesktop.org/releases/pkg-config-0.28.tar.gz \
  && tar -zxvf pkg-config-0.28.tar.gz \
  && cd pkg-config-0.28 \
  && ./configure --with-internal-glib && make && make install \
  || exit
#FIX problem with aclocal
#cp /usr/local/share/aclocal/* /usr/share/aclocal && mv /usr/local/share/aclocal /tmp

