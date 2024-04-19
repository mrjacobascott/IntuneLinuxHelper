#! /bin/bash
#Intune Linux Helper
#Licensed under: MIT License
#For more information, see LICENSE file in the source repo https://github.com/mrjacobascott/IntuneLinuxHelper/tree/main
#Copyright (c) 2024 Jacob Scott

menu(){
	# Create a menu of actions to select from and perform
	echo "Choose an option by entering the number from the below list"
	echo "Note: Some options will request sudo/root access to perform" 
	echo "1-  Edge app-- Install, Update, or Uninstall"
	echo "2-  Intune app-- Install, Update, or Uninstall"
	echo "3-  Display UserID, Intune Device ID, Entra Device ID, "
	echo "    and Tenant ID for the enrollment"
	echo "4-  Display Microsoft software versions"
	echo "5-  Display hardware and OS software information"
	echo "6-  Check encryption status"
	echo "7-  Collect identity broker service logs locally"
	echo "8-  Upload identity broker, Intune, and Edge logs to Microsoft support"
	echo
	echo "T- Tips"
	echo "Q-  Quit"
	echo
	#request response from user, allows a single character
	read -n 1 -p "Enter selection: " reply
	echo
	echo "Selected: $reply"
	echo 
	#determining what was entered
	if [ "$reply" = "1" ]; then
		#edge app menu
		edgeApp
	elif  [ "$reply" = "2" ]; then
		#intune app menu
		intuneApp	
	elif  [ "$reply" = "3" ]; then
		#get userID, Intune deviceID, Entra device ID, and tenant ID
		uddata
	elif  [ "$reply" = "4" ]; then
		#display Edge and Intune software versions
		swversions
	elif  [ "$reply" = "5" ]; then
		#display hardware and software information
		machdata
	elif  [ "$reply" = "6" ]; then
		#check for disk encryption being enabled
		encryptCheck
	elif [ "$reply" = "7" ]; then
		#Collect identity broker service logs locally
		jourlogs
	elif [ "$reply" = "8" ]; then
		#Upload identity broker, Intune, and Edge logs to Microsoft support
		edgeLogs
	elif  [ "$reply" = "T" ] || [ "$reply" = "t" ]; then
		#display a list of tips
		tips
	elif  [ "$reply" = "Q" ] || [ "$reply" = "q" ]; then
		#exit script
		echo "Exiting"
		sleep 1
		exit 0
	else 
		#unknown response, redo
		echo "Unrecognized response"
		echo
		menu
	fi 
}

tips(){
	#display a list of tips to the user
	breaker
	echo "https://learn.microsoft.com/mem/intune/user-help/enroll-device-linux"
	echo "has the most up-to-date information. Basic info to know:"
	echo "- Intune enrollment is supported on: "
	echo "--- Ubuntu Desktop 20.04 LTS and 22.04 LTS with GNOME desktop"
	echo "- Microsoft Edge 102.X+ MUST be installed for enrollment to succeed"
	echo "--- You do not have to sign in to Edge for enrollment to succeed"
	echo "- All enrollments will be considered corporate"
	echo "- When in doubt, make sure both the Edge and Intune apps are up-to-date"
	echo "- Do not immediately try to sign in to the Intune app after a reboot"
	echo "    The auth modules take 30-60 seconds to startup. Please wait at"
	echo "    least 60 seconds after a reboot before attempting sign-in to the"
	echo "    Intune app. This will present sometimes as a 1001 error after"
 	echo "    entering your password and other times as showing a screen that"
  	echo "    has a button for -Get the App- instead of -Register-"
	breaker
	sleep 3
	menu
}

