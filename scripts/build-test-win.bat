@echo off
setlocal

REM run:
REM scripts/build-test-win.bat [cleanall]

REM commands
set CAT=c:\gnuwin32\bin\cat
set DATE=c:\gnuwin32\bin\date
set ECHO=c:\gnuwin32\bin\echo
set LS=c:\gnuwin32\bin\ls
set MAKE=c:\gnuwin32\bin\make
set RM=c:\gnuwin32\bin\rm
set UNAME=c:\gnuwin32\bin\uname
set SCP=c:\msys\bin\scp
set GCC=c:\mingw64\bin\gcc
set GCXX=c:\mingw64\bin\g++
set GFC=c:\mingw64\bin\gfortran

REM settings
set SSHRSA="c:/users/mad/.ssh/id_rsa"
set MACDIR="mad@macserv15865.cern.ch:Projects/madX"

if "%1"=="dont-redirect" shift & goto next
%rm% -f build-test-win.out
call scripts\build-test-win.bat dont-redirect %* > build-test-win.out 2>&1
%scp% -q -i %sshrsa% build-test-win.out *-win32.exe *-win64.exe %macdir%
exit /B 

:next

%echo% -e "\n===== Start of build and tests ====="
%date%
%uname% -m -n -r -s

%echo% -e "\n===== SVN update ====="
"c:\Program Files\TortoiseSVN\bin\svn" update
if ERRORLEVEL 1 %echo% "ERROR: svn update failed"

%echo% -e "\n===== Release number ====="
%cat% VERSION

%echo% -e "\n===== Clean build ====="
if "%1"=="cleanall" (
REM cleanall not supported on windows (relies on find)
  %make% cleanbuild
) else (
  %echo% "Skipped (no explicit request)."
)

%echo% -e "\n===== Gnu build ====="
%gcc%  --version
%gcxx% --version 
%gfc%  --version
%make% all-win64-gnu
if ERRORLEVEL 1 %echo% "ERROR: make all-win64-gnu failed"

%echo% -e "\n===== Intel build ====="
call "C:\Program Files (x86)\Intel\Composer XE 2013 SP1\bin\ipsxe-comp-vars.bat" ia32 vs2012
%make% all-win32-intel all-win32
if ERRORLEVEL 1 %echo% "ERROR: make all-win32-intel failed"

call "C:\Program Files (x86)\Intel\Composer XE 2013 SP1\bin\ipsxe-comp-vars.bat" intel64 vs2012
%make% all-win64-intel all-win64
if ERRORLEVEL 1 %echo% "ERROR: make all-win64-intel failed"

%echo% -e "\n===== Binaries dependencies ====="
%make% infobindep
if ERRORLEVEL 1 %echo% "ERROR: make infobindep failed"

%echo% -e "\n===== Tests pointless files ====="
%make% cleantest && %make% infotestdep
if ERRORLEVEL 1 %echo% "ERROR: make infotestdep failed"

%echo% -e "\n===== Testing madx-win64-intel ====="
%make% madx-win64-intel && %ls% -l madx-win64-intel.exe madx64.exe && %make% cleantest && %make% tests-all ARCH=64 NOCOLOR=yes
if ERRORLEVEL 1 %echo% "ERROR: make tests-all for madx-win64-intel failed"

%echo% -e "\n===== Testing madx-win32-intel ====="
%make% madx-win32-intel && %ls% -l madx-win32-intel.exe madx32.exe && %make% cleantest && %make% tests-all ARCH=32 NOCOLOR=yes
if ERRORLEVEL 1 %echo% "ERROR: make tests-all for madx-win32-intel failed"

%echo% -e "\n===== Testing madx-win64-gnu ====="
set GFORTRAN_UNBUFFERED_PRECONNECTED=y
%make% madx-win64-gnu && %ls% -l madx-win64-gnu.exe madx64.exe && %make% cleantest && %make% tests-all ARCH=64 NOCOLOR=yes
if ERRORLEVEL 1 %echo% "ERROR: make tests-all for madx-win64-intel failed"

REM restore the default version
%make% madx-win32 > tmp.out && %make% madx-win64 > tmp.out && %rm% -f tmp.out
if ERRORLEVEL 1 %echo% "ERROR: error restoring the default version"

REM date & end marker
%date%
%echo% -e "\n===== End of build and tests ====="
