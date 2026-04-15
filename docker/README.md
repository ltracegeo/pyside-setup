# PySide2 Docker Build Environments

This directory contains Dockerfiles for building PySide2 wheels on Linux (slicer/slicer-base [AlmaLinux 8 & Qt5]) and Windows (Windows Server 2019).

## Prerequisites

- **Docker**: Installed and running.
- **Windows**: Docker for Windows must be switched to **Windows Containers** mode to build the Windows image.
- **Git Bash**: Recommended for running the `build_wheels.sh` script on Windows.

## Usage

Use the `build_wheels.sh` script in the project root to build the images and run the build process.

### Build Linux Wheels
```bash
./build_wheels.sh linux
```

### Build Windows Wheels
```bash
./build_wheels.sh windows
```

## Details

### Linux (Dockerfile.linux)
- **Base**: slicer/slicer-base (AlmaLinux 8)
- **Python**: 3.12
- **Qt**: 5.15.2 
- **Clang/LLVM**: Installed via system packages.

### Windows (Dockerfile.windows)
- **Base**: Windows Server 2019 (ltsc2019)
- **Python**: 3.12
- **Compiler**: MSVC 2019 Build Tools
- **Qt**: 5.15.2 (installed via aqtinstall)

## Troubleshooting

- **Large Images**: The Windows image is very large (~20GB+) due to the MSVC Build Tools. Ensure you have enough disk space.
- **Build Time**: The first build will take a long time as it downloads and installs Qt and Build Tools.
- **Volume Mounts**: On Windows, if using Git Bash, the script handles path conversion for the `-v` flag.
