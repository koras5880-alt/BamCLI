<#
.SYNOPSIS
    FSChecker - Forensic System Collector
.DESCRIPTION
    Сбор системной информации и артефактов для анализа
.NOTES
    Developers: fracturesdecora, net_dobra, op4ox
    Version: 1.0
#>

Clear-Host
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# ============================================
# БАННЕР
# ============================================
function Show-Banner {
    $banner = @"
    ╔══════════════════════════════════════════════════════════════╗
    ║  ███████╗ ██████╗ ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗    ║
    ║  ██╔════╝██╔════╝██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝    ║
    ║  █████╗  ██║     ██║     ███████║█████╗  ██║     █████╔╝     ║
    ║  ██╔══╝  ██║     ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗     ║
    ║  ██║     ╚██████╗╚██████╗██║  ██║███████╗╚██████╗██║  ██╗    ║
    ║  ╚═╝      ╚═════╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝    ║
    ╠══════════════════════════════════════════════════════════════╣
    ║         Forensic System Checker v1.0                         ║
    ║         Developers: fracturesdecora | net_dobra | op4ox      ║
    ╚══════════════════════════════════════════════════════════════╝
"@
    Write-Host $banner -ForegroundColor Cyan
    Write-Host
}

# ============================================
# ПРОВЕРКА ПРАВ АДМИНИСТРАТОРА
# ============================================
function Test-AdminRights {
    $currentPrincipal = [Security.Principal.WindowsPrincipal]::GetCurrent([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "[!] ОШИБКА: Требуются права администратора!" -ForegroundColor Red
        Write-Host "[!] Запустите PowerShell от имени администратора" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "[+] Права администратора: ОК" -ForegroundColor Green
}

# ============================================
# СОЗДАНИЕ РАБОЧЕЙ ДИРЕКТОРИИ
# ============================================
function Initialize-WorkDirectory {
    param([string]$Path = "C:\FSChecker")
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "[+] Создана рабочая директория: $Path" -ForegroundColor Green
    } else {
        Write-Host "[+] Рабочая директория: $Path" -ForegroundColor Green
    }
    
    Set-Location $Path
    return $Path
}

# ============================================
# ОСТАНОВКА МЕШАЮЩИХ ПРОЦЕССОВ
# ============================================
function Stop-InterferingProcesses {
    Write-Host "[*] Остановка мешающих процессов..." -ForegroundColor Yellow
    
    $processesToStop = @("obs64", "obs32", "obs", "ayugram", "telegram", 
                         "nvcontainer", "gamebar", "wallpaper32", "wallpaper64", 
                         "steam", "lively")
    
    $stopped = @()
    foreach ($proc in $processesToStop) {
        $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
        if ($running) {
            $running | Stop-Process -Force -ErrorAction SilentlyContinue
            $stopped += $proc
        }
    }
    
    if ($stopped.Count -gt 0) {
        Write-Host "[+] Остановлены процессы: $($stopped -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "[!] Нет процессов для остановки" -ForegroundColor Gray
    }
}

# ============================================
# ОСТАНОВКА СЛУЖБЫ БУФЕРА ОБМЕНА
# ============================================
function Stop-ClipboardService {
    Write-Host "[*] Остановка службы истории буфера обмена..." -ForegroundColor Yellow
    
    $clipService = Get-Service -Name "*cbdhsvc*" -ErrorAction SilentlyContinue
    if ($clipService) {
        Stop-Service -Name $clipService.Name -Force -ErrorAction SilentlyContinue
        Write-Host "[+] Служба буфера обмена остановлена" -ForegroundColor Green
    } else {
        Write-Host "[!] Служба буфера обмена не найдена" -ForegroundColor Gray
    }
}

# ============================================
# ГЛАВНАЯ ФУНКЦИЯ
# ============================================
function Main {
    Show-Banner
    Test-AdminRights
    $workDir = Initialize-WorkDirectory -Path "C:\FSChecker"
    Stop-InterferingProcesses
    Stop-ClipboardService
    
    Write-Host "`n[+] FSChecker готов к работе!" -ForegroundColor Green
    Write-Host "[+] Рабочая директория: $workDir" -ForegroundColor Cyan
    Write-Host "[+] Время запуска: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" -ForegroundColor Cyan
    
    # TODO: Добавить остальные функции
}

# ============================================
# ЗАПУСК
# ============================================
Main
