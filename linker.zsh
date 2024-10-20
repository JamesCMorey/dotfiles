#!/bin/bash

read -p "This script assumes you are in the dotfiles repo. Press enter to continue... " input

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir $(pwd)/.vim
mkdir -p ~/.vim/swp
mkdir -p ~/.vim/backup
mkdir -p ~/.vim/undodir

ln -s $(pwd)/files/tmux.conf ~/.tmux.conf
ln -s $(pwd)/files/ctags ~/.ctags
ln -s $(pwd)/files/zshrc ~/.zshrc
ln -s $(pwd)/files/vimrc ~/.vimrc
