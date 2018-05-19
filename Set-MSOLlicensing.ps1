Import-Module MSOnline
Import-Module ActiveDirectory

$username = "someuser@domain.foo"
$password = "Password Goes Here" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, ($password)

$O365UsageLocation = "US"

#Each item in the "group" array matches the name of an AD group
$groups[0] = "O365-BusinessEssentials"
$groups[1] = "O365-BusinessPremium"
$groups[2] = "O365-E3"
$groups[3] = "ExchangeOnline"

Connect-MsolService -Credential $credential 

foreach ($group in $groups) {
    $sku = Get-ADGroup -Identity $group -Properties extensionAttribute1
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
        } else {
            if ((Get-MsolUser -UserPrincipalName $AdUpName | Select-Object -ExpandProperty Licenses).AccountSkuId -ne $sku {
                $oldSku = $((Get-MsolUser -UserPrincipalName $AdUpName | Select-Object -ExpandProperty Licenses).AccountSkuId)
                Set-MsolUserLicense -UserPrincipalName $AdUpName -AddLicenses $sku -RemoveLicenses $oldSku
            }
        }
    }
}