edgeApp(){
	#Ask the user if they want to install, update, or uninstall the Edge app
	breaker
	echo "Choose an option by entering the number from the below list"
	echo "1- Install the Edge app"
	echo "2- Update the Edge app"
	echo "3- Uninstall the Edge app"
	echo "Q- Quit"
	echo
	#pause for user input of 1 character
	read -n 1 -p "Enter selection: " reply
	echo
	echo "Selected: $reply"
	echo
	if [ "$reply" = "1" ]; then
		#install Edge
		edgeInstall "menu"
	elif  [ "$reply" = "2" ]; then
		#update Edge
		edgeUpdate
	elif  [ "$reply" = "3" ]; then
		#uninstall Edge
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

checkCurl(){
		MICROSOFT_KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
	httpResponse=$(curl --write-out "%{http_code}" --silent --output /dev/null "$MICROSOFT_KEY_URL")
	if [ $? -eq 0 ] && [ "$httpResponse" -eq 200 ] || [ "$httpResponse" -eq 204 ]; then
		echo "Curl is successful with response: $httpResponse"
		curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
		#install Microsoft signing cert(s)
		sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/ 
		return 0
	else
		echo
		echo "Curl is failing to get the Microsoft GPG key"
		echo "HTTP response code: $httpResponse"
		echo "Manually check network connectivity to https://packages.microsoft.com/keys/microsoft.asc"
		echo "Before trying again"
		echo "Aborting back to main menu"
		breaker
		return 1
	fi
}

edgeInstall(){
	#kick of Edge app installation flow
	breaker
	echo "Starting Edge installation"
	#install curl if not already
	sudo apt install curl gpg -y
	#check if curl is successful, abort if not
	if checkCurl $1; then
		echo "Curl success"
	else
		menu
	fi
	#add to apt ledger
	sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-ubuntu-focal-prod.list'
	#clear signing cert path
	sudo rm microsoft.gpg
	#update apt ledger
	sudo apt update -y
	#actually install the app
	sudo apt install microsoft-edge-stable -y
	echo
	echo
	echo "Edge installation complete"
	#verify Edge install was successful
	if command -v microsoft-edge-stable&> /dev/null; then
		#display new current version
		microsoft-edge-stable --version
	else
		echo "Edge installation failed"
		echo "Review installation logs above and/or try manual installation"
	fi
	sleep 2
	breaker
	#see if script flow should go back to main menu or 
	#go back Intune app installation
	if [ "$1" == "menu" ]; then
		menu
	elif [ "$1" == "installIntune" ]; then
		installIntune	
	fi
}

edgeUpdate(){
	#update the Edge app
	breaker
	echo "This will check to see if an update is available for the"
	echo "Edge app and install it if available. Starting version:"
	#validate that Edge is even installed
	if command -v microsoft-edge-stable&> /dev/null; then
		#display pre-update version
		microsoft-edge-stable --version
		echo
		sleep 2
		#do the apt update
		sudo apt update -y
		sudo apt-get dist-upgrade -y
		sleep 2
		echo "Completed. Version now:"
		#display new current version
		microsoft-edge-stable --version
	else
		# Edge wasn't detected, prompt user
		echo "Microsoft Edge is NOT installed. Edge MUST be installed"
		echo "for Intune enrollment to be successful."
		echo "Would you like to install the Edge app now? (Y/N)"
		read -n 1 -p "Enter selection: " reply
		echo
		echo "Selected: $reply"
		echo 
		if [ "$reply" = "Y" ] || [ "$reply" = "y" ]; then
			#Install Edge and go back to main menu when done
			edgeInstall "menu"
		elif  [ "$reply" = "N" ] || [ "$reply" = "n" ]; then
			echo "Not installing Edge"
		else 
			echo "Unrecognized response, back to main menu"
			breaker
			menu
		fi
	fi
	
	breaker
	sleep 2
	edgeApp
}

edgeRemove(){
	#uninstall Edge
	breaker
	echo "Uninstalling the Edge app"
	#uninstalls the app
	sudo apt remove microsoft-edge-stable -y
	#purges the configs
	sudo apt purge microsoft-edge-stable -y
	echo
	if command -v microsoft-edge-stable&> /dev/null; then
		#display version that is still installed
		echo "Microsoft Edge failed to uninstall. Version still installed: "
		microsoft-edge-stable --version
	else
		echo "Uninstall complete"
	fi
	breaker
	sleep 2
	menu
}


intuneApp(){
	#loads the intune app menu
	breaker
	echo "Choose an option by entering the number from the below list"
	echo "1- Install the Intune app"
	echo "2- Update the Intune app"
	echo "3- Uninstall the Intune app and remove device registration"
	echo "Q- Quit"
	echo
	read -n 1 -p "Enter selection: " reply
	echo
	echo "Selected: $reply"
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
	#installs the Intune app after validating Edge is already installed
	breaker
	if command -v microsoft-edge-beta&> /dev/null; then
		echo "Edge beta branch is installed. If Intune enrollment fails,"
		echo "     try switching to the stable branch"
	elif command -v microsoft-edge-dev&> /dev/null; then
		echo "Edge dev branch is installed. If Intune enrollment fails,"
		echo "     try switching to the stable branch"
	elif command -v microsoft-edge-stable&> /dev/null; then
		echo "Validated Microsoft Edge is already installed"
	else
		echo "Microsoft Edge is NOT installed. Edge MUST be installed"
		echo "for Intune enrollment to be successful"
		echo 
		echo "Would you like to install the Edge app now? (Y/N)"
		read -n 1 -p "Enter selection: " reply
		echo
		echo "Selected: $reply"
		echo 
		if [ "$reply" = "Y" ] || [ "$reply" = "y" ]; then
			edgeInstall "installIntune"
		elif  [ "$reply" = "N" ] || [ "$reply" = "n" ]; then
			echo "Not installing Edge, continuing with Intune app install"
		else 
			echo "Unrecognized response, back to main menu"
			breaker
			menu
		fi
	fi
	
	echo "Ready to install the Intune app"
	echo "The machine will automatically reboot when install is completed"
	echo "Do not immediately try to sign in to the Intune app after the reboot"
	echo "    The auth modules take 30-60 seconds to startup. Please wait at"
	echo "    least 60 seconds after a reboot before attempting sign-in to the"
	echo "    Intune app."
	echo
	read -n 1 -p "Are you sure you want to continue? [Y/N] " reply
	echo
	echo "Selected: $reply"
	echo 
	if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
		echo "Starting installation"
		#installs curl if not present
		sudo apt install curl gpg -y
		#check if curl is successful
		if checkCurl $1; then
			echo "Curl success"
		else
			menu
		fi
		#installs the certs
		sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/ 
		#validates the version of the OS so it gets the right source
		distro=$(lsb_release -rs)
		if [[ "$distro" == "20.04" ]]; then
			sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/20.04/prod focal main" > /etc/apt/sources.list.d/microsoft-ubuntu-focal-prod.list'
		elif [[ "$distro" == "22.04" ]]; then
			sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" > /etc/apt/sources.list.d/microsoft-ubuntu-jammy-prod.list' 
		else
			echo "Unable to determine if 20.04 or 22.04 distro version. Detected version: $distro"
		fi
		sudo rm microsoft.gpg
		#update apt ledger
		sudo apt update -y
		#install app
		sudo apt install intune-portal -y		
		echo
		echo
		
		if command -v intune-portal&> /dev/null; then
			#display installed version
			intune-portal --version
			# setting the intune app as a favorite so it's easy to find
			gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'intune-portal.desktop']"
			echo "Complete. Restarting in 5 seconds."
			sleep 5
			reboot
		else
			echo "Microsoft Intune app installation failed"
			echo "Review installation logs above and/or try manual installation"
			echo "NOT restarting the system since installation failed"
			echo "Returning to menu"
			breaker
			sleep 5
			menu
		fi
		
	else
		echo "Did not install Intune app. Returning to menu"
		sleep 2
		breaker
		menu
	fi
}

