#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "=== 1. Installing Cross-Compilation Dependencies ==="
dnf install -y \
    cmake \
    make \
    python3 \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtmultimedia-devel \
    mingw64-gcc-c++ \
    mingw64-qt6-qtbase \
    mingw64-qt6-qtdeclarative \
    mingw64-qt6-qtmultimedia \
    mingw64-qt6-qtsvg \
    mingw64-qt6-qttools \
    mingw64-filesystem \
    mingw64-openssl \
    zip

echo "=== 2. Configuring Project with MinGW CMake ==="
cd client
mkdir -p build_win
cd build_win
mingw64-cmake ..

echo "=== 3. Compiling Windows Binary ==="
make -j$(nproc)

echo "=== 4. Packaging DLLs using deploy_win.py ==="
cd /workspace
python3 deploy_win.py

echo "=== 5. Zipping Build Output ==="
cd /workspace/client/build_win
rm -f ../../tortu-windows-x64.zip
zip -r ../../tortu-windows-x64.zip dist

echo "========================================================"
echo "Windows build completed successfully!"
echo "Output directory: client/build_win/dist"
echo "ZIP Archive: /workspace/tortu-windows-x64.zip"
echo "========================================================"

