<#
.SYNOPSIS
Automaps the Onedrive client to sync with a sharepoint library
.DESCRIPTION
Run the script with all mandatory parameters
In order to use the parameters you need to fetch them from the applicable site.
Every _api link should have tenantname.sharepoint.com/ in front of it if it's the default site, or tenantname.sharepoint.com/sites/SITENAME for any other site.
If the _api data is hard to read, use a tool like https://codebeautify.org/xmlviewer
.PARAMETER siteid
_api/web
Search for "D:Id", here you will find the SiteID Guid
.PARAMETER webid
.PARAMETER listid
_api/web/Lists/getbytitle('NAMEOFTHELIBRARY')
Search for "D:Id", here you will find the ListID Guid
.PARAMETER URL
_api/web
Search for "D:web", here you will find the SiteID Guid
.PARAMETER webtitle
Set this to the name of the organisation
.PARAMETER listtitle
Set this to the name of the library
.EXAMPLE
.\SharePoint_Automapping.ps1 -siteid GUID -webid = "GUID" -listid = "GUID" -URL https://company.sharepoint.com/ -webtitle Company -listtitle Documents
which will create the following link for the OneDrive app:
start "odopen://sync/?siteId=GUID&webId=GUID&listId=GUID&userEmail=$upn&webUrl=https://company.sharepoint.com/&webtitle=Company&listtitle=Documents" 
.NOTES
In order to retrieve the _api info you need to log in to the tenant, no admin rights are necessary.
#>
param(
[string]$siteid,
[string]$webid,
[string]$listid,
[string]$URL,
[string]$webtitle,
[string]$listtitle
)
$rand = Get-Random -Maximum 10
sleep $rand
#Sleep is required, if the same script runs at the same time it'll mess up the configuration.
$Version = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID | Select-Object ReleaseID
if($version.releaseID -lt 1709) { break }
$strFilter = “(&(objectCategory=User)(SAMAccountName=$Env:USERNAME))”
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1
$objSearcher.Filter = $strFilter
$objSearcher.SearchScope = “Subtree”
$objSearcher.PropertiesToLoad.Add(“userprincipalname”) | Out-Null
$colResults = $objSearcher.FindAll()
$UPN = $colResults[0].Properties.userprincipalname
$path = "C:\Users\$($env:username)\Colacino Industries\Lime Networks - $($listtitle)"
if(Test-Path $path){
#DoNothing
} else {
start "odopen://sync/?siteId=$siteid&webId=$webid&listId=$listid&userEmail=$upn&webUrl=$URL&webtitle=$webtitle&listtitle=$listtitle" 
}
