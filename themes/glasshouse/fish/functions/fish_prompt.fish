function fish_prompt
    set -l last $status $pipestatus
    set -l code $last[1]
    set -l pipe $last[2..]

    set -l cache ~/.cache
    set -q XDG_CACHE_HOME; and set cache $XDG_CACHE_HOME
    set -l world light
    test -r $cache/theme-switch/current; and read world <$cache/theme-switch/current
    set -l glyph (set_color -o yellow)☉
    test "$world" = dark; and set glyph (set_color -o brwhite)☽

    set -l who
    fish_is_root_user; and set who (set_color red)root' '
    set -q SSH_TTY; and set who $who(set_color brblack)$USER@(prompt_hostname)' '

    set -l place (string replace -r '^'(string escape --style=regex -- $HOME)'(?=/|$)' '~' -- $PWD)
    test (string length -- $place) -gt (math -s0 "$COLUMNS * 0.45"); and set place (prompt_pwd -d 1 -D 2)

    if set -q __gh_git_stale; or test "$__gh_git_pwd" != "$PWD"
        set -g __gh_git
        set -g __gh_git_pwd $PWD
        set -e __gh_git_stale
        set -l git (command git --no-optional-locks status --porcelain=v2 --branch --ignore-submodules=dirty 2>/dev/null)
        if test $status -eq 0
            set -l head (string match -rg '^# branch\.head (.+)$' -- $git)
            test "$head" = "(detached)"; and set head (string sub -l 7 -- (string match -rg '^# branch\.oid (.+)$' -- $git))
            set __gh_git '  '(set_color brblue)\uf418' '$head
            string match -qrv '^#' -- $git; and set __gh_git $__gh_git' '(set_color -o yellow)✦(set_color normal)
        end
    end
    set -l branch $__gh_git

    set -l took
    if set -q CMD_DURATION; and test "$CMD_DURATION" -gt 5000
        set -l s (math -s0 "$CMD_DURATION / 1000")
        set -l t {$s}s
        test $s -ge 60; and set t (math -s0 "$s / 60")m' '(printf '%02d' (math "$s % 60"))s
        test $s -ge 3600; and set t (math -s0 "$s / 3600")h' '(printf '%02d' (math -s0 "$s % 3600 / 60"))m
        set took '  '(set_color -o brblack)'⧗ '(set_color normal)(set_color white)$t
    end

    set -l failed
    if string match -qv 0 -- $pipe
        set -l what (string join '|' -- $pipe)
        if test (count $pipe) -eq 1
            set -l sig (fish_status_to_signal $code)
            string match -q 'SIG*' -- $sig; and set what (string replace SIG '' -- $sig)
        end
        set failed '  '(set_color -o red)'✗ '(set_color normal)(set_color red)$what
    end

    set -l jobs
    jobs -q; and set jobs '  '(set_color brblack)'&'(jobs -p | count)

    set -l mark ❯
    test "$fish_key_bindings" = fish_vi_key_bindings; and switch $fish_bind_mode
        case default
            set mark ❮
        case replace replace_one
            set mark ▶
        case visual
            set mark V
    end

    echo
    echo -s $glyph (set_color normal) ' ' $who (set_color -o bryellow) $place (set_color normal) $branch $took $failed $jobs (set_color normal)
    echo -n -s (set_color -o magenta) $mark (set_color normal) ' '
end

function __gh_git_stale --on-event fish_postexec
    set -g __gh_git_stale 1
end
