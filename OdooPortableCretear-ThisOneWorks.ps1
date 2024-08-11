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

function waitAbortion {
    $timeout = 5

    Write-Host ""
Write-Host "[### Pausing for option for abortion. ###]"
    Write-Host "Press any key within $timeout seconds to exit, or wait to continue..."
    Write-Host ""

    for ($seconds = 0; $seconds -lt $timeout; $seconds++) {
        Start-Sleep -Seconds 1

        if ([Console]::KeyAvailable) {
            Write-Host "`nKey pressed. Exiting..."
            exit
        }
    }

    Write-Host "`nNo key was pressed. Continuing..."
	Write-Host ""
}

function SleepBaby {
    # Generate a random number between 0.20 and 0.85, rounded to two decimal places
    $randNum = [math]::Round((Get-Random -Minimum 0.20 -Maximum 0.85), 2)
    
    # Output the random number for verification (optional)
    #Write-Host "Sleeping for $randNum seconds..."
    
    # Sleep for the random interval
    Start-Sleep -Seconds $randNum
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
# https://archive.org/details/odoo-17-enterprise.-7z

Write-Host $splash
Write-HyphenToEnd
Write-Host ""
Start-Sleep -Seconds 0.84

Write-Host "I may have left some debug code behind, or whatever, this works, and I quit"
Write-Host "This script sets up a portable instance of Odoo."
Write-Host "Please ensure that the Odoo package is extracted to the 'Odoo-17-Community' directory in the script root."
Write-Host "This script will configure and initialize PostgreSQL, set up the necessary Odoo database, and configure Odoo to run in portable mode."
Write-Host ""
Write-Host "Once the portable instance has been created, use the provided launcher script to start or stop the Odoo portable instance."
Write-Host "If Odoo is not properly extracted to the specified directory, the script will fail."
Write-Host "do not go here https://archive.org/details/odoo-17-enterprise.-7z"
Write-Host "-- Whale Linguini"
Write-Host "also I didn't write the script to control the start/stop whatever yet, or maybe I won't ever, I'm very sick of this script."
Write-Host ""


$goScript = Read-Host "Start downloads and do things? (y/n)"
If ($goScript -eq 'Y' -or $goScript -eq 'y') {
	Write-Host "Ok!"
	Write-Host ""
  } else {	
	 Write-Host "kthxbye"
	 Pause
	 exit 
}

# ------------------------------------#
# ---       startup checks         ---#
# ------------------------------------#
Write-Message "SUBTITLE;Startup Checks"
Write-Host ""
SleepBaby
if (Test-InternetConnection) {
    Write-Message "+;Proceeding with internet-dependent tasks."
} else {
    Write-Message "ERROR;Please check your internet connection."
#    exit
}

# Check if 7-Zip is installed
Write-Message "-;Checking for 7z binary"
if (-not (Test-Path $sevenZipPath)) {
    Write-Host "7-Zip is not installed or not found in the bin directory. Please ensure 7-Zip is available in $sevenZipPath."
    exit
}
Write-Message "+;7z binary found"

# --- Script Start More or less --- #
Write-Host ""
Write-Message "SUBTITLE;Starting File Downloads!"
Write-Host ""

# ------------------------------------#
# --- Download and Extract Files --- #
# ------------------------------------#
$fileUrl1 = "https://github.com/winpython/winpython/releases/download/4.6.20211106/Winpython64-3.10.0.1.exe"
$fileName1 = [System.IO.Path]::GetFileName($fileUrl1)
$outputFile1 = Join-Path $scriptDir $fileName1

$fileUrl2 = "https://github.com/garethflowers/postgresql-portable/releases/download/v10.4.1/PostgreSQLPortable_10.4.1.zip"
$fileName2 = [System.IO.Path]::GetFileName($fileUrl2)
$outputFile2 = Join-Path $scriptDir $fileName2

Write-Message "-;Downloading [1/2] WinPython: $fileName1..."
Invoke-WebRequest -Uri $fileUrl1 -OutFile $outputFile1
Write-Message "+;$fileName1 download finished"

Write-Message "-;Extracting $fileName1 ..."
Write-HyphenToEnd
$Host.UI.RawUI.ForegroundColor = "Cyan"
Start-Process $sevenZipPath -ArgumentList "x", "`"$outputFile1`"", "-o`"$scriptDir`"" -NoNewWindow -Wait
$Host.UI.RawUI.ForegroundColor = "Green"
Write-HyphenToEnd
Write-Message "+;Extraction complete"
Write-Host ""
SleepBaby

Write-Message "-;Downloading [2/2] PostgreSQL: $fileName2..."
Invoke-WebRequest -Uri $fileUrl2 -OutFile $outputFile2
Write-Message "+;$fileName2 download finished"

$extractDir2 = Join-Path $scriptDir "PostgreSQLPortable_10.4.1"
Write-Message "-;Extracting $fileName2 ..."
Write-HyphenToEnd
$Host.UI.RawUI.ForegroundColor = "Cyan"
Start-Process $sevenZipPath -ArgumentList "x", "`"$outputFile2`"", "-o`"$extractDir2`"" -NoNewWindow -Wait
$Host.UI.RawUI.ForegroundColor = "Green"
Write-HyphenToEnd
Write-Message "+;Extraction complete"
Write-Host ""
Write-Message "+;All downloads and extractions complete"
waitAbortion
SleepBaby



# ------------------------------------#
# ---       Enviorment Check       ---#
# ------------------------------------#
Write-Message "SUBTITLE;Enviorment Check"
Write-Host ""
Write-Message "-;Checking enviorment paths"
SleepBaby

# Add the new paths
$pythonExePath = Join-Path -Path $scriptDir -ChildPath "WPy64-31001\python-3.10.0.amd64\python.exe"
$pythonLauncherPath = Join-Path -Path $scriptDir -ChildPath "WPy64-31001\WinPython Command Prompt.exe"

# Modify paths for the Python requirements installation
$odooRequirements = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\requirements.txt"
$pgsqlBinPath = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\App\PgSQL\bin"
$pgDataPath = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\data"
$odooConfPath = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\odoo.conf"
$odooBinPath = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\odoo-bin"
$odooDataDir = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\data"
$pgBinPath = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\App\PgSQL\bin"
#$pgDataPath = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\data" # this does not exist yet

# Verify that all paths exist
Test-PathEx $pythonExePath
Test-PathEx $odooRequirements
Test-PathEx $pgsqlBinPath
Test-PathEx $odooBinPath
Test-PathEx $pgBinPath
#Test-PathEx $pgDataPath # this does not exist yet


Write-Message "+;Environment paths valid"
Write-Host ""


# ------------------------------------#
# --- Install Python Requirements --- #
# ------------------------------------#
Write-Message "SUBTITLE; Configuring Python"
Write-Host ""
SleepBaby
Write-Message "NOTIFY;Warnings/Errors about PATH can be ignored"
Write-Host ""

# Option to clear pip cache for good measure.
$cachePath = "$env:LOCALAPPDATA\pip\cache"

if (Test-Path $cachePath) {
    Write-Host "Press any key before 0 to clear the pip cache directory for good measure."

    $seconds = 10
    while ($seconds -gt 0) {
        Write-Host -NoNewline "$seconds "
        Start-Sleep -Seconds 1
        $seconds--

        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Write-Host "`nDeleting the pip cache directory..."
            Remove-Item -Recurse -Force $cachePath
            Write-Host "The pip cache directory has been deleted."
			Write-Host ""
            break
        }
    }

    if ($seconds -eq 0) {
        Write-Host "`nNo key was pressed. The pip cache directory was not deleted."
		Write-Host ""
    }
} else {
    Write-Host "The pip cache directory does not exist at: $cachePath"
	Write-Host ""
}


