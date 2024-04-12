#! /bin/bash
# Create a menu of actions to perform in the VM
menu(){
	echo Choose an option by entering the number from the below list
	echo "1-  Edge app-- Install, Update, or Uninstall"
	echo "2-  Intune app-- Install, Update, or Uninstall"
	echo 3- 
	echo "4-  Display relevant software versions"
	echo "5-  Display enforced password requirements"
	echo "6-  Display UserID, Intune Device ID, Entra Device ID, "
	echo "    and Tenant ID for the enrollment"
	echo "7-  Display hardware and OS software information"
	echo "8-  Check encryption status"
	echo "9-  Collect identity broker service logs locally"
	echo "10- Upload identity broker, Intune, and Edge logs to Microsoft support"

	echo "Q-  Quit"
	echo
	read -p "Enter selection: " reply
	echo 
	if [ "$reply" = "1" ]; then
		edgeApp
	elif  [ "$reply" = "2" ]; then
		intuneApp	
	elif  [ "$reply" = "3" ]; then
		menu
	elif  [ "$reply" = "4" ]; then
		swversions
	elif  [ "$reply" = "5" ]; then
		pwcheck
	elif  [ "$reply" = "6" ]; then
		uddata
	elif [ "$reply" = "7" ]; then
		machdata
	elif [ "$reply" = "8" ]; then
		encrypt
	elif [ "$reply" = "9" ]; then
		jourlogs
	elif [ "$reply" = "10" ]; then
		edgeLogs
	elif  [ "$reply" = "Q" ] || [ "$reply" = "q" ]; then
		echo "Exiting"
		sleep 1
		exit 0
	else 
		echo "Unrecognized response"
		echo
		menu
	fi 
}

edgeApp(){
	breaker
	echo Choose an option by entering the number from the below list
	echo 1- Install the Edge app
	echo 2- Update the Edge app
	echo 3- Uninstall the Edge app
	echo Q- Quit
	echo
	read -p "Enter selection: " reply
	echo 
	if [ "$reply" = "1" ]; then
		edgeInstall
	elif  [ "$reply" = "2" ]; then
		edgeUpdate
	elif  [ "$reply" = "3" ]; then
		edgeRemove
	elif  [ "$reply" = "Q" ] || [ "$reply" = "q" ]; then
		echo "Back to main menu"
		sleep 1
		menu
	else 
		echo "Unrecognized response"
		echo
		edgeApp
	fi 
}

edgeInstall(){
	breaker
	echo "Starting Edge installation"
	sudo apt install curl gpg
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/ 

	sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-ubuntu-focal-prod.list'

	sudo rm microsoft.gpg
	sudo apt update -y
	sudo apt install microsoft-edge-stable -y
	echo
	echo
	echo Edge installation complete
	sleep 2
	breaker
	menu
}

edgeUpdate(){
	breaker
	echo This will check to see if an update is available for the
	echo Edge app and install it if available. Starting version: 
	if command -v microsoft-edge-stable&> /dev/null; then
		microsoft-edge-stable --version
		echo
		sleep 2
		sudo apt update -y
		sudo apt-get dist-upgrade -y
		sleep 2
		echo Completed. Version now:
		microsoft-edge-stable --version
	else
		echo Microsoft Edge is NOT installed. Edge MUST be installed
		echo for Intune enrollment to be successful.
	fi
	breaker
	edgeApp
}

edgeRemove(){
	breaker
	echo Uninstalling the Edge app
	sudo apt remove microsoft-edge-stable -y
	sudo apt purge microsoft-edge-stable -y
	echo
	echo Uninstall complete
	breaker
	menu
}


intuneApp(){
	breaker
	echo Choose an option by entering the number from the below list
	echo 1- Install the Intune app
	echo 2- Update the Intune app
	echo 3- Uninstall the Intune app and remove device registration
	echo Q- Quit
	echo
	read -p "Enter selection: " reply
	echo 
	if [ "$reply" = "1" ]; then
		intuneInstall
	elif  [ "$reply" = "2" ]; then
		intuneUpdate	
	elif  [ "$reply" = "3" ]; then
		intuneRemove
	elif  [ "$reply" = "Q" ] || [ "$reply" = "q" ]; then
		echo "Back to main menu"
		sleep 1
		menu
	else 
		echo "Unrecognized response"
		breaker
		intuneApp
	fi 
}

intuneInstall(){
	breaker
	echo Selected Install the Intune app.
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
		echo "Returning to menu"
		sleep 2
		menu
	fi
}

