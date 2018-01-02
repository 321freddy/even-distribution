@echo off

cd %cd%

REM get name of current directory
for %%* in (.) do set CurrDirName=%%~nx*

rmdir /S /Q "%temp%\.build\"
del /f /s /q "%cd%\.build\%CurrDirName%.zip"

xcopy /e /s /y "%cd%" "%temp%\.build\%CurrDirName%\" /exclude:exclude.txt

echo Set objArgs = WScript.Arguments > _zipIt.vbs
echo InputFolder = objArgs(0) >> _zipIt.vbs
echo ZipFile = objArgs(1) >> _zipIt.vbs
echo CreateObject("Scripting.FileSystemObject").CreateTextFile(ZipFile, True).Write "PK" ^& Chr(5) ^& Chr(6) ^& String(18, vbNullChar) >> _zipIt.vbs
echo Set objShell = CreateObject("Shell.Application") >> _zipIt.vbs
echo Set source = objShell.NameSpace(InputFolder).Items >> _zipIt.vbs
echo objShell.NameSpace(ZipFile).CopyHere(source) >> _zipIt.vbs
echo wScript.Sleep 2000 >> _zipIt.vbs

CScript _zipIt.vbs "%temp%\.build\" "%cd%\.build\%CurrDirName%.zip"
del "_zipIt.vbs"

echo Success!
call explorer "%cd%\.build\"