# Attempt to install libsass==0.21
Write-Message "-;Installing libsass==0.21 ..."
Write-HyphenToEnd
$Host.UI.RawUI.ForegroundColor = "Green"
Start-Process $pythonExePath -ArgumentList "-m", "pip", "install", "libsass==0.21", "--only-binary=:all:" -NoNewWindow -Wait
$Host.UI.RawUI.ForegroundColor = "Green"
Write-HyphenToEnd
Write-Message "-; Checking for libsass install"
SleepBaby
# Check if libsass was installed successfully
$libsassInstalled = & $pythonExePath -m pip show libsass

if (-not $libsassInstalled) {
    Write-Message "ERROR;Failed to install libsass==0.21. Check the output for details."
	Write-Host "This could possibly be a false error. Please check the console."
    $goScript = Read-Host "Continue Anyways? (y/n)"
If ($goScript -eq 'Y' -or $goScript -eq 'y') {
	Write-Host "Ok!"
	Write-Host ""
	Write-Message "+;libsass==0.21 installation complete. (probably)"
  } else {
	 Write-Host "kthxbye"
	 Pause
	 exit 
}
} else {
    Write-Message "+;libsass==0.21 installation complete."
}

# Modify the requirements.txt to comment out the libsass line
Write-Message "-;Removing libsass from requirements.txt ..."
$requirementsContent = Get-Content $odooRequirements
$requirementsContent | ForEach-Object {
    if ($_ -match "^libsass") {
        "# $_"  # Comment out the libsass line
    } else {
        $_  # Keep the other lines as they are
    }
} | Set-Content $odooRequirements
Write-Message "+;Removed libsass from requirements.txt"

