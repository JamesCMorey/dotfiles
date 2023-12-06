#!/bin/bash

ln -s ~/dotfiles/.vimrc ~/.vimrc
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -s ~/dotfiles/.ctags ~/.ctags

sudo apt update && sudo apt upgrade && sudo apt install $(cat packages.txt) -y