intuneUpdate(){
	#update the Intune app
	breaker
	echo "This will check to see if an update is available for the"
	echo "Intune and install it if available. Starting version: "
	if command -v intune-portal&> /dev/null; then
		intune-portal --version
		echo
		sleep 2
		sudo apt update -y
		sudo apt-get dist-upgrade -y
		sleep 2
		echo
		echo "Completed. Version now: "
		intune-portal --version
		breaker
		menu
	else
		# Intune wasn't detected, prompt user
		echo "Microsoft Intune is NOT installed"
		echo "Would you like to install the Intune app now? (Y/N)"
		read -n 1 -p "Enter selection: " reply
		echo
		echo "Selected: $reply"
		echo 
		if [ "$reply" = "Y" ] || [ "$reply" = "y" ]; then
			#Install Intune
			intuneInstall 
		elif  [ "$reply" = "N" ] || [ "$reply" = "n" ]; then
			echo "Not installing the Intune app"
		else 
			echo "Unrecognized response, back to main menu"
			breaker
			menu
		fi
		
		breaker
		sleep 2
		menu
	fi
}

intuneRemove(){
	#remove the Intune app and the device registration information
	breaker
	echo "Selected remove the Intune app and device registration"
	echo "Note- This will not remove the objects from the Entra/Intune portals"
	echo "This only removes the enrollment locally from the device"
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
	dpkg -s libsecret-tools 2>/dev/null >/dev/null || sudo apt-get install libsecret-tools -y
	secret-tool search --all env 60a144fbac31dfcf32034c112a615303b0e55ecad3a7aa61b7982557838908dc
	secret-tool clear env 60a144fbac31dfcf32034c112a615303b0e55ecad3a7aa61b7982557838908dc
	secret-tool clear name LinuxBrokerSystemUserSecretKey
	secret-tool clear name LinuxBrokerRegularUserSecretKey
	sleep 3
	
	if command -v intune-portal&> /dev/null; then
		echo "Uninstallation of the Intune app failed. Currently installed version: "
		#display still installed version
		intune-portal --version		
	else
		echo "Microsoft Intune app uninstalled successfully"
	fi
	echo
	breaker
	sleep 2
	menu
}

