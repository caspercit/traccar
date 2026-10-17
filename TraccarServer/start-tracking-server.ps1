
# ==============================================
# CAFESOFT - INICIO AUTOMATICO DE TRACCAR
# Docker + Cloudflare + Deteccion de URL
# ==============================================

$ErrorActionPreference = "Continue"

$carpeta = "C:\TraccarServer"
$cloudflared = "C:\Program Files (x86)\cloudflared\cloudflared.exe"

$carpetaLogs = Join-Path $carpeta "logs"
$archivoInicio = Join-Path $carpetaLogs "inicio.log"
$archivoURLs = Join-Path $carpeta "urls-cloudflare.txt"

# ==============================================
# 1. CREAR CARPETAS
# ==============================================

New-Item -ItemType Directory `
    -Path $carpetaLogs `
    -Force | Out-Null

function Registrar {
    param([string]$Mensaje)

    $fecha = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

    Write-Host $Mensaje

    "[$fecha] $Mensaje" |
        Out-File $archivoInicio -Append -Encoding UTF8
}

Registrar "Iniciando CafeSoft - Traccar"

# ==============================================
# 2. VERIFICAR CLOUDFLARED
# ==============================================

if (-not (Test-Path $cloudflared)) {
    Registrar "ERROR: No se encontro cloudflared."
    exit 1
}

# ==============================================
# 3. ESPERAR A DOCKER
# ==============================================

$dockerListo = $false

for ($i = 0; $i -lt 36; $i++) {

    $resultado = & docker.exe info 2>&1

    if ($LASTEXITCODE -eq 0) {
        $dockerListo = $true
        break
    }

    Registrar "Esperando a Docker..."
    Start-Sleep -Seconds 5
}

if (-not $dockerListo) {
    Registrar "ERROR: Docker no esta disponible."
    exit 1
}

Registrar "Docker disponible."

# ==============================================
# 4. INICIAR CONTENEDOR TRACCAR
# ==============================================

$estadoTraccar = docker inspect `
    --format "{{.State.Running}}" traccar 2>$null

if ($LASTEXITCODE -ne 0) {
    Registrar "ERROR: No existe el contenedor traccar."
    exit 1
}

if ($estadoTraccar -eq "true") {

    Registrar "Traccar ya estaba iniciado."

} else {

    docker start traccar | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Registrar "ERROR: No se pudo iniciar Traccar."
        exit 1
    }

    Registrar "Contenedor Traccar iniciado."
}

# ==============================================
# 5. ESPERAR A LOS PUERTOS LOCALES
# ==============================================

$puertos = @(8082, 5055)

foreach ($puerto in $puertos) {

    $disponible = $false

    for ($i = 0; $i -lt 30; $i++) {

        $conexion = Test-NetConnection `
            -ComputerName "127.0.0.1" `
            -Port $puerto `
            -InformationLevel Quiet `
            -WarningAction SilentlyContinue

        if ($conexion) {
            $disponible = $true
            break
        }

        Start-Sleep -Seconds 2
    }

    if (-not $disponible) {
        Registrar "ERROR: Puerto $puerto no disponible."
        exit 1
    }

    Registrar "Puerto $puerto disponible."
}

# ==============================================
# 6. CONFIGURAR TUNELES
# ==============================================

$tuneles = @(
    @{ Nombre = "web"; Puerto = 8082 },
    @{ Nombre = "gps"; Puerto = 5055 }
)

# Guardar el inicio de cada sesion nueva
$inicioTuneles = @{}

foreach ($tunel in $tuneles) {

    $puerto = $tunel.Puerto
    $nombre = $tunel.Nombre

    $log = Join-Path $carpetaLogs "$nombre.log"

    $existe = Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -eq "cloudflared.exe" -and
            $_.CommandLine -match "localhost:$puerto(\s|`"|$)"
        } |
        Select-Object -First 1

    if ($existe) {

        Registrar "Tunel $nombre ya iniciado."

        # No podemos garantizar que la URL antigua
        # siga vigente sin comprobarla.
        $inicioTuneles[$nombre] = $null
        continue
    }

    # Limpiar registro anterior para evitar URL viejas
    if (Test-Path $log) {
        Remove-Item $log -Force
    }

    $inicioTuneles[$nombre] = Get-Date

    Start-Process `
        -FilePath $cloudflared `
        -ArgumentList @(
            "tunnel",
            "--protocol",
            "http2",
            "--url",
            "http://localhost:$puerto",
            "--logfile",
            $log,
            "--loglevel",
            "info"
        ) `
        -WindowStyle Hidden

    Registrar "Tunel $nombre iniciado."
}

# ==============================================
# 7. DETECTAR URL DE CLOUDFLARE
# ==============================================

function Obtener-URL {
    param(
        [string]$Nombre,
        [int]$Puerto
    )

    $log = Join-Path $carpetaLogs "$Nombre.log"

    if (-not (Test-Path $log)) {
        return $null
    }

    $proceso = Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -eq "cloudflared.exe" -and
            $_.CommandLine -match "localhost:$Puerto(\s|`"|$)"
        } |
        Select-Object -First 1

    if (-not $proceso) {
        return $null
    }

    $contenido = Get-Content $log -Raw

    $coincidencias = [regex]::Matches(
        $contenido,
        'https://[a-zA-Z0-9-]+\.trycloudflare\.com'
    )

    if ($coincidencias.Count -eq 0) {
        return $null
    }

    return $coincidencias[
        $coincidencias.Count - 1
    ].Value
}

