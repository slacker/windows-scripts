<#
.SYNOPSIS
    This script allows you to find out who is logged into remote computers.
.DESCRIPTION
    You can call this script to run against a specific computer, a space
    separated list of computers, a file containing a list of computers on
    individual lines.  You can also run it against every computer in your
    domain or an individual OU.
.NOTES
    File Name : loggedin.ps1
    Author    : Daniel Robertson <dan@540tech.com>
.EXAMPLE
    ./loggedin.ps1 computer1 computer2 computer3
.EXAMPLE
    ./loggedin.ps1 "C:\list of computers.txt"
.EXAMPLE
    ./loggedin.ps1 domain -byUser
.EXAMPLE
    ./loggedin.ps1 ou Accounting
.PARAMETER target
    The target may be any number of computers separated by a space.
    The target may be a path to a file.
    The target may be 'domain'.
    The target may be 'ou' followed by the name of an OU.
    If a target is not specified, the script will ask you to enter one.
.PARAMETER byUser
    By default the list will be sorted by computer name.  You can use
    the -byUser switch to instead sort the list by username.
#>

param([switch]$byUsers)
$list = $args

# Prompt for computers if none were given
while (-not $list[0])
{
    $list = Read-Host "Computers to check"
    $list = $list.split(" ")
}

# Allow searching through Active Directory
if (($list[0] -eq "domain") -or ($list[0] -eq "ou"))
{
    if ($list[0] -eq "domain")
    {
        $SearchRoot = New-Object System.DirectoryServices.DirectoryEntry
    }
    elseif ($list[0] -eq "ou")
    {        
        # Prompt for OU if one was not given
        $ou = $list[1]
        while (-not $ou)
        {
            $ou = Read-Host "Enter OU to check"
        }
        
        # Can't handle subdomains yet
        $dc1,$dc2 = $env:userdnsdomain.split(".")
        $SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://ou=$ou,dc=$dc1,dc=$dc2")
    }
    
    # Build the search
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = $SearchRoot
    $searcher.SearchScope = "Subtree"
    $searcher.PageSize = 1000
    $searcher.Filter = "(objectCategory=Computer)"
    
    # Only return the name property
    $searcher.PropertiesToLoad.Add("name") | Out-Null # Suppresses return value of Add()

    # Perform the search
    try
    {
        $list = @()
        foreach ($objResult in $searcher.FindAll())
        {
            $list = $list + $objResult.Properties.name
        }
    }
    catch [system.exception]
    {
        "ERROR: " + $_.exception.message
        exit
    }
}
# Allow a file with list of computers
elseif (Test-Path $list[0])
{
    $list = Get-Content $list[0]
}

$result = @{}
foreach ($ComputerName in $list)
{
    try
    {
        $result.$ComputerName = (Get-WMIObject win32_computersystem -computername $ComputerName -errorAction stop).username
        
        if ($result.$ComputerName -eq $null)
        {
            $result.$ComputerName = "(Not logged in)"
        }
    }
    catch [system.exception]
    {
        $result.$ComputerName = "(ERROR: Unable to connect to remote computer)"
    }
}

if ($byUsers)
{
    # Sort by username
    $result.GetEnumerator() | Sort-Object value
}
else
{
    # Sort by computer name
    [collections.sortedlist]$result
}