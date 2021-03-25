@echo off
echo.
echo Sets Variables for SetupMarket.sql script
echo.
echo This script will prompt you for the required inputs.
echo.


REM ------------------------------------------------------------------
REM - DATABASE
REM ------------------------------------------------------------------

:promptDB
set /p DB=Enter Database Name (no default): 
if "%DB%"=="" goto promptDB

REM ------------------------------------------------------------------
REM - SCHEMA NAME
REM ------------------------------------------------------------------

:promptSchema
set /p SCHEMA=Enter the application Schema Name (no default): 
if "%SCHEMA%"=="" goto promptSchema

REM ------------------------------------------------------------------
REM - SUPER USER ACCOUNT
REM ------------------------------------------------------------------

:promptSuperUser
set /p SUSER=Enter the name of the SuperUser Account (default=neaadmin): 
if "%SUSER%"=="" set SUSER=neaadmin


goto start

:start
echo --------------------------------------------------------------------------
echo  Run patch for:
echo.    
echo    DB=%DB%
echo    SCHEMA=%SCHEMA%
echo    SUSER=%SUSER%
echo.
echo	Once SQL*PLUS starts, you will be prompted for your password
echo. 
echo --------------------------------------------------------------------------

PAUSE

sqlplus /nolog @SetupMarket.sql %DB% %SCHEMA% %SUSER%

:end
PAUSE
