function Install-CodexCli {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " OpenAI Codex CLI"
    Write-Host "========================================"


    if (Get-Command codex -ErrorAction SilentlyContinue) {

        Write-Host "[OK] Codex CLI bereits installiert."

        return
    }


    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {

        Write-Warning `
            "npm wurde nicht gefunden. Codex CLI kann nicht installiert werden."

        return
    }


    Write-Host "[INSTALL] @openai/codex"

    npm install -g @openai/codex


    Update-SessionPath


    if (Get-Command codex -ErrorAction SilentlyContinue) {

        Write-Host "[OK] Codex CLI installiert."

    }
    else {

        Write-Warning `
            "Codex CLI wurde installiert, aber ist nicht verfügbar."

    }

}
