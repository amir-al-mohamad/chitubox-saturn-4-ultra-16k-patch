@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul 2>&1
title ELEGOO Saturn 4 Ultra 16K Profile Patch for CHITUBOX Dental

set "APP_NAME=CHITUBOX Dental"
set "APP_EXE=CHITUBOX Dental.exe"
set "PRINTER_16K=ELEGOO Saturn 4 Ultra 16K"
set "PRINTER_BASE=ELEGOO Saturn 4 Ultra"

set "SCRIPT_DIR=%~dp0"
set "SRC_MACHINE=%SCRIPT_DIR%Data\machinecfg"
set "SRC_RESOURCES=%SCRIPT_DIR%Data\resources"
set "TEMP_DATA=%TEMP%\CHITUBOX_Patch_Elegoo_Saturn_4_Ultra_16K"
set "USER_PROFILES_DIR=%LOCALAPPDATA%\%APP_NAME%\default_account"
set "BACKUP_DIR=%LOCALAPPDATA%\%APP_NAME%\Patch_Backups"

set "WORK_MACHINE=%SRC_MACHINE%"
set "WORK_RESOURCES=%SRC_RESOURCES%"
set "INSTALL_DIR="
set "MODE="

call :CheckAdmin || exit /b 1
call :PrintBanner
call :SelectMode || goto :Abort

if not "!MODE!"=="restore" (
    call :ValidateSourceFiles || goto :Abort
)

call :FindInstallDir
if not defined INSTALL_DIR (
    call :LogError "CHITUBOX Dental installation not found!"
    goto :Abort
)

if /i "!MODE!"=="restore" (
    call :PerformRestore || goto :Abort
    call :Cleanup
    call :PrintSuccess
    pause
    exit /b 0
)

call :CreateBackup || goto :Abort

if /i "!MODE!"=="replace" (
    call :PrepareReplaceFiles || goto :Abort
)

call :DeployToAppFolder || goto :Abort
call :DeployToUserProfiles

call :Cleanup
call :PrintSuccess
pause
exit /b 0

:Abort
call :Cleanup
call :PrintFailure
pause
exit /b 1

:CheckAdmin
net session >nul 2>&1
if errorlevel 1 (
    echo.
    echo   [X] Access Denied!
    echo   [!] This patch must be run as an Administrator to modify program files.
    echo.
    echo   Right-click "Install.bat" and select "Run as administrator".
    echo.
    pause
    exit /b 1
)
exit /b 0

:SelectMode
echo.
echo   ┌───────────────────────────────────────────────────────────┐
echo   │ Select action:                                            │
echo   │                                                           │
echo   │ [1] ADD     - Install 16K as a new printer                │
echo   │ [2] REPLACE - Overwrite existing Saturn 4 Ultra with 16K  │
echo   │ [3] RESTORE - Remove patch and restore original files     │
echo   └───────────────────────────────────────────────────────────┘
echo.
choice /c 123 /n /m "  Your choice [1/2/3]: "
if errorlevel 3 set "MODE=restore"
if errorlevel 2 if not defined MODE set "MODE=replace"
if errorlevel 1 if not defined MODE set "MODE=add"

if not defined MODE (
    call :LogError "Operation cancelled by user."
    exit /b 1
)

echo.
if "!MODE!"=="add" call :LogSuccess "Mode selected: ADD (New Printer)"
if "!MODE!"=="replace" call :LogSuccess "Mode selected: REPLACE (Overwrite Original)"
if "!MODE!"=="restore" call :LogSuccess "Mode selected: RESTORE (Remove Patch)"
exit /b 0

:ValidateSourceFiles
call :LogInfo "Validating source directories..."
if not exist "%SRC_MACHINE%\" (
    call :LogError "Missing directory: Data\machinecfg"
    exit /b 1
)
if not exist "%SRC_RESOURCES%\" (
    call :LogError "Missing directory: Data\resources"
    exit /b 1
)
call :LogSuccess "Source directories validated."
exit /b 0

:FindInstallDir
echo.
call :LogInfo "Searching for %APP_NAME% in Windows Registry..."
set "REG_KEY_1=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
set "REG_KEY_2=HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
set "REG_KEY_3=HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

