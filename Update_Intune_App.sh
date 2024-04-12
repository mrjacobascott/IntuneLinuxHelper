#! /bin/bash
echo ------Update the Intune App------
echo This will check to see if an update is available and install it
echo This window will close when completed
sleep 3
sudo apt update -y
sudo apt-get dist-upgrade -y
sleep 3
echo Completed. Exiting
exit 0
