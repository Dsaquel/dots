#!/usr/bin/env fish

set -l repo_dir (realpath (dirname (status filename)))
cd $repo_dir

if not type -q stow
    echo "stow not installed. Run: sudo pacman -S --needed stow"
    exit 1
end

argparse h/help D/delete 't/theme=' -- $argv; or exit 2

if set -q _flag_help
    echo "Usage: ./install.fish [-D|--delete] [-t|--theme NAME] [PACKAGE ...]"
    echo "  no args        : (un)stow base/ and the theme over it"
    echo "  -t NAME        : a theme of themes/ (default glasshouse), none for base/ only"
    echo "  PACKAGE ...    : (un)stow only the listed packages"
    echo "  -D | --delete  : unstow instead of stow"
    exit 0
end

set -l theme glasshouse
set -q _flag_theme; and set theme $_flag_theme
set -l requested $argv

set -l layers base
if test $theme != none
    if not test -f themes/$theme/packages.fish
        echo "no theme $theme (themes/: "(string join ', ' (path basename themes/*))")"
        exit 1
    end
    set -a layers themes/$theme
end

set -l mode stow
set -q _flag_delete; and set mode unstow

set -l known
for layer in $layers
    set -l pkg_map
    set -l seed_map
    source $layer/packages.fish
    for entry in $pkg_map
        set -a known (string split ':' $entry)[1]
    end
end
set -l unknown
for pkg in $requested
    contains -- $pkg $known; or set -a unknown $pkg
end
if set -q unknown[1]
    echo "unknown package: $unknown (known: "(string join ' ' (printf '%s\n' $known | sort -u))")"
    exit 2
end

set -l failed
for layer in $layers
    set -l pkg_map
    set -l seed_map
    source $layer/packages.fish; or set -a failed "source $layer/packages.fish"

    for entry in $pkg_map
        set -l parts (string split ':' $entry)
        set -l pkg $parts[1]
        set -l target $parts[2]
        set -l flags $parts[3..]

        if test (count $requested) -gt 0; and not contains $pkg $requested
            continue
        end

        if not test -d $layer/$pkg
            echo "skip $layer/$pkg (not a directory)"
            continue
        end

        mkdir -p $target
        switch $mode
            case stow
                echo "stowing $layer/$pkg → $target"
                stow -v $flags --dir=$repo_dir/$layer --target=$target $pkg; or set -a failed "stow $layer/$pkg"
            case unstow
                echo "unstowing $layer/$pkg → $target"
                stow -v -D $flags --dir=$repo_dir/$layer --target=$target $pkg; or set -a failed "unstow $layer/$pkg"
        end
    end

    test $mode = stow; or continue
    for entry in $seed_map
        set -l parts (string split -m 1 ':' $entry)
        set -l pkg (string split -m 1 '/' $parts[1])[1]
        if test (count $requested) -gt 0; and not contains $pkg $requested
            continue
        end
        if not test -e $parts[2]
            echo "seeding $layer/$parts[1] → $parts[2]"
            cp $layer/$parts[1] $parts[2]; or set -a failed "seed $layer/$parts[1]"
        end
    end
end

if test $mode = stow; and test $theme != none; and test (count $requested) -eq 0; and test -x themes/$theme/setup
    echo "setting up $theme"
    themes/$theme/setup; or set -a failed "themes/$theme/setup"
end

echo
if set -q failed[1]
    echo "failed:"
    printf '  %s\n' $failed
    exit 1
end
echo done.
