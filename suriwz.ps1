<#
.SYNOPSIS
    Instalador y configurador automatizado de Suricata + Npcap + Wazuh Agent.
.DESCRIPTION
    Este script automatiza el despliegue de un sensor de red Suricata en Windows,
    lo configura con las reglas de Emerging Threats, lo enlaza mediante un adaptador
    de red (UUID), inyecta los logs eve.json de forma segura en el XML de Wazuh,
    y establece la persistencia como Tarea Programada ejecutada por SYSTEM.
#>

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue" 

# --- ARTE ASCII ---
$asciiArt = @"
         . ..:--::::-----:..          . .                                    .   .                  
  .      ..-*%@%#*-:::-------.                                                                      
  .   ...:-%%*%%#*+:::--++*+==.                 . .                             .                   
=*#+......%%@@%%#**-:-*##%%#*==.   .        .                                    .                  
#%%-....:-%%%%%##*=---%%%%%*#==.        .                .                     .    ..       ..  .  
-#=.::::.:#*-:::::::--+*%%###===.                            .   .. .                               
 .:...:.-.::::::::::::=%%%%#===..          .        ..                 .         .    . .   .       
  .:-:..:.:::.:::::::-+%%%#===..            .  .                                                    
    .:.-:::...::::::::-##=====+:.. .                          .       .  .                 .        
    .....--::::--------======+===-..                    .  .         .  .                    . .    
.      ...  .....:::::::::-=====+==+*+-:......    ..  .              .      .   .         .         
          .     ..:.......:::-==---++==+*+=+**+=-.....             .        .                       
         .       ..:.......:::-:::---==+==+*+=+*+==+**=:.                                   .      .
    .           .   .:......::=:::----====*====+==++==+*+==..               .       .               
                .    .:......:=::::----==========+===++==**+=-.   . .     . .    . .    .      .    
            .         .:......::::::---=================+==+**+=..     .      .              .      
               .      ..:.....:.::::---=======================++=-.                       .       . 
                   .   ..:.....:::::----========-:::::::::----=+***.               . .              
        .               .......:::::---======-::::::::::::::---=====:. ...                          
        .    ..    .      .:....-:::---====-:::::::::::::::::---=+***:.           ..    .  .        
  .                        .:..:::::---===:::::::::::::::::::--======+..            .     .         
                          . ..-:-::-----:-::::::::::::::::::::---=====+.                 .      .   
           ..   .  .          .::::---=::-::::::::::::::::::::---==+***-. .          .   .          
           .                   ..:---=:::-:::::::::::::::::::-----=====+.                .          
               .    .   .  .   ::----::.::::::::::::::::::::::-----=====:.                          
    .      .   .        .  .  .---=::...:::::::::::::::::::::------======.         .          .    .
        .                     .-:--:....:::::::::::::::::::::------======..                         
      .                        .:--:.....::::::::::::::::::::------=====+:.    .       .            
     .  .   .   .    .         .--=-......::::::::::::::::::-------===+*+=.                         
                .   .    . ..   .-=++:.....:::::::::::::::---------=+=====..                        
                         .       ..-...:..:::::-::::::::---------===+======:..             .        
                          .             ...:------------------====++=========-:.......              
                .                      ..-======================+++===================--:...........
           .                   .       ..---------===--=======.:=+++================================
"@

# --- RUTAS Y VARIABLES ---
$urlSuricata = "https://www.openinfosecfoundation.org/download/windows/Suricata-7.0.14-1-64bit.msi"
$urlNpcap = "https://npcap.com/dist/npcap-1.85.exe"
$rulesUrl = "https://rules.emergingthreats.net/open/suricata-7.0.3/emerging-all.rules"

$tempDir = $env:TEMP
$fileSuricata = "$tempDir\suricata_installer.msi"
$fileNpcap = "$tempDir\npcap_installer.exe"

$suricataBaseDir = "C:\Program Files\Suricata"
$rulesDir = "$suricataBaseDir\rules"
$rulesFile = "$rulesDir\emerging-all.rules"
$suricataYaml = "$suricataBaseDir\suricata.yaml"
$suricataExe = "$suricataBaseDir\suricata.exe"
$taskName = "Suricata IDS"

# --- FUNCION ADMINISTRADOR ---
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Host $asciiArt -ForegroundColor Cyan
Write-Host "`n=========================================================================" -ForegroundColor Cyan
Write-Host "   DEPLOYMENT AUTOMATIZADO: SURICATA + WAZUH by Jechua" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

if (-not (Test-Administrator)) {
    Write-Host "`n[ERROR] Este script necesita privilegios elevados. Ejecuta PowerShell como Administrador." -ForegroundColor Red
    Break
}

