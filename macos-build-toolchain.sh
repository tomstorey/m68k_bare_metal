#! /usr/bin/env bash

###############################################################################
# Credit for this script goes to https://github.com/deplinenoise
#
# Original source:
#     https://gist.github.com/deplinenoise/bcfa4fb9964f90a5f3e9d69f08ca4464
#
# I have modified it only to use more recent versions of gcc and binutils.
###############################################################################

echo Building GCC m68k toolchain...

mkdir -p sources
mkdir -p build

CORES=8
TARGET=m68k-unknown-elf
PREFIX=$PWD/m68k-unknown-elf

MIRROR=http://ftpmirror.gnu.org

BINUTILS=binutils-2.34
BINUTILS_URL=$MIRROR/binutils/$BINUTILS.tar.xz

GCC=gcc-9.3.0
GCC_URL=$MIRROR/gcc/$GCC/$GCC.tar.xz

brew install wget mpfr mpc gmp # Can't check this, because brew errors if things are already installed.

if [ ! -f sources/$BINUTILS.tar.xz ]; then
  echo Fetching $BINUTILS_URL
  (cd sources && wget $BINUTILS_URL) || exit 1
fi

if [ ! -f sources/$GCC.tar.xz ]; then
  echo Fetching $GCC_URL
  (cd sources && wget $GCC_URL) || exit 1
fi

test -d sources/$BINUTILS || (cd sources && tar xjvf ../sources/$BINUTILS.tar.xz) || exit 1
test -d sources/$GCC || (cd sources && tar xjvf ../sources/$GCC.tar.xz) || exit 1
mkdir -p build

if [ ! -f $PREFIX/bin/$TARGET-nm ]; then
  echo Building binutils
  rm -rf build/binutils
  mkdir -p build/binutils
  (cd build/binutils && ../../sources/$BINUTILS/configure --target=$TARGET --disable-werror --prefix=$PREFIX && make -j $CORES && make install) || exit 1
fi

if [ ! -f $PREFIX/bin/$TARGET-gcc ]; then
  echo Building GCC
  rm -rf build/gcc
  mkdir -p build/gcc
  (cd build/gcc && ../../sources/$GCC/configure --target=$TARGET --disable-werror --prefix=$PREFIX --enable-languages=c --with-gmp=/usr/local --with-mpfr=/usr/local --with-mpc=/usr/local && make -j $CORES all-gcc && make install-gcc) || exit 1
fi
