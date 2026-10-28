function fish_user_key_bindings
  fish_vi_key_bindings

  bind -M insert \cl forward-char
  bind -M insert \cd delete-char

end

functions -q fzf_configure_bindings; and fzf_configure_bindings --directory=\cf

command -q fzf; and fzf --fish | source
