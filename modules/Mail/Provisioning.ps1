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

    const exchangeUsername = account => {
      if (!account.domain) {
        return account.username;
      }

      return `${account.domain}\\${account.username}`;
    };

    const setImapAdvancedSettings = (server, account) => {
      if (account.type !== "imap") {
        return;
      }

      if (
        Object.hasOwn(account.incoming, "server_directory") &&
        account.incoming.server_directory
      ) {
        Services.prefs.setCharPref(
          `mail.server.${server.key}.server_sub_directory`,
          account.incoming.server_directory
        );
      }

      if (
        Object.hasOwn(account.incoming, "personal_namespace") &&
        account.incoming.personal_namespace
      ) {
        Services.prefs.setCharPref(
          `mail.server.${server.key}.namespace.personal`,
          JSON.stringify(account.incoming.personal_namespace)
        );
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

      let existing = MailServices.accounts.accounts.find(account =>
        account.incomingServer?.type === expectedIncomingType &&
        account.identities.some(identity =>
          identity.email?.toLowerCase() === accountData.email.toLowerCase()
        )
      );

      let wasRecreated = false;

      if (
        existing &&
        accountData.type === "exchange" &&
        existing.incomingServer.username !== exchangeUsername(accountData)
      ) {
        MailServices.accounts.removeAccount(existing, true);
        existing = null;
        wasRecreated = true;
      }

      if (existing) {
        existing.incomingServer.prettyName = accountData.display_name;
        setImapAdvancedSettings(existing.incomingServer, accountData);

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
        config.incoming.username = exchangeUsername(accountData);
        config.incoming.password = accountData.password;
        config.incoming.socketType = Ci.nsMsgSocketType.SSL;
        config.incoming.auth = exchangeAuth(accountData.auth);
        config.incoming.exchangeURL = accountData.ews_url;
        config.rememberPassword = true;
      }

      const account = await CreateInBackend.createAccountInBackend(config);
      account.incomingServer.prettyName = accountData.display_name;
      setImapAdvancedSettings(account.incomingServer, accountData);

      if (account.defaultIdentity) {
        setSignature(account.defaultIdentity, accountData);
      }

      results.push({
        id: accountData.id,
        state: wasRecreated ? "recreated" : "created",
      });
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