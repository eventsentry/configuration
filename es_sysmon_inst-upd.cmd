@ECHO off
:: Script to install or update sysmon. Inside the network source installation folder should be a es_sysmon_version.txt
:: Version number format: XX.XX.XXX Example: 13.00.000. First 4 digits are Sysmon version, the last 3 digits is your internal configuration
:: versioning. Increment this number for force new configuration apply to sysmon installations.

:: If files does not exist, script wont update Sysmon
setlocal enableextensions enabledelayedexpansion

:: Set file server IP
set _server=192.168.1.15
:: Set folder location [Remember to add "\" at the end]
set _shared=\tools\sysmon\
:: Set custom configuration file, leave it blank for no custom config. This script will grab the config from the same shared folder of the Sysmon installer
set _customcfg=sysmon.conf
:: Set Temp folder to use
set _tempy=%systemroot%\system32\eventsentry\temp

:: Uncomment next line and specify IP, Share, Username and Password if you want to specify user access
net use \\%_Server%%share% /d
net use \\%_Server%%share% "1Xp5zx45fZ224BxRjeZJdWIV" /user:demodomain\sysmonuser

:: Check if Sysmon service is installed
sc.exe qc Sysmon 2> nul >nul

IF %ERRORLEVEL% == 0 (
    ECHO 32bit Service Installed
    set _os_bitness=32
    GOTO update
) ELSE (
    GOTO Next64
)

:Next64
sc.exe qc Sysmon64 2> nul >nul

IF %ERRORLEVEL% == 0 (
    ECHO 64bit Service Installed
    set _os_bitness=64
    GOTO update
) ELSE (
    GOTO Install
)

:: INSTALLATION
:Install
ECHO No version detected, so installing a fresh one

:: Check OS Architecture for install
Set _os_bitness=64
IF %PROCESSOR_ARCHITECTURE% == x86 (
  ECHO 32 bit platform detected, sysmon not installed, aborting...
  EXIT /b 1
  )

:: Check Install file exist
IF EXIST \\%_server%%_shared%sysmon64.exe GOTO Install2
ECHO Sysmon64.exe [at \\%_server%%_shared%] not found in shared folder or can't access (user/credentials not valid)
EXIT /b 1

:Install2
:: Check if config file is provided
IF "%_customcfg%" == "" GOTO NoConfig
:: Check if config file exist
IF EXIST \\%_server%%_shared%%_customcfg% GOTO WithConfig
ECHO Custom Config File %_customcfg% [at \\%_server%%_shared%] not found in shared folder or can't access [user/credentials not valid]
EXIT /b 1

:NoConfig
copy \\%_server%%_shared%Sysmon64.exe %_tempy% 2>nul >nul
%_tempy%\Sysmon64.exe -i -accepteula
DEL %_tempy%\Sysmon64.exe 2>NUL
EXIT /b %errorlevel%

:WithConfig
copy \\%_server%%_shared%%_customcfg% %_tempy% 2>nul >nul
copy \\%_server%%_shared%Sysmon64.exe %_tempy% 2>nul >nul
%_tempy%\Sysmon64.exe -i %_tempy%\%_customcfg% -accepteula
DEL %_tempy%\Sysmon64.exe 2>NUL
DEL %_tempy%\%_customcfg% 2>NUL        
EXIT /b %errorlevel%

::UPDATE
:update
IF EXIST \\%_server%%_shared%es_sysmon_version.txt GOTO UPDCont
Echo No es_sysmon_version.txt found at \\%_server%%_shared%. Not Updating. Exiting
EXIT /B 0
:UPDCont
copy \\%_server%%_shared%es_sysmon_version.txt %_tempy% 2>nul >nul
for /f "tokens=1" %%a in ('type %_tempy%\es_sysmon_version.txt') do set _SysVerInsTMP=%%a
set _SysVerIns=%_SysVerInsTMP:~0,5%
set _CFGVer=%_SysVerInsTMP:~6,9%
IF %_os_bitness% == 64 GOTO 64VersionCheck
IF NOT EXIST %SystemRoot%\Sysmon.exe (
             ECHO Sysmon service not installed on standard folder [%SystemRoot%\Sysmon.exe]. Update Cancelled
             EXIT /B 1
)
for /f "tokens=3" %%a in ('%SystemRoot%\Sysmon.exe ^|findstr "System Monitor"') do set _SysVerTMP=%%a
set _SysVerLocal=%_SysVerTMP:~1,5%
GOTO UPDCont1

:64VersionCheck
IF NOT EXIST %SystemRoot%\Sysmon64.exe (
             ECHO Sysmon64 service not installed on standard folder [%SystemRoot%\Sysmon64.exe]. Update Cancelled
             EXIT /B 1
)
for /f "tokens=3" %%a in ('%SystemRoot%\Sysmon64.exe ^|findstr "System Monitor"') do set _SysVerTMP=%%a
set _SysVerLocal=%_SysVerTMP:~1,5%

GOTO UPDCont1

:UPDCont1
:: Query Version
if %_SysVerIns% gtr %_SysVerLocal% (
    echo Sysmon Local version outdated. Updating...
    GOTO UPDCont2
) else (
    echo Sysmon Local version already at latest build [V%_SysVerIns%]
    goto CFGVer
)
:UPDCont2
IF "%_customcfg%" == "" GOTO UPDNoConfig
:: Check if config file exist
IF EXIST \\%_server%%_shared%%_customcfg% GOTO UPDWithConfig
ECHO ERR Updating: Custom Config File %_customcfg% [at \\%_server%%_shared%] not found in shared folder or can't access [user/credentials not valid]
EXIT /b 1

:UPDNoConfig
IF %_os_bitness% == 64 (
    ECHO No config file provided. Updating without config file...
    copy \\%_server%%_shared%Sysmon64.exe %_tempy% 2>nul >nul
    %_tempy%\Sysmon64.exe -u force 2>nul >nul
    %_tempy%\Sysmon64.exe -i -accepteula
    DEL %_tempy%\Sysmon64.exe 2>NUL
    EXIT /b %errorlevel%
) ELSE (
    ECHO No config file provided. Updating without config file...
    copy \\%_server%%_shared%Sysmon.exe %_tempy% 2>nul >nul
    %_tempy%\Sysmon.exe -u force 2>nul >nul
    %_tempy%\Sysmon.exe -i -accepteula
    DEL %_tempy%\Sysmon.exe 2>NUL
    EXIT /b %errorlevel%
)
GOTO EOF
:UPDWithConfig
copy \\%_server%%_shared%%_customcfg% %_tempy% 2>nul >nul
IF %_os_bitness% == 64 (
    ECHO Config file found. Updating with config file...
    copy \\%_server%%_shared%Sysmon64.exe %_tempy% 2>nul >nul
    %_tempy%\Sysmon64.exe -u force 2>nul >nul
    %_tempy%\Sysmon64.exe -i %_tempy%\%_customcfg% -accepteula
    DEL %_tempy%\Sysmon64.exe 2>NUL
    DEL %_tempy%\%_customcfg% 2>NUL        
    EXIT /b %errorlevel%
) ELSE (
    ECHO Config file found. Updating with config file...
    copy \\%_server%%_shared%Sysmon.exe %_tempy% 2>nul >nul
    %_tempy%\Sysmon.exe -u force 2>nul >nul
    %_tempy%\Sysmon.exe -i %_tempy%\%_customcfg% -accepteula
    DEL %_tempy%\Sysmon.exe 2>NUL
    DEL %_tempy%\%_customcfg% 2>NUL            
    EXIT /b %errorlevel%
)
:CFGVer
IF EXIST %_tempy%\es_sysmon_cfg_ver.txt GOTO CFGVerCHK
:: No previous config version tracking found, creating one
ECHO %_CFGVer% >%_tempy%\es_sysmon_cfg_ver.txt
GOTO CFGUpd
:CFGVerCHK
for /f "tokens=1" %%a in ('type %_tempy%\es_sysmon_cfg_ver.txt') do set _SysCFGVer=%%a
if %_CFGVer% GTR %_SysCFGVer% GOTO CFGUpd
ECHO Local Config version Up-To-Date [V%_SysCFGVer%]
EXIT /B 0
:CFGUpd
ECHO Updating SySMon Configuration...
IF EXIST \\%_server%%_shared%%_customcfg% GOTO CFGUpdCont1
ECHO ERR - Config file not found or cant access [\\%_server%%_shared%%_customcfg%]
EXIT /b 1
:CFGUpdCont1
COPY \\%_server%%_shared%%_customcfg% %_tempy% 2>nul >nul
ECHO %_CFGVer% >%_tempy%\es_sysmon_cfg_ver.txt
IF %_os_bitness% == 64 (
     "%SystemRoot%\Sysmon64.exe" -c "%_tempy%\%_customcfg%"
     EXIT /b %errorlevel% 
) ELSE (
     "%SystemRoot%\Sysmon.exe" -c "%_tempy%\%_customcfg%"
     EXIT /b %errorlevel%
)
:EOF
:: Dismounting
net use \\%_Server%%share% /d