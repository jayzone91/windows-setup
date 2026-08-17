function Read-ThunderbirdMarionettePacket {
    param(
        [Parameter(Mandatory)]
        [System.Net.Sockets.NetworkStream] $Stream
    )

    $lengthText = ""

    while ($true) {
        $byte = $Stream.ReadByte()

        if ($byte -eq -1) {
            throw "Thunderbird Marionette-Verbindung wurde geschlossen."
        }

        $char = [char] $byte

        if ($char -eq ":") {
            break
        }

        $lengthText += $char
    }

    $length = [int] $lengthText
    $buffer = [byte[]]::new($length)
    $offset = 0

    while ($offset -lt $length) {
        $read = $Stream.Read($buffer, $offset, $length - $offset)

        if ($read -le 0) {
            throw "Thunderbird Marionette-Paket wurde unvollständig übertragen."
        }

        $offset += $read
    }

    return [Text.Encoding]::UTF8.GetString($buffer) | ConvertFrom-Json
}


function Send-ThunderbirdMarionettePacket {
    param(
        [Parameter(Mandatory)]
        [System.Net.Sockets.NetworkStream] $Stream,

        [Parameter(Mandatory)]
        $Packet
    )

    $json = $Packet | ConvertTo-Json -Compress -Depth 40
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $prefix = [Text.Encoding]::ASCII.GetBytes("$($bytes.Length):")

    $Stream.Write($prefix, 0, $prefix.Length)
    $Stream.Write($bytes, 0, $bytes.Length)
    $Stream.Flush()
}


function Get-ThunderbirdExecutablePath {
    $appPathKey =
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\thunderbird.exe"

    if (-not (Test-Path -LiteralPath $appPathKey)) {
        return $null
    }

    $path = (Get-Item -LiteralPath $appPathKey).GetValue("")

    if (
        [string]::IsNullOrWhiteSpace($path) -or
        -not (Test-Path -LiteralPath $path -PathType Leaf)
    ) {
        return $null
    }

    return $path
}


function Get-ThunderbirdMailDesiredState {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $secretsPath = Join-Path $RepositoryPath "secrets\mail.sops.json"

    if (-not (Test-Path -LiteralPath $secretsPath -PathType Leaf)) {
        return $null
    }

    if (-not (Get-Command sops -ErrorAction SilentlyContinue)) {
        throw "sops ist für die Thunderbird-Provisionierung nicht verfügbar."
    }

    $decrypted = @(
        & sops decrypt `
            --input-type json `
            --output-type json `
            $secretsPath `
            2>&1
    )

    if ($LASTEXITCODE -ne 0) {
        throw "Mail-Secrets konnten nicht entschlüsselt werden."
    }

    $json = $decrypted -join [Environment]::NewLine

    try {
        $data = $json | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }
    finally {
        $decrypted = $null
    }

    if (
        -not $data.ContainsKey("mail") -or
        -not $data.mail.ContainsKey("accounts")
    ) {
        throw "Ungültige Mail-Secrets-Struktur."
    }

    $accounts = @()
    $missingSignatures = $false
    $signatureDirectory = Join-Path $env:APPDATA "Thunderbird\Signatures"

    foreach ($entry in $data.mail.accounts.GetEnumerator()) {
        $account = $entry.Value
        $type = [string] $account.type

        if ($type -notin @("imap", "gmail", "exchange")) {
            throw "Nicht unterstützter Mail-Account-Typ: $type"
        }

        $normalized = [ordered]@{
            id           = [string] $entry.Key
            type         = $type
            display_name = [string] $account.display_name
            sender_name  = if ($account.ContainsKey("sender_name")) {
                [string] $account.sender_name
            }
            else {
                ""
            }
            email        = [string] $account.email
            username     = [string] $account.username
            password     = if ($account.ContainsKey("password")) {
                [string] $account.password
            }
            else {
                ""
            }
            signature    = if ($account.ContainsKey("signature")) {
                [string] $account.signature
            }
            else {
                ""
            }
            signature_path = $null
        }

        if (-not [string]::IsNullOrWhiteSpace($normalized.signature)) {
            $signaturePath = Join-Path $signatureDirectory $normalized.signature

            if (Test-Path -LiteralPath $signaturePath -PathType Leaf) {
                $normalized.signature_path = $signaturePath
            }
            else {
                $missingSignatures = $true
                Write-Warning (
                    "Thunderbird-Signatur fehlt für Account '{0}': {1}" `
                        -f $entry.Key, $signaturePath
                )
            }
        }

        switch ($type) {
            "imap" {
                foreach ($sectionName in @("incoming", "outgoing")) {
                    if (-not $account.ContainsKey($sectionName)) {
                        throw "Account '$($entry.Key)' benötigt '$sectionName'."
                    }
                }

                $normalized.incoming = $account.incoming
                $normalized.outgoing = $account.outgoing
            }

            "gmail" {
                $normalized.incoming = [ordered]@{
                    host     = "imap.gmail.com"
                    port     = 993
                    security = "ssl"
                }
                $normalized.outgoing = [ordered]@{
                    host     = "smtp.gmail.com"
                    port     = 465
                    security = "ssl"
                    username = $normalized.username
                }
            }

            "exchange" {
                if (-not $account.ContainsKey("ews_url")) {
                    throw "Exchange-Account '$($entry.Key)' benötigt 'ews_url'."
                }

                $normalized.ews_url = [string] $account.ews_url
                $normalized.auth = if ($account.ContainsKey("auth")) {
                    [string] $account.auth
                }
                else {
                    "ntlm"
                }
                $normalized.domain = if ($account.ContainsKey("domain")) {
                    [string] $account.domain
                }
                else {
                    ""
                }
            }
        }

        $accounts += $normalized
    }

    $desiredJson = $accounts | ConvertTo-Json -Compress -Depth 20
    $hashBytes = [Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($desiredJson)
    )
    $hash = [Convert]::ToHexString($hashBytes).ToLowerInvariant()

    $data = $null
    $json = $null

    return [pscustomobject]@{
        Accounts          = $accounts
        Hash              = $hash
        MissingSignatures = $missingSignatures
    }
}
