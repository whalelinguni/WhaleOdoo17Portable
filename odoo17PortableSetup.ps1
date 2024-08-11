#--------------------------------------------------------------------------------------------------------------------------------------------------------------#
#
#  Skip to line 260ish for the script start. The junk below is just a bunch of my super common used standard functions and setup and self elevation stuff.
#
#  The main issue is the python setup. When initially testing, it worked fine... now... it fails. I have tried setting env vars, no avail.
#  I'm kinda sick of this now. It's very close to working though. 
#                                                        -- Whale Linguini
#--------------------------------------------------------------------------------------------------------------------------------------------------------------#
param (
    [switch]$Debug  # Define a switch parameter for debugging
)
Clear-Host

# Stop execution on all errors
$ErrorActionPreference = "Stop"

# Initial setup
$origForegroundColor = $host.UI.RawUI.ForegroundColor
$origBackgroundColor = $host.UI.RawUI.BackgroundColor
$scriptDir = $PWD
$tmpDirectory = Join-Path -Path $scriptDir -ChildPath "tmp"
# Path to 7-Zip executable
$sevenZipPath = Join-Path -Path $scriptDir -ChildPath "bin\7z.exe"

# Self-elevate the script if required
Clear-Host
Write-Host "###################---------            [ Detecting Elevation Status ]            ---------###################"
Write-Host "#                           This script requires administrative privileges to run                            #"
Write-Host "#                            User will be prompted by UAC if elevation is required.                          #"
Write-Host "##############################################################################################################"
Write-Host ""
Write-Host "                                                        	-- Or UAC won't if it's disabled or something I guess."
Start-Sleep -Seconds 3

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine -WindowStyle Hidden
        Exit
    }
}

$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Green"
Clear-Host

#--- Function Definitions ---#
function Write-Message {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$InputString,

        [int]$SleepTime = 350,

        [switch]$Wide,

        [int]$LinePadding = 1
    )

    function Write-FormattedMessage {
        param(
            [string]$ForegroundColor,
            [string]$BackgroundColor,
            [string]$Prefix,
            [string]$Message,
            [int]$Padding
        )
        $paddingSpaces = " " * $Padding
        Write-Host -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor -NoNewLine $Prefix
        Write-Host -ForegroundColor White "$paddingSpaces$Message"
    }

    function Goodbye {
        Read-Host "Press Enter to exit"
        exit
    }

    # Split the input string into symbol and message
    $parts = $InputString -split ';'
    if ($parts.Count -ne 2) {
        Write-Host "Invalid input format. Please use 'Symbol; Message'."
        return
    }
    $Symbol = $parts[0].Trim()
    $Message = $parts[1].Trim()

    # Validate the symbol
    $validSymbols = "+", "-", "ERROR", "#", "W", "TITLE", "SUBTITLE", "NOTIFY"
    if (-not $validSymbols -contains $Symbol) {
        Write-Host "Unsupported message type: $Symbol"
        return
    }

    # Set the symbols based on the mode
    $prefix = if ($Wide) { "[  $Symbol  ]" } else { "[$Symbol]" }

    if ($Symbol -eq "NOTIFY") {
        $prefix = if ($Wide) { "[--Attention!--]" } else { "[--Attention!--]" }
    }
    if ($Symbol -eq "W") {
        $prefix = if ($Wide) { "[--WARNING!--]" } else { "[--WARNING!--]" }
    }

    switch ($Symbol) {
        "+" {
            # Process or Command etc has finished without error.
            Write-FormattedMessage -ForegroundColor Black -BackgroundColor Green -Prefix $prefix -Message $Message -Padding $LinePadding
        }
        "-" {
            # Process or command etc has started.
            Write-FormattedMessage -ForegroundColor Black -BackgroundColor Blue -Prefix $prefix -Message $Message -Padding $LinePadding
        }
        "ERROR" {
            Write-FormattedMessage -ForegroundColor Black -BackgroundColor Red -Prefix $prefix -Message $Message -Padding $LinePadding
        }
        "#" {
            Write-FormattedMessage -ForegroundColor Black -BackgroundColor Cyan -Prefix $prefix -Message $Message -Padding $LinePadding
        }
        "W" {
            Write-FormattedMessage -ForegroundColor Black -BackgroundColor Yellow -Prefix $prefix -Message $Message -Padding $LinePadding
        }
        "TITLE" {
            # Main section title
            Write-Host ""
            Write-Host "####--- $Message ---####" -BackgroundColor Green -ForegroundColor Black
        }
        "SUBTITLE" {
            # Sub section title.
            Write-Host "--- $Message ---" -BackgroundColor White -ForegroundColor Black
        }
        "NOTIFY" {
            Write-Host -ForegroundColor Red -BackgroundColor Yellow -NoNewLine $prefix
            Write-Host " $Message" -BackgroundColor Black -ForegroundColor White
        }
        default {
            Write-Host "Unsupported message type: $Symbol"
        }
    }

    Start-Sleep -Milliseconds $SleepTime

    # Example usage of Goodbye within the function
    if ($Symbol -eq "ERROR") {
        Goodbye
    }
}