edgeLogs(){
	#Trigger the Edge log upload if Edge is installed. Otherwise go to main menu
	breaker
	if command -v microsoft-edge-beta&> /dev/null; then
		echo "Edge beta branch is installed. If Intune enrollment fails,"
		echo "     try switching to the stable branch"
	elif command -v microsoft-edge-dev&> /dev/null; then
		echo "Edge dev branch is installed. If Intune enrollment fails,"
		echo "     try switching to the stable branch"
	elif command -v microsoft-edge-stable&> /dev/null; then
		echo "Confirmed Microsoft Edge is installed"
	else
		echo "Microsoft Edge is NOT installed, back to main menu"
			breaker
			sleep 2
			menu
	fi
	
	echo "Triggering Edge log upload"
	sudo /opt/microsoft/microsoft-identity-diagnostics/scripts/collect_logs
	breaker
	sleep 2
	menu
}

jourlogs(){
	#Collect the journal logs for the Identity service and save to desktop
	breaker
	echo "Collecting journalctl user and system identity broker logs. "
	echo "You will be able to find them on the desktop"
	journalctl --user -u microsoft-identity-broker.service --since today > ~/Desktop/journalctlUserlogs.txt
	journalctl --system -u microsoft-identity-broker.service --since today > ~/Desktop/journalctlSystemlogs.txt
	echo "Done"
	breaker
	sleep 2
	menu
}

encryptCheck(){
	#check for drive encryption
	breaker
	encStatus=$(sudo dmsetup status)
	if [[ "$encStatus" == *"No devices found"* ]]; then
		echo "Encryption is not enabled"
	else
		echo "$output"
	fi
	breaker
	sleep 2
	menu
}

breaker(){
	#simple line break method for the echos
	echo
	echo ------------------------------------------------------------
	echo
}

machdata(){
	#display information about the machine and OS
	breaker
	hostnamectl
	breaker
	sleep 2
	menu
}

uddata(){
	#display the userID, IntuneDeviceID, EntraDeviceID, Tenant ID to the user
	breaker
	FILE=~/.config/intune/registration.toml
	if [ -f "$FILE" ]; then
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
		done
	else
		echo "Device is not enrolled in Intune"
	fi 
	
	breaker
	sleep 2
	menu
}

swversions(){
	# verify if Edge and Intune apps are installed
	# prompt user if they are not
	# display versions if they are
	breaker
	if command -v microsoft-edge-beta&> /dev/null; then
		microsoft-edge-beta --version
		echo "Edge beta branch is installed. If enrollment is failing,"
		echo "     try switching to the stable branch"
	elif command -v microsoft-edge-dev&> /dev/null; then
		microsoft-edge-dev --version
		echo "Edge dev branch is installed. If enrollment is failing,"
		echo "     try switching to the stable branch"
	elif command -v microsoft-edge-stable&> /dev/null; then
		microsoft-edge-stable --version
	else
		echo "Microsoft Edge is NOT installed. Edge MUST be installed"
		echo "for Intune enrollment to be successful"
		echo 
		echo "Would you like to install the Edge app now? (Y/N)"
		read -n 1 -p "Enter selection: " reply
		echo
		echo "Selected: $reply"
		echo 
		if [ "$reply" = "Y" ] || [ "$reply" = "y" ]; then
			edgeInstall "menu"
		elif  [ "$reply" = "N" ] || [ "$reply" = "n" ]; then
			echo "Not installing Edge, back to main menu"
			breaker
			sleep 1
			menu
		else 
			echo "Unrecognized response, back to main menu"
			breaker
			menu
		fi
	fi
	
	if command -v intune-portal&> /dev/null; then
		intune-portal --version
	else
		echo "Microsoft Intune app is not installed"
		echo "Would you like to install the Microsoft Intune app now? (Y/N)"
		read -n 1 -p "Enter selection: " reply
		echo
		echo "Selected: $reply"
		echo 
		if [ "$reply" = "Y" ] || [ "$reply" = "y" ]; then
			intuneInstall
		elif  [ "$reply" = "N" ] || [ "$reply" = "n" ]; then
			echo "Not installing Intune app, back to main menu"
			breaker
			sleep 1
			menu
		else 
			echo "Unrecognized response, back to main menu"
			breaker
			menu
		fi
	fi
	
	breaker
	sleep 2
	menu
}

#what is ran on script start

#init logging
log_file="/tmp/intunelinuxhelper.log"
{
	date '+[%Y-%m-%d %H:%M:%S] Starting script'
	echo "Welcome to the Intune Linux Assistance Tool"
	breaker
	menu
	date '+[%Y-%m-%d %H:%M:%S] Script exit'
} 2>&1 | tee -a "$log_file"