Registrar "Buscando URL de Cloudflare..."

$urlWeb = $null
$urlGPS = $null

for ($i = 0; $i -lt 15; $i++) {

    $urlWeb = Obtener-URL -Nombre "web" -Puerto 8082
    $urlGPS = Obtener-URL -Nombre "gps" -Puerto 5055

    if ($urlWeb -and $urlGPS) {
        break
    }

    Start-Sleep -Seconds 2
}

# ==============================================
# 8. COMPROBAR URL PUBLICAS
# ==============================================

function Probar-URL {
    param(
        [string]$URL,
        [string]$Tipo
    )

    if (-not $URL) {
        return $false
    }

    try {

        if ($Tipo -eq "web") {
            $respuesta = Invoke-WebRequest `
                -Uri $URL `
                -Method Get `
                -UseBasicParsing `
                -TimeoutSec 15
        } else {
            # Comprobar DNS sin enviar posiciones falsas
            $hostURL = ([uri]$URL).Host

            $dns = Resolve-DnsName `
                -Name $hostURL `
                -ErrorAction Stop

            return [bool]$dns
        }

        return ($respuesta.StatusCode -eq 200)

    } catch {
        return $false
    }
}

$webOK = Probar-URL -URL $urlWeb -Tipo "web"
$gpsDNS = Probar-URL -URL $urlGPS -Tipo "gps"

# ==============================================
# 9. GUARDAR URL
# ==============================================

$fecha = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

$estadoWeb = if ($webOK) {
    "HTTP 200 confirmado"
} else {
    "No verificado"
}

$estadoGPS = if ($gpsDNS) {
    "DNS resuelto; envio GPS no comprobado"
} else {
    "No verificado"
}

$resultado = @"
========================================
CAFESOFT - URL CLOUDFLARE
========================================

Actualizado: $fecha

TRACCAR WEB:
$urlWeb
Estado: $estadoWeb

TRACCAR GPS:
$urlGPS
Estado: $estadoGPS

Puerto WEB: 8082
Puerto GPS: 5055

========================================
"@

$resultado |
    Set-Content $archivoURLs -Encoding UTF8

Write-Host ""
Write-Host $resultado

Registrar "Archivo de URL actualizado."

# ==============================================
# 10. FINALIZAR
# ==============================================

Registrar "Proceso de inicio finalizado."

exit 0