# Install other Python requirements
Write-Message "-;Installing Python requirements from $odooRequirements ..."
Write-HyphenToEnd
SleepBaby
$Host.UI.RawUI.ForegroundColor = "Green"
Start-Process $pythonExePath -ArgumentList "-m", "pip", "install", "-r", "`"$odooRequirements`"" -NoNewWindow -Wait
Write-HyphenToEnd

if ($LASTEXITCODE -ne 0) {
    Write-Message "ERROR;Failed to install Python requirements. Check the output for details."
} else {
    Write-Message "+;Python requirements installation complete."
	Write-Host ""
}
SleepBaby



# --------------------------#
# --- Set Up PostgreSQL --- #
# --------------------------#
Write-Message "SUBTITLE;Configuring PostgreSQL..."
Write-Host ""

# Define PostgreSQL paths
$pgBinPath = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\App\PgSQL\bin"
$pgDataPath = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\data"
$pgLogFile = Join-Path -Path $pgDataPath -ChildPath "logfile"
$pgPortableBin = Join-Path -Path $scriptDir -ChildPath "PostgreSQLPortable_10.4.1\PostgreSQLPortable.exe"

# Start PostgreSQL server
Write-Message "-;Starting PostgreSQL server as a new process."
Start-Process -FilePath $pgPortableBin -ArgumentList "start -D `"$pgDataPath`" -l `"$pgLogFile`"" -NoNewWindow -PassThru

# Wait for PostgreSQL to fully start
Write-Message "#;Waiting 12 seconds for PostgreSQL to start..."
Start-Sleep -Seconds 12

# Check if PostgreSQL is running
Write-Message "-;Checking if PostgreSQL server is running..."
$pgProcessStatus = Get-Process -Name "postgres" -ErrorAction SilentlyContinue

if ($pgProcessStatus) {
    Write-Message "+;PostgreSQL server is running."
} else {
    Write-Message "ERROR;PostgreSQL server is not running."
    exit
}

# Create admin superuser if it doesn't exist
Write-Message "-;Creating PostgreSQL superuser 'admin'..."
$createAdmin = & "$pgBinPath\psql.exe" -U postgres -c "CREATE USER admin WITH SUPERUSER PASSWORD 'admin';"

if ($createAdmin) {
    Write-Message "+;Superuser 'admin' created."
} else {
    Write-Message "ERROR;Failed to create superuser 'admin'."
    exit
}

