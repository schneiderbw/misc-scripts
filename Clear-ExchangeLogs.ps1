################################################################################
# Script: Clear-ExchangeLogs.ps1
# Author: Benjamin Schneider benjamin.schneider@evolvemynetwork.com
# Date: 4/17/2018
# Keywords:
# Comments:
# Pre-Requisites: PowerShell Execution Permission on Exchange Server, Exchange
#                 2013 or 2016
#
# +------------+-----+---------------------------------------------------------+
# |       Date | Usr | Description                                             |
# +------------+-----+---------------------------------------------------------+
# | 4/17/2018 | BWS | Initial Script                                          |
# +------------+-----+---------------------------------------------------------+
#
# DISCLAIMER
# ==========
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
# RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
##################################################################################

##################################################################################
#            Variables
#
# How many days do you want to keep logs?
$days = 30
#
##################################################################################

# Import IIS Administration Module
Import-Module WebAdministration

# Create the array where we store the IIS log file locations
$iisLogPath = @()

# Get location of IIS logs
foreach($WebSite in $(get-website))
    {
    $logFile="$($Website.logFile.directory)\w3scv$($website.id)".replace("%SystemDrive%",$env:SystemDrive)
    Write-Verbose "Got IIS Site $($WebSite.name) [$logfile]"
    $iisLogPath += $logFile
    } 

# Load in Exchange Management SnapIn
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

# Create the array where we store the Exchange Database Log file locations
$edbLogPath = @()

# Get location of Exchange Database Logs
foreach($edb in $(Get-MailboxDatabase))
    {
    $edbLogFile=$edb.LogFolderPath
    Write-Verbose "Got MDB $($edb.Name) [$edbLogFile]"
    $edbLogPath += $edbLogFile
    }

# Create the array where we store ETL logging paths
$etlLogPath = @()

##################################################################################
# Note: Per Microsoft Blog Post (https://bit.ly/2qANieq) ETL files should only
#       reside in two static places.  The location can be changed in the registry
#       but will automatically be switched back by Exchange.  In order to future-
#       proof this script, I'll program it to read the locations from the
#       system's registry.
##################################################################################

