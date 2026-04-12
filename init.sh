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
    docker docker-compose
    postgresql18 # psql
    go
    man-pages

    # Dependences
    npm # nvim mason pyright
)

SUSE_PATTERNS=(
    devel_basis
    devel_kernel
    devel_C_C++
)

suse_packages() {
    suse_patterns_cli=()
    for pattern in "${SUSE_PATTERNS[@]}"; do
	suse_patterns_cli+=(-t pattern "$pattern")
    done
    sudo zypper install "${suse_patterns_cli[@]}" "${SUSE_PACKAGES[@]}"
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
