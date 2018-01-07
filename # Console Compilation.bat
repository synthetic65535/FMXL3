@echo off
REM ========== ��������� ==========
set studiopath=C:\Embarcadero\Studio\17.0\
REM ===============================

set project=%~dp0
set dcc32=%studiopath%\bin\dcc32.exe
set dcc64=%studiopath%\bin\dcc64.exe
set dpr=%project%\FMXL3.dpr

if not exist "%dcc32%" (
echo �訡��! ��������� dcc32.exe �� ������! �஢���� ����ன�� � .bat 䠩��.
echo Error! Compiler dcc32.exe not found! Edit .bat file and check settings.
pause
exit
)

if not exist "%dcc64%" (
echo �訡��! ��������� dcc64.exe �� ������! �஢���� ����ன�� � .bat 䠩��.
echo Error! Compiler dcc64.exe not found! Edit .bat file and check settings.
pause
exit
)

if not exist "%dpr%" (
echo �訡��! ���� FMXL3.dpr �� ������! �஢���� ����ன�� � .bat 䠩��.
echo Error! File FMXL3.dpr not found! Edit .bat file and check settings.
pause
exit
)

echo -aWinTypes=Windows;WinProcs=Windows;DbiProcs=BDE;DbiTypes=BDE;DbiErrs=BDE>"%studiopath%\bin\dcc32.cfg"
echo -u"%studiopath%\lib\win32\release">>"%studiopath%\bin\dcc32.cfg"

echo -aWinTypes=Windows;WinProcs=Windows;DbiProcs=BDE;DbiTypes=BDE;DbiErrs=BDE>"%studiopath%\bin\dcc64.cfg"
echo -u"%studiopath%\lib\win64\release">>"%studiopath%\bin\dcc64.cfg"

cd "%project%"
md "%project%\Win32\Release\"
md "%project%\Win64\Release\"

"%dcc32%" "%dpr%" -NS"Winapi;System;System.Win" -E"%project%\Win32\Release"
"%dcc64%" "%dpr%" -NS"Winapi;System;System.Win" -E"%project%\Win64\Release"
pause
