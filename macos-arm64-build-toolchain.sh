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

echo
echo "Notice to ARM (Apple Silicon) based Mac users"
echo =============================================
echo 
echo As of macOS Sequoia version 15.2, Apple upgraded the included version of clang from 16 to 17.
echo 
echo clang 17 is not backwardly able to compile some sources used by this toolchain.
echo 
echo "It is recommended to use clang no later than version 16 to build this toolchain."
echo 
echo You can check your version of clang by running: clang -v
echo 
echo If your version of clang reports as 17 or higher, you can install clang 16 using brew with the following command:
echo 
echo brew install llvm@16
echo 
echo Once clang 16 is installed, set some environment variables and then re-run this build script:
echo 
echo export PATH=\"/opt/homebrew/opt/llvm@16/bin:\$PATH\"
echo export CC=\"/opt/homebrew/opt/llvm@16/bin/clang\"
echo export CXX=\"\$CC++\"
echo export LDFLAGS=\"-L/opt/homebrew/opt/llvm@16/lib -L/opt/homebrew/opt/llvm@16/lib/c++ -Wl,-rpath,/opt/homebrew/opt/llvm@16/lib/c++\"
echo export CFLAGS=\"-I/opt/homebrew/opt/llvm@16/include\"
echo export CPPFLAGS=\"-I/opt/homebrew/opt/llvm@16/include\"
echo 
echo clang 16 can be uninstalled afterwards if you choose, and the environment variables are temporary to the current shell session and will clear once it is terminated.
echo 
read -p "Press enter to continue building, or Ctrl-C to abort"
echo

echo Building GCC m68k toolchain...

mkdir -p toolchain
mkdir -p toolchain/sources
mkdir -p toolchain/build

CORES=8
TARGET=m68k-eabi-elf
PREFIX=$PWD/toolchain/$TARGET

MIRROR=http://ftpmirror.gnu.org
# MIRROR=https://mirror.team-cymru.com/gnu

BINUTILS=binutils-2.44
BINUTILS_URL=$MIRROR/binutils/$BINUTILS.tar.xz

GCCVER=13.4.0
GCC=gcc-$GCCVER
GCC_URL=$MIRROR/gcc/$GCC/$GCC.tar.xz

brew install wget mpfr mpc libmpc gmp # Can't check this, because brew errors if things are already installed.

if [ ! -f toolchain/sources/$BINUTILS.tar.xz ]; then
  echo Fetching $BINUTILS_URL
  (cd toolchain/sources && wget -q --show-progress $BINUTILS_URL) || exit 1
fi

if [ ! -f toolchain/sources/$GCC.tar.xz ]; then
  echo Fetching $GCC_URL
  (cd toolchain/sources && wget -q --show-progress $GCC_URL) || exit 1
fi

echo Extracting $BINUTILS ...
test -d toolchain/sources/$BINUTILS || (cd toolchain/sources && tar xjf ../sources/$BINUTILS.tar.xz) || exit 1
echo Extracting $GCC ...
test -d toolchain/sources/$GCC || (cd toolchain/sources && tar xjf ../sources/$GCC.tar.xz) || exit 1
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
  (cd toolchain/build/gcc && ../../sources/$GCC/configure --target=$TARGET --disable-werror --prefix=$PREFIX-$GCCVER --enable-languages=c --with-gmp=/opt/homebrew/var/homebrew/linked/gmp --with-mpfr=/opt/homebrew/var/homebrew/linked/mpfr --with-mpc=/opt/homebrew/var/homebrew/linked/libmpc && make -j $CORES all-gcc && make install-gcc) || exit 1
fi

echo All done!
