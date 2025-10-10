#!/usr/bin/env python3
from subprocess import run
import os


packages = {
    "general": ["build-essential", "curl"],
    "debugging": ["gdb", "valgrind"],
    "workflow": ["vim", "tmux", "git", "python3-virtualenv"],
    "build-system": ["make", "cmake"],
    "libraries": ["python3.13-venv"],
    "compilers": ["gcc"],
    "docs": ["manpages", "manpages-dev", "bash-doc", "glibc-doc"],
}


def main():
    install_packages()
    setup_vim()
    install_neovim()
    install_dotfiles()


def install_packages():
    run(["sudo", "apt", "update"], check=True)
    for category in packages:
        run(["sudo", "apt", "install", "-y", *packages[category]], check=True)


def install_dotfiles():
    run(["sudo", "apt", "install", "stow"], check=True)

    bashrc = os.path.expanduser("~/.bashrc")
    if os.path.isfile(bashrc):
        run(["mv", bashrc, bashrc + ".bak"], check=True)

    run(["stow", "--dotfiles", "-S", "default/", "git/"], check=True)


vim_plug_download = [
    "curl",
    "-fLo",
    os.path.expanduser("~/.vim/autoload/plug.vim"),
    "--create-dirs",
    "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim",
]


def setup_vim():
    dirs = ["~/.vim/swp", "~/.vim/backup", "~/.vim/undodir"]

    for d in dirs:
        run(["mkdir", "-p", os.path.expanduser(d)], check=True)

    if not os.path.isfile(os.path.expanduser("~/.vim/autoload/plug.vim")):
        run(vim_plug_download, check=True)


def install_neovim():
    repo_dir = os.path.expanduser("~/neovim")

    # Download
    if not os.path.isdir(repo_dir):
        run(
            ["git", "clone", "https://github.com/neovim/neovim", repo_dir],
            check=True,
        )
    # Build
    run(["git", "checkout", "stable"], cwd=repo_dir, check=True)
    run(["make", "CMAKE_BUILD_TYPE=RelWithDebInfo"], cwd=repo_dir, check=True)
    # Install
    run(["sudo", "make", "install"], cwd=repo_dir, check=True)


if __name__ == "__main__":
    main()
