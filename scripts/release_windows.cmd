@echo off
setlocal enabledelayedexpansion

if "%1" == "" (
  echo Please specify x86 ^(32-bit^), x64 ^(64-bit^) or arm64 architecture in cmdline
  goto :eof
)

set ARCH=%1
set BOTH=0
if /I not "%ARCH%"=="x86" if /I not "%ARCH%"=="x64" if /I not "%ARCH%"=="arm64" set BOTH=1

if %BOTH% == 1 (
  echo Only x86 ^(32-bit^), x64 ^(64-bit^) or arm64 architectures are supported!
  goto :eof
)

if /I "%ARCH%"=="x86" (
  set QT=C:\Qt\5.13.2\msvc2017\
  set VSARCH=x86
  set CMAKE_ARCH=Win32
) else if /I "%ARCH%"=="arm64" (
  set QT=C:\Qt\5.13.2\msvc2017_arm64\
  set VSARCH=x64_arm64
  set CMAKE_ARCH=arm64
) else if /I "%ARCH%"=="x64" (
  set QT=C:\Qt\5.13.2\msvc2017_64\
  set VSARCH=amd64
  set CMAKE_ARCH=x64
)

call "c:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" %VSARCH%

set PATH=%QT%\bin;%PATH%

set ROOT="%~dp0.."
set BUILD="%~dp0..\build\build\release"
set CMAKEGEN="Visual Studio 16 2019"

set /p VERSION=<"%ROOT%\VERSION"

where /q git.exe
if "%ERRORLEVEL%" equ "0" (
  for /f "tokens=*" %%t in ('git.exe rev-parse --short HEAD') do (
    set COMMIT=%%t
  )
  set VERSION_COMMIT=%VERSION%-!COMMIT!
)

if "%ARCH%"=="x86" (
  set TARGET="%~dp0\..\release\rclone-browser-%VERSION_COMMIT%-windows-32-bit"
  set TARGET_EXE="%~dp0\..\release\rclone-browser-%VERSION_COMMIT%-windows-32-bit"
) else if "%ARCH%" == "arm64" (
  set TARGET="%~dp0\..\release\rclone-browser-%VERSION_COMMIT%-windows-arm64"
  set TARGET_EXE="%~dp0\..\release\rclone-browser-%VERSION_COMMIT%-windows-arm64"
) else (
  set TARGET="%~dp0\..\release\rclone-browser-%VERSION_COMMIT%-windows-64-bit"
  set TARGET_EXE="%~dp0\..\release\rclone-browser-%VERSION_COMMIT%-windows-64-bit"
)

pushd "%ROOT%"

if not exist release mkdir release

if exist "%TARGET%" rd /s /q "%TARGET%"
if exist "%TARGET%.zip" del "%TARGET%.zip"
if exist "%TARGET_EXE%.exe" del "%TARGET_EXE%.exe"

if exist build rd /s /q build
mkdir build
cd build

cmake -G %CMAKEGEN% -A %CMAKE_ARCH% -DCMAKE_CONFIGURATION_TYPES="Release" -DCMAKE_PREFIX_PATH=%QT% ..
cmake --build . --config Release
popd

mkdir "%TARGET%" 2>nul

copy "%ROOT%\README.md" "%TARGET%\Readme.md"
copy "%ROOT%\CHANGELOG.md" "%TARGET%\Changelog.md"
copy "%ROOT%\LICENSE" "%TARGET%\License.txt"
copy "%BUILD%\RcloneBrowser.exe" "%TARGET%"

windeployqt.exe --no-translations --no-angle --no-compiler-runtime --no-svg "%TARGET%\RcloneBrowser.exe"
rd /s /q "%TARGET%\imageformats"

copy "%VCToolsRedistDir%\%ARCH%\Microsoft.VC142.CRT\msvcp140.dll" "%TARGET%\"
copy "%VCToolsRedistDir%\%ARCH%\Microsoft.VC142.CRT\vcruntime140*.dll" "%TARGET%\"

if "%ARCH%"=="x86" (
  copy "c:\Program Files (x86)\openssl-1.1.1d-win32\libssl-1_1.dll" "%TARGET%\"
  copy "c:\Program Files (x86)\openssl-1.1.1d-win32\libcrypto-1_1.dll" "%TARGET%\"
)

(
  echo [Paths]
  echo Prefix = .
  echo LibraryExecutables = .
  echo Plugins = .
) > "%TARGET%\qt.conf"

"c:\Program Files\7-Zip\7z.exe" a -mx=9 -r -tzip "%TARGET%.zip" "%TARGET%"

if "%ARCH%"=="x86" (
  "c:\Program Files (x86)\Inno Setup 6"\iscc "/dMyAppVersion=%VERSION%" "/dMyAppId={{5644ED3A-6028-47C0-9796-29548EF7CEA3}" "/dMyAppDir=rclone-browser-%VERSION_COMMIT%-windows-32-bit" "/dMyAppArch=x86" /O"../release" /F"rclone-browser-%VERSION_COMMIT%-windows-32-bit" rclone-browser-win-installer.iss
) else if "%ARCH%" == "arm64" (
  "c:\Program Files (x86)\Inno Setup 6"\iscc "/dMyAppVersion=%VERSION%" "/dMyAppId={{0AF9BF43-8D44-4AFF-AE60-6CECF1BF0D31}" "/dMyAppDir=rclone-browser-%VERSION_COMMIT%-windows-arm64" "/dMyAppArch=arm64" /O"../release" /F"rclone-browser-%VERSION_COMMIT%-windows-arm64" rclone-browser-win-installer.iss
) else (
  "c:\Program Files (x86)\Inno Setup 6"\iscc "/dMyAppVersion=%VERSION%" "/dMyAppId={{0AF9BF43-8D44-4AFF-AE60-6CECF1BF0D31}" "/dMyAppDir=rclone-browser-%VERSION_COMMIT%-windows-64-bit" "/dMyAppArch=x64" /O"../release" /F"rclone-browser-%VERSION_COMMIT%-windows-64-bit" rclone-browser-win-installer.iss
)
