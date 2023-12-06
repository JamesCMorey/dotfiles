#!/bin/bash

ln -s $(pwd)/.vimrc ~/.vimrc
ln -s $(pwd)/.tmux.conf ~/.tmux.conf
ln -s $(pwd)/.ctags ~/.ctags

sudo apt update && sudo apt install $(cat packages.txt) -y
