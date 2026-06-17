#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "=== 1. Installing Host Compilation Dependencies ==="
dnf install -y \
    cmake \
    make \
    gcc-c++ \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtmultimedia-devel \
    qt6-qtsvg-devel \
    rpm-build

echo "=== 2. Configuring Project with CMake ==="
cd client
mkdir -p build_linux
cd build_linux
cmake -DCMAKE_BUILD_TYPE=Release ..

echo "=== 3. Compiling Linux Binary ==="
make -j$(nproc)

echo "=== 4. Packaging with CPack ==="
cpack -G RPM
cpack -G DEB

cp *.rpm *.deb /workspace/

echo "========================================================"
echo "Linux packaging completed successfully!"
echo "Generated packages copied to project root:"
ls -lh /workspace/*.rpm /workspace/*.deb
echo "========================================================"
