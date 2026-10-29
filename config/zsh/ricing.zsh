# Ricing Tokyo Night — chargé depuis ~/.zshrc
# Prompt Starship (config : ~/.config/starship.toml)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
