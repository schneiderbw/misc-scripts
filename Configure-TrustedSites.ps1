#####################################################
#                                                   #
# Name: Configure-TrustedSites.ps1                  #
# Author: Benjamin W. Schneider, Evolution Networks #
# Creation Date: August 13, 2017                    #
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



## Add a new line to $siteList for each site to insert.  All lines (except for the last) end in a comma!
## Syntax: ("<Full URL>","<Zone Number>"),
## Example: ( "https://url.mydomain.com", "1" )

$siteList = (
    ("https://autologon.microsoftazuread-sso.com","1"),
    ("https://msappproxy.net","1")
)

######## DO NOT MODIFY BELOW THIS LINE ##########

function New-TrustedIESite	{
	<#
		.SYNOPSIS  
			Programmatically add a URI to a security zone in Internet Explorer.
		
		.DESCRIPTION  
			URIs can be added to the Trusted Sites, Local Intranet, Restricted Sites, or Internet zones in Internet Explorer. Full support for using either any protocol including http, https, ftp, etc.
		
		.NOTES  
			Version      	   		: 1.0 
			Wish list						: scope for machine (all users) or current user
													: remove entry
			Rights Required			: TBD
			Sched Task Req'd		: No
			Lync Version				: N/A
			Author(s)      			: Pat Richard, Lync MVP
			Email/Blog/Twitter	: pat@innervation.com  http://www.ehloworld.com  @patrichard
			Dedicated Post			: http://www.ehloworld.com/2545
			Disclaimer   				: You running this script means you won't blame me if this breaks your stuff. This script is
		    										provided AS IS without warranty of any kind. I disclaim all implied warranties including, 
														without limitation, any implied warranties of merchantability or of fitness for a particular
		    										purpose. The entire risk arising out of the use or performance of the sample scripts and 
		    										documentation remains with you. In no event shall I be liable for any damages whatsoever 
		    										(including, without limitation, damages for loss of business profits, business interruption,
		    										loss of business information, or other pecuniary loss) arising out of the use of or inability
		    										to use the script or documentation. 
			Acknowledgements 		: http://msdn.microsoft.com/en-us/library/system.uri(v=VS.90).aspx
		                      : http://blogs.technet.com/b/heyscriptingguy/archive/2005/02/14/how-can-i-add-a-web-site-to-the-trusted-sites-zone.aspx
			Assumptions					: 
			Limitations					: Not tested in an environment where a GPO locks down the security zones
			Known issues				: None yet, but I'm sure you'll find some!    		
		
		.LINK  
			http://www.ehloworld.com/2545
		
		.EXAMPLE
			.\New-TrustedIESite.ps1 -url https://www.contoso.com -zone 1 
		 
			Description
			-----------
			Adds https://www.contoso.com to the Trusted Intranet Sites in Internet Explorer
	#>
	#Requires -Version 2.0
	
	param(
		# Defines the URL to be placed into a security zone. URL must containt protocol, such as http, https, ftp, etc.
		[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] 
		[ValidateNotNullOrEmpty()]
		[string] $url,
	
		# This parameter defines what security zone the url specified via -url will be placed in. Options are 1 (Local Intranet), 2 (Trusted Sites), 3 (Internet), and 4 (Restricted Sites)
		[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] 
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1,4)]
		[int] $zone = 1,
		
		# Specified whether the site should be added for all users. If not specified, it is configured for the current user only
		[parameter(ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)] 
		[switch] $AllUsers
	)
	
	$error.clear()
	[object] $uri = [system.URI] $url
	[string] $scheme = ($uri).Scheme
	[string] $fqdn = ($uri).host
	[string[]] $split = $fqdn.split(".")
	[string] $resource = $split[0]
	[string] $domainname = $split[1]+"."+$split[2]
	[string] $regkey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"
	
	# domain
	if (Test-Path "$regkey\$domainname") { 
		Write-Host "Domain $domainname already exists." -ForegroundColor yellow
	} else { 
		# md "$regkey\$domainname" | Out-Null
		New-Item -Path "$regkey\$domainname" | Out-Null
		Write-Verbose "Domain name $domainname added"
	} 
	 
	# resource
	if (Test-Path "$regkey\$domainname\$resource") { 
		Write-Host "Site $resource.$domainname already exists." -ForegroundColor yellow 
	} else { 
		New-Item -Path "$regkey\$domainname\$resource" | Out-Null
		Write-Verbose "Resource $resource added"
	} 
	
	# scheme
	if (Get-ItemProperty -Name $scheme -path "$regkey\$domainname\$resource" -ErrorAction SilentlyContinue) { 
		Write-Host "Scheme $scheme already exists." -ForegroundColor yellow
		Write-Host "Setting for zone $zone" -ForegroundColor yellow
		Set-ItemProperty "$regkey\$domainname\$resource" -Name $scheme -Value $zone | Out-Null
	} else { 
		New-ItemProperty "$regkey\$domainname\$resource" -Name $scheme -Value $zone -PropertyType "DWord" | Out-Null
		Write-Verbose "Scheme $scheme configured"
	}
}

ForEach ($site in $siteList) {
    New-TrustedIESite -url $site[0] -zone $site[1]
}