function Test-PathEx {
    param (
        [string]$Path
    )
    Write-Message "#;Testing Path: $Path"
    if (Test-Path $Path) {
        Write-Message "#;Path Valid: $Path"
    } else {
        Write-Message "ERROR;Error. Path '$Path' does not exist.`nAborting. Exiting."
        Write-Host " "
        pause
        exit
    }
}

function loadButtholes {
    param (
        [string]$loadMsg
    )

    Write-Host $loadMsg -NoNewLine
    $Symbols = [string[]]('|','/','-','\')
    $SymbolIndex = [byte] 0
    $Job = Start-Job -ScriptBlock { Start-Sleep -Seconds 3 }
    while ($Job.'JobStateInfo'.'State' -eq 'Running') {
        if ($SymbolIndex -ge $Symbols.'Count') {$SymbolIndex = [byte] 0}
        Write-Host -NoNewline -Object ("{0}`b" -f $Symbols[$SymbolIndex++])
        Start-Sleep -Milliseconds 200
    }
}

function SplashMe {
    param([string]$Text)

    $Text.ToCharArray() | ForEach-Object {
        switch -Regex ($_){
            "`r" {
                break
            }
            "`n" {
                Write-Host " "; break
            }
            "[^ ]" {
                $writeHostOptions = @{
                    NoNewLine = $true
                }
                Write-Host $_ @writeHostOptions
                break
            }
            " " {
                Write-Host " " -NoNewline
            }
        } 
    }
}

function Write-HyphenToEnd {
    param (
        [string]$text = "",
        [int]$padding = 0
    )

    if ($text -eq "") {
        $consoleWidth = [Console]::WindowWidth
        Write-Host ("-" * $consoleWidth)
    } else {
        $textLength = $text.Length + ($padding * 2)
        Write-Host ("-" * $textLength)
    }
}

function pauseDebug {
	Write-Message "#; Debug pause"
	pause
}

function Test-InternetConnection {
    param (
        [string]$TestUrl = "github.com"
    )

    Write-Message "-;Checking network connection"

    try {
        $pingResult = Test-Connection -ComputerName $TestUrl -Count 1 -Quiet
        if ($pingResult) {
            Write-Message "+;Internet connection is active."
            return $true
        } else {
            Write-Message "W;No internet connection."
            #return $false
			return $true
        }
    } catch {
        Write-Message "ERROR;Error checking internet connection: $_"
        #return $false
		return $true
    }
}

$splash = @"
 _____     _               ___              _         _     _           ___                      _     _____ _                   
(  _  )   ( )             (  _ \           ( )_      ( )   (_ )        (  _ \            _      ( )_  (_   _) )    _             
| ( ) |  _| |  _     _    | |_) )  _   _ __|  _)  _ _| |_   | |   __   | (_(_)  ___ _ __(_)_ _  |  _)   | | | |__ (_) ___    __  
| | | |/ _  |/ _ \ / _ \  |  __/ / _ \(  __) |  / _  )  _ \ | | / __ \  \__ \ / ___)  __) |  _ \| |     | | |  _  \ |  _  \/ _  \
| (_) | (_| | (_) ) (_) ) | |   ( (_) ) |  | |_( (_| | |_) )| |(  ___/ ( )_) | (___| |  | | (_) ) |_    | | | | | | | ( ) | (_) |
(_____)\__ _)\___/ \___/  (_)    \___/(_)   \__)\__ _)_ __/(___)\____)  \____)\____)_)  (_)  __/ \__)   (_) (_) (_)_)_) (_)\__  |
                                                                                          | |                             ( )_) |
                                                                                          (_)                              \___/ 
"@

#--------------------------------------##--------------------------------------##--------------------------------------##--------------------------------------#
       ### Main Start Here ###                   ### Main Start Here ###                 ### Main Start Here ###              ### Main Start Here ###
#--------------------------------------##--------------------------------------##--------------------------------------##--------------------------------------#
Write-Host $splash
Write-HyphenToEnd
Write-Host ""
Start-Sleep -Seconds 0.84

