@ECHO OFF

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: cb-install.bat
::
:: Copyright by toolarium, all rights reserved.
:: MIT License: https://mit-license.org
::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:: define defaults
if .%CB_DEVTOOLS_NAME%==. set "CB_DEVTOOLS_NAME=devtools"
if .%CB_DEVTOOLS_DRIVE%==.  set "CB_DEVTOOLS_DRIVE=c:"
if .%CB_DEVTOOLS%==. set "CB_DEVTOOLS=%CB_DEVTOOLS_DRIVE%\%CB_DEVTOOLS_NAME%"
if .%CB_WGET_VERSION%==. set "CB_WGET_VERSION=1.20.3"
if .%CB_WGET_DOWNLOAD_URL%==. set "CB_WGET_DOWNLOAD_URL=https://eternallybored.org/misc/wget/"

:: define parameters
set CB_LINE=----------------------------------------------------------------------------------------
set PN=%~nx0
set "CB_CURRENT_PATH=%CD%"
set "CB_USER_DRIVE=%CD:~0,2%"
set "CB_SCRIPT_PATH=%~dp0"
set "CB_SCRIPT_DRIVE=%~d0"
set CB_FORCE_INSALL=false
set "CB_INSTALLER_VERSION=1.0.0"
set "CB_RELEASE_URL=https://api.github.com/repos/toolarium/common-build/releases"

SET CB_PROCESSOR_ARCHITECTURE_NUMBER=64
if not "%PROCESSOR_ARCHITECTURE%"=="%PROCESSOR_ARCHITECTURE:32=%" SET CB_PROCESSOR_ARCHITECTURE_NUMBER=32
if not "%PROCESSOR_ARCHITECTURE%"=="%PROCESSOR_ARCHITECTURE:64=%" SET CB_PROCESSOR_ARCHITECTURE_NUMBER=64

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%" & set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "DATESTAMP=%YYYY%%MM%%DD%" & set "TIMESTAMP=%HH%%Min%%Sec%" & set "FULLTIMESTAMP=%DATESTAMP%-%TIMESTAMP%"
set "USER_FRIENDLY_DATESTAMP=%DD%.%MM%.%YYYY%" & set "USER_FRIENDLY_TIMESTAMP=%HH%:%Min%:%Sec%" 
set "USER_FRIENDLY_FULLTIMESTAMP=%USER_FRIENDLY_DATESTAMP% %USER_FRIENDLY_TIMESTAMP%"


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:CHECK_PARAMETER
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
if %0X==X goto COMMON_BUILD_INSTALL
if .%1==.-h goto HELP
if .%1==.--help goto HELP
if .%1==.-v goto VERSION
if .%1==.--version goto VERSION
if .%1==.--force (set CB_FORCE_INSALL=true)
shift
goto CHECK_PARAMETER


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:VERSION
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo %CB_LINE%
echo toolarium common build installer %CB_INSTALLER_VERSION%
echo %CB_LINE%
echo.
goto END


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:COMMON_BUILD_INSTALL
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo %CB_LINE%
echo Started toolarium-common-build installation on %COMPUTERNAME%, %USER_FRIENDLY_FULLTIMESTAMP%
echo -Use %CB_DEVTOOLS% path as devtools folder
echo %CB_LINE%
pause
echo.

:: check connection
ping 8.8.8.8 -n 1 -w 1000 >nul 2>nul
if errorlevel 1 (set "ERROR_INFO=No internet connection detected!" & goto INSTALL_FAILED)

