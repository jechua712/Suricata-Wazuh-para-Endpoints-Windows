# --- Configuración Inicial ---
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue" 

# URLs proporcionadas
$urlSuricata = "https://www.openinfosecfoundation.org/download/windows/Suricata-7.0.13-1-64bit.msi"
$urlNpcap = "https://npcap.com/dist/npcap-1.85.exe"

# Rutas temporales
$tempDir = $env:TEMP
$fileSuricata = "$tempDir\suricata_installer.msi"
$fileNpcap = "$tempDir\npcap_installer.exe"

# --- Función para verificar Administrador ---
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   INSTALADOR: SURICATA (AUTO) Y NPCAP (MANUAL)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

if (-not (Test-Administrator)) {
    Write-Host "[ERROR] Este script necesita permisos de Administrador." -ForegroundColor Red
    Break
}

try {
    # --- 1. NPCAP ---
    Write-Host "`n--- Procesando Npcap ---" -ForegroundColor Magenta
    
    Write-Host "1. Descargando Npcap (v1.85)..." -ForegroundColor Yellow
    $time = Measure-Command {
        Invoke-WebRequest -Uri $urlNpcap -OutFile $fileNpcap -UseBasicParsing
    }
    Write-Host "   -> Descargado en $($time.TotalSeconds.ToString("N2")) s." -ForegroundColor Green

    Write-Host "2. Iniciando instalador Npcap..." -ForegroundColor Yellow
    Write-Host "   [ATENCION] La version gratuita requiere instalacion manual." -ForegroundColor Cyan
    Write-Host "   -> Por favor, completa la instalacion en la ventana que aparecera." -ForegroundColor Cyan
    
    # Quitamos el "/S" porque falla en version gratuita. 
    # Usamos -Wait para que el script espere a que termines de instalar Npcap antes de seguir.
    $procNpcap = Start-Process -FilePath $fileNpcap -Wait -PassThru
    
    Write-Host "   -> Instalacion de Npcap finalizada." -ForegroundColor Green

    # --- 2. SURICATA ---
    Write-Host "`n--- Procesando Suricata ---" -ForegroundColor Magenta

    Write-Host "3. Descargando Suricata (v8.0.2)..." -ForegroundColor Yellow
    $time = Measure-Command {
        Invoke-WebRequest -Uri $urlSuricata -OutFile $fileSuricata -UseBasicParsing
    }
    Write-Host "   -> Descargado en $($time.TotalSeconds.ToString("N2")) s." -ForegroundColor Green

    Write-Host "4. Instalando Suricata (Silencioso)..." -ForegroundColor Yellow
    # Suricata SI permite instalacion silenciosa gratis (/qn)
    $procSuricata = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$fileSuricata`" /qn /norestart" -Wait -PassThru

    if ($procSuricata.ExitCode -eq 0) {
        Write-Host "   -> Suricata instalado correctamente." -ForegroundColor Green
    } else {
        Write-Host "   -> Codigo salida Suricata: $($procSuricata.ExitCode)" -ForegroundColor Gray
    }

    # --- 3. LIMPIEZA ---
    Write-Host "`n--- Limpieza ---" -ForegroundColor Magenta
    Remove-Item -Path $fileSuricata -ErrorAction SilentlyContinue
    Remove-Item -Path $fileNpcap -ErrorAction SilentlyContinue
    Write-Host "   -> Instaladores borrados." -ForegroundColor Green

    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "   INSTALACION COMPLETADA" -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan

} catch {
    Write-Host "`n[ERROR CRITICO]" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# --- Configuración Inicial ---
$ErrorActionPreference = "Stop"
$rulesUrl = "https://rules.emergingthreats.net/open/suricata-7.0.3/emerging-all.rules"
$baseDir = "C:\Program Files\Suricata"
$rulesDir = "$baseDir\rules"
$rulesFile = "$rulesDir\emerging-all.rules"
$configFile = "$baseDir\suricata.yaml"

# --- Función para verificar Administrador ---
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   CONFIGURADOR SURICATA (RANGO 2222-2268)    " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# 1. Verificar Permisos
if (-not (Test-Administrator)) {
    Write-Host "[ERROR] Necesitas ejecutar como Administrador." -ForegroundColor Red
    Break
}

try {
    # --- INTERACCION CON EL USUARIO ---
    Write-Host "`n--- Paso 1: Configuracion de Red ---" -ForegroundColor Magenta
    $userIP = Read-Host ">> Por favor, ingresa la IP del Windows para HOME_NET (Ej: 192.168.1.10)"
    
    if ([string]::IsNullOrWhiteSpace($userIP)) {
        Write-Host "No ingresaste una IP. Abortando." -ForegroundColor Red
        Break
    }

    # --- DESCARGA DE REGLAS ---
    Write-Host "`n--- Paso 2: Descargando Reglas ---" -ForegroundColor Magenta
    if (-not (Test-Path $rulesDir)) {
        New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null
    }
    Write-Host "Descargando emerging-all.rules..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $rulesUrl -OutFile $rulesFile -UseBasicParsing
    Write-Host "-> Reglas guardadas en: $rulesFile" -ForegroundColor Green


    # --- EDICION DEL YAML ---
    Write-Host "`n--- Paso 3: Editando suricata.yaml ---" -ForegroundColor Magenta
    if (-not (Test-Path $configFile)) { Throw "No se encontro el archivo: $configFile" }

    # Usamos lista para poder insertar lineas facilmente
    $contentList = [System.Collections.Generic.List[string]](Get-Content $configFile)

    # 3.1. HOME_NET
    $homeNetIndex = $contentList.FindIndex({ $args[0] -match "^\s*HOME_NET:" })
    if ($homeNetIndex -ne -1) {
        Write-Host "-> Configurando HOME_NET con $userIP" -ForegroundColor Green
        $contentList[$homeNetIndex] = "    HOME_NET: `"$userIP`""
    }

    # 3.2. EXTERNAL_NET (Linea 25 -> Index 24)
    if ($contentList.Count -gt 24) {
        Write-Host "-> Descomentando linea 25 (EXTERNAL_NET)..." -ForegroundColor Green
        $contentList[24] = "    EXTERNAL_NET: `"any`"" 
    }

    # 3.3. INSERTAR REGLA Y COMENTAR EL RESTO
    $ruleFilesIndex = $contentList.FindIndex({ $args[0] -match "^rule-files:" })
    
    if ($ruleFilesIndex -ne -1) {
        Write-Host "-> Encontrado 'rule-files:' en linea $($ruleFilesIndex + 1)." -ForegroundColor Cyan
        
        # A) INSERTAR emerging-all.rules
        $newRuleLine = " - emerging-all.rules"
        
        # Solo insertamos si no esta ya ahi (para evitar duplicados al re-ejecutar)
        if ($contentList[$ruleFilesIndex + 1] -ne $newRuleLine) {
            Write-Host "-> Insertando '$newRuleLine'..." -ForegroundColor Green
            $contentList.Insert($ruleFilesIndex + 1, $newRuleLine)
        }

        # B) COMENTAR RANGO 2222 a 2268
        # Indices: 2221 a 2267 (Array empieza en 0)
        Write-Host "-> Comentando reglas antiguas (Lineas 2222-2268)..." -ForegroundColor Yellow
        
        # Verificamos que el archivo tenga suficientes lineas
        if ($contentList.Count -ge 2268) {
            for ($j = 2221; $j -le 2267; $j++) {
                # Si la linea NO empieza con #, se lo agregamos
                if ($contentList[$j] -notmatch "^\s*#") {
                    $contentList[$j] = "# " + $contentList[$j]
                }
            }
            Write-Host "-> Reglas antiguas desactivadas correctamente." -ForegroundColor Green
        } else {
            Write-Warning "El archivo es mas corto de lo esperado (menos de 2268 lineas). No se pudo comentar el rango completo."
        }

    } else {
        Write-Warning "No se encontro la seccion 'rule-files:'."
    }

    # --- GUARDAR CAMBIOS ---
    Write-Host "Guardando cambios..." -ForegroundColor Yellow
    $contentList | Set-Content $configFile -Encoding UTF8

    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "   LISTO: REGLAS ACTUALIZADAS (2222-2268)     " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan

} catch {
    Write-Host "`n[ERROR CRITICO]" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# --- Configuración Inicial ---
$ErrorActionPreference = "Stop"
$wazuhConfigPath = "${env:ProgramFiles(x86)}\ossec-agent\ossec.conf"
# Carpetas para Suricata
$suricataDir = "C:\Program Files\Suricata"
$suricataExe = "suricata.exe" 
$suricataYaml = "suricata.yaml"

# --- Función para verificar Administrador ---
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   SCRIPT 3: UUID, SURICATA Y WAZUH (FINAL)   " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# 1. Verificar Permisos
if (-not (Test-Administrator)) {
    Write-Host "[ERROR] Necesitas ejecutar como Administrador." -ForegroundColor Red
    Break
}

try {
    # ---------------------------------------------------------
    # PASO 1: OBTENER UUID (SettingID)
    # ---------------------------------------------------------
    Write-Host "`n--- Paso 1: Seleccion de Interfaz de Red ---" -ForegroundColor Magenta
    
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}

    if ($adapters.Count -eq 0) { Throw "No se encontraron adaptadores de red con IP activa." }

    Write-Host "Adaptadores encontrados:" -ForegroundColor Yellow
    $i = 0
    foreach ($nic in $adapters) {
        Write-Host "[$i] IP: $($nic.IPAddress[0]) | Desc: $($nic.Description)"
        Write-Host "    UUID: $($nic.SettingID)" -ForegroundColor Gray
        $i++
    }

    $selection = Read-Host "`n>> Selecciona el numero [0 - $($adapters.Count - 1)] del adaptador a usar"

    if ($selection -match "^\d+$" -and [int]$selection -lt $adapters.Count) {
        $selectedNic = $adapters[[int]$selection]
        $uuid = $selectedNic.SettingID
        Write-Host "-> Seleccionado: $($selectedNic.Description)" -ForegroundColor Green
        Write-Host "-> UUID: $uuid" -ForegroundColor Green
    } else {
        Throw "Seleccion invalida."
    }

    # ---------------------------------------------------------
    # PASO 2: EJECUTAR SURICATA (METODO CARPETA)
    # ---------------------------------------------------------
    Write-Host "`n--- Paso 2: Ejecutando Suricata ---" -ForegroundColor Magenta

    $deviceFlag = "\Device\NPF_$uuid"
    
    if (Test-Path "$suricataDir\$suricataExe") {
        Write-Host "-> Abriendo CMD en la carpeta de Suricata..." -ForegroundColor Yellow
        
        # Ejecutamos Suricata en ventana aparte, situándonos primero en la carpeta correcta
        $simpleArgs = "/k $suricataExe -c $suricataYaml -i $deviceFlag"
        Start-Process -FilePath "cmd.exe" -WorkingDirectory $suricataDir -ArgumentList $simpleArgs -Verb RunAs
        
        Write-Host "-> Suricata iniciado en nueva ventana." -ForegroundColor Green
    } else {
        Write-Warning "No se encontro Suricata en: $suricataDir"
    }

    # ---------------------------------------------------------
    # PASO 3: CONFIGURAR WAZUH-AGENT Y REINICIAR (CMD)
    # ---------------------------------------------------------
    Write-Host "`n--- Paso 3: Configurar Wazuh Agent ---" -ForegroundColor Magenta

    if (-not (Test-Path $wazuhConfigPath)) {
        Throw "No se encontro ossec.conf en: $wazuhConfigPath"
    }

    $wazuhLines = [System.Collections.Generic.List[string]](Get-Content $wazuhConfigPath)

    $xmlBlock = @"
  <localfile>
    <log_format>json</log_format>
    <location>C:\Program Files\Suricata\log\eve.json</location>
  </localfile>
"@
    $targetLine = 213 
    $targetIndex = $targetLine 
    $needsRestart = $false

    # Lógica de inserción
    if ($wazuhLines.Count -ge $targetLine) {
        $alreadyExists = $false
        for($k = $targetIndex; $k -lt ($targetIndex + 5); $k++) {
            if ($k -lt $wazuhLines.Count -and $wazuhLines[$k] -match "eve.json") {
                $alreadyExists = $true
            }
        }

        if (-not $alreadyExists) {
            Write-Host "-> Insertando configuracion en la linea 214..." -ForegroundColor Yellow
            $wazuhLines.Insert($targetIndex, $xmlBlock)
            $wazuhLines | Set-Content $wazuhConfigPath -Encoding ASCII
            Write-Host "-> Configuracion guardada." -ForegroundColor Green
            $needsRestart = $true
        } else {
            Write-Warning "La configuracion ya existia. Se forzara reinicio de todas formas."
            $needsRestart = $true
        }
    } else {
        Write-Warning "Archivo corto. Agregando al final."
        $wazuhLines.Add($xmlBlock)
        $wazuhLines | Set-Content $wazuhConfigPath -Encoding ASCII
        $needsRestart = $true
    }

    # REINICIO DEL SERVICIO VÍA CMD
    if ($needsRestart) {
        Write-Host "`n--- Reiniciando Wazuh (CMD) ---" -ForegroundColor Magenta
        
        Write-Host "Ejecutando: net stop Wazuh" -ForegroundColor Yellow
        cmd.exe /c "net stop Wazuh"
        
        # Pequeña pausa para asegurar que el servicio bajó
        Start-Sleep -Seconds 2
        
        Write-Host "Ejecutando: net start Wazuh" -ForegroundColor Yellow
        cmd.exe /c "net start Wazuh"
        
        Write-Host "-> Comandos ejecutados." -ForegroundColor Green
    }

    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "   PROCESO FINALIZADO                         " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan

} catch {
    Write-Host "`n[ERROR CRITICO]" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# --- Configuración Inicial ---
$ErrorActionPreference = "Stop"
$taskName = "Suricata IDS"
$suricataExe = "C:\Program Files\Suricata\suricata.exe"
$suricataYaml = "C:\Program Files\Suricata\suricata.yaml"

# --- Función para verificar Administrador ---
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "   SCRIPT 4: CREAR TAREA PROGRAMADA (AUTO)    " -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# 1. Verificar Permisos
if (-not (Test-Administrator)) {
    Write-Host "[ERROR] Necesitas ejecutar como Administrador." -ForegroundColor Red
    Break
}

try {
    # ---------------------------------------------------------
    # PASO 1: OBTENER UUID (Necesario para los argumentos)
    # ---------------------------------------------------------
    Write-Host "`n--- Paso 1: Seleccion de Interfaz de Red ---" -ForegroundColor Magenta
    
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}

    if ($adapters.Count -eq 0) { Throw "No se encontraron adaptadores de red con IP activa." }

    Write-Host "Adaptadores encontrados:" -ForegroundColor Yellow
    $i = 0
    foreach ($nic in $adapters) {
        Write-Host "[$i] IP: $($nic.IPAddress[0]) | Desc: $($nic.Description)"
        Write-Host "    UUID: $($nic.SettingID)" -ForegroundColor Gray
        $i++
    }

    $selection = Read-Host "`n>> Selecciona el numero [0 - $($adapters.Count - 1)] del adaptador a usar"

    if ($selection -match "^\d+$" -and [int]$selection -lt $adapters.Count) {
        $selectedNic = $adapters[[int]$selection]
        $uuid = $selectedNic.SettingID
        Write-Host "-> UUID Detectada: $uuid" -ForegroundColor Green
    } else {
        Throw "Seleccion invalida."
    }

    # ---------------------------------------------------------
    # PASO 2: DEFINIR ARGUMENTOS
    # ---------------------------------------------------------
    Write-Host "`n--- Paso 2: Configurando Argumentos ---" -ForegroundColor Magenta

    # Construimos la cadena exacta de argumentos:
    # -c "Ruta al Yaml" -i \Device\NPF_{UUID}
    $arguments = "-c `"$suricataYaml`" -i \Device\NPF_$uuid"
    
    Write-Host "Ejecutable: $suricataExe" -ForegroundColor Gray
    Write-Host "Argumentos: $arguments" -ForegroundColor Gray

    # ---------------------------------------------------------
    # PASO 3: CREAR LA TAREA EN WINDOWS
    # ---------------------------------------------------------
    Write-Host "`n--- Paso 3: Registrando Tarea en Windows ---" -ForegroundColor Magenta

    # Verificar si ya existe y borrarla para evitar errores
    $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($taskExists) {
        Write-Host "-> La tarea '$taskName' ya existia. Borrandola para recrearla..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # A) La Acción (Qué ejecutar)
    $action = New-ScheduledTaskAction -Execute $suricataExe -Argument $arguments

    # B) El Desencadenador (Cuándo ejecutar -> Al inicio del sistema)
    $trigger = New-ScheduledTaskTrigger -AtStartup

    # C) El Principal (Quién ejecuta -> SYSTEM con maximos privilegios)
    # Usamos SYSTEM para que arranque antes de que el usuario haga login.
    $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # D) Configuracion extra (Para que no se detenga si se va la luz o es laptop)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0

    # E) Registrar Tarea
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null

    Write-Host "-> Tarea '$taskName' creada exitosamente." -ForegroundColor Green


    # ---------------------------------------------------------
    # PASO 4: ABRIR EL PROGRAMADOR DE TAREAS (VISUAL)
    # ---------------------------------------------------------
    Write-Host "`n--- Paso 4: Abriendo Interfaz Visual ---" -ForegroundColor Magenta
    Write-Host "Abriendo el Programador de tareas para que verifiques..." -ForegroundColor Yellow
    Start-Process "taskschd.msc"

    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "   PROCESO FINALIZADO                         " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "Nota: En el Programador, busca la tarea 'Suricata IDS' en la Biblioteca principal." -ForegroundColor Gray

} catch {
    Write-Host "`n[ERROR CRITICO]" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
