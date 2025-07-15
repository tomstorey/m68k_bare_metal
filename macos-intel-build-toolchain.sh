#! /usr/bin/env bash

###############################################################################
# Credit for this script goes to https://github.com/deplinenoise
#
# Original source:
#     https://gist.github.com/deplinenoise/bcfa4fb9964f90a5f3e9d69f08ca4464
#
# I have modified it only to use more recent versions of gcc and binutils, to
# include libmpc in the list of packages for brew to install, and create
# directories within the toolchain directory instead of the working directory.
###############################################################################

echo Building GCC m68k toolchain...

mkdir -p toolchain
mkdir -p toolchain/sources
mkdir -p toolchain/build

CORES=8
TARGET=m68k-eabi-elf
PREFIX=$PWD/toolchain/$TARGET

MIRROR=http://ftpmirror.gnu.org
# MIRROR=https://mirror.team-cymru.com/gnu

BINUTILS=binutils-2.37
BINUTILS_URL=$MIRROR/binutils/$BINUTILS.tar.xz

GCCVER=11.2.0
GCC=gcc-$GCCVER
GCC_URL=$MIRROR/gcc/$GCC/$GCC.tar.xz

brew install wget mpfr mpc libmpc gmp # Can't check this, because brew errors if things are already installed.

if [ ! -f toolchain/sources/$BINUTILS.tar.xz ]; then
  echo Fetching $BINUTILS_URL
  (cd toolchain/sources && wget $BINUTILS_URL) || exit 1
fi

if [ ! -f toolchain/sources/$GCC.tar.xz ]; then
  echo Fetching $GCC_URL
  (cd toolchain/sources && wget $GCC_URL) || exit 1
fi

test -d toolchain/sources/$BINUTILS || (cd toolchain/sources && tar xjvf ../sources/$BINUTILS.tar.xz) || exit 1
test -d toolchain/sources/$GCC || (cd toolchain/sources && tar xjvf ../sources/$GCC.tar.xz) || exit 1
mkdir -p toolchain/build

if [ ! -f $PREFIX-$GCCVER/bin/$TARGET-nm ]; then
  echo Building binutils
  rm -rf toolchain/build/binutils
  mkdir -p toolchain/build/binutils
  (cd toolchain/build/binutils && ../../sources/$BINUTILS/configure --target=$TARGET --disable-werror --prefix=$PREFIX-$GCCVER && make -j $CORES && make install) || exit 1
fi

if [ ! -f $PREFIX-$GCCVER/bin/$TARGET-gcc ]; then
  echo Building GCC
  rm -rf toolchain/build/gcc
  mkdir -p toolchain/build/gcc
  (cd toolchain/build/gcc && ../../sources/$GCC/configure --target=$TARGET --disable-werror --prefix=$PREFIX-$GCCVER --enable-languages=c --with-gmp=/usr/local --with-mpfr=/usr/local --with-mpc=/usr/local && make -j $CORES all-gcc && make install-gcc) || exit 1
fi
