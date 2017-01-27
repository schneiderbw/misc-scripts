@echo off


copy "\\<SERVER FQDN>\NetworkDeploy\Agent_Uninstall.exe" "C:\Agent_Uninstall.exe"
echo "Copied uninstaller from server"
echo "Executing uninstallation. Please wait..."
START /WAIT C:\Agent_Uninstall.exe
echo "Agent uninstalled.  Removing uninstaller"

echo "Beginning installation.  Copying Labtech from server."
copy "\\<SERVER FQDN>\NetworkDeploy\LabTechInstall.MSI" "C:\LabTechInstall.MSI"
echo "Copied Labtech from Server"
msiexec.exe /i "C:\LabTechInstall.MSI" /q
echo "Labtech installed, deleting MSI"
del /Q C:\LabTechInstall.MSI
