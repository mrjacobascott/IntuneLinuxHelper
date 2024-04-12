#! /bin/bash
# Installing the Intune app
echo ------Install the Intune app------
echo The machine will automatically reboot when completed
echo
read -p "Are you sure you want to continue? [Y/N] " reply
echo 
if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
	echo "Starting installation"
	sudo apt install curl gpg
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/ 

	distro=$(lsb_release -rs)
	if [[ "$distro" == "20.04" ]]; then
		sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/20.04/prod focal main" > /etc/apt/sources.list.d/microsoft-ubuntu-focal-prod.list'

	elif [[ "$distro" == "22.04" ]]; then
		sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-ubuntu-jammy-prod.list' 
	else
		echo "Unable to determine if 20.04 or 22.04 distro version. Detected version: $distro"
	fi
	
	sudo rm microsoft.gpg
	sudo apt update -y
	sudo apt install intune-portal -y
	echo
	echo
	# setting the intune app as a favorite so it's easy to find
	gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'intune-portal.desktop']"
	echo Complete. Restarting in 5 seconds.
	sleep 5
	reboot
else
	echo "Exiting"
	sleep 2
fi
