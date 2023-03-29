function fish_mode_prompt
    if test "$fish_key_bindings" != fish_default_key_bindings
        set --local vi_mode_color
        set --local vi_mode_symbol
        switch $fish_bind_mode
            case default
                set vi_mode_color (set_color $tuna_color_git)
                set vi_mode_symbol n
            case insert
                set vi_mode_color (set_color $tuna_color_pwd)
                set vi_mode_symbol i
            case replace replace_one
                set vi_mode_color (set_color $tuna_color_duration)
                set vi_mode_symbol r
            case visual
                set vi_mode_color (set_color $tuna_color_duration)
                set vi_mode_symbol v
        end
        echo -e "$vi_mode_color$vi_mode_symbol\x1b[0m "
    end
end

function fish_prompt --description tuna
    echo -e "$_tuna_color_pwd$_tuna_pwd$tuna_color_normal $_tuna_color_git$$_tuna_git$tuna_color_normal$_tuna_color_duration$_tuna_cmd_duration$tuna_color_normal$_tuna_status$tuna_color_normal "
end
