status is-interactive || exit

set --global _tuna_git _tuna_git_$fish_pid

function $_tuna_git --on-variable $_tuna_git
    commandline --function repaint
end

function _tuna_pwd --on-variable PWD --on-variable tuna_ignored_git_paths --on-variable fish_prompt_pwd_dir_length
    set --local git_root (command git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
    set --local git_base (string replace --all --regex -- "^.*/" "" "$git_root")
    set --local path_sep /

    test "$fish_prompt_pwd_dir_length" = 0 && set path_sep

    if set --query git_root[1] && ! contains -- $git_root $tuna_ignored_git_paths
        set --erase _tuna_skip_git_prompt
    else
        set --global _tuna_skip_git_prompt
    end

    set --global _tuna_pwd (
        string replace --ignore-case -- ~ \~ $PWD |
        string replace -- "/$git_base/" /:/ |
        string replace --regex --all -- "(\.?[^/]{"(
            string replace --regex --all -- '^$' 1 "$fish_prompt_pwd_dir_length"
        )"})[^/]*/" "\$1$path_sep" |
        string replace -- : "$git_base" |
        string replace --regex -- '([^/]+)$' "\x1b[1m\$1\x1b[22m" |
        string replace --regex --all -- '(?!^/$)/|^$' "\x1b[2m/\x1b[22m"
    )
end

function _tuna_prompt --on-event fish_prompt
    set --query _tuna_status || set --global _tuna_status "$_tuna_newline$_tuna_color_prompt$tuna_symbol_prompt"
    set --query _tuna_pwd || _tuna_pwd

    command kill $_tuna_last_pid 2>/dev/null

    set --query _tuna_skip_git_prompt && set $_tuna_git && return

    fish --private --command "
        set branch (
            command git symbolic-ref --short HEAD 2>/dev/null ||
            command git describe --tags --exact-match HEAD 2>/dev/null ||
            command git rev-parse --short HEAD 2>/dev/null |
                string replace --regex -- '(.+)' '@\$1'
        )

        test -z \"\$$_tuna_git\" && set --universal $_tuna_git \"\$branch \"

        ! command git diff-index --quiet HEAD 2>/dev/null ||
            count (command git ls-files --others --exclude-standard) >/dev/null && set info \"$tuna_symbol_git_dirty\"

        for fetch in $tuna_fetch false
            command git rev-list --count --left-right @{upstream}...@ 2>/dev/null |
                read behind ahead

            switch \"\$behind \$ahead\"
                case \" \" \"0 0\"
                case \"0 *\"
                    set upstream \" $tuna_symbol_git_ahead\$ahead\"
                case \"* 0\"
                    set upstream \" $tuna_symbol_git_behind\$behind\"
                case \*
                    set upstream \" $tuna_symbol_git_ahead\$ahead $tuna_symbol_git_behind\$behind\"
            end

            set --universal $_tuna_git \"\$branch\$info\$upstream \"

            test \$fetch = true && command git fetch --no-tags 2>/dev/null
        end
    " &

    set --global _tuna_last_pid (jobs --last --pid)
end

function _tuna_fish_exit --on-event fish_exit
    set --erase $_tuna_git
end

function _tuna_uninstall --on-event tuna_uninstall
    set --names |
        string replace --filter --regex -- "^(_?tuna_)" "set --erase \$1" |
        source
    functions --erase (functions --all | string match --entire --regex "^_?tuna_")
end

set --global tuna_color_normal (set_color normal)

for color in tuna_color_{pwd,git,error,prompt,duration}
    function $color --on-variable $color --inherit-variable color
        set --query $color && set --global _$color (set_color $$color)
    end && $color
end

# Newline if previous output exists
function postexec_test --on-event fish_postexec
    echo
end

set --query tuna_color_error || set --global tuna_color_error $fish_color_error
set --query tuna_symbol_prompt || set --global tuna_symbol_prompt \u24
set --query tuna_symbol_git_dirty || set --global tuna_symbol_git_dirty \x2a
set --query tuna_symbol_git_ahead || set --global tuna_symbol_git_ahead \u2191
set --query tuna_symbol_git_behind || set --global tuna_symbol_git_behind \u2193
set --query tuna_multiline || set --global tuna_multiline true
set --query tuna_color_duration || set --global tuna_color_duration magenta
set --query tuna_color_git || set --global tuna_color_git magenta
set --query tuna_color_prompt || set --global tuna_color_prompt cyan
set --query tuna_color_pwd || set --global tuna_color_pwd yellow
set --global fish_greeting ''