#####################################################
#                                                   #
# Name: Set-MSOLlicensing.ps1                       #
# Author: Benjamin W. Schneider, Evolution Networks #
# Creation Date: June 21, 2016                      #
# Modification Date: May 18, 2017                   #
# License: (c) 2018, B.W. Schneider Enterprises,    #
#    All Rights Reserved. Do Not Modify or Reuse    #
#                                                   #
#####################################################

    ########                        ##              ##      ##                          ##      ##              ##                                              ##                  
   ##        ##      ##    ####    ##  ##    ##  ########        ####    ######        ####    ##    ####    ########  ##      ##      ##    ####    ##  ####  ##  ##      ######   
  ######    ##      ##  ##    ##  ##  ##    ##    ##      ##  ##    ##  ##    ##      ##  ##  ##  ########    ##      ##      ##      ##  ##    ##  ####      ####      ####        
 ##          ##  ##    ##    ##  ##  ##    ##    ##      ##  ##    ##  ##    ##      ##    ####  ##          ##        ##  ##  ##  ##    ##    ##  ##        ##  ##        ####     
########      ##        ####    ##    ######      ####  ##    ####    ##    ##      ##      ##    ######      ####      ##      ##        ####    ##        ##    ##  ######        



Import-Module MSOnline
Import-Module ActiveDirectory

#SECURITY RISK: This credential should be a single use credential which is assigned the "User Administrator" AAD admin role.
$username = "someuser@domain.foo"
$password = "Password Goes Here" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, ($password)

$O365UsageLocation = "US"

#Each item in the "group" array matches the name of an AD group
$groups = @("O365-BusinessEssentials",
    "O365-BusinessPremium",
    "O365-E3",
    "ExchangeOnline")

Connect-MsolService -Credential $credential 

foreach ($group in $groups) {
    $sku = $(Get-ADGroup -Identity $group -Properties extensionAttribute1).extensionAttribute1
    $members = Get-ADGroup -Identity $group | Get-ADGroupMember
    foreach ($member in $members) {
        $AdUpName = (Get-ADUser -Identity $member -Properties *).UserPrincipalName
    
        if ((Get-MsolUser -UserPrincipalName $AdUpName).UsageLocation -eq $null) {
            Set-MsolUser -UserPrincipalName $AdUpName -UsageLocation $O365UsageLocation
        } else {
            echo "UsageLocation already set for $AdUpName"
        }
        if ((Get-MsolUser -UserPrincipalName $AdUpName).isLicensed -eq $false) {
            Set-MsolUserLicense -UserPrincipalName $AdUpName -AddLicenses $sku
            echo "Set license $sku for user $AdUpName"
        } else {
            if ((Get-MsolUser -UserPrincipalName $AdUpName | Select-Object -ExpandProperty Licenses).AccountSkuId -ne $sku) {
                $oldSku = $((Get-MsolUser -UserPrincipalName $AdUpName | Select-Object -ExpandProperty Licenses).AccountSkuId)
                Set-MsolUserLicense -UserPrincipalName $AdUpName -AddLicenses $sku -RemoveLicenses $oldSku
                echo "Removed license $oldSku for user $AdUpName."
                echo "Set license $sku for user $AdUpName."
            }
        }
    }
}
