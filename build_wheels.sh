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

rm -rf ./pyside3_build
rm -rf ./pyside3_install
rm -rf ./shiboken2*.egg-info
rm -f ./dist/shiboken2*.whl
rm -f ./dist/pyside2*.whl

echo "Updating submodules..."
git submodule update --init --recursive

echo "Building Docker image for $PLATFORM (this may take a while)..."
if [[ "$PLATFORM" == "windows" ]]; then
    docker build -t "$IMAGE_TAG" -f "$DOCKERFILE" \
        --build-arg "QT_EMAIL=$QT_EMAIL" \
        --build-arg "QT_PASSWORD=$QT_PASSWORD" .
else
    docker build -t "$IMAGE_TAG" -f "$DOCKERFILE" .
fi

echo "Running build for $PLATFORM..."

# Prepare dist directory
mkdir -p dist

if [[ "$PLATFORM" == "linux" ]]; then
    # Linux build
    docker run --rm -v "$(pwd):/app" "$IMAGE_TAG" bash -c "
        # Run the installation command requested by the user
        python setup.py install \
            --qmake=/opt/qt/5.15.2/gcc_64/bin/qmake \
            --cmake='C:\Program Files\CMake\bin\cmake.exe' \
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
    # MSYS_NO_PATHCONV=1 prevents Git Bash from mangling the paths.
    WIN_PWD=$(pwd -W 2>/dev/null || pwd)

    MSYS_NO_PATHCONV=1 docker run --memory 16g --storage-opt "size=50G" --rm -v "${WIN_PWD}:C:\\app" "$IMAGE_TAG" powershell -Command "
        \$ErrorActionPreference = 'Stop';
        
        # 1. Create a local workspace on the container's internal local drive
        \$local_work = 'C:\pyside_work';
        if (Test-Path \$local_work) { Remove-Item -Recurse -Force \$local_work }
        New-Item -ItemType Directory -Path \$local_work -Force;

        # 2. Copy source code (excluding large/hidden folders to save time)
        Write-Host 'Copying source to local drive for stable building...' -ForegroundColor Cyan;
        # Robocopy is used for speed; exit codes < 8 are considered success.
        robocopy C:\app \$local_work /E /MT:32 /XD .git pyside3_build pyside3_install build dist /NFL /NDL /NJH /NJS /nc /ns /np;
        if (\$LASTEXITCODE -ge 8) { throw \"Robocopy failed with code \$LASTEXITCODE\" }
        
        Set-Location \$local_work;

        # 3. Activate MSVC 2019 amd64
        \$vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat';
        if (-not (Test-Path \$vcvars)) {
            \$vcvars = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat';
        }

        Write-Host 'Activating MSVC 2019 amd64...' -ForegroundColor Cyan;
        \$env_vars = cmd /c \"\`\"\$vcvars\`\" amd64 && set\" | Where-Object { \$_ -match '^[A-Za-z_].*=' };
        foreach (\$line in \$env_vars) {
            \$name, \$value = \$line -split '=', 2;
            [System.Environment]::SetEnvironmentVariable(\$name, \$value, 'Process');
        }

        # 4. Set Environment
        \$env:PATH = 'C:\Qt\Tools\libclang\bin;C:\Qt\5.15.2\msvc2019_64\bin;' + \$env:PATH;
        
        # Fix for Python 3.8+ DLL loading and CMake type-hint generator paths
        \$py_ver_short = python -c \"import sys; print('{}.{}'.format(sys.version_info.major, sys.version_info.minor))\"
        \$build_name = \"p\$py_ver_short\"
        \$install_dir = \"\$local_work\pyside3_install\\\$build_name\"
        \$build_dir = \"\$local_work\pyside3_build\\\$build_name\"
        \$site_packages = \"\$install_dir\Lib\site-packages\"
        
        # Early directory creation for .pth file and junctions
        New-Item -ItemType Directory -Path \$site_packages -Force
        
        # A .pth file ensures that every Python process (including type-hint generators) 
        # can find the required DLLs (shiboken2.dll, pyside2.dll, and Qt DLLs)
        \$pth_content = @\"
import os
import sys
bin_dir = r'\$install_dir\bin'
qt_bin = r'C:\Qt\5.15.2\msvc2019_64\bin'
libpyside_dir = r'\$build_dir\pyside2\libpyside'
if os.path.isdir(bin_dir): os.add_dll_directory(bin_dir)
if os.path.isdir(qt_bin): os.add_dll_directory(qt_bin)
if os.path.isdir(libpyside_dir): os.add_dll_directory(libpyside_dir)
\"@
        Set-Content -Path \"\$site_packages\fix_dll_paths.pth\" -Value \$pth_content

        # Satisfy the Linux-style paths hardcoded in PySideModules.cmake for --sys-path
        \$linux_style_site = \"\$install_dir\lib\python\site-packages\"
        New-Item -ItemType Directory -Path \$linux_style_site -Force
        New-Item -ItemType Directory -Path \"\$site_packages\shiboken2\" -Force
        New-Item -ItemType Directory -Path \"\$build_dir\pyside2\PySide2\" -Force
        New-Item -ItemType Junction -Path \"\$linux_style_site\shiboken2\" -Value \"\$site_packages\shiboken2\"
        New-Item -ItemType Junction -Path \"\$linux_style_site\PySide2\" -Value \"\$build_dir\pyside2\PySide2\"

        # Set environment variables expected by CMake and the build system
        \$env:BUILD_PREFIX = \$install_dir
        \$env:PY_VER = '' # Makes the path look like BUILD_PREFIX/lib/python/site-packages
        \$env:PYTHONPATH = \"\$site_packages;\$build_dir\pyside2\"

        # 5. Build (Now running on local C:\ drive)
        Write-Host 'Starting PySide2 build...' -ForegroundColor Cyan;
        python setup.py bdist_wheel \`
            --qmake=C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe \`
            --cmake='C:\Program Files\CMake\bin\cmake.exe' \`
            --ignore-git \`
            --shorter-paths \`
            --make-spec=ninja \`
            --build-type=all \`
            --parallel=1 \`
            --no-pyi \`
            --skip-modules=QtAxContainer

        if (\$LASTEXITCODE -ne 0) {
            Write-Host 'Build failed!' -ForegroundColor Red;
            exit \$LASTEXITCODE
        }

        # 6. Copy finished wheels back to the host mount
        Write-Host 'Build finished. Copying wheels to dist folder...' -ForegroundColor Cyan;
        if (Test-Path dist) {
            if (-not (Test-Path C:\app\dist)) { New-Item -ItemType Directory -Path C:\app\dist -Force }
            Copy-Item -Path dist\*.whl -Destination C:\app\dist -Force
        }
    "
fi

echo "------------------------------------------------------------"
echo "Build finished for $PLATFORM."
echo "Wheels should be available in the 'dist/' directory."