:: get the list of release from GitHub
set CB_REMOTE_VERSION= & set CB_DOWNLOAD_VERSION_URL= & set ERROR_DETAIL_INFO= & set ERROR_INFO=
set cbInfoTemp=%TEMP%\toolarium-common-build_info.txt & set cbErrorTemp=%TEMP%\toolarium-common-build_error.txt
echo -Check newest version of toolarium-common-build...
powershell -Command "$releases = Invoke-RestMethod -Headers $githubHeader -Uri "%CB_RELEASE_URL%" | Select-Object -First 1; Split-Path -Path $releases.zipball_url -Leaf" 2>%cbErrorTemp% > %cbInfoTemp%
if exist %cbInfoTemp% (set /pCB_REMOTE_VERSION=<%cbInfoTemp%)
if .%CB_REMOTE_VERSION%==. set "ERROR_INFO=Could not get remote release information!" & goto INSTALL_FAILED
set CB_REMOTE_VERSION=%CB_REMOTE_VERSION:~1%
echo -Latest version of common-build is %CB_REMOTE_VERSION%, select download link
del %cbInfoTemp% 2>nul & del %cbErrorTemp% 2>nul
powershell -Command "$releases = Invoke-RestMethod -Headers $githubHeader -Uri "%CB_RELEASE_URL%" | Select-Object -First 1; Write-Output $releases.zipball_url" 2>%cbErrorTemp% > %cbInfoTemp%
if exist %cbInfoTemp% (set /pCB_DOWNLOAD_VERSION_URL=<%cbInfoTemp%)
if .%CB_DOWNLOAD_VERSION_URL%==. set "ERROR_INFO=Could not get download url of verison %CB_REMOTE_VERSION%!" & goto INSTALL_FAILED
del %cbInfoTemp% 2>nul & del %cbErrorTemp% 2>nul
set "CB_VERSION_NAME=toolarium-common-build-%CB_REMOTE_VERSION%"

:: create directories
if not exist %CB_DEVTOOLS% mkdir %CB_DEVTOOLS% >nul 2>nul & echo -Create directory %CB_DEVTOOLS%
set "CB_DEV_REPOSITORY=%CB_DEVTOOLS%\.repository" 
if not exist %CB_DEV_REPOSITORY% mkdir %CB_DEV_REPOSITORY% >nul 2>nul

:: download toolarium-common-build
if .%CB_FORCE_INSALL%==.true (del %CB_DEV_REPOSITORY%\%CB_VERSION_NAME%.zip 2>nul)
if exist %CB_DEV_REPOSITORY%\%CB_VERSION_NAME%.zip (echo -Found already downloaded version, %CB_DEV_REPOSITORY%\%CB_VERSION_NAME%.zip & goto DOWNLOAD_CB_END)
echo -Install %CB_VERSION_NAME%
powershell -Command "iwr $start_time = Get-Date;Invoke-WebRequest -Uri '%CB_DOWNLOAD_VERSION_URL%' -OutFile '%CB_DEV_REPOSITORY%\%CB_VERSION_NAME%.zip';Write-Output 'Time taken: $((Get-Date).Subtract($start_time).Seconds) seconds' 2>nul | iex 2>nul" 2>nul
:: in case we donwload a new version we also extract new!
rmdir %CB_DEVTOOLS%\%CB_VERSION_NAME% /s /q >nul 2>nul
:DOWNLOAD_CB_END

if exist %CB_DEVTOOLS%\%CB_VERSION_NAME% goto EXTRACT_CB_END
echo -Extract %CB_VERSION_NAME%.zip in %CB_DEVTOOLS%... 
if /I [%CB_DEVTOOLS_DRIVE%] NEQ [%CB_USER_DRIVE%] (%CB_DEVTOOLS_DRIVE%)
powershell -command "Expand-Archive -Force %CB_DEV_REPOSITORY%\%CB_VERSION_NAME%.zip %CB_DEV_REPOSITORY%"
move %CB_DEV_REPOSITORY%\toolarium-common-build-???????? %CB_DEVTOOLS%\%CB_VERSION_NAME% >nul
if /I [%CB_DEVTOOLS_DRIVE%] NEQ [%CB_USER_DRIVE%] (%CB_USER_DRIVE%)

:: remove unecessary files
del %CB_DEVTOOLS%\%CB_VERSION_NAME%\.gitattributes 2>nul
del %CB_DEVTOOLS%\%CB_VERSION_NAME%\.gitignore 2>nul
del %CB_DEVTOOLS%\%CB_VERSION_NAME%\README.md 2>nul

:: keep backward compatibility
if not exist %CB_DEVTOOLS%\%CB_VERSION_NAME%\src goto EXTRACT_CB_END
mkdir %CB_DEVTOOLS%\%CB_VERSION_NAME%\bin
copy %CB_DEVTOOLS%\%CB_VERSION_NAME%\src\main\cli\*.bat %CB_DEVTOOLS%\%CB_VERSION_NAME%\bin >nul 2>nul
rmdir %CB_DEVTOOLS%\%CB_VERSION_NAME%\src /s /q >nul 2>nul
:EXTRACT_CB_END

