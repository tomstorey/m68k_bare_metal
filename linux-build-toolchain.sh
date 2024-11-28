#!/usr/bin/env bash

echo Building GCC m68k toolchain...

mkdir -p toolchain
mkdir -p toolchain/sources
mkdir -p toolchain/build

CORES=8
TARGET=m68k-eabi-elf
PREFIX=$PWD/toolchain/$TARGET-fuzix

MIRROR=http://ftpmirror.gnu.org

BINUTILS=binutils-2.37
BINUTILS_URL=$MIRROR/binutils/$BINUTILS.tar.gz

GCCVER=13.2.0
GCC=gcc-$GCCVER
GCC_URL=$MIRROR/gcc/$GCC/$GCC.tar.gz

if [ ! -f toolchain/sources/$BINUTILS.tar.gz ]; then
  echo Fetching $BINUTILS_URL ...
  (cd toolchain/sources && wget -q --show-progress $BINUTILS_URL) || exit 1
fi

if [ ! -f toolchain/sources/$GCC.tar.gz ]; then
  echo Fetching $GCC_URL ...
  (cd toolchain/sources && wget -q --show-progress $GCC_URL) || exit 1
fi

echo Extracting $BINUTILS_URL ...
test -d toolchain/sources/$BINUTILS || (cd toolchain/sources && tar xzf $BINUTILS.tar.gz) || exit 1
echo Extracting $GCC_URL ...
test -d toolchain/sources/$GCC || (cd toolchain/sources && tar xzf $GCC.tar.gz) || exit 1
mkdir -p toolchain/build

if [ ! -f $PREFIX-$GCCVER/bin/$TARGET-nm ]; then
  echo Building binutils
#  rm -rf toolchain/build/binutils
  mkdir -p toolchain/build/binutils
  (cd toolchain/build/binutils && ../../sources/$BINUTILS/configure --target=$TARGET --disable-werror --prefix=$PREFIX-$GCCVER && make -j $CORES && make install) || exit 1
fi

if [ ! -f $PREFIX-$GCCVER/bin/$TARGET-gcc ]; then
  echo Building GCC
#  rm -rf toolchain/build/gcc
  mkdir -p toolchain/build/gcc
  (cd toolchain/build/gcc && ../../sources/$GCC/configure --target=$TARGET --disable-werror --prefix=$PREFIX-$GCCVER --enable-languages=c --with-gmp=/usr/local --with-mpfr=/usr/local --with-mpc=/usr/local && make -j $CORES all-gcc all-target-libgcc && make install-gcc install-target-libgcc) || exit 1
fi

echo Cleaning up
rm -rf toolchain/build
rm -rf toolchain/sources/$BINUTILS
rm -rf toolchain/sources/$GCC

echo All done!
