$env.config = {
    show_banner: false
    edit_mode: emacs

    history: {
        file_format: sqlite
        max_size: 100_000
        sync_on_enter: true
        isolation: false
    }

    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: prefix

        external: {
            enable: true
            max_results: 100
            completer: null
        }
    }
}

# Starship wird im offiziellen Nushell-Autoload-Verzeichnis erzeugt.
if (which starship | is-not-empty) {
    let starship_autoload_directory = (
        $nu.data-dir
        | path join "vendor" "autoload"
    )

    mkdir $starship_autoload_directory

    starship init nu
    | save --force (
        $starship_autoload_directory
        | path join "starship.nu"
    )
}