if [%CB_HOME%] equ [%CB_DEVTOOLS%\%CB_VERSION_NAME%] goto SET_CBHOME_END
echo -Set CB_HOME to %CB_DEVTOOLS%\%CB_VERSION_NAME%
set "CB_HOME=%CB_DEVTOOLS%\%CB_VERSION_NAME%" 
setx CB_HOME "%CB_DEVTOOLS%\%CB_VERSION_NAME%" >nul 2>nul

:: add to path
set "SystemPath=" & set "UserPath="
for /F "skip=2 tokens=1,2*" %%N in ('%SystemRoot%\System32\reg.exe query "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v "Path" 2^>nul') do (if /I "%%N" == "Path" (set "SystemPath=%%P" & goto GET_USER_PATH_FROM_REGISTRY))
:GET_USER_PATH_FROM_REGISTRY
for /F "skip=2 tokens=1,2*" %%N in ('%SystemRoot%\System32\reg.exe query "HKCU\Environment" /v "Path" 2^>nul') do (if /I "%%N" == "Path" (set "UserPath=%%P" & goto GET_USER_PATH_FROM_REGISTRY_END))
:GET_USER_PATH_FROM_REGISTRY_END
if /I [%CB_DEVTOOLS_DRIVE%] NEQ [%CB_USER_DRIVE%] (%CB_DEVTOOLS_DRIVE%)
cd %CB_HOME%
WHERE cb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (echo -Set %%CB_HOME%% to path. & setx PATH "%CB_HOME%\bin;%UserPath%" >nul 2>nul)
set "PATH=%CB_HOME%\bin;%PATH%"
if /I [%CB_DEVTOOLS_DRIVE%] NEQ [%CB_USER_DRIVE%] (%CB_USER_DRIVE%)
cd %CB_CURRENT_PATH%
:SET_CBHOME_END

set "CB_BIN=%CB_HOME%\bin" 
if not exist %CB_BIN% (mkdir %CB_BIN% >nul 2>nul)
set "CB_LOGS=%CB_HOME%\logs" 
if not exist %CB_LOGS% (mkdir %CB_LOGS% >nul 2>nul)

:: download wget -> https://eternallybored.org/misc/wget/1.20.3/64/wget.exe
set CB_WGET_CMD=wget.exe
if exist %CB_BIN%\%CB_WGET_CMD% goto DOWNLOAD_WGET_END
set "CB_WGET_PACKAGE_URL=%CB_WGET_DOWNLOAD_URL%/%CB_WGET_VERSION%/%CB_PROCESSOR_ARCHITECTURE_NUMBER%/%CB_WGET_CMD%"
echo -Install %CB_BIN%\%CB_WGET_CMD%
powershell -Command "iwr $start_time = Get-Date;Invoke-WebRequest -Uri '%CB_WGET_PACKAGE_URL%' -OutFile %CB_BIN%\%CB_WGET_CMD%;Write-Output 'Time taken: $((Get-Date).Subtract($start_time).Seconds) seconds' 2>nul | iex 2>nul" 2>nul
:DOWNLOAD_WGET_END
goto INSTALL_SUCCESSFULL_END

:INSTALL_FAILED
echo.
echo %CB_LINE%
echo Failed installation: %ERROR_INFO%
if exist %cbErrorTemp% (echo. & type %cbErrorTemp%)
echo %CB_LINE%
goto END

:INSTALL_SUCCESSFULL_END
echo.
echo %CB_LINE%
echo Successfully installed toolarium-common-build v%CB_REMOTE_VERSION%
echo in folder %CB_HOME%. 
echo.
echo The %%PATH%% is already extended and you can start working with it with the command cb!
echo %CB_LINE%
goto END


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:HELP
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo %PN% - toolarium common build installer v%CB_INSTALLER_VERSION%
echo usage: %PN% [OPTION]
echo.
echo Overview of the available OPTIONs:
echo  -h, --help                Show this help message.
echo  -v, --version             Print version information.
echo  --force                   Force to reinstall the common-build.
echo.
goto END


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:END
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
del %cbInfoTemp% 2>nul
del %cbErrorTemp% 2>nul
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
