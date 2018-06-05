#####################################################
# Title:       Install-Font.ps1                     #
# Author:      Benjamin W. Schneider                #
# Created:     6/5/2018                             #
# Modified:    6/5/2018                             #
#                                                   #
# Description: Use this script to install multiple  #
#              fonts on a Windows computer.         #
# Permissions: Run in either administrator or       #
#              SYSTEM context.                      #
#                                                   #
# Credits: Based on script from Michael Murgolo,    #
#          Senior Consultant, Microsoft Services.   #
#                                                   #
#####################################################

### Change these variables ###

# UNC Path on network where font files are stored
# Note: The computer object should have at least "Read" permission to the UNC path
$folderPath = "\\WBECS-ADSVR014\SoftwareDeploy\Fonts\lato" 


# Each item in the fontFile array matches the name of a font file stored in $folderPath
# Be sure to include the full file name including extension
$fontFiles = @(
    "Lato-Black.ttf",
    "Lato-BlackItalic.ttf",
    "Lato-Bold.ttf",
    "Lato-BoldItalic.ttf",
    "Lato-Hairline.ttf",
    "Lato-HairlineItalic.ttf",
    "Lato-Heavy.ttf",
    "Lato-HeavyItalic.ttf",
    "Lato-Italic.ttf",
    "Lato-Light.ttf",
    "Lato-LightItalic.ttf",
    "Lato-Medium.ttf",
    "Lato-MediumItalic.ttf",
    "Lato-Regular.ttf",
    "Lato-Semibold.ttf",
    "Lato-SemiboldItalic.ttf",
    "Lato-Thin.ttf",
    "Lato-ThinItalic"
    )

### Contents of Add-Font.ps1 as a function ###
function Add-Font {

#******************************************************************************
# File:     Add-Font.ps1
# Date:     08/28/2013
# Version:  1.0.1
#
# Purpose:  PowerShell script to install Windows fonts.
#
# Usage:    Add-Font -help | -path "<Font file or folder path>"
#
# Copyright (C) 2010 Microsoft Corporation
#
#
# Revisions:
# ----------
# 1.0.0   09/22/2010   Created script.
# 1.0.1   08/28/2013   Fixed help text.  Added quotes around paths in messages.
#
#******************************************************************************

#requires -Version 2.0

#*******************************************************************
# Declare Parameters
#*******************************************************************
param(
    [string] $path = "",
    [switch] $help = $false
)


#*******************************************************************
# Declare Global Variables and Constants
#*******************************************************************

# Define constants
set-variable CSIDL_FONTS 0x14 -option constant

# Create hashtable containing valid font file extensions and text to append to Registry entry name.
$hashFontFileTypes = @{}
$hashFontFileTypes.Add(".fon", "")
$hashFontFileTypes.Add(".fnt", "")
$hashFontFileTypes.Add(".ttf", " (TrueType)")
$hashFontFileTypes.Add(".ttc", " (TrueType)")
$hashFontFileTypes.Add(".otf", " (OpenType)")
# Type 1 fonts require handling multiple resource files.
# Not supported in this script
#$hashFontFileTypes.Add(".mmm", "")
#$hashFontFileTypes.Add(".pbf", "")
#$hashFontFileTypes.Add(".pfm", "")

# Initialize variables
$invocation = (Get-Variable MyInvocation -Scope 0).Value
$scriptPath = Split-Path $Invocation.MyCommand.Path
$fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

}

### Custom logic to process multiple files ###

foreach ($font in $fontFiles) {
    Add-Font -path $folderPath + "\" + $font
    }