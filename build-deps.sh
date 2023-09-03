#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source ./version.sh
source ./emsdk/emsdk_env.sh

embuilder build zlib bzip2

rm -rf deps
mkdir deps && cd deps

tar xvf ../sources/xz-${XZ_VER}.tar.gz
pushd xz-${XZ_VER}
emconfigure ./configure --disable-shared --enable-static --prefix=$PWD/prefix
emmake make -j$(nproc) install
popd

tar xvf ../sources/cpython-${CPYTHON_VER}.tar.gz
mv cpython-${CPYTHON_VER} cpython
pushd cpython

mkdir -p builddir/build
pushd builddir/build
../../configure -C
make -j$(nproc)
popd

mkdir -p builddir/emscripten-browser
pushd builddir/emscripten-browser

CONFIG_SITE=../../Tools/wasm/config.site-wasm32-emscripten \
  emconfigure ../../configure -C \
    --host=wasm32-unknown-emscripten \
    --build=$(../../config.guess) \
    --with-emscripten-target=browser \
    --enable-wasm-pthreads \
    --with-build-python=$(pwd)/../build/python \
    CFLAGS="-I ../../../xz-${XZ_VER}/prefix/include/" LDFLAGS="-L ../../../xz-${XZ_VER}/prefix/lib/"

emmake make -j$(nproc)
popd

popd





tar xvf ../sources/qt-everywhere-src-${QT_VER}.tar.xz
mv qt-everywhere-src-${QT_VER} qt5
pushd qt5/
patch -p1 < $SCRIPT_DIR/patches/qt/qt.patch
pushd qtbase
patch -p1 < $SCRIPT_DIR/patches/qt/qtcore-5.15.2-gcc11.patch
patch -p1 < $SCRIPT_DIR/patches/qt/0008-Add-missing-limits-include.patch
patch -p1 < $SCRIPT_DIR/patches/qt/wasm-settings.patch
popd
./configure -xplatform wasm-emscripten -nomake examples -prefix $PWD/qtbase -feature-thread -opensource -confirm-license
make module-qtbase module-qtdeclarative qtsvg -j$(nproc)
popd



cpython/builddir/build/python -m venv venv
source venv/bin/activate

tar -xf ../sources/sip-${SIP_VER}.tar.gz
pushd sip-${SIP_VER}
python setup.py install
popd



tar -xf ../sources/PyQt5_sip-${PYQT5SIP_VER}.tar.gz
pushd PyQt5_sip-${PYQT5SIP_VER}/
patch -p1 < $SCRIPT_DIR/patches/pyqt5sip.patch
mkdir build

for file in apiversions.c voidptr.c threads.c objmap.c descriptors.c array.c qtlib.c int_convertors.c siplib.c; do
    emcc -pthread -Wno-unused-result -Wsign-compare -DNDEBUG -g -fwrapv -O3 -Wall -I ../cpython/Include/ -I ../cpython/builddir/emscripten-browser/ -c $file -o "build/${file%.*}.o"
done

emar cqs libsip.a build/*.o
popd





tar -xf ../sources/PyQt5-${PYQT5_VER}.tar.gz
pushd PyQt5-${PYQT5_VER}/
patch -p1 < $SCRIPT_DIR/patches/pyqt5.patch
python ./configure.py --qmake ../qt5/qtbase/bin/qmake --static --confirm-license --sip-incdir=../PyQt5_sip-${PYQT5SIP_VER}/

pushd QtCore
sed -i "s+-I../../cpython/Include+-I../../cpython/Include -I../../cpython/builddir/emscripten-browser/+g" Makefile
patch < $SCRIPT_DIR/patches/pyqt5-qtcore.patch
make -j$(nproc)
popd

pushd QtGui
sed -i "s+-I../../cpython/Include+-I../../cpython/Include -I../../cpython/builddir/emscripten-browser/+g" Makefile
make -j$(nproc)
popd

pushd QtWidgets
sed -i "s+-I../../cpython/Include+-I../../cpython/Include -I../../cpython/builddir/emscripten-browser/+g" Makefile
patch < $SCRIPT_DIR/patches/pyqt5-qtwidgets.patch
make -j$(nproc)
popd

pushd QtSvg
sed -i "s+-I../../cpython/Include+-I../../cpython/Include -I../../cpython/builddir/emscripten-browser/+g" Makefile
make -j$(nproc)
popd


popd


cd ..
