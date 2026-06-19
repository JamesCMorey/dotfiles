# Dotfiles

## Setup

```bash
git clone https://github.com/JamesCMorey/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow --dotfiles default git
```

### Packages

The `default` package ships a cross-platform zsh config (`dot-zshenv`,
`dot-zprofile`, `dot-zshrc`) that detects macOS vs Linux and guards every
optional tool, so it runs anywhere.

- **macOS:** `brew bundle` (uses `Brewfile`) — or `source init.sh && brew_packages`
- **openSUSE:** `source init.sh && suse_packages`

Both lists include the modern shell stack the zshrc lights up when present:
`fzf`, `zoxide`, `eza`, `bat`, `fd`, `ripgrep`, and the zsh
autosuggestions / syntax-highlighting / history-substring-search / completions
plugins. Drop machine-specific, untracked tweaks in `~/.zshrc.local`.

See [`docs/zsh.md`](docs/zsh.md) for a full tour of the zsh features, keybindings,
aliases, and tips.
