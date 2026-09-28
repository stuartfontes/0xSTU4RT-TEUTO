[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$caminho_env = ""
$arquivo_env = Join-Path -Path $caminho_env -ChildPath ".env"

function Lettring0xSTUART {
    write-host "-------------------------------------------------" -ForegroundColor Red
    write-host "   ___        ____ _____ _   _ _  _   ____ _____ 
  / _ \__  __/ ___|_   _| | | | || | |  _ \_   _|
 | | | \ \/ /\___ \ | | | | | | || |_| |_) || |  
 | |_| |>  <  ___) || | | |_| |__   _|  _ < | |  
  \___//_/\_\|____/ |_|  \___/   |_| |_| \_\|_|  
                                                 
-------------------------------------------------
" -ForegroundColor Red 
}

function BoasVindas {
    Lettring0xSTUART
    write-host "0xSTU4RT / Laboratório Teuto Brasileiro " -ForegroundColor Blue
    Write-Host "Ferramenta para criação de usuários baseada na utilização de pendrives validados em processo`n" -ForegroundColor Blue
    write-host "[x] GITHUB - https://github.com/stuartfontes"
    write-host "[x] LINKEDIN - https://www.linkedin.com/in/mauricio-stuart-fontes-83b45318a/`n"
}

function RodandoCodigo { 
    write-host "`n[-] executando função, aguarde...`n"
    Start-Sleep -Seconds 3
}

function ValidarEnv {

    if (-not (Test-Path -Path $caminho_env -PathType Container)) {
        write-host "[!] pasta da .env não encontrada: $caminho_env" -ForegroundColor Yellow
        exit 1
    }

    if (-not (Test-Path -Path $arquivo_env -PathType Leaf)) {
        write-host "[!] .env não encontrada em: $arquivo_env" -ForegroundColor Yellow
        exit 1
    }

    try {
        Get-Content -Path $arquivo_env -ErrorAction Stop | ForEach-Object {
            if ($_ -and $_ -notmatch '^\s*#' -and $_ -match '=') {
                $chave, $valor = $_ -split '=', 2
                Set-Variable -Name $chave.Trim() -Value $valor.Trim() -Scope Global
            }
        }
    } catch {
        write-host "[!] falha ao ler a .env, encerrando" -ForegroundColor Yellow
        exit 1
    }

    if (-not $GUID_PADRAO) {
        write-host "[!] GUID_PADRAO ausente na .env, encerrando" -ForegroundColor Yellow
        exit 1
    }

    write-host "[+] .env carregada de: $arquivo_env" -ForegroundColor Green
}

function ValidarPendrive {

    RodandoCodigo

    $pen_drive = get-volume -FileSystemLabel "0xSTU4RT" -ErrorAction SilentlyContinue

    if (-not $pen_drive) {
        write-host "[!] pendrive validado não encontrado, favor conectar o pendrive disponibilizado para a Coordenação!`n[!] encerrando processo!" -ForegroundColor Yellow
        exit 1
    }

    if ($pen_drive.UniqueId -ne $GUID_PADRAO) {
        write-host "[!] GUID nao correspondente`n[!] encerrando..." -ForegroundColor Yellow
        exit 1
    }

    write-host "[+] pendrive validado" -ForegroundColor Green
}

function CriarUsuario {

    $option   = read-host "`n[U] Digite a opção desejada:`n[1] Para criar acesso`n[2] Para desbloquear acesso`n"
    $user     = read-host "[U] Digite a matrícula do usuário"
    $password = read-host "[U] Digite a senha para o usuário" -AsSecureString

    switch ($option.Trim()) {
        "1"     { write-host "criar" }
        "2"     { write-host "desbloquear" }
        default { write-host "[!] opção inválida" -ForegroundColor Yellow; exit 1 }
    }
}

BoasVindas
ValidarEnv
ValidarPendrive
CriarUsuario