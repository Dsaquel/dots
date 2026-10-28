if status is-interactive; and test (tty 2>/dev/null) != /dev/tty1; and command -q glasshouse-fetch
    function fish_greeting
        glasshouse-fetch
    end
end
