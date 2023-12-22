#!/bin/bash

###### Functions ######
remove_libreoffice() {
	sudo apt remove --purge "libreoffice*" -y
	sudo apt clean
	sudo apt autoremove
}

install_onlyoffice() {
	mkdir -p -m 700 ~/.gnupg
	gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg \
		--keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
	chmod 644 /tmp/onlyoffice.gpg
	sudo chown root:root /tmp/onlyoffice.gpg
	sudo mv /tmp/onlyoffice.gpg /usr/share/keyrings/onlyoffice.gpg

	echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] \
		https://download.onlyoffice.com/repo/debian squeeze main' | \
		sudo tee -a /etc/apt/sources.list.d/onlyoffice.list

	sudo apt-get update
	sudo apt-get install -y onlyoffice-desktopeditors
}


###### Guard ######
read -p "This script expects you to be within the dotfile repo. Are you? [y/N] " input
input=${input:-"n"}
if [[ ${input,,} == "n" ]]; then
	exit 1
fi


###### Surveying ######
read -p "Install OnlyOffice? [y/N] " onlyoffice
onlyoffice=${onlyoffice:-"n"}

read -p "Remove the LibreOffice suite? [y/N] " libreoffice
libreoffice=${libreoffice:-"n"}

read -p "Configure Wireguard? [y/N] " wireguard
wireguard=${wireguard:-"n"}

if [[ ${wireguard,,} == "y" ]]; then
	read -p "Enter the name of your conf file (minus the .conf part). " confname
	read -p "Enter the full path of your Wireguard conf file. " path
fi

read -p "Configure git. [Y/n]" confgit
git=${confgit:-"y"}

if [[ ${confgit,,} == "y" ]]; then
	read -p "Enter your name" name
	read -p "Enter your email" email
fi


###### Installation ######
echo "Preliminary updating and upgrading..."
sudo apt update && sudo apt upgrade -y

echo "Installing packages from basic.pack..."
sudo apt install -y $(cat basic.pack)

if [[ ${onlyoffice,,} == "y" ]]; then
	echo "installing OnlyOffice..."
	install_onlyoffice
fi

if [[ ${libreoffice,,} == "y" ]]; then
	echo "Removing the LibreOffice suite..."
	remove_libreoffice
fi

echo "Installing Thunar dependencies..."
sudo apt install -y gvfs-backends

echo "Installing Wireguard alongside dependencies..."
sudo apt install -y wireguard resolvconf


###### Configuration ######
echo "Linking dotfiles..."
ln -s $(pwd)/files/vimrc ~/.vimrc
ln -s $(pwd)/files/tmux.conf ~/.tmux.conf
ln -s $(pwd)/files/ctags ~/.ctags

sudo ln -s $(pwd)/files/auto-update /etc/cron.daily/

if [[ ${confgit,,} == "y" ]]; then
	echo "Configuring git..."
	git config --global user.name "$name"
	git config --global user.email "$email"
	git config --global core.editor vim
fi


if [[ ${wireguard,,} == "y" ]]; then
	echo "Creating symbolic link to conf file in /etc/wireguard before creating and starting systemd service."
	sudo ln -s $path /etc/wireguard/
	sudo systemctl enable "wg-quick@${confname}.service"
	sudo systemctl start "wg-quick@${confname}.service"
fi