intuneUpdate(){
	breaker
	echo This will check to see if an update is available for the
	echo Intune and install it if available. Starting version: 
	if command -v intune-portal&> /dev/null; then
		intune-portal --version
		echo
		sleep 2
		sudo apt update -y
		sudo apt-get dist-upgrade -y
		sleep 2
		echo
		echo Completed. Version now: 
		intune-portal --version
		breaker
		menu
	else
		echo Microsoft Intune app is not installed. Returning...
		breaker
		menu
	fi
}

intuneRemove(){
	breaker
	echo Selected remove the Intune app and device registration
	echo Note- This will not remove the objects from the Entra/Intune portals
	echo This only removes the enrollment locally from the device
	sleep 3
	#uninstall the intune app
	sudo apt remove intune-portal -y
	sudo apt purge intune-portal -y

	#stop identity services and clean up states
	sudo systemctl stop microsoft-identity-device-broker.service
	sudo systemctl clean --what=configuration --what=runtime --what=state microsoft-identity-device-broker
	systemctl --user stop microsoft-identity-broker
	systemctl --user clean --what=state --what=configuration --what=runtime microsoft-identity-broker

	#clean up secrets
	secret-tool search --all env 60a144fbac31dfcf32034c112a615303b0e55ecad3a7aa61b7982557838908dc
	secret-tool clear env 60a144fbac31dfcf32034c112a615303b0e55ecad3a7aa61b7982557838908dc
	secret-tool clear name LinuxBrokerSystemUserSecretKey
	secret-tool clear name LinuxBrokerRegularUserSecretKey
	sleep 3
	echo
	echo Completed.
	breaker
	menu
}

edgeLogs(){
	breaker
	echo Triggering Edge log upload
	sudo /opt/microsoft/microsoft-identity-diagnostics/scripts/collect_logs
	breaker
	menu
}


jourlogs(){
	breaker
	echo Collecting journalctl user and system identity broker logs. 
	echo You will be able to find them on the desktop
	journalctl --user -u microsoft-identity-broker.service --since today > ~/Desktop/journalctlUserlogs.txt
	journalctl --system -u microsoft-identity-broker.service --since today > ~/Desktop/journalctlSystemlogs.txt
	echo Done
	breaker
	menu
}

encrypt(){
	breaker
	echo If the response after the sudo shows no devices found, then the 
	echo hard drive is not currently encrypted. Any other result
	echo indicates at least partial encryption is present
	sudo dmsetup status
	
	breaker
	sleep 2
	menu
}

breaker(){
	echo
	echo ------------------------------------------------------------
	echo
}


machdata(){
	breaker
	hostnamectl
	breaker
	sleep 2
	menu
}

uddata(){
	breaker
	
	cat ~/.config/intune/registration.toml | while read line;
	do
		if [[ "$line" = account* ]]; then
			aid=$(echo "${line}" | awk '{ print substr($0, length($0) - 37) }')
			echo "AccountID:     ${aid}"
		
		elif  [[ "$line" = device* ]]; then
			did=$(echo "${line}" | awk '{ print substr($0, length($0) - 37) }')
			echo "DeviceID:      ${did}"
		elif  [[ "$line" = aad* ]]; then
			aadid=$(echo "${line}" | awk '{ print substr($0, length($0) - 37) }')
			echo "EntraDeviceID: ${aadid}"
		elif  [[ "$line" = authority* ]]; then
			tid=$(echo "${line}" | awk '{ print substr($0, length($0) - 36) }')
			echo "TenantID:      \"${tid}"
		fi 
		#echo $line
	done
	breaker
	sleep 2
	menu
}

swversions(){
	breaker

	if command -v intune-portal&> /dev/null; then
		intune-portal --version
	else
		echo Microsoft Intune app is not installed
	fi

	if command -v microsoft-edge-beta&> /dev/null; then
		microsoft-edge-beta --version
	elif command -v microsoft-edge-dev&> /dev/null; then
		microsoft-edge-dev --version
	elif command -v microsoft-edge-stable&> /dev/null; then
		microsoft-edge-stable --version
	else
		echo Microsoft Edge is NOT installed. Edge MUST be installed
		echo for Intune enrollment to be successful
		echo Download the needed version via the Microsoft website
	fi

	breaker
	sleep 2
	menu
}

pwcheck(){
	breaker
	
	sed -n '25p;26q' /etc/pam.d/common-password

	breaker
	sleep 2
	menu
}

echo Welcome to the Intune Linux Assistance Tool
breaker
menu
