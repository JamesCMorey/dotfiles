#!/bin/bash

vim-plug() {
    echo "Installing vim-plug"
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

nvim-plugins() {
    sudo apt install -y git clangd
    mkdir -p ~/.config/nvim/pack/plugins/start

    git clone --depth 1 https://github.com/junegunn/fzf ~/.config/nvim/pack/plugins/start/fzf
    git clone https://github.com/junegunn/fzf.vim ~/.config/nvim/pack/plugins/start/fzf.vim
    ~/.config/nvim/pack/plugins/start/fzf/install --all
}

docs() {
    echo "Installing manpages"
    sudo apt install -y manpages manpages-dev manpages-posix manpages-posix-dev \
		bash-doc gdb-doc glibc-doc
}

dev-tools() {
    echo "Installing dev-tools"
    sudo apt install -y gcc gdb valgrind make vim tmux git build-essential cmake
}

dotfiles() {
	echo "stowing dotfiles"
	sudo apt install -y stow
	#mv ~/.bashrc ~/.bashrc_old
	stow --dotfiles -S default/ git/
}

everything() {
	dev-tools
	vim-plug
	# nvim-plugins
	nvim
	docs
	dotfiles

	mkdir -p ~/.vim/swp
	mkdir -p ~/.vim/backup
	mkdir -p ~/.vim/undodir
}

echo "What do you want to install?"
select opt in "vim-plug" "Docs" "Dev-tools" "Dotfiles" "nvim-plugins" "Everything" "Quit"; do
	case $REPLY in
		1) vim-plug; break ;;
		2) docs; break ;;
		3) dev-tools; break ;;
		4) dotfiles; break ;;
		5) nvim-plugins; break;;
		6) everything; break ;;
		*) break ;;
	esac
done
