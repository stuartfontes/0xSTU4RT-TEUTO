[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$caminho_env = ""
$arquivo_env = Join-Path -Path $caminho_env -ChildPath ".env"

function SairComPausa {
    param($codigo = 1)
    Read-Host "`nPressione ENTER para sair"
    exit $codigo
}

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
        SairComPausa
    }

    if (-not (Test-Path -Path $arquivo_env -PathType Leaf)) {
        write-host "[!] .env não encontrada em: $arquivo_env" -ForegroundColor Yellow
        SairComPausa
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
        SairComPausa
    }

    if (-not $GUID_PADRAO -or -not $IP_PADRAO -or -not $PASTA_COMPARTILHADA) {
        write-host "[!] .env incompleta (GUID_PADRAO / IP_PADRAO / PASTA_COMPARTILHADA), encerrando" -ForegroundColor Yellow
        SairComPausa
    }

    write-host "[+] .env carregada de: $arquivo_env" -ForegroundColor Green
}

function ValidarPendrive {

    RodandoCodigo

    $pen_drive = get-volume -FileSystemLabel "0xSTU4RT" -ErrorAction SilentlyContinue

    if (-not $pen_drive) {
        write-host "[!] pendrive validado não encontrado, favor conectar o pendrive disponibilizado para a Coordenação!`n[!] encerrando processo!" -ForegroundColor Yellow
        SairComPausa
    }

    if ($pen_drive.UniqueId -ne $GUID_PADRAO) {
        write-host "[!] GUID nao correspondente`n[!] encerrando..." -ForegroundColor Yellow
        SairComPausa
    }

    write-host "[+] pendrive validado" -ForegroundColor Green
}

function ObterIPLocal {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 |
           Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } |
           Select-Object -First 1).IPAddress
    return $ip
}

function GerarEEnviarLog {
    param($user, $acao, $resultado)

    $ipLocal   = ObterIPLocal
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $conteudo = @"
Data/Hora: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
IP local: $ipLocal
Usuario: $user
Acao: $acao
Resultado: $resultado
"@

    $nomeArquivo = "log_${user}_$timestamp.txt"
    $caminhoTemp = Join-Path $env:TEMP $nomeArquivo

    $conteudo | Out-File -FilePath $caminhoTemp -Encoding UTF8

    $destino = "\\$IP_PADRAO\$PASTA_COMPARTILHADA"

    & robocopy $env:TEMP $destino $nomeArquivo /R:3 /W:5 /NP
    $codigoRetorno = $LASTEXITCODE

    if ($codigoRetorno -ge 8) {
        write-host "[!] falha ao enviar log (codigo $codigoRetorno). Copia mantida em: $caminhoTemp" -ForegroundColor Yellow
    } else {
        write-host "[+] log enviado com sucesso para $destino" -ForegroundColor Green
        Remove-Item -Path $caminhoTemp -ErrorAction SilentlyContinue
    }
}

function CriarUsuario {

    $option   = read-host "`n[U] Digite a opção desejada:`n[1] Para criar acesso`n[2] Para desbloquear acesso`n"
    $user     = read-host "[U] Digite a matrícula do usuário"
    $password = read-host "[U] Digite a senha para o usuário" -AsSecureString

    switch ($option.Trim()) {
        "1" { 
            write-host "[+] iniciando criação de usuário..."

            if (get-localuser -name $user -ErrorAction SilentlyContinue) {
                write-host "[!] erro: a matrícula $user já possui cadastro" -ForegroundColor Yellow
                return
            }

            $grupo = "AntaresVision.PowerUser"

            new-localuser -name $user -Password $password -Description "user criado via 0xSTU4RT" -FullName "colaborador matrícula $user"
            add-localgroupmember -group $grupo -Member $user

            write-host "[+] sucesso! usuário $user está ativo no grupo $grupo" -ForegroundColor Green

            GerarEEnviarLog -user $user -acao "Criacao" -resultado "Sucesso"
        }
        "2" { 
            write-host "[+] iniciando desbloqueio de usuário..."

            $usuarioObj = get-localuser -name $user -ErrorAction SilentlyContinue

            if (-not $usuarioObj) {
                write-host "[!] erro: a matrícula $user não existe" -ForegroundColor Yellow
                return
            }

            if ($usuarioObj.Enabled) {
                write-host "[!] a matrícula $user já está desbloqueada" -ForegroundColor Yellow
                return
            }

            Enable-LocalUser -Name $user
            write-host "[+] sucesso! usuário $user foi desbloqueado" -ForegroundColor Green

            GerarEEnviarLog -user $user -acao "Desbloqueio" -resultado "Sucesso"
        }
        default { 
            write-host "[!] opção inválida" -ForegroundColor Yellow
            SairComPausa
        }
    }
}

BoasVindas
ValidarEnv
ValidarPendrive
CriarUsuario

Read-Host "`nPressione ENTER para sair"