Write-Host "I didn't add in downloading odoo. Please make sure that it is present and extracted to the 'Odoo-17-Community' directory in the script root."
Write-Host "It isn't going to check really either, so if you would like to make this work instead of failing, should probably do that."
Write-Hossst ""
I purposly broke it here to force you to do things.
# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #
# Look for the rocket ships to find notes on this dumpster fire code
# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #
$goScript = Read-Host "Start downloads and do things? (y/n)"
If ($goScript -eq 'Y' -or $goScript -eq 'y') {
	Write-Host "Ok!"
	Write-Host ""
  } else {
	 Write-Host "kthxbye"
	 Pause
	 exit 
}

if (Test-InternetConnection) {
    Write-Message "+;Proceeding with internet-dependent tasks."
} else {
    Write-Message "ERROR;Please check your internet connection."
#    exit
}

# Check if 7-Zip is installed
if (-not (Test-Path $sevenZipPath)) {
    Write-Host "7-Zip is not installed or not found in the bin directory. Please ensure 7-Zip is available in $sevenZipPath."
    exit
}

# --- Main Script Start --- #
Write-Host ""
Write-Message "SUBTITLE;Starting File Downloads!"
Write-Host ""

# --- Download and Extract Files --- #
$fileUrl1 = "https://github.com/winpython/winpython/releases/download/9.1.20240804/Winpython64-3.12.4.2b3.7z"
$fileName1 = [System.IO.Path]::GetFileName($fileUrl1)
$outputFile1 = Join-Path $scriptDir $fileName1
$fileUrl2 = "https://github.com/garethflowers/postgresql-portable/releases/download/v10.4.1/PostgreSQLPortable_10.4.1.zip"
$fileName2 = [System.IO.Path]::GetFileName($fileUrl2)
$outputFile2 = Join-Path $scriptDir $fileName2

Write-Message "-;Downloading [1/2] WinPython: $fileName1..."
#Invoke-WebRequest -Uri $fileUrl1 -OutFile $outputFile1
Write-Message "+;$fileName1 download finished"

Write-Message "-;Extracting $fileName1 ..."
Write-HyphenToEnd
$Host.UI.RawUI.ForegroundColor = "Cyan"
Start-Process $sevenZipPath -ArgumentList "x", "`"$outputFile1`"", "-o`"$scriptDir`"" -NoNewWindow -Wait
$Host.UI.RawUI.ForegroundColor = "Green"
Write-HyphenToEnd
Write-Message "+;Extraction complete"

Write-Message "-;Downloading [2/2] PostgreSQL: $fileName2..."
#Invoke-WebRequest -Uri $fileUrl2 -OutFile $outputFile2
Write-Message "+;$fileName2 download finished"

$extractDir2 = Join-Path $scriptDir "PostgreSQLPortable_10.4.1"
Write-Message "-;Extracting $fileName2 ..."
Write-HyphenToEnd
$Host.UI.RawUI.ForegroundColor = "Cyan"
Start-Process $sevenZipPath -ArgumentList "x", "`"$outputFile2`"", "-o`"$extractDir2`"" -NoNewWindow -Wait
$Host.UI.RawUI.ForegroundColor = "Green"
Write-HyphenToEnd
Write-Message "+;Extraction complete"


# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #
## Odoo Stuff  not implemented ##
# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #
Write-Message "-;Extracting Odoo 17 Community"
# Extract odoo17-community.7z to odoo17-community directory
$odooArchive = Join-Path $scriptDir "Odoo-17-Enterprise.7z"
$odooExtractDir = $scriptDir # Testing paths not final. Change this later

Write-HyphenToEnd
$Host.UI.RawUI.ForegroundColor = "Cyan"
# Start-Process $sevenZipPath -ArgumentList "x", "`"$odooArchive`"", "-o`"$odooExtractDir`"" -NoNewWindow -Wait
$Host.UI.RawUI.ForegroundColor = "Green"
Write-HyphenToEnd
Write-Message "+;Extraction complete"
# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #


Write-Message "+;All archives extracted!"
Write-Host ""

# --- Environment Check and Path Verification --- #
Write-Message "SUBTITLE;Checking environment ..."

# Define all paths and executables
$pythonExePath = Join-Path -Path $scriptDir -ChildPath "WPy64-31242b3\python-3.12.4.amd64\python.exe"
$pythonLauncherPath = Join-Path -Path $scriptDir -ChildPath "WPy64-31242b3\WinPython Command Prompt.exe"
$odooRequirements = Join-Path -Path $odooExtractDir -ChildPath "Odoo-17-Community\requirements.txt"
$pgsqlBinPath = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\App\PgSQL\bin"
$pgDataPath = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\data"
$odooConfPath = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\odoo.conf"
$odooBinPath = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\odoo-bin"
$odooDataDir = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\data"

# Verify that all paths exist
Test-PathEx $pythonExePath
Test-PathEx $odooRequirements
Test-PathEx $pgsqlBinPath
Test-PathEx $odooBinPath

Write-Message "+;Environment paths valid"
Write-Host ""

# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #
# Set PostgreSQL environment variables 
# Not sure if this is neeeded or not.
# This stuff should be removed when odoo is shutdown if you enable/set path stuffs.
# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #

#$env:PGSQL = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\App\PgSQL"
#$env:PGDATA = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\data"
#$env:PGUSER = "postgres"
#$env:PGPORT = "5432"
#$env:PGLOG = Join-Path -Path $env:PGDATA -ChildPath "logfile"
#$env:PGDATABASE = "odoo"
# Add PostgreSQL bin directory to PATH
#$env:PATH = "$env:PGSQL\bin;$env:PATH"
# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #


# --- Install Python Requirements --- #
Write-Message "SUBTITLE; Configuring Python"
Write-Message "-;Installing Python requirements from $odooRequirements ..."
Write-HyphenToEnd
Start-Process $pythonLauncherPath -ArgumentList "-m", "pip", "install", "-r", "`"$odooRequirements`"" -NoNewWindow -Wait
#Start-Process $pythonExePath -ArgumentList "-m", "pip", "install", "-r", "`"$odooRequirements`"" -NoNewWindow -Wait
Write-HyphenToEnd
Write-Message "+;Python requirements installation complete."
Write-Host ""

# --- Set Up PostgreSQL --- #
Write-Message "SUBTITLE;Configuring PostgreSQL..."
Write-Host ""

# Initialize PostgreSQL Database Cluster if not already initialized
if (-not (Test-Path $pgDataPath)) {
    Write-Message "-;Initializing PostgreSQL data directory..."
	Write-HyphenToEnd
    Start-Process -FilePath (Join-Path -Path $pgsqlBinPath -ChildPath "initdb.exe") -ArgumentList "--username=postgres", "--pgdata=`"$pgDataPath`"" -NoNewWindow -Wait
	Write-HyphenToEnd
    Write-Message "+;PostgreSQL data directory initialized."
} else {
    Write-Message "+;PostgreSQL data directory already exists, skipping initialization."
}

Write-Message "-;Starting PostgreSQL server..."
Write-HyphenToEnd

$pgsqlCmd = Join-Path -Path $pgsqlBinPath -ChildPath "pg_ctl.exe"
$pgLogFile = Join-Path -Path $pgDataPath -ChildPath "logfile"

# Use & to execute the command with arguments
& $pgsqlCmd start -D $pgDataPath -l $pgLogFile
Start-Sleep -Seconds 3
Write-HyphenToEnd
Write-Message "+;PostgreSQL server started."

# Create Odoo database
$odooDbName = "odoo"
Write-Message "-;Creating Odoo database '$odooDbName'..."
Start-Process -FilePath (Join-Path -Path $pgsqlBinPath -ChildPath "createdb.exe") -ArgumentList "--username=postgres", $odooDbName -NoNewWindow -Wait
Write-Message "+;Odoo database '$odooDbName' created."

Write-Message "+;PostgreSQL setup complete."
Write-Host ""

# --- Odoo Configuration File --- #
Write-Message "SUBTITLE;Configuring Odoo"
Write-Host ""
# Create the odoo.conf file if it does not exist
if (-not (Test-Path $odooConfPath)) {
    Write-Message "-;Creating Odoo configuration file at $odooConfPath ..."

    $odooConfContent = @"
	[options]
	addons_path = addons, odoo/addons
	data_dir = $odooDataDir
	db_host = localhost
	db_port = 5432
	db_user = odoo
	db_password = odoo_password
"@

    $odooConfContent | Out-File -FilePath $odooConfPath -Encoding utf8
    Write-Message "+;Odoo configuration file created."
} else {
    Write-Message "+;Odoo configuration file already exists."
}

# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #
# This just outright fails around here. I haven't got this far to debug.
# ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- ~~~ 8==D --------- #

# --- Initialize Odoo Environment --- #
Write-Message "-;Initializing Odoo environment with base module installation ..."
Write-HyphenToEnd
# Start Odoo in a new window
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $odooBinPath

# Properly format the arguments
$startInfo.Arguments = "--config=`"$odooConfPath`" -i base"
$startInfo.WindowStyle = "Normal"  # Opens in a normal window
$startInfo.UseShellExecute = $true
$startInfo.CreateNoWindow = $false

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo
$process.Start() | Out-Null

# Wait for the process to complete (adjust timeout as needed)
$process.WaitForExit()
Write-HyphenToEnd
# Check the exit code to determine success or failure
if ($process.ExitCode -eq 0) {
    Write-Message "+;Odoo environment initialized successfully."
} else {
    Write-Message "ERROR;Odoo initialization failed. Check the logs for more details."
}

$process.Dispose()
Write-Message "+;Odoo environment process closed."

Write-Message "+;Setup process complete."
