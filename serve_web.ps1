# May chu web noi bo chi phuc vu file HTML tren http://127.0.0.1:8080
# Khong tai file .exe, khong can quyen Admin.
# Can thiet cho Tab 2 (Android WebUSB). Tab 1 (Chieu QR/Ma vach) co the mo truc tiep file HTML cung duoc.

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$htmlFile = Join-Path $scriptDir "barcode_scanner_dual_mode.html"

if (-not (Test-Path $htmlFile)) {
    Write-Host "Khong tim thay file barcode_scanner_dual_mode.html!" -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    exit 1
}

$port = 8080
$listener = $null
for ($p = 8080; $p -le 8095; $p++) {
    try {
        $l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $p)
        $l.Start()
        $listener = $l
        $port = $p
        break
    } catch { }
}

if ($null -eq $listener) {
    Write-Host "Khong mo duoc cong 8080-8095." -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    exit 1
}

$url = "http://127.0.0.1:$port/"
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "  TRAM BAN MA VACH DA CHE DO (QR/CODE128 + WEBUSB ADB)  " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Dang mo trinh duyet tai: $url" -ForegroundColor Green
Write-Host "Giu cua so nay mo khi dung Tab 2 (WebUSB). Nhan Ctrl+C de dong." -ForegroundColor DarkGray

Start-Process $url

try {
    while ($true) {
        if (-not $listener.Pending()) {
            Start-Sleep -Milliseconds 30
            continue
        }
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8, $false, 4096, $true)
            $reqLine = $reader.ReadLine()
            while ($true) {
                $h = $reader.ReadLine()
                if ([string]::IsNullOrEmpty($h)) { break }
            }

            $bodyBytes = [System.IO.File]::ReadAllBytes($htmlFile)
            $headers = @(
                "HTTP/1.1 200 OK",
                "Content-Type: text/html; charset=utf-8",
                "Cache-Control: no-store",
                "Content-Length: $($bodyBytes.Length)",
                "Connection: close",
                "",
                ""
            ) -join "`r`n"
            $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($headers)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($bodyBytes, 0, $bodyBytes.Length)
            $stream.Flush()
        } catch {
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
}
