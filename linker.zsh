#!/bin/bash

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

mkdir -p ~/.vim/swp
mkdir -p ~/.vim/backup
mkdir -p ~/.vim/undodir

FILES=("tmux.conf"  "ctags" "zshrc" "vimrc" "gitignore_global" "gitconfig")
DOTFILES_DIR=$(pwd)

for FILE in "${FILES[@]}"; do
  TARGET="$HOME/.$FILE"
  SOURCE="$DOTFILES_DIR/$FILE"

  # Check if the target already exists
  if [ -e "$TARGET" ]; then
    echo "Skipping $FILE: $TARGET already exists."
  else
    ln -s "$SOURCE" "$TARGET"
    echo "Created symlink for $FILE."
  fi
done
