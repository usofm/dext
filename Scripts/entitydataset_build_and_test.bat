@echo off
echo.
echo ============================================================
echo   Dext - Build and Test Suite
echo ============================================================
echo.

call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"

echo.
echo [1/4] Building Dext.Core...
msbuild "C:\dev\Dext\DextRepository\Sources\Dext.Core.dproj" /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal /nologo
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed for Dext.Core
    exit /b %errorlevel%
)

echo.
echo [2/4] Building Dext.EF.Core...
msbuild "C:\dev\Dext\DextRepository\Sources\Dext.EF.Core.dproj" /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal /nologo
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed for Dext.EF.Core
    exit /b %errorlevel%
)

echo.
echo [3/4] Building Dext.EntityDataSet.UnitTests...
msbuild "C:\dev\Dext\DextRepository\Tests\Entity\UnitTests\Dext.Entity.UnitTests.dproj" /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal /nologo
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed for Dext.Entity.UnitTests
    exit /b %errorlevel%
)

echo.
echo [4/4] Running UnitTests...
"C:\dev\Dext\DextRepository\Tests\Output\Dext.Entity.UnitTests.exe"

set EXIT_CODE=%errorlevel%
if %EXIT_CODE% neq 0 (
    echo.
    echo WARNING: Some tests failed (Exit Code: %EXIT_CODE%)
) else (
    echo.
    echo SUCCESS: All tests passed!
)

exit /b %EXIT_CODE%
