#!/bin/bash


read -p "This script assumes you are in the dotfiles repo. Press enter to continue... " input
ln -s $(pwd)/files/vimrc ~/.vimrc
mkdir -p ~/.vim/swp
mkdir -p ~/.vim/backup
ln -s $(pwd)/files/tmux.conf ~/.tmux.conf
ln -s $(pwd)/files/ctags ~/.ctags
ln -s $(pwd)/files/zshrc ~/.zshrc
ln -s $(pwd)/vim ~/.vim
