#!/usr/bin/env bash

SUSE_PACKAGES=(
    # Firmware
    sof-firmware
    kernel-firmware-bluetooth

    # Visual
    symbols-only-nerd-fonts

    # General Applications
    xournalpp
    flatpak # chrome, intellij, zoom
    kicad
    discord

    # VPN Applications
    openvpn
    tailscale

    # Dev
    git stow
    neovim tmux ripgrep
    gdb valgrind
    bear cmake meson
    postgresql18 # psql
    go
    man-pages

    # Shell (zsh experience — mirrors Brewfile)
    zsh
    fzf zoxide bat fd eza
    zsh-autosuggestions zsh-syntax-highlighting

    # Dependences
    npm # nvim mason pyright
)

SUSE_PATTERNS=(
    devel_basis
    devel_kernel
    devel_C_C++
)

DEBIAN_PACKAGES=(
    # Dev
    git stow
    neovim tmux
    golang npm        # nvim mason / tooling
    postgresql-client # psql
    man-db

    # Shell (zsh experience — mirrors Brewfile / SUSE_PACKAGES).
    # Debian names two binaries differently: bat→batcat, fd→fdfind
    # (the debian_packages() function symlinks the canonical names below).
    zsh
    fzf zoxide bat fd-find eza ripgrep
    zsh-autosuggestions zsh-syntax-highlighting
)

suse_packages() {
    suse_patterns_cli=()
    for pattern in "${SUSE_PATTERNS[@]}"; do
	suse_patterns_cli+=(-t pattern "$pattern")
    done
    sudo zypper install "${suse_patterns_cli[@]}" "${SUSE_PACKAGES[@]}"
}

debian_packages() {
    # Debian/Ubuntu (apt) — the analog of suse_packages / brew_packages.
    sudo apt-get update
    sudo apt-get install -y "${DEBIAN_PACKAGES[@]}"

    # zsh-history-substring-search isn't packaged for Debian; clone it onto a
    # path the zshrc already searches (/usr/share/...).
    local hss=/usr/share/zsh-history-substring-search
    if [[ ! -e "$hss/zsh-history-substring-search.zsh" ]]; then
	sudo git clone --depth 1 \
	    https://github.com/zsh-users/zsh-history-substring-search.git "$hss"
    fi

    # Debian renames two binaries (bat→batcat, fd→fdfind). Symlink the
    # canonical names into ~/.local/bin (already on PATH via .zprofile) so the
    # zshrc's fzf/preview integrations light up.
    mkdir -p "$HOME/.local/bin"
    [[ -x /usr/bin/fdfind ]] && ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
    [[ -x /usr/bin/batcat ]] && ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
}

brew_packages() {
    # macOS: install the package set declared in the Brewfile.
    brew bundle --file="$(dirname "${BASH_SOURCE[0]}")/Brewfile"
    # Homebrew leaves $(brew --prefix)/share group-writable, which makes zsh's
    # compinit flag the completion dirs as insecure (and prompt on each new
    # shell). Drop the group-write bit so completions load without a prompt.
    chmod g-w "$(brew --prefix)/share" 2>/dev/null || true
}

dotfiles_stow() {
    stow --dotfiles default git
}

vim_setup() {
    mkdir -p ~/.vim/{backups,undodir,swapdir}

    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    }

terminal_theme() {
    # Spacegray 
    # bg: #090E13 
    # green: #76946A
    bash -c "$(wget -qO- https://git.io/vQgMr)"
}

add_codex_support() {
    sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
    sudo zypper refresh
    sudo zypper dup --from packman --allow-vendor-change
}
echo "You're supposed to source this file and run the functions manually"
