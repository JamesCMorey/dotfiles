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

## Devbox Container

Docker config lives in `docker/`. The container is an Arch-based dev environment with neovim, tmux, claude, codex, and dotfiles pre-installed.

### Commands

All commands are symlinks to a single `,devbox` script and are available after stow:

| Command | Description |
|---------|-------------|
| `,enter` | Start the container if needed, then shell in. Use this as a terminal profile command. |
| `,start` | Start the container (errors if already running). |
| `,stop` | Stop the container. |
| `,build` | Incremental build (layer cache decides what's stale). |
| `,build --dotfiles` | Rebuild from the dotfiles stage only, keeping base layers cached. |
| `,build --full` | Full rebuild, no cache. |
| `,devbox <subcmd>` | Unified entrypoint, accepts any of the above as a subcommand. |

### Neovim / Treesitter

The Dockerfile runs two headless nvim passes:

1. `nvim --headless "+Lazy! sync" +qa` -- installs plugins via lazy.nvim.
2. `nvim --headless +qa` -- loads the now-installed plugins so treesitter's `config` fires.

The treesitter config detects headless mode and blocks on parser compilation (`install(langs):wait()`), so all parsers are pre-compiled in the image. `tree-sitter-cli` is installed as a system package since the current nvim-treesitter shells out to `tree-sitter build` for parser compilation.
