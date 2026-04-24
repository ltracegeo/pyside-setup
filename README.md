# Qt For Python (PySide2) - Python 3.12 Compatibility Fork

> [!IMPORTANT]
> **Unofficial Fork:** This repository is an unofficial fork of the [original pyside-setup](https://github.com/pyside/pyside-setup). It is maintained independently to provide compatibility fixes that are not present in the upstream version.

## Purpose

The primary goal of this fork is to enable **PySide2 (Qt 5.15.2) support for Python 3.12+**. 

As PySide2 has transitioned to limited maintenance in favor of PySide6, official support for newer Python versions (3.12 and beyond) was not fully implemented for the 5.15 branch. This fork integrates critical patches and custom fixes to ensure a stable runtime:
*   **Community Patches:** Integrated fixes from [Conda-forge](https://github.com/conda-forge/pyside2-feedstock/), [Debian](https://sources.debian.org/patches/pyside2/5.15.14-1/), and [NixOS](https://github.com/NixOS/nixpkgs/pull/327976).
*   **Interpreter Stability:** Fixed shutdown crashes and C-API incompatibilities specific to Python 3.12.
*   **Build Robustness:** Added the `--no-pyi` flag to bypass complex type-hint generation, significantly improving build success rates on CI/CD runners.
*   **CI/CD Optimization:** Optimized GitHub Actions and Docker configurations for reliable, reproducible cross-platform wheel generation.

## Disclaimer

**Use at your own risk.** This fork is maintained for legacy project support. No formal support is provided, and users are strongly encouraged to migrate to [PySide6](https://doc.qt.io/qtforpython-6/) for modern features and official long-term support.

## Building Wheels (Docker)

This repository includes a `build_wheels.sh` script to simplify the creation of stable, platform-native wheels using Docker. This is the recommended way to build PySide2 for Python 3.12.

### Prerequisites
*   **Docker:** Installed and running.
*   **Windows Containers (Windows only):** If building for Windows, your Docker Desktop must be switched to "Windows Containers" mode.

### Usage

1.  **Build for Linux:**
    ```bash
    ./build_wheels.sh linux
    ```

2.  **Build for Windows:**
    Windows builds use the official Qt installer and require credentials passed via environment variables to avoid hardcoding:
    ```bash
    export QT_EMAIL="your_email@example.com"
    export QT_PASSWORD="your_password"
    ./build_wheels.sh windows
    ```

The generated `.whl` files will be available in the `dist/` directory upon successful completion.

## Overview 

Qt For Python is the [Python Qt bindings project](http://wiki.qt.io/PySide2), providing
access to the complete Qt 5.x framework as well as to generator tools for rapidly
generating bindings for any C++ libraries.

shiboken2 is the generator used to build the bindings.

See README.pyside2.md and README.shiboken2.md for details.
