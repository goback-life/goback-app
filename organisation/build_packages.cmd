@echo off
setlocal enabledelayedexpansion
cd /d packages
for /d %%D in (*) do (
  if exist "%%D\pubspec.yaml" (
    echo Building %%D...
    pushd "%%D"
    findstr /i /c:"build_runner" "pubspec.yaml" >nul
    if not errorlevel 1 (
      fvm flutter pub run build_runner build --delete-conflicting-outputs
    )
    popd
  )
)
cd /d ..
endlocal
