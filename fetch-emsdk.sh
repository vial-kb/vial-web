#!/bin/bash

set -e

git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
git checkout 891b4491419c42f9d2b9f97c47d1043b26dfd3e5
./emsdk install 3.1.10
./emsdk activate 3.1.10
cd ..
