#!/usr/bin/env python3
from subprocess import run
import os
from pathlib import Path


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

    valid_inputs = ['y', 'n', '']
    user = input("Install authorized key for user (y/N)")
    while user.lower() not in valid_inputs:
        user = input("Install authorized key for user (y/N)")

    if user == 'y':
        ssh_key = input("Enter key: ")



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


def setup_authorized_key():
    valid_inputs = ['y', 'n', '']
    user = input("Install authorized key for user (y/N): ").strip().lower()

    # Re-prompt until valid
    while user not in valid_inputs:
        user = input("Install authorized key for user (y/N): ").strip().lower()

    # Default is "no"
    if user == '' or user == 'n':
        print("Skipping authorized key installation.")
        return

    ssh_key = input("Enter key: ").strip()

    if not ssh_key:
        print("No key entered. Skipping.")
        return

    # Expand ~/.ssh and authorized_keys
    ssh_dir = Path.home() / ".ssh"
    auth_keys = ssh_dir / "authorized_keys"

    # Ensure directory exists and has correct permissions
    ssh_dir.mkdir(mode=0o700, exist_ok=True)

    # Append key only if not already present
    if auth_keys.exists() and ssh_key in auth_keys.read_text():
        print("Key already exists in authorized_keys.")
    else:
        with auth_keys.open("a") as f:
            f.write(ssh_key + "\n")
        os.chmod(auth_keys, 0o600)
        print(f"Added key to {auth_keys}")


if __name__ == "__main__":
    main()
