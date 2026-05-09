@echo off
set SOURCE_DIR=%~dp0
set DEST=%~1

:: If no destination is provided, try to find the standard Dext Output directory
if "%DEST%"=="" (
    set DEST=%SOURCE_DIR%..\..\Output
)

echo ======================================================
echo Deploying Gemini Server Assets...
echo Source: %SOURCE_DIR%
echo Destination: %DEST%
echo ======================================================

:: Criar diretório de destino se não existir
if not exist "%DEST%" (
    echo Creating destination directory...
    mkdir "%DEST%"
)

:: Copiar wwwroot (Arquivos do Frontend)
if exist "%SOURCE_DIR%wwwroot" (
    echo Copying wwwroot...
    xcopy /E /I /Y "%SOURCE_DIR%wwwroot" "%DEST%\wwwroot\"
) else (
    echo Error: wwwroot directory not found in %SOURCE_DIR%
)

:: Copiar config.yml (Configurações da API)
if exist "%SOURCE_DIR%config.yml" (
    echo Copying config.yml...
    copy /Y "%SOURCE_DIR%config.yml" "%DEST%\"
) else (
    echo Error: config.yml not found in %SOURCE_DIR%
)

echo.
echo Deploy finished!
