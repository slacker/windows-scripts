<#
.SYNOPSIS
	Retrieve a list of all domain user accounts along with the groups they are
	members of.
.DESCRIPTION
	This will query your active directory domain for all user accounts
	(currently includes contacts) and place them in a csv file along with
	their active directory group memberships.
.NOTES
	File Name : users.ps1
	Author    : Daniel Robertson <dan@540tech.com>
#>

$SearchRoot = New-Object System.DirectoryServices.DirectoryEntry
    
# Build the search
$searcher = New-Object System.DirectoryServices.DirectorySearcher
$searcher.SearchRoot = $SearchRoot
$searcher.SearchScope = "Subtree"
$searcher.PageSize = 1000
$searcher.Filter = "(objectCategory=User)"

# Perform the search
$list = @()
foreach ($user in $searcher.FindAll())
{
	$groups = @()
	foreach ($group in $user.properties.memberof)
	{
		$groups += $group
	}
	$list += new-object psobject -property @{"name" = [string]$user.properties.name; "groups" = [string]::join(" ", $groups)}
}

$list | export-csv -path users.csv
