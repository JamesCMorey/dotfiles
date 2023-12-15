#!/bin/bash

ln -s $(pwd)/.vimrc ~/.vimrc
ln -s $(pwd)/.tmux.conf ~/.tmux.conf
ln -s $(pwd)/.ctags ~/.ctags

sudo ln -s $(pwd)/auto-update /etc/cron.daily/

sudo apt update && sudo apt install $(cat packages.txt) -y
