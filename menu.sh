#! /bin/bash
# Create a menu of actions to perform in the VM
menu(){
	echo Choose an option by entering the number from the below list
	echo 1- Install the Intune app
	echo 2- Update the Intune app
	echo 3- Uninstall the Intune app and remove device registration
	echo 4- Display relevant software versions
	echo 5- Display enforced password requirements
	echo 6- Display UserID, Intune Device ID, Entra Device ID, 
	echo "   and Tenant ID for the enrollment"
	echo 7- Display hardware and OS software information
	echo 8- Check encryption status
	echo 9- Collect identity broker service logs locally
	echo 10- Upload identity broker, Intune, and Edge logs to Microsoft support

	echo Q- Quit
	echo
	read -p "Enter number: " reply
	echo 
	if [ "$reply" = "1" ]; then
		/home/intuneuser/Documents/Scripts/Install_Intune_App.sh
	elif  [ "$reply" = "2" ]; then
		/home/intuneuser/Documents/Scripts/Update_Intune_App.sh	
	elif  [ "$reply" = "3" ]; then
		/home/intuneuser/Documents/Scripts/Uninstall_Intune_App.sh
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
