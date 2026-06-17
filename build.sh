#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "Starting build process..."

# Navigate to client directory if script is run from project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR/client"

# Create build directory
mkdir -p build
cd build

# Configure project with CMake
echo "Configuring project with CMake..."
cmake ..

# Build project
echo "Building project..."
make -j$(nproc)

echo "--------------------------------------------------------"
echo "Build finished successfully!"
echo "To run the Tortu client, run:"
echo "  ./build/tortu"
echo "--------------------------------------------------------"