for %%K in ("%REG_KEY_1%" "%REG_KEY_2%" "%REG_KEY_3%") do (
    for /f "tokens=2*" %%A in ('reg query %%K /s /v InstallLocation 2^>nul ^| findstr /i "%APP_NAME%"') do (
        if exist "%%B\%APP_EXE%" (
            set "INSTALL_DIR=%%B"
            goto :InstallDirFound
        )
    )
)
exit /b 0

:InstallDirFound
if "!INSTALL_DIR:~-1!"=="\" set "INSTALL_DIR=!INSTALL_DIR:~0,-1!"
call :LogSuccess "Found installation at: !INSTALL_DIR!"
exit /b 0

:CreateBackup
echo.
call :LogInfo "Checking original files backup..."
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1

if not exist "%BACKUP_DIR%\list.cfgx" (
    copy /y "!INSTALL_DIR!\machinecfg\list.cfgx" "%BACKUP_DIR%\list.cfgx" >nul 2>&1
    copy /y "!INSTALL_DIR!\machinecfg\Elegoo\%PRINTER_BASE%.cfgd" "%BACKUP_DIR%\%PRINTER_BASE%.cfgd" >nul 2>&1
    copy /y "!INSTALL_DIR!\machinecfg\Elegoo\%PRINTER_BASE%.png" "%BACKUP_DIR%\%PRINTER_BASE%.png" >nul 2>&1
    copy /y "!INSTALL_DIR!\resources\model\MachineModel\%PRINTER_BASE%.stl" "%BACKUP_DIR%\%PRINTER_BASE%.stl" >nul 2>&1
    call :LogSuccess "Original files backed up securely."
) else (
    call :LogInfo "Backup already exists. Skipping backup step."
)
exit /b 0

:PerformRestore
echo.
call :LogInfo "Restoring original application state..."

if not exist "%BACKUP_DIR%\list.cfgx" (
    call :LogError "No backup found! Cannot restore original files."
    call :LogWarning "If the program behaves incorrectly, reinstall CHITUBOX Dental."
    exit /b 1
)

del /q /f "!INSTALL_DIR!\machinecfg\Elegoo\%PRINTER_16K%.*" >nul 2>&1
del /q /f "!INSTALL_DIR!\resources\model\MachineModel\%PRINTER_16K%.stl" >nul 2>&1

copy /y "%BACKUP_DIR%\list.cfgx" "!INSTALL_DIR!\machinecfg\list.cfgx" >nul 2>&1
copy /y "%BACKUP_DIR%\%PRINTER_BASE%.cfgd" "!INSTALL_DIR!\machinecfg\Elegoo\%PRINTER_BASE%.cfgd" >nul 2>&1
copy /y "%BACKUP_DIR%\%PRINTER_BASE%.png" "!INSTALL_DIR!\machinecfg\Elegoo\%PRINTER_BASE%.png" >nul 2>&1
copy /y "%BACKUP_DIR%\%PRINTER_BASE%.stl" "!INSTALL_DIR!\resources\model\MachineModel\%PRINTER_BASE%.stl" >nul 2>&1
call :LogSuccess "Application folder restored."

if exist "%USER_PROFILES_DIR%\" (
    for /d %%D in ("%USER_PROFILES_DIR%\*") do (
        set "PROFILE_NAME=%%~nxD"
        if /i not "!PROFILE_NAME!"=="mask_image" (
            del /q /f "%%D\machinecfg\Elegoo\%PRINTER_16K%.*" >nul 2>&1
            copy /y "%BACKUP_DIR%\list.cfgx" "%%D\machinecfg\list.cfgx" >nul 2>&1
            copy /y "%BACKUP_DIR%\%PRINTER_BASE%.cfgd" "%%D\machinecfg\Elegoo\%PRINTER_BASE%.cfgd" >nul 2>&1
            copy /y "%BACKUP_DIR%\%PRINTER_BASE%.png" "%%D\machinecfg\Elegoo\%PRINTER_BASE%.png" >nul 2>&1
        )
    )
    call :LogSuccess "User profiles restored."
)
exit /b 0

:PrepareReplaceFiles
echo.
call :LogInfo "Preparing 'Replace' mode data (stripping '16K' identifiers)..."

if exist "%TEMP_DATA%" rd /s /q "%TEMP_DATA%" >nul 2>&1
mkdir "%TEMP_DATA%" >nul 2>&1

