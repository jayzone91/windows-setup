@{
    Mods = @(
        @{
            Id         = "macos-lock-keys-notifier"
            Name       = "macOS Lock Keys Notifier"
            Enabled    = $true
            SourceFile = "config/windhawk/macos-lock-keys-notifier.wh.cpp"
            Replaces   = @(
                "lock-keys-notifier"
            )
        }
    )
}
