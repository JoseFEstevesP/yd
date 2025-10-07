# Descargador de Videos Auto-Configurable - PowerShell Version Mejorada
$Host.UI.RawUI.WindowTitle = "Descargador de Videos Auto-Configurable v2.0"
$ErrorActionPreference = "Stop"

# Configuración de URLs para descarga
$ytdlp_url = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
$ffmpeg_url = "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"

# Guardar la ruta del script original
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Configuración de colores
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorInfo = "Cyan"
$ColorDebug = "Gray"

# Función para mostrar mensajes con formato
function Write-ColorMessage {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Función para mostrar mensajes de progreso
function Write-ProgressMessage {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $ColorInfo
}

# Función para preguntar sí/no al usuario
function Get-UserConfirmation {
    param([string]$Prompt)
    
    do {
        $response = Read-Host "$Prompt (s/n)"
        $response = $response.Trim().ToLower()
    } while ($response -notin @('s', 'n', 'si', 'no', 'y', 'n'))
    
    return $response -in @('s', 'si', 'y')
}

# Función para verificar conexión a internet
function Test-InternetConnection {
    try {
        $null = Resolve-DnsName -Name "github.com" -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Función para descargar archivo con reintentos
function Invoke-SafeDownload {
    param([string]$Url, [string]$OutputPath, [int]$Retries = 3)
    
    for ($i = 1; $i -le $Retries; $i++) {
        try {
            Write-ProgressMessage "Descargando... (Intento $i de $Retries)"
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UserAgent "PowerShell"
            if (Test-Path $OutputPath) {
                return $true
            }
        } catch {
            Write-ColorMessage "Error en intento $i : $($_.Exception.Message)" $ColorWarning
            if ($i -eq $Retries) {
                return $false
            }
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

# Función para verificar y actualizar yt-dlp
function Update-ytdlp {
    if (-not (Test-Path $ytdlp_path)) { return $false }
    
    Write-ProgressMessage "Verificando actualizaciones de yt-dlp..."
    try {
        & $ytdlp_path -U
        if ($LASTEXITCODE -eq 0) {
            Write-ColorMessage "yt-dlp está actualizado" $ColorSuccess
        }
    } catch {
        Write-ColorMessage "No se pudo verificar actualizaciones: $($_.Exception.Message)" $ColorWarning
    }
}

# Verificar conexión a internet al inicio
if (-not (Test-InternetConnection)) {
    Write-ColorMessage "ADVERTENCIA: No hay conexión a internet o es inestable" $ColorWarning
    $continuar = Get-UserConfirmation "¿Continuar de todos modos?"
    if (-not $continuar) {
        exit 1
    }
}

# Verificar y descargar yt-dlp (en el directorio del script)
$ytdlp_path = Join-Path $ScriptDirectory "yt-dlp.exe"
if (-not (Test-Path $ytdlp_path)) {
    Write-ColorMessage "Descargando yt-dlp..." $ColorWarning
    if (-not (Invoke-SafeDownload -Url $ytdlp_url -OutputPath $ytdlp_path)) {
        Write-ColorMessage "ERROR: No se pudo descargar yt-dlp después de varios intentos" $ColorError
        Write-ColorMessage "Verifica tu conexión a internet y vuelve a intentarlo" $ColorWarning
        Read-Host "Presiona Enter para salir"
        exit 1
    }
    Write-ColorMessage "yt-dlp descargado correctamente" $ColorSuccess
} else {
    # Verificar actualizaciones si ya existe
    Update-ytdlp
}

# Función mejorada para verificar FFmpeg completo
function Test-FFmpegComplete {
    $requiredFiles = @("ffmpeg.exe", "ffprobe.exe", "ffplay.exe")
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path $ffmpeg_bin_dir $file
        if (-not (Test-Path $filePath)) {
            $missingFiles += $file
        }
    }
    
    return $missingFiles
}

# Función mejorada para descargar FFmpeg
function Install-FFmpeg {
    Write-ColorMessage "Descargando FFmpeg..." $ColorWarning
    
    $ffmpeg_zip = Join-Path $ScriptDirectory "ffmpeg.zip"
    
    if (-not (Invoke-SafeDownload -Url $ffmpeg_url -OutputPath $ffmpeg_zip)) {
        Write-ColorMessage "ERROR: No se pudo descargar FFmpeg" $ColorError
        return $false
    }

    Write-ColorMessage "Descomprimiendo FFmpeg..." $ColorWarning
    
    # Crear carpeta temporal para extracción
    $tempDir = Join-Path $ScriptDirectory "ffmpeg_temp"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    try {
        Expand-Archive -Path $ffmpeg_zip -DestinationPath $tempDir -Force
        
        # Buscar el directorio bin de FFmpeg
        $binSourceDir = Get-ChildItem -Path $tempDir -Recurse -Directory -Filter "bin" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if (-not $binSourceDir) {
            Write-ColorMessage "ERROR: No se encontró el directorio bin de FFmpeg" $ColorError
            return $false
        }
        
        # Crear estructura de directorios ffmpeg\bin si no existe
        if (-not (Test-Path $ffmpeg_bin_dir)) {
            New-Item -ItemType Directory -Path $ffmpeg_bin_dir -Force | Out-Null
        }
        
        # Copiar todos los ejecutables de FFmpeg del directorio bin
        $ffmpegFiles = @("ffmpeg.exe", "ffprobe.exe", "ffplay.exe")
        $copiedFiles = 0
        
        foreach ($file in $ffmpegFiles) {
            $sourceFile = Join-Path $binSourceDir.FullName $file
            $destFile = Join-Path $ffmpeg_bin_dir $file
            
            if (Test-Path $sourceFile) {
                Copy-Item $sourceFile $destFile -Force
                $copiedFiles++
                Write-ColorMessage "  ✓ $file copiado" $ColorSuccess
            } else {
                Write-ColorMessage "  ✗ $file no encontrado en el paquete" $ColorWarning
            }
        }
        
        if ($copiedFiles -gt 0) {
            Write-ColorMessage "FFmpeg instalado correctamente ($copiedFiles de $($ffmpegFiles.Count) archivos)" $ColorSuccess
            return $true
        } else {
            Write-ColorMessage "ERROR: No se pudieron copiar los archivos de FFmpeg" $ColorError
            return $false
        }
        
    } catch {
        Write-ColorMessage "ERROR durante la extracción: $($_.Exception.Message)" $ColorError
        return $false
    } finally {
        # Limpieza
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $ffmpeg_zip -Force -ErrorAction SilentlyContinue
    }
}

# Configurar rutas de FFmpeg
$ffmpeg_dir = Join-Path $ScriptDirectory "ffmpeg"
$ffmpeg_bin_dir = Join-Path $ffmpeg_dir "bin"
$ffmpeg_exe_path = Join-Path $ffmpeg_bin_dir "ffmpeg.exe"
$ffprobe_exe_path = Join-Path $ffmpeg_bin_dir "ffprobe.exe"

# Verificar y descargar FFmpeg (opcional) - en directorio del script
$ffmpegAvailable = $false

if (Test-Path $ffmpeg_exe_path) {
    $missingFiles = Test-FFmpegComplete
    if ($missingFiles.Count -eq 0) {
        Write-ColorMessage "FFmpeg detectado y completo - listo para usar" $ColorSuccess
        $ffmpegAvailable = $true
    } else {
        Write-ColorMessage "FFmpeg incompleto - faltan: $($missingFiles -join ', ')" $ColorWarning
        $reparar = Get-UserConfirmation "¿Deseas reparar la instalación de FFmpeg?"
        if ($reparar) {
            $success = Install-FFmpeg
            $ffmpegAvailable = $success
        }
    }
} else {
    Write-Host ""
    $descargarFFmpeg = Get-UserConfirmation "¿Deseas descargar FFmpeg para mejores funciones (recomendado)?"
    
    if ($descargarFFmpeg) {
        $success = Install-FFmpeg
        $ffmpegAvailable = $success
        if (-not $success) {
            Write-ColorMessage "AVISO: FFmpeg no se pudo instalar, pero puedes continuar sin él" $ColorWarning
        }
    } else {
        Write-ColorMessage "Continuando sin FFmpeg - algunas funciones estarán limitadas" $ColorWarning
    }
}

# Agregar FFmpeg al PATH de esta sesión si está disponible
if ($ffmpegAvailable) {
    $env:PATH = "$ffmpeg_bin_dir;$env:PATH"
    Write-ColorMessage "FFmpeg agregado al PATH de esta sesión" $ColorSuccess
}

# Función para verificar si FFmpeg está completamente funcional
function Test-FFmpegFunctional {
    if (-not $ffmpegAvailable) { return $false }
    
    try {
        # Verificar que ffmpeg funciona
        & $ffmpeg_exe_path -version *>$null
        & $ffprobe_exe_path -version *>$null
        return $true
    } catch {
        return $false
    }
}

# Función para mostrar el menú de opciones de descarga
function Show-DownloadOptions {
    Write-Host ""
    Write-ColorMessage "=== OPCIONES DE DESCARGA ===" $ColorInfo
    Write-Host "1. Video (calidad automática - recomendado)"
    Write-Host "2. Solo audio (MP3)"
    Write-Host "3. Video 1080p (si está disponible)"
    Write-Host "4. Video 720p"
    Write-Host "5. Personalizado (avanzado)"
    Write-Host ""
    
    do {
        $opcion = Read-Host "Selecciona una opción (1-5)"
    } while ($opcion -notin @('1','2','3','4','5'))
    
    return $opcion
}

# Función para construir argumentos según la opción seleccionada
function Get-DownloadArguments {
    param([string]$Option)
    
    $baseArgs = @("--console-title", "--no-part")
    
    # Agregar ubicación de FFmpeg si está disponible
    if ($ffmpegAvailable) {
        $baseArgs += "--ffmpeg-location", $ffmpeg_bin_dir
    }
    
    switch ($Option) {
        "1" { # Video calidad automática
            $baseArgs += "-f", "best[height<=720]/best"
            if ($ffmpegAvailable) {
                $baseArgs += "--embed-metadata", "--embed-thumbnail"
                Write-ProgressMessage "Modo: Video calidad automática con metadatos"
            } else {
                Write-ProgressMessage "Modo: Video calidad automática (sin metadatos)"
            }
        }
        "2" { # Solo audio
            $baseArgs += "-x", "--audio-format", "mp3", "--audio-quality", "0"
            if ($ffmpegAvailable) {
                $baseArgs += "--embed-metadata", "--embed-thumbnail"
                Write-ProgressMessage "Modo: Solo audio (MP3 alta calidad con metadatos)"
            } else {
                Write-ProgressMessage "Modo: Solo audio (MP3 alta calidad)"
            }
        }
        "3" { # Video 1080p
            $baseArgs += "-f", "bestvideo[height<=1080]+bestaudio/best[height<=1080]"
            if ($ffmpegAvailable) {
                $baseArgs += "--embed-metadata", "--embed-thumbnail"
                Write-ProgressMessage "Modo: Video 1080p con metadatos"
            } else {
                Write-ProgressMessage "Modo: Video 1080p (sin metadatos)"
            }
        }
        "4" { # Video 720p
            $baseArgs += "-f", "bestvideo[height<=720]+bestaudio/best[height<=720]"
            if ($ffmpegAvailable) {
                $baseArgs += "--embed-metadata", "--embed-thumbnail"
                Write-ProgressMessage "Modo: Video 720p con metadatos"
            } else {
                Write-ProgressMessage "Modo: Video 720p (sin metadatos)"
            }
        }
        "5" { # Personalizado
            Write-Host ""
            Write-ColorMessage "Opciones avanzadas:" $ColorInfo
            Write-Host "Deja vacío para usar valores por defecto"
            $customFormat = Read-Host "Formato personalizado (ej: bestvideo+bestaudio)"
            if ($customFormat) {
                $baseArgs += "-f", $customFormat
            }
            if ($ffmpegAvailable) {
                $addMetadata = Get-UserConfirmation "¿Incluir metadatos y miniaturas?"
                if ($addMetadata) {
                    $baseArgs += "--embed-metadata", "--embed-thumbnail"
                }
            }
            Write-ProgressMessage "Modo: Personalizado"
        }
    }
    
    return $baseArgs
}

# Función para validar URL
function Test-ValidUrl {
    param([string]$Url)
    
    if ([string]::IsNullOrWhiteSpace($Url)) {
        return $false
    }
    
    # Patrones simples para URLs comunes
    $patterns = @(
        '^https?://',
        'youtube\.com|youtu\.be',
        'vimeo\.com',
        'twitter\.com',
        'tiktok\.com',
        'instagram\.com',
        'facebook\.com',
        'twitch\.tv'
    )
    
    foreach ($pattern in $patterns) {
        if ($Url -match $pattern) {
            return $true
        }
    }
    
    # Preguntar si quieren continuar con URLs no reconocidas
    Write-ColorMessage "ADVERTENCIA: La URL no parece ser de un sitio conocido" $ColorWarning
    return (Get-UserConfirmation "¿Continuar de todos modos?")
}

# Función principal del programa mejorada
function Start-Downloader {
    # Verificar funcionalidad de FFmpeg al inicio
    $ffmpegFunctional = Test-FFmpegFunctional
    if ($ffmpegAvailable -and (-not $ffmpegFunctional)) {
        Write-ColorMessage "ADVERTENCIA: FFmpeg está instalado pero no funciona correctamente" $ColorWarning
        Write-ColorMessage "Las funciones de metadatos estarán deshabilitadas" $ColorWarning
    }
    
    do {
        Clear-Host
        Write-ColorMessage "=== DESCARGADOR DE VIDEOS v2.0 ===" $ColorInfo
        Write-ColorMessage "Herramientas disponibles:" $ColorInfo
        Write-Host "  • yt-dlp: $(if (Test-Path $ytdlp_path) {'✓'} else {'✗'})"
        Write-Host "  • FFmpeg: $(if ($ffmpegFunctional) {'✓ Completamente funcional'} elseif ($ffmpegAvailable) {'⚠ Parcialmente instalado'} else {'✗ No disponible'})"
        Write-Host ""
        
        # Pedir URL con validación
        do {
            $url = Read-Host "Introduce la URL del video/playlist"
            if (-not (Test-ValidUrl -Url $url)) {
                Write-ColorMessage "URL no válida o no reconocida" $ColorError
                $url = $null
            }
        } while ([string]::IsNullOrWhiteSpace($url))
        
        # Mostrar opciones de descarga
        $opcion = Show-DownloadOptions
        
        # Pedir carpeta de destino
        Write-Host ""
        $carpeta = Read-Host "Introduce la carpeta de descarga (dejar vacío para usar actual)"
        
        if ([string]::IsNullOrWhiteSpace($carpeta)) {
            $carpeta = "."
            Write-ColorMessage "Usando carpeta actual: $(Get-Location)" $ColorWarning
        } else {
            if (-not (Test-Path $carpeta)) {
                Write-ColorMessage "La carpeta no existe. Creando carpeta..." $ColorWarning
                try {
                    New-Item -ItemType Directory -Path $carpeta -Force | Out-Null
                    Write-ColorMessage "Carpeta creada exitosamente" $ColorSuccess
                } catch {
                    Write-ColorMessage "ERROR: No se pudo crear la carpeta: $($_.Exception.Message)" $ColorError
                    continue
                }
            }
            # Convertir a ruta absoluta
            $carpeta = Resolve-Path $carpeta
        }
        
        # Mostrar resumen
        Write-Host ""
        Write-ColorMessage "=== RESUMEN ===" $ColorInfo
        Write-ColorMessage "URL: $url" $ColorWarning
        Write-ColorMessage "Carpeta: $carpeta" $ColorWarning
        Write-ColorMessage "FFmpeg: $(if ($ffmpegFunctional) {'Completamente funcional'} elseif ($ffmpegAvailable) {'Parcial - sin metadatos'} else {'No disponible'})" $ColorWarning
        Write-Host ""
        
        # Confirmar descarga
        $confirmar = Get-UserConfirmation "¿Iniciar la descarga?"
        
        if ($confirmar) {
            # Realizar descarga
            try {
                Write-Host ""
                Write-ColorMessage "Iniciando descarga..." $ColorSuccess
                Write-Host ""
                
                # Guardar ubicación actual
                $originalLocation = Get-Location
                
                # Cambiar a la carpeta de destino
                Set-Location $carpeta
                
                # Obtener argumentos según la opción seleccionada
                $ytdlpArgs = Get-DownloadArguments -Option $opcion
                $ytdlpArgs += $url
                
                Write-ColorMessage "Comando: $ytdlp_path $($ytdlpArgs -join ' ')" $ColorDebug
                Write-Host ""
                
                # Ejecutar yt-dlp
                $startTime = Get-Date
                & $ytdlp_path $ytdlpArgs
                $endTime = Get-Date
                $duration = $endTime - $startTime
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-ColorMessage ">>> DESCARGA COMPLETADA EXITOSAMENTE! <<<" $ColorSuccess
                    Write-ColorMessage "Tiempo total: $($duration.ToString('mm\:ss'))" $ColorSuccess
                    Write-ColorMessage "Archivos guardados en: $(Get-Location)" $ColorSuccess
                } else {
                    Write-Host ""
                    Write-ColorMessage "ERROR en la descarga. Código: $LASTEXITCODE" $ColorError
                    
                    # Mensajes de error específicos
                    switch ($LASTEXITCODE) {
                        1 { Write-ColorMessage "Posible causa: URL no válida o sin conexión" $ColorWarning }
                        2 { Write-ColorMessage "Posible causa: Opciones incorrectas" $ColorWarning }
                        101 { Write-ColorMessage "Posible causa: Video no disponible o restringido" $ColorWarning }
                        default { Write-ColorMessage "Consulta: https://github.com/yt-dlp/yt-dlp#exit-codes" $ColorInfo }
                    }
                }
                
                # Regresar a la ubicación original
                Set-Location $originalLocation
                
            } catch {
                Write-ColorMessage "ERROR durante la descarga: $($_.Exception.Message)" $ColorError
                Write-ColorMessage "Ubicación yt-dlp: $ytdlp_path" $ColorDebug
            }
        } else {
            Write-Host ""
            Write-ColorMessage "Descarga cancelada por el usuario" $ColorWarning
        }
        
        Write-Host ""
        $continuar = Get-UserConfirmation "¿Deseas hacer otra descarga?"
        
    } while ($continuar)
    
    Write-Host ""
    Write-ColorMessage "¡Gracias por usar el descargador!" $ColorInfo
    Write-ColorMessage "Presiona cualquier tecla para salir..." $ColorInfo
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Verificar que yt-dlp existe antes de iniciar
if (-not (Test-Path $ytdlp_path)) {
    Write-ColorMessage "ERROR CRÍTICO: yt-dlp.exe no se encuentra en $ytdlp_path" $ColorError
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Iniciar el programa
Start-Downloader