xcopy "%SRC_MACHINE%" "%TEMP_DATA%\machinecfg\" /E /I /Y /Q >nul
xcopy "%SRC_RESOURCES%" "%TEMP_DATA%\resources\" /E /I /Y /Q >nul

if exist "%TEMP_DATA%\machinecfg\list.cfgx" del /q /f "%TEMP_DATA%\machinecfg\list.cfgx" >nul 2>&1

set "T_MACH=%TEMP_DATA%\machinecfg\Elegoo"
set "T_MODL=%TEMP_DATA%\resources\model\MachineModel"

if exist "%T_MACH%\%PRINTER_16K%.cfgd" move /y "%T_MACH%\%PRINTER_16K%.cfgd" "%T_MACH%\%PRINTER_BASE%.cfgd" >nul
if exist "%T_MACH%\%PRINTER_16K%.png" move /y "%T_MACH%\%PRINTER_16K%.png" "%T_MACH%\%PRINTER_BASE%.png" >nul
if exist "%T_MODL%\%PRINTER_16K%.stl" move /y "%T_MODL%\%PRINTER_16K%.stl" "%T_MODL%\%PRINTER_BASE%.stl" >nul

set "PS_SCRIPT=$f='%T_MACH%\%PRINTER_BASE%.cfgd'; (Get-Content $f -Raw) -replace '%PRINTER_16K%','%PRINTER_BASE%' | Set-Content $f -NoNewline"
powershell -NoProfile -Command "!PS_SCRIPT!" >nul 2>&1

call :LogSuccess "Temporary files prepared."

set "WORK_MACHINE=%TEMP_DATA%\machinecfg"
set "WORK_RESOURCES=%TEMP_DATA%\resources"
exit /b 0

:DeployToAppFolder
echo.
call :LogInfo "Deploying files to application directory..."

xcopy "%WORK_MACHINE%" "!INSTALL_DIR!\machinecfg\" /E /I /Y /Q >nul
if errorlevel 1 (
    call :LogError "Failed to copy machinecfg."
    exit /b 1
)
call :LogSuccess "machinecfg  -> Application Folder"

xcopy "%WORK_RESOURCES%" "!INSTALL_DIR!\resources\" /E /I /Y /Q >nul
if errorlevel 1 (
    call :LogError "Failed to copy resources."
    exit /b 1
)
call :LogSuccess "resources   -> Application Folder"
exit /b 0

:DeployToUserProfiles
echo.
call :LogInfo "Deploying machine configuration to user profiles..."

if not exist "%USER_PROFILES_DIR%\" (
    call :LogWarning "No user profiles found. Skipping profile injection."
    exit /b 0
)

set "INJECT_COUNT=0"
for /d %%D in ("%USER_PROFILES_DIR%\*") do (
    set "PROFILE_NAME=%%~nxD"
    if /i not "!PROFILE_NAME!"=="mask_image" (
        xcopy "%WORK_MACHINE%" "%%D\machinecfg\" /E /I /Y /Q >nul
        call :LogSuccess "Profile updated: !PROFILE_NAME!"
        set /a INJECT_COUNT+=1
    )
)

if !INJECT_COUNT!==0 (
    call :LogWarning "No valid profiles matched for injection."
)
exit /b 0

:Cleanup
if exist "%TEMP_DATA%" rd /s /q "%TEMP_DATA%" >nul 2>&1
exit /b 0

:PrintBanner
echo.
echo   ╔═════════════════════════════════════════════════════════════╗
echo   ║ ELEGOO Saturn 4 Ultra 16K Profile Patch for CHITUBOX Dental ║
echo   ╚═════════════════════════════════════════════════════════════╝
echo.
exit /b 0

:PrintSuccess
echo.
echo   ╔═════════════════════════════════════════════════════════════╗
echo   ║                      Operation Complete!                    ║
echo   ╚═════════════════════════════════════════════════════════════╝
echo.
exit /b 0

:PrintFailure
echo.
echo   ╔═════════════════════════════════════════════════════════════╗
echo   ║                 Installation aborted/failed.                ║
echo   ╚═════════════════════════════════════════════════════════════╝
echo.
exit /b 0

:LogInfo
echo   [*] %~1
exit /b 0

:LogSuccess
echo   [+] %~1
exit /b 0

:LogWarning
echo   [!] %~1
exit /b 0

:LogError
echo   [-] ERROR: %~1
exit /b 0
