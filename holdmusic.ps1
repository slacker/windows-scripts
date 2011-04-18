<#
.SYNOPSIS
    Prepares new hold music files and copies them to a target directory for use.
.DESCRIPTION
    This script will take a directory of wav files and properly rename them to
	fit the needs of the I3 phone system.  It will make copies of the files it
	there are less than the necessary nine.  The files are then copied to the
	target directory for use and also inside a folder in the target directory
	for archive purposes.
.NOTES
    File Name : holdmusic.ps1
    Author    : Daniel Robertson <dan@540tech.com>
.EXAMPLE
    ./holdmusic.ps1 "C:\Users\djr\desktop\Hold Music 2011-04-18" "\\bowic-a\d$\i3\ic\resources"
.PARAMETER source
    Source directory containing the new files
.PARAMETER target
    Target directory to place the new files
.PARAMETER noArchive
    Switch to disable creating the archive folder when copying to target directory
.PARAMETER noDefault
    Switch to disable overwriting the SystemDefaultAudioOnHold.wav file
#>

param([string]$source = '.', [string]$target, [switch]$noArchive, [switch]$noDefault)

if ( ! $source.EndsWith("\"))
{
    $source = $source + "\"
}

try
{
    $files = Get-ChildItem $source -filter "*.wav" -ErrorAction stop
}
catch [system.exception]
{
    Write-Warning "Invalid source directory"
	exit
}

if ( ! $files.count)
{
    Write-Warning "No wav files found in source directory"
    exit
}

if ($target -and ( ! (Test-Path $target)))
{
    Write-Warning "Invalid target directory"
	exit
}

# Copy files so we have 9 total (or 8 if $noDefault is set)
[int]$diff = 9 - $files.count
if ($noDefault)
{
    $diff--
}
for ($i=0; $i -lt $diff; $i++)
{
    Copy-Item ($source + [string]$files[$i]) ($source + $i + ".wav")
}

# Update the list of files
$files = Get-ChildItem $source -filter "*.wav" | Sort-Object -property CreationTime

# Rename files
for ($i=0; $i -le 7; $i++)
{
    Rename-Item ($source + [string]$files[$i]) ($source + "SystemAudioOnHold" + $i + ".wav") -ErrorAction SilentlyContinue
}
if ( ! $noDefault)
{
    Rename-Item ($source + [string]$files[8]) ($source + "SystemDefaultAudioOnHold.wav")
}


# Copy to target
if ($target)
{	
    # Copy to destination
    Copy-Item ($source + "*.wav") $target -force
	
	if ( ! $noArchive)
    {
        # Copy to folder for archiving
        Copy-Item $source $target -recurse
    }
}

Write-Host "Operation completed."