# Create odoo user and database
$odooDbName = "odoo"

# Create odoo user and database
$odooDbName = "odoo"
Write-Message "-;Creating PostgreSQL user 'odoo' with password 'odoo'..."
& "$pgBinPath\psql.exe" -U postgres -c "CREATE USER odoo WITH PASSWORD 'odoo';"
Write-Message "+;PostgreSQL user 'odoo' created."

Write-Message "-;Creating Odoo database '$odooDbName'..."
& "$pgBinPath\createdb.exe" -U postgres $odooDbName
Write-Message "+;Odoo database '$odooDbName' created."

Write-Message "-;Granting privileges on database 'odoo' to user 'odoo'..."
& "$pgBinPath\psql.exe" -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE odoo TO odoo;"
Write-Message "+;Privileges granted to user 'odoo'."

Write-Message "+;PostgreSQL Setup Complete"
Write-Host ""
waitAbortion
SleepBaby




#############################################
Write-Host ""
Write-Message "SUBTITLE;Sanity Check"
Write-Host ""
$goScript = Read-Host "Continue? (y/n)"
If ($goScript -eq 'Y' -or $goScript -eq 'y') {
	Write-Host "Ok!"
	Write-Host ""
  } else {
	 Write-Host "kthxbye"
	 Pause
	 exit 
}
#############################################

# -------------------------------------------#
# --- Odooo Configuration File odoo.conf --- #
# -------------------------------------------#
Write-Message "SUBTITLE;Creating odoo.conf Configuration File"
Write-Host ""
SleepBaby

# Define the path to the odoo.conf file
$odooConfPath = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\odoo.conf"

# Define the content of the odoo.conf file
$odooConfContent = @"
[options]
addons_path = addons, odoo/addons
data_dir = $scriptDir\Odoo-17-Community\data
db_host = localhost
db_port = 5432
db_user = odoo
db_password = odoo
"@

# Write the content to the odoo.conf file
Write-Message "-;Writing odoo.conf file to $odooConfPath ..."
$odooConfContent | Set-Content -Path $odooConfPath
Test-PathEx $odooConfPath
Write-Message "+;odoo.conf configuration file created successfully."

SleepBaby
Write-Message "+;Odoo configutation complete."
Write-Host ""
waitAbortion

# -----------------------------#
# --- Initialize Odoo --- #
# -----------------------------#
Write-Message "SUBTITLE;Initializing Odoo..."
Write-Host ""

# Define the Odoo initialization command
$pythonExe = Join-Path -Path $scriptDir -ChildPath "WPy64-31001\python-3.10.0.amd64\python.exe"
$odooBin = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\odoo-bin"
$odooConf = Join-Path -Path $scriptDir -ChildPath "Odoo-17-Community\odoo.conf"
$odooDbName = "odoo"  # Explicitly defining the Odoo database name
$initModules = "base,web"

# Run the Odoo initialization command
$cmd = "$pythonExe $odooBin -c $odooConf -d $odooDbName --init=$initModules"
Write-Message "-;Running Odoo initialization with command:"
Write-Host $cmd

# Start the Odoo process
Start-Process -FilePath $pythonExe -ArgumentList "$odooBin -c $odooConf -d $odooDbName --init=$initModules"

# Notify the user that Odoo has been launched
Write-Message "+;Odoo has been successfully started and is initializing."
Write-Host ""
Write-Host "Odoo Portable Creation Finished."
Write-Host ""
Write-Message "SUBTITLE;Script Finished"
Write-Host ""
Write-Host ""

# Inform the user to check the console output and log file
Write-Host "Odoo should now be running. Please check the console output for initialization progress."
Write-Host "Once initialization is complete, you can access Odoo at http://localhost:8069 to log in."
Write-Host "Please use the launcher script to start/stop odoo portable"
Write-Host ""
Write-Host ""
Write-Host "goodbye."
write-host ""
pause
