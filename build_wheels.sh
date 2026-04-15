#!/bin/bash

# build_wheels.sh - Script to build PySide2 wheels using Docker
# This script builds both Linux and Windows wheels in their respective containers.

set -e

# Default to linux if no argument provided
PLATFORM=${1:-linux}

if [[ "$PLATFORM" != "linux" && "$PLATFORM" != "windows" ]]; then
    echo "Usage: ./build_wheels.sh [linux|windows]"
    exit 1
fi

IMAGE_TAG="pyside2-builder-$PLATFORM"
DOCKERFILE="docker/Dockerfile.$PLATFORM"

echo "Building Docker image for $PLATFORM (this may take a while)..."
docker build -t "$IMAGE_TAG" -f "$DOCKERFILE" .

echo "Running build for $PLATFORM..."

# Prepare dist directory
mkdir -p dist

if [[ "$PLATFORM" == "linux" ]]; then
    # Linux build
    docker run --rm -v "$(pwd):/app" "$IMAGE_TAG" bash -c "
        # Run the installation command requested by the user
        python setup.py install \
            --qmake=/opt/qt/5.15.2/gcc_64/bin/qmake \
            --parallel=8 \
            --build-tests \
            --ignore-git \
            --build-type=all \
            --standalone

        # Ensure wheels are generated in the dist/ folder
        echo 'Packaging wheels...'
        python setup.py bdist_wheel --only-package --standalone --qmake=/opt/qt/5.15.2/gcc_64/bin/qmake
    "
else
    # Windows build
    # NOTE: Docker for Windows must be in 'Windows Containers' mode.
    # We use a path conversion for the volume mount that works in Git Bash.
    WIN_PWD=$(pwd -W 2>/dev/null || pwd)
    
    docker run --rm -v "${WIN_PWD}:C:/app" "$IMAGE_TAG" powershell -Command "
        # Run the installation command requested by the user
        python setup.py install \
            --qmake=C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe \
            --parallel=8 \
            --build-tests \
            --ignore-git \
            --build-type=all \
            --standalone;

        # Ensure wheels are generated in the dist/ folder
        Write-Host 'Packaging wheels...';
        python setup.py bdist_wheel --only-package --standalone --qmake=C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe
    "
fi

echo "------------------------------------------------------------"
echo "Build finished for $PLATFORM."
echo "Wheels should be available in the 'dist/' directory."
