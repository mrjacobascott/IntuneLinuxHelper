#! /bin/bash
echo ------Uninstalling the Intune App------
echo This window will close when completed
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
echo Completed. Exiting
exit 0
