function fastfetch --wraps fastfetch
    if test (count $argv) -eq 0; and command -q glasshouse-fetch
        glasshouse-fetch --static
    else
        command fastfetch $argv
    end
end
