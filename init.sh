#!/bin/bash

vim-plug() {
    echo "Installing vim-plug"
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

docs() {
    echo "Installing manpages"
    sudo apt install manpages manpages-dev manpages-posix manpages-posix-dev \
		bash-doc gdb-doc glibc-doc
}

dev-tools() {
    echo "Installing dev-tools"
    sudo apt install gcc gdb valgrind make vim tmux git build-essential
}

dotfiles() {
	echo "stowing dotfiles"
	stow --dotfiles -S default/ git/
}

everything() {
	vim-plug
	docs
	dev-tools
	dotfiles

	mkdir -p ~/.vim/swp
	mkdir -p ~/.vim/backup
	mkdir -p ~/.vim/undodir
}

echo "What do you want to install?"
select opt in "vim-plug" "Docs" "Dev-tools" "Dotfiles" "Everything" "Quit"; do
	case $REPLY in
		1) vim-plug; break ;;
		2) docs; break ;;
		3) dev-tools; break ;;
		4) dotfiles; break ;;
		5) everything; break ;;
		*) break ;;
	esac
done
