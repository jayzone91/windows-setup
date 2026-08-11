[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$targetModel = "g502x_plus"
$uri = [Uri] "ws://127.0.0.1:9010"

function Receive-WebSocketText {
    param(
        [Parameter(Mandatory)]
        [System.Net.WebSockets.ClientWebSocket] $Socket,

        [Parameter(Mandatory)]
        [System.Threading.CancellationToken] $CancellationToken
    )

    $buffer = New-Object byte[] 65536
    $stream = [System.IO.MemoryStream]::new()

    try {
        do {
            $segment = [ArraySegment[byte]]::new($buffer)

            $result = $Socket.ReceiveAsync(
                $segment,
                $CancellationToken
            ).GetAwaiter().GetResult()

            if (
                $result.MessageType -eq
                [System.Net.WebSockets.WebSocketMessageType]::Close
            ) {
                throw "G HUB hat die WebSocket-Verbindung geschlossen."
            }

            $stream.Write(
                $buffer,
                0,
                $result.Count
            )
        }
        while (-not $result.EndOfMessage)

        return [System.Text.Encoding]::UTF8.GetString(
            $stream.ToArray()
        )
    }
    finally {
        $stream.Dispose()
    }
}

function Send-GhubRequest {
    param(
        [Parameter(Mandatory)]
        [System.Net.WebSockets.ClientWebSocket] $Socket,

        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [System.Threading.CancellationToken] $CancellationToken
    )

    $request = @{
        msgId = ""
        verb  = "GET"
        path  = $Path
    } | ConvertTo-Json -Compress

    $bytes = [System.Text.Encoding]::UTF8.GetBytes(
        $request
    )

    $Socket.SendAsync(
        [ArraySegment[byte]]::new($bytes),
        [System.Net.WebSockets.WebSocketMessageType]::Text,
        $true,
        $CancellationToken
    ).GetAwaiter().GetResult() | Out-Null
}

function Receive-GhubPath {
    param(
        [Parameter(Mandatory)]
        [System.Net.WebSockets.ClientWebSocket] $Socket,

        [Parameter(Mandatory)]
        [string] $ExpectedPath,

        [Parameter(Mandatory)]
        [System.Threading.CancellationToken] $CancellationToken
    )

    for ($index = 0; $index -lt 20; $index++) {
        $text = Receive-WebSocketText `
            -Socket $Socket `
            -CancellationToken $CancellationToken

        $message = $text | ConvertFrom-Json

        if ($message.path -eq $ExpectedPath) {
            if ($message.result.code -ne "SUCCESS") {
                throw (
                    "G-HUB-Anfrage '{0}' fehlgeschlagen: {1}"
                ) -f $ExpectedPath, $message.result.what
            }

            return $message
        }
    }

    throw (
        "Keine G-HUB-Antwort für '{0}' erhalten."
    ) -f $ExpectedPath
}

$socket = [System.Net.WebSockets.ClientWebSocket]::new()
$cts = [System.Threading.CancellationTokenSource]::new(
    [TimeSpan]::FromSeconds(5)
)

try {
    $socket.Options.AddSubProtocol("json")
    $socket.Options.SetRequestHeader(
        "Origin",
        "file://"
    )

    $socket.ConnectAsync(
        $uri,
        $cts.Token
    ).GetAwaiter().GetResult() | Out-Null

    Send-GhubRequest `
        -Socket $socket `
        -Path "/devices/list" `
        -CancellationToken $cts.Token

    $deviceMessage = Receive-GhubPath `
        -Socket $socket `
        -ExpectedPath "/devices/list" `
        -CancellationToken $cts.Token

    $device = @(
        $deviceMessage.payload.deviceInfos |
        Where-Object {
            $_.deviceModel -eq $targetModel -and
            $_.capabilities.hasBatteryStatus -eq $true
        }
    ) |
    Select-Object -First 1

    if (-not $device) {
        exit 0
    }

    $batteryPath = "/battery/$($device.id)/state"

    Send-GhubRequest `
        -Socket $socket `
        -Path $batteryPath `
        -CancellationToken $cts.Token

    $batteryMessage = Receive-GhubPath `
        -Socket $socket `
        -ExpectedPath $batteryPath `
        -CancellationToken $cts.Token

    $usbConnected = $false

    if (
        $device.connectionType -in @(
            "WIRED",
            "USB"
        )
    ) {
        $usbConnected = $true
    }

    if (-not $usbConnected) {
        $usbConnected = @(
            $device.activeInterfaces |
            Where-Object {
                $_.path -match '(?i)vid_046d&pid_c095'
            }
        ).Count -gt 0
    }

    if (
        -not $usbConnected -and
        $device.path -match '(?i)vid_046d&pid_c095'
    ) {
        $usbConnected = $true
    }

    [ordered] @{
        device        = $device.extendedDisplayName
        percentage    = [int] [Math]::Round(
            [double] $batteryMessage.payload.percentage
        )
        charging      = [bool] $batteryMessage.payload.charging
        fullyCharged  = [bool] $batteryMessage.payload.fullyCharged
        criticalLevel = [bool] $batteryMessage.payload.criticalLevel
        usbConnected  = [bool] $usbConnected
    } |
    ConvertTo-Json -Compress
}
finally {
    if (
        $socket.State -eq
        [System.Net.WebSockets.WebSocketState]::Open
    ) {
        try {
            $socket.CloseAsync(
                [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,
                "complete",
                [System.Threading.CancellationToken]::None
            ).GetAwaiter().GetResult() | Out-Null
        }
        catch {
            Write-Verbose (
                "G-HUB-WebSocket konnte beim Cleanup nicht sauber geschlossen werden: {0}" -f
                $_.Exception.Message
            )
        }
    }

    $cts.Dispose()
    $socket.Dispose()
}