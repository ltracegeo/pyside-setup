# build.ps1 — Build PySide2 wheel for Python 3.12 on Windows
# Prerequisites: pyside-setup patched by apply-patches.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"


$PYTHON = 'C:\\Users\\Windows\\.conda\\envs\\python312\\python.exe'
$QMAKE  = "C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe"
$CMAKE  = "C:\Program Files\CMake\bin\cmake.exe"
$LLVM   = "C:\Program Files\LLVM"
$VCVARS = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
$PYSIDE = "C:\ltrace\gs-root\installations\07-gs\pyside-setup"

# $PYTHON = "C:\ltrace\gs-root\installations\07-gs\bin\PythonSlicer.exe"
# $QMAKE  = "C:\Qt\5.15.2\msvc2019_64\bin\qmake.exe"
# $CMAKE  = "C:\Program Files\CMake\bin\cmake.exe"
# $LLVM   = "C:\Program Files\LLVM"
# $VCVARS = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat"
# $PYSIDE = "C:\ltrace\gs-root\installations\07-gs\pyside-setup"

# Step 1: Activate MSVC 2019 x64 environment
Write-Host "Activating MSVC 2019 x64..." -ForegroundColor Cyan
$env_vars = cmd /c "`"$VCVARS`" amd64 && set" | Where-Object { $_ -match "^[A-Za-z_].*=" }
foreach ($line in $env_vars) {
    $name, $value = $line -split "=", 2
    [System.Environment]::SetEnvironmentVariable($name, $value, "Process")
}

# Step 2: LLVM / libclang
$env:CLANG_INSTALL_DIR = $LLVM
$env:PATH = "$LLVM\bin;C:\ltrace;$env:PATH"   # C:\ltrace has ninja.exe

# Step 3: Build
Set-Location $PYSIDE

Write-Host "Starting PySide2 build..." -ForegroundColor Cyan
& $PYTHON setup.py bdist_wheel `
    --qmake="$QMAKE" `
    --cmake="$CMAKE" `
    --make-spec=ninja `
    --build-type=all `
    --parallel=8 `
    --skip-modules=QtAxContainer

Write-Host "`nBuild complete. Wheel is in $PYSIDE\dist\" -ForegroundColor Green
Get-ChildItem "$PYSIDE\dist\*.whl" | Select-Object Name