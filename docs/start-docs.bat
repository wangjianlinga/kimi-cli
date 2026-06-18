@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM Start Kimi CLI VitePress documentation site
REM Usage: double-click this file or run "start-docs.bat" in Command Prompt/PowerShell

cd /d "%~dp0"

echo ========================================
echo  Kimi CLI Docs - Startup Script
echo ========================================
echo.

REM Try bun first
where bun >nul 2>nul
if %errorlevel% == 0 (
    set "PKG_MGR=bun"
    set "INSTALL_CMD=bun install"
    set "DEV_CMD=bun run dev"
    echo Found package manager: bun
    goto :check_deps
)

REM Try npm directly
where npm >nul 2>nul
if %errorlevel% == 0 (
    set "PKG_MGR=npm"
    set "INSTALL_CMD=npm install"
    set "DEV_CMD=npm run dev"
    echo Found package manager: npm
    goto :check_deps
)

REM npm not in PATH, but maybe node is and npm is next to node.exe
where node >nul 2>nul
if %errorlevel% == 0 (
    for /f "delims=" %%i in ('where node') do (
        set "NODE_DIR=%%~dpi"
        if exist "!NODE_DIR!npm.cmd" (
            set "PKG_MGR=npm"
            set "INSTALL_CMD=!NODE_DIR!npm.cmd install"
            set "DEV_CMD=!NODE_DIR!npm.cmd run dev"
            echo Found package manager: npm (next to node.exe)
            goto :check_deps
        )
    )
)

echo ERROR: Node.js found, but npm/bun is not available in PATH.
echo.
echo Please ensure npm is installed and added to your system PATH.
echo Node.js download: https://nodejs.org/
echo.
pause
exit /b 1

:check_deps
echo.

REM Install dependencies if node_modules is missing
if not exist "node_modules" (
    echo Installing dependencies with %PKG_MGR%...
    call %INSTALL_CMD%
    if %errorlevel% neq 0 (
        echo ERROR: Failed to install dependencies.
        pause
        exit /b 1
    )
    echo Dependencies installed successfully.
    echo.
) else (
    echo Dependencies already installed.
    echo.
)

REM Start VitePress dev server
echo Starting VitePress dev server...
call %DEV_CMD%

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Dev server exited with code %errorlevel%.
    pause
)

endlocal
