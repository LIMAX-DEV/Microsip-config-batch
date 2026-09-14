
@echo off
setlocal enabledelayedexpansion
title Instalar MicroSIP

REM ====================================================================
REM  Instalar-MicroSIP.bat
REM  --------------------------------------------------------------
REM  Instala o MicroSIP (versao portatil, sem precisar de admin) e
REM  configura automaticamente a conta SIP do usuario com base no
REM  arquivo ramais.txt (mesma pasta deste script).
REM
REM  Formato esperado do ramais.txt (um por linha):
REM      usuario.windows:ramal
REM  Ex:
REM      lucas.lima:10011
REM      Limax:10021
REM      coronel:10013
REM
REM  O "usuario.windows" precisa ser IGUAL ao nome de login do
REM  Windows (%USERNAME%) da maquina onde o script for executado.
REM
REM  O MicroSIP ja e instalado/configurado em Portugues do Brasil
REM  (Language=portuguesebr no microsip.ini).
REM ====================================================================

REM --------------------------------------------------------------
REM 0) CONFIGURACOES FIXAS - ajuste aqui se precisar
REM --------------------------------------------------------------
set "SIP_SERVER=batata.tec.br"
set "SIP_PROXY=batata.tec.br:1220"
set "SIP_DOMAIN=batata.tec.br"
set "SIP_PASSWORD=batata021@"

set "SCRIPT_DIR=%~dp0"
set "RAMAIS_FILE=%SCRIPT_DIR%ramais.txt"
set "INSTALL_DIR=%APPDATA%\MicroSIP"
set "INI_PATH=%INSTALL_DIR%\microsip.ini"
set "EXE_PATH=%INSTALL_DIR%\microsip.exe"

REM Link oficial da versao portatil (Lite) - troque a versao se precisar
set "DOWNLOAD_URL=https://www.microsip.org/download/MicroSIP-Lite-3.22.12.zip"
set "ZIP_TEMP=%TEMP%\MicroSIP-Lite-portable.zip"

echo Usuario Windows detectado: %USERNAME%
echo.

REM --------------------------------------------------------------
REM 1) Verificar se o ramais.txt existe
REM --------------------------------------------------------------
if not exist "%RAMAIS_FILE%" (
    echo ERRO: nao encontrei o arquivo "ramais.txt" em: %SCRIPT_DIR%
    echo Coloque o ramais.txt na MESMA pasta deste script.
    pause
    exit /b 1
)

REM --------------------------------------------------------------
REM 2) Procurar o ramal do usuario atual na lista
REM --------------------------------------------------------------
set "RAMAL="

for /f "usebackq tokens=1,2 delims=:" %%A in ("%RAMAIS_FILE%") do (
    set "U=%%A"
    set "R=%%B"
    set "U=!U: =!"
    set "R=!R: =!"
    if not "!U!"=="" (
        if /i "!U!"=="%USERNAME%" set "RAMAL=!R!"
    )
)

if not defined RAMAL (
    echo ERRO: usuario "%USERNAME%" nao encontrado no ramais.txt.
    echo Verifique se o nome de login do Windows bate exatamente com o que esta no arquivo.
    pause
    exit /b 1
)

echo Ramal encontrado para "%USERNAME%": %RAMAL%
echo.

REM --------------------------------------------------------------
REM 3) Instalar o MicroSIP (modo portatil) se ainda nao existir
REM --------------------------------------------------------------
if not exist "%EXE_PATH%" (
    echo MicroSIP nao encontrado em %INSTALL_DIR% - preparando instalacao...

    if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

    set "ZIP_LOCAL="
    for %%Z in ("%SCRIPT_DIR%MicroSIP*.zip") do set "ZIP_LOCAL=%%Z"

    if defined ZIP_LOCAL (
        echo Usando pacote local: !ZIP_LOCAL!
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '!ZIP_LOCAL!' -DestinationPath '%INSTALL_DIR%' -Force"
    ) else (
        echo Baixando MicroSIP portatil de %DOWNLOAD_URL% ...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_TEMP%' -UseBasicParsing"
        if not exist "%ZIP_TEMP%" (
            echo ERRO ao baixar o MicroSIP.
            echo Baixe manualmente em https://www.microsip.org/downloads ^(versao portatil/zip^)
            echo e coloque o .zip na mesma pasta deste script, depois rode de novo.
            pause
            exit /b 1
        )
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_TEMP%' -DestinationPath '%INSTALL_DIR%' -Force"
        del "%ZIP_TEMP%" >nul 2>&1
    )

    if not exist "%EXE_PATH%" (
        echo ERRO: nao encontrei microsip.exe apos a extracao em %INSTALL_DIR%
        echo Confira se o zip baixado/local e realmente a versao PORTATIL do MicroSIP.
        pause
        exit /b 1
    )

    echo MicroSIP instalado em %INSTALL_DIR%
) else (
    echo MicroSIP ja esta instalado em %INSTALL_DIR%
)
echo.

REM --------------------------------------------------------------
REM 4) Fechar o MicroSIP se estiver aberto (para sobrescrever o ini)
REM --------------------------------------------------------------
taskkill /IM microsip.exe /F >nul 2>&1

REM --------------------------------------------------------------
REM 5) Gerar o microsip.ini com os dados da conta do ramal
REM --------------------------------------------------------------
(
echo [Account1]
echo label=%RAMAL%
echo Server=%SIP_SERVER%
echo Proxy=%SIP_PROXY%
echo Username=%RAMAL%
echo Domain=%SIP_DOMAIN%
echo AuthID=%RAMAL%
echo Password=%SIP_PASSWORD%
echo DisplayName=%RAMAL%
echo.
echo [Settings]
echo accountId=1
echo Language=portuguesebr
) > "%INI_PATH%"

echo Arquivo de configuracao gerado em: %INI_PATH%
echo.

REM --------------------------------------------------------------
REM 6) (Opcional) Criar atalho na Area de Trabalho
REM --------------------------------------------------------------
set "SHORTCUT=%USERPROFILE%\Desktop\MicroSIP.lnk"
if not exist "%SHORTCUT%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut('%SHORTCUT%'); $s.TargetPath='%EXE_PATH%'; $s.WorkingDirectory='%INSTALL_DIR%'; $s.Save()"
    echo Atalho criado na Area de Trabalho.
    echo.
)

REM --------------------------------------------------------------
REM 7) Abrir o MicroSIP ja configurado
REM --------------------------------------------------------------
echo Iniciando o MicroSIP...
start "" "%EXE_PATH%"

echo.
echo ==================================================================
echo  Configuracao concluida para o ramal %RAMAL% (%USERNAME%)
echo ==================================================================
echo.
echo IMPORTANTE: se o MicroSIP nao registrar (ficar "Offline"), veja a
echo observacao sobre senha no arquivo LEIA-ME.txt que acompanha este script.
echo.
pause
