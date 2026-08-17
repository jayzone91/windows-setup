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


function Initialize-ThunderbirdMailAccounts {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Thunderbird Mailkonten"
    Write-Host "========================================"

    $thunderbirdPath = Get-ThunderbirdExecutablePath

    if (-not $thunderbirdPath) {
        Write-Warning "Thunderbird wurde nicht gefunden."
        return
    }

    $desired = Get-ThunderbirdMailDesiredState -RepositoryPath $RepositoryPath

    if (-not $desired) {
        Write-Host "[SKIP] Keine Mail-Secrets vorhanden."
        return
    }

    $stateDirectory = Join-Path $RepositoryPath ".generated\state\thunderbird"
    $statePath = Join-Path $stateDirectory "accounts.sha256"

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $currentHash = (Get-Content -LiteralPath $statePath -Raw).Trim()

        if ($currentHash -ceq $desired.Hash) {
            Write-Host "[SKIP] Thunderbird-Mailkonten unverändert." `
                -ForegroundColor Green
            return
        }
    }

    if (Get-Process -Name thunderbird -ErrorAction SilentlyContinue) {
        Write-Warning (
            "Thunderbird läuft. Mail-Provisionierung wird auf den nächsten " +
            "Bootstrap verschoben."
        )
        return
    }

    $accountsJson = $desired.Accounts | ConvertTo-Json -Compress -Depth 20
    $client = $null
    $process = Start-Process `
        -FilePath $thunderbirdPath `
        -ArgumentList @("--marionette", "-remote-allow-system-access") `
        -PassThru

    try {
        $portReady = $false

        for ($attempt = 1; $attempt -le 40; $attempt++) {
            try {
                $testClient = [Net.Sockets.TcpClient]::new()
                $testClient.Connect("127.0.0.1", 2828)
                $testClient.Dispose()
                $portReady = $true
                break
            }
            catch {
                Start-Sleep -Milliseconds 500
            }
        }

        if (-not $portReady) {
            throw "Thunderbird Marionette konnte nicht gestartet werden."
        }

        $client = [Net.Sockets.TcpClient]::new()
        $client.Connect("127.0.0.1", 2828)
        $stream = $client.GetStream()

        $null = Read-ThunderbirdMarionettePacket -Stream $stream

        Send-ThunderbirdMarionettePacket -Stream $stream -Packet @(
            0
            1
            "WebDriver:NewSession"
            @{ capabilities = @{} }
        )
        $session = Read-ThunderbirdMarionettePacket -Stream $stream

        if ($session[2]) {
            throw $session[2].message
        }

        Send-ThunderbirdMarionettePacket -Stream $stream -Packet @(
            0
            2
            "Marionette:SetContext"
            @{ value = "chrome" }
        )
        $context = Read-ThunderbirdMarionettePacket -Stream $stream

        if ($context[2]) {
            throw $context[2].message
        }

        $script = @'
const done = arguments[arguments.length - 1];
const accounts = JSON.parse(arguments[0]);

(async () => {
  try {
    const { AccountConfig } = ChromeUtils.importESModule(
      "resource:///modules/accountcreation/AccountConfig.sys.mjs"
    );
    const { CreateInBackend } = ChromeUtils.importESModule(
      "resource:///modules/accountcreation/CreateInBackend.sys.mjs"
    );
    const { MailServices } = ChromeUtils.importESModule(
      "resource:///modules/MailServices.sys.mjs"
    );

    const socketType = value => {
      switch ((value ?? "").toLowerCase()) {
        case "none":
          return Ci.nsMsgSocketType.plain;
        case "starttls":
          return Ci.nsMsgSocketType.alwaysSTARTTLS;
        case "ssl":
          return Ci.nsMsgSocketType.SSL;
        default:
          throw new Error(`Unsupported security mode: ${value}`);
      }
    };

    const exchangeAuth = value => {
      switch ((value ?? "ntlm").toLowerCase()) {
        case "ntlm":
          return Ci.nsMsgAuthMethod.NTLM;
        case "password":
        case "basic":
          return Ci.nsMsgAuthMethod.passwordCleartext;
        case "oauth2":
          return Ci.nsMsgAuthMethod.OAuth2;
        default:
          throw new Error(`Unsupported Exchange auth mode: ${value}`);
      }
    };

    const setSignature = (identity, account) => {
      if (!account.signature) {
        identity.attachSignature = false;
        return;
      }

      if (!account.signature_path) {
        return;
      }

      const file = Cc["@mozilla.org/file/local;1"].createInstance(Ci.nsIFile);
      file.initWithPath(account.signature_path);
      identity.signature = file;
      identity.attachSignature = true;
      identity.htmlSigFormat = true;
    };

    const results = [];

    for (const accountData of accounts) {
      const expectedIncomingType =
        accountData.type === "exchange" ? "ews" : "imap";

      const existing = MailServices.accounts.accounts.find(account =>
        account.incomingServer?.type === expectedIncomingType &&
        account.identities.some(identity =>
          identity.email?.toLowerCase() === accountData.email.toLowerCase()
        )
      );

      if (existing) {
        existing.incomingServer.prettyName = accountData.display_name;
        const identity = existing.defaultIdentity;

        if (identity) {
          if (accountData.sender_name) {
            identity.fullName = accountData.sender_name;
          }
          setSignature(identity, accountData);
        }

        results.push({ id: accountData.id, state: "existing" });
        continue;
      }

      const config = new AccountConfig();
      config.displayName = accountData.display_name;
      config.identity.realname = accountData.sender_name ?? "";
      config.identity.emailAddress = accountData.email;

      if (accountData.type === "gmail") {
        config.incoming.type = "imap";
        config.incoming.hostname = accountData.incoming.host;
        config.incoming.port = accountData.incoming.port;
        config.incoming.username = accountData.username;
        config.incoming.socketType = Ci.nsMsgSocketType.SSL;
        config.incoming.auth = Ci.nsMsgAuthMethod.OAuth2;

        config.outgoing.type = "smtp";
        config.outgoing.hostname = accountData.outgoing.host;
        config.outgoing.port = accountData.outgoing.port;
        config.outgoing.username = accountData.username;
        config.outgoing.socketType = Ci.nsMsgSocketType.SSL;
        config.outgoing.auth = Ci.nsMsgAuthMethod.OAuth2;
        config.rememberPassword = false;
      } else if (accountData.type === "imap") {
        config.incoming.type = "imap";
        config.incoming.hostname = accountData.incoming.host;
        config.incoming.port = accountData.incoming.port;
        config.incoming.username = accountData.username;
        config.incoming.password = accountData.password;
        config.incoming.socketType = socketType(accountData.incoming.security);
        config.incoming.auth = Ci.nsMsgAuthMethod.passwordCleartext;

        config.outgoing.type = "smtp";
        config.outgoing.hostname = accountData.outgoing.host;
        config.outgoing.port = accountData.outgoing.port;
        config.outgoing.username =
          accountData.outgoing.username || accountData.username;
        config.outgoing.password = accountData.password;
        config.outgoing.socketType = socketType(accountData.outgoing.security);
        config.outgoing.auth = Ci.nsMsgAuthMethod.passwordCleartext;
        config.rememberPassword = true;
      } else if (accountData.type === "exchange") {
        const url = new URL(accountData.ews_url);
        config.incoming.type = "ews";
        config.incoming.hostname = url.hostname;
        config.incoming.port = url.port ? Number(url.port) : 443;
        config.incoming.username = accountData.username;
        config.incoming.password = accountData.password;
        config.incoming.socketType = Ci.nsMsgSocketType.SSL;
        config.incoming.auth = exchangeAuth(accountData.auth);
        config.incoming.exchangeURL = accountData.ews_url;
        config.rememberPassword = true;
      }

      const account = await CreateInBackend.createAccountInBackend(config);
      account.incomingServer.prettyName = accountData.display_name;

      if (account.defaultIdentity) {
        setSignature(account.defaultIdentity, accountData);
      }

      results.push({ id: accountData.id, state: "created" });
    }

    Services.prefs.savePrefFile(null);
    done({ success: true, results });
  } catch (error) {
    done({
      success: false,
      error: error?.stack ?? error?.toString() ?? String(error),
    });
  }
})();
'@

        Send-ThunderbirdMarionettePacket -Stream $stream -Packet @(
            0
            3
            "WebDriver:ExecuteAsyncScript"
            @{
                script        = $script
                args          = @($accountsJson)
                newSandbox    = $true
                sandbox       = "system"
                scriptTimeout = 120000
            }
        )

        $response = Read-ThunderbirdMarionettePacket -Stream $stream

        if ($response[2]) {
            throw $response[2].message
        }

        $value = $response[3].value

        if (-not $value.success) {
            throw $value.error
        }

        foreach ($result in $value.results) {
            Write-Host (
                "[{0}] Thunderbird Account: {1}" `
                    -f $result.state.ToUpperInvariant(), $result.id
            ) -ForegroundColor Green
        }

        if (-not $desired.MissingSignatures) {
            if (-not (Test-Path -LiteralPath $stateDirectory -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $stateDirectory -Force
            }

            [IO.File]::WriteAllText(
                $statePath,
                $desired.Hash + [Environment]::NewLine,
                [Text.UTF8Encoding]::new($false)
            )
        }
    }
    finally {
        $accountsJson = $null
        $desired = $null

        if ($client) {
            $client.Dispose()
        }

        if (-not $process.HasExited) {
            $null = $process.CloseMainWindow()
            Start-Sleep -Seconds 2

            if (-not $process.HasExited) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Start-Process -FilePath $thunderbirdPath

    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message (
            "[INFO] Thunderbird wurde gestartet. Gmail-OAuth bei Aufforderung " +
            "im Browser abschließen."
        )
}