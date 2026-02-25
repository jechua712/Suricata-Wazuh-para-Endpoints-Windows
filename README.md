# Suricata & Wazuh Windows Auto-Deploy

**Suricata & Wazuh Windows Auto-Deploy** es un script desarrollado en PowerShell que automatiza por completo la instalación, configuración e integración de un sensor de red Suricata con un agente de Wazuh en endpoints de Windows. Está diseñado para facilitar el despliegue a escala en arquitecturas de ciberseguridad defensiva (Blue Team) y entornos corporativos.

> ATENCION: Este script modifica la configuración de red y las tareas programadas del sistema. Se recomienda probarlo primero en un entorno de laboratorio o staging.

---

## Caracteristicas

* Descarga e instalación automática de dependencias (Suricata y Npcap).
* Detección interactiva de adaptadores de red y extracción automática del UUID.
* Descarga de reglas actualizadas (Emerging Threats).
* Edición automática y segura de archivos de configuración:
  * Modificación de `suricata.yaml` mediante Expresiones Regulares (Regex) para definir variables de red y reglas.
  * Inyección nativa de nodos XML en `ossec.conf` para el reenvío de logs (eve.json) hacia el SIEM.
* Configuración de persistencia nativa creando una Tarea Programada ejecutada con privilegios máximos (NT AUTHORITY\SYSTEM).
* Reinicio automático de servicios utilizando cmdlets nativos de PowerShell.

---

## Captura de Pantalla
![Script en ejecucion](images/screenshot.jpg)

---

## Requisitos Previos

* Sistema operativo Windows (Probado en Windows 10/11 y Windows Server).
* PowerShell 5.1 o superior.
* Wazuh Agent previamente instalado en el sistema.
* Privilegios de Administrador local.

---

## Instalacion y Uso

1. Clona el repositorio en el equipo Windows objetivo:

```powershell
git clone [https://github.com/jechua712/Suricata-Wazuh-Windows.git](https://github.com/jechua712/Suricata-Wazuh-Windows.git)
