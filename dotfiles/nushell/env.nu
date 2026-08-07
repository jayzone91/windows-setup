# fnm / Node.js
if (which fnm | is-not-empty) {
    let fnm_environment = (fnm env --json | from json)

    load-env $fnm_environment

    $env.Path = (
        $env.Path
        | prepend $env.FNM_MULTISHELL_PATH
        | uniq
    )
}
