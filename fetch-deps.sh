#!/bin/bash

set -e

source ./version.sh

mkdir -p sources && cd sources

# XZ
wget https://github.com/vial-kb/vial-deps/releases/download/v1/xz-${XZ_VER}.tar.gz -O xz-${XZ_VER}.tar.gz
echo "${XZ_HASH} xz-${XZ_VER}.tar.gz" | sha256sum --check

# CPython
wget https://github.com/vial-kb/vial-deps/releases/download/v1/cpython-${CPYTHON_VER}.tar.gz -O cpython-${CPYTHON_VER}.tar.gz
echo "${CPYTHON_HASH} cpython-${CPYTHON_VER}.tar.gz" | sha256sum --check

# Qt 5
wget https://github.com/vial-kb/vial-deps/releases/download/v1/qt-everywhere-src-${QT_VER}.tar.xz -O qt-everywhere-src-${QT_VER}.tar.xz
echo "${QT_HASH} qt-everywhere-src-${QT_VER}.tar.xz" | sha256sum --check

# SIP
wget https://github.com/vial-kb/vial-deps/releases/download/v1/sip-${SIP_VER}.tar.gz -O sip-${SIP_VER}.tar.gz
echo "${SIP_HASH} sip-${SIP_VER}.tar.gz" | sha256sum --check

# PyQt5-sip
wget https://github.com/vial-kb/vial-deps/releases/download/v1/PyQt5_sip-${PYQT5SIP_VER}.tar.gz -O PyQt5_sip-${PYQT5SIP_VER}.tar.gz
echo "${PYQT5SIP_HASH} PyQt5_sip-${PYQT5SIP_VER}.tar.gz" | sha256sum --check

# PyQt5
wget https://github.com/vial-kb/vial-deps/releases/download/v1/PyQt5-${PYQT5_VER}.tar.gz -O PyQt5-${PYQT5_VER}.tar.gz
echo "${PYQT5_HASH} PyQt5-${PYQT5_VER}.tar.gz" | sha256sum --check

echo "All OK. Now run ./build-deps.sh"