try {
    # =========================================================
    # FASE 1: DESCARGA E INSTALACIÓN
    # =========================================================
    Write-Host "`n[FASE 1] INSTALACION DE DEPENDENCIAS" -ForegroundColor Magenta
    
    # 1.1 NPCAP
    Write-Host "[*] Descargando Npcap..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $urlNpcap -OutFile $fileNpcap -UseBasicParsing
    Write-Host "    [ATENCION] Se abrira el instalador de Npcap. Por favor, instalalo manualmente (Siguiente -> Finalizar)." -ForegroundColor Cyan
    $procNpcap = Start-Process -FilePath $fileNpcap -Wait -PassThru
    Write-Host "    -> Npcap instalado." -ForegroundColor Green

    # 1.2 SURICATA
    Write-Host "[*] Descargando Suricata..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $urlSuricata -OutFile $fileSuricata -UseBasicParsing
    Write-Host "[*] Instalando Suricata en modo silencioso..." -ForegroundColor Yellow
    $procSuricata = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$fileSuricata`" /qn /norestart" -Wait -PassThru
    
    if ($procSuricata.ExitCode -eq 0) {
        Write-Host "    -> Suricata instalado correctamente." -ForegroundColor Green
    } else {
        Throw "Error al instalar Suricata. Codigo de salida: $($procSuricata.ExitCode)"
    }


    # =========================================================
    # FASE 2: IDENTIFICACIÓN DE RED (UUID)
    # =========================================================
    Write-Host "`n[FASE 2] CONFIGURACION DE INTERFAZ DE RED" -ForegroundColor Magenta
    
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq $true}
    if ($adapters.Count -eq 0) { Throw "No se encontraron adaptadores de red con IP activa." }

    Write-Host "Adaptadores encontrados:" -ForegroundColor Yellow
    $i = 0
    foreach ($nic in $adapters) {
        Write-Host "  [$i] IP: $($nic.IPAddress[0]) | Desc: $($nic.Description)"
        $i++
    }

    $selection = Read-Host "`n>> Selecciona el numero [0 - $($adapters.Count - 1)] del adaptador a monitorear"
    if ($selection -match "^\d+$" -and [int]$selection -lt $adapters.Count) {
        $selectedNic = $adapters[[int]$selection]
        $uuid = $selectedNic.SettingID
        $userIP = $selectedNic.IPAddress[0]
        Write-Host "    -> Interfaz seleccionada: $($selectedNic.Description)" -ForegroundColor Green
        Write-Host "    -> UUID ($uuid) y HOME_NET ($userIP) capturados." -ForegroundColor Green
    } else {
        Throw "Seleccion de adaptador invalida."
    }


    # =========================================================
    # FASE 3: DESCARGA DE REGLAS Y CONFIGURACIÓN YAML (MEJORADO CON REGEX)
    # =========================================================
    Write-Host "`n[FASE 3] CONFIGURACION DE SURICATA.YAML Y REGLAS" -ForegroundColor Magenta
    
    if (-not (Test-Path $rulesDir)) { New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null }
    
    Write-Host "[*] Descargando emerging-all.rules..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $rulesUrl -OutFile $rulesFile -UseBasicParsing
    
    if (-not (Test-Path $suricataYaml)) { Throw "No se encontro suricata.yaml en $suricataYaml" }
    
    Write-Host "[*] Editando suricata.yaml usando Expresiones Regulares..." -ForegroundColor Yellow
    $yamlContent = Get-Content $suricataYaml

    # 3.1 Expresiones Regulares para variables de red
    $yamlContent = $yamlContent -replace '(?m)^\s*HOME_NET:.*', "    HOME_NET: `"$userIP`""
    $yamlContent = $yamlContent -replace '(?m)^\s*#?\s*EXTERNAL_NET:.*', "    EXTERNAL_NET: `"any`""

    # 3.2 Buscar seccion rule-files, inyectar nuestra regla y comentar las demas
    $inRuleFilesSection = $false
    $newYaml = foreach ($line in $yamlContent) {
        # Si entramos a la seccion rule-files:
        if ($line -match '^\s*rule-files:') {
            $inRuleFilesSection = $true
            $line # Imprimimos la cabecera
            " - emerging-all.rules" # Inyectamos nuestra regla inmediatamente
            continue
        }
        
        # Si encontramos una linea que no es regla ni comentario, salimos de la seccion
        if ($inRuleFilesSection -and $line -match '^\S') {
            $inRuleFilesSection = $false
        }

        # Si estamos dentro de la seccion y encontramos un archivo .rules (que no sea el nuestro)
        if ($inRuleFilesSection -and $line -match '^\s+-\s+.*\.rules' -and $line -notmatch 'emerging-all\.rules') {
            "# $line" # Lo comentamos
        } else {
            # Si ya existia nuestra regla más abajo por accidente, la ignoramos para no duplicar
            if ($inRuleFilesSection -and $line -match 'emerging-all\.rules') { continue }
            $line
        }
    }
    
    $newYaml | Set-Content $suricataYaml -Encoding UTF8
    Write-Host "    -> suricata.yaml configurado con exito." -ForegroundColor Green


    # =========================================================
    # FASE 4: INTEGRACIÓN CON WAZUH (MEJORADO CON [XML])
    # =========================================================
    Write-Host "`n[FASE 4] INTEGRACION CON WAZUH AGENT" -ForegroundColor Magenta
    
    # Intentar buscar la ruta de Wazuh en el registro, si no, usar por defecto
    $wazuhPath = "${env:ProgramFiles(x86)}\ossec-agent"
    $regPath = "HKLM:\SOFTWARE\ossec"
    if (Test-Path $regPath) {
        $wazuhPath = (Get-ItemProperty -Path $regPath -Name "Install_Dir" -ErrorAction SilentlyContinue).Install_Dir
    }
    $wazuhConfigPath = "$wazuhPath\ossec.conf"

    if (-not (Test-Path $wazuhConfigPath)) { Throw "No se encontro ossec.conf en: $wazuhConfigPath" }
    
    Write-Host "[*] Parseando ossec.conf como XML..." -ForegroundColor Yellow
    
    # Cargamos el archivo como objeto XML real
    [xml]$ossecXml = Get-Content $wazuhConfigPath
    
    # Buscamos si ya existe el log de suricata
    $suricataLogPath = "C:\Program Files\Suricata\log\eve.json"
    $alreadyExists = $ossecXml.ossec_config.localfile | Where-Object { $_.location -eq $suricataLogPath }

    if (-not $alreadyExists) {
        Write-Host "    -> Inyectando nuevo nodo <localfile> para Suricata..." -ForegroundColor Yellow
        $newLocalFile = $ossecXml.CreateElement("localfile")
        
        $logFormat = $ossecXml.CreateElement("log_format")
        $logFormat.InnerText = "json"
        
        $location = $ossecXml.CreateElement("location")
        $location.InnerText = $suricataLogPath

        $newLocalFile.AppendChild($logFormat) | Out-Null
        $newLocalFile.AppendChild($location) | Out-Null
        
        $ossecXml.ossec_config.AppendChild($newLocalFile) | Out-Null
        $ossecXml.Save($wazuhConfigPath)
        Write-Host "    -> XML actualizado y guardado." -ForegroundColor Green
    } else {
        Write-Host "    -> El bloque de Suricata ya existia en el XML. Se omite inyeccion." -ForegroundColor Cyan
    }

    Write-Host "[*] Reiniciando servicio de Wazuh (Cmdlet Nativo)..." -ForegroundColor Yellow
    # Reiniciamos el servicio usando PowerShell nativo en lugar de CMD
    Restart-Service -Name "WazuhSvc", "Wazuh" -Force -ErrorAction SilentlyContinue
    Write-Host "    -> Servicio Wazuh reiniciado." -ForegroundColor Green


    # =========================================================
    # FASE 5: PERSISTENCIA - TAREA PROGRAMADA
    # =========================================================
    Write-Host "`n[FASE 5] CONFIGURACION DE PERSISTENCIA (TAREA PROGRAMADA)" -ForegroundColor Magenta
    
    $arguments = "-c `"$suricataYaml`" -i \Device\NPF_$uuid"
    
    $taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($taskExists) {
        Write-Host "    -> Borrando tarea anterior '$taskName'..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    $action = New-ScheduledTaskAction -Execute $suricataExe -Argument $arguments
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings | Out-Null
    
    Write-Host "    -> Tarea Programada creada. Suricata arrancara de forma invisible con el sistema." -ForegroundColor Green

    # Inicializamos Suricata ahora mismo lanzando la tarea que acabamos de crear (sin abrir ventanas extra)
    Write-Host "[*] Iniciando el motor de Suricata en background..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName $taskName
    Start-Sleep -Seconds 3


    # =========================================================
    # FASE 6: LIMPIEZA Y FINALIZACIÓN
    # =========================================================
    Write-Host "`n[FASE 6] LIMPIEZA" -ForegroundColor Magenta
    Remove-Item -Path $fileSuricata, $fileNpcap -ErrorAction SilentlyContinue
    Write-Host "    -> Instaladores temporales borrados." -ForegroundColor Green

    Write-Host "`n=========================================================================" -ForegroundColor Cyan
    Write-Host "   DESPLIEGUE FINALIZADO CON EXITO" -ForegroundColor Cyan
    Write-Host "=========================================================================" -ForegroundColor Cyan
    Write-Host "Para verificar los logs, puedes revisar 'C:\Program Files\Suricata\log\eve.json'." -ForegroundColor Gray
    Write-Host "Abriendo el Programador de tareas para verificacion visual..." -ForegroundColor Gray
    Start-Process "taskschd.msc"

} catch {
    Write-Host "`n[ERROR CRITICO DURANTE LA EJECUCION]" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Linea del error: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
}
