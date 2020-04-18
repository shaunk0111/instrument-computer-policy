param(
   
    [String]
    $USER_BASE_DRIVE_PATH)

<# Map Drive #>
function mapDrive {

    New-PSDrive -Name "U" -PSProvider "FileSystem" -Persist -Root $USER_BASE_DRIVE_PATH -Scope global | Out-Null
	
    $isUserDrive = Test-Path "U:"

	return $isUserDrive
}


<# Map Shared Drive #>
function assignUserDrive {

	# Create user path

	$userDrivePath = "$USER_BASE_DRIVE_PATH\$USERNAME"

	$testUserPath = Test-Path $userDrivePath 

	if (!$testUserPath) {

		New-Item -Path $userDrivePath -ItemType Directory | Out-Null
	}
	
    return $userDrivePath
}


<# Assign Local Instrument Directory #>
function assignLocalDirectory {

	if ($INSTRUMENT_NAME) {
	
		$testInstrumentPath = Test-Path $USER_INSTRUMENT_PATH 

		if (!$testInstrumentPath) {

			New-Item -Path $USER_INSTRUMENT_PATH -ItemType Directory | Out-Null
		}
		
		# Create data path

		$userDataPath = "$USER_INSTRUMENT_PATH\data"

		$testUserDataPath = Test-Path $userDataPath | Out-Null

		if (!$testUserDataPath) {
				
		   New-Item -Path $userDataPath -ItemType Directory | Out-Null
		}	
	}
}


<# Assign Local Session Directory #>
function assignSessionDirectory {

	$runSession = Get-Date -UFormat "%Y-%m-%d_%H-%M"

	if ($INSTRUMENT_NAME) {
		
		# Create data session path

		$sessionData = "$USER_INSTRUMENT_PATH\data\$runSession"

		$isSession = Test-Path $sessionData | Out-Null

		if (!$isSession) {
				
		   New-Item -Path $sessionData -ItemType Directory | Out-Null
		}
	}

    return $sessionData 
}


function assignLocalPolicies {
	
	# Set desktop item to user shared drive

	$WshShell = New-Object -comObject WScript.Shell

	$sharedDriveShortcut = $WshShell.CreateShortcut("$USERHOME_PATH\Desktop\Shared Drive.lnk")

	$sharedDriveShortcut.TargetPath = "$USER_DRIVE"

	$sharedDriveShortcut.Save()
		

	# Set desktop item to user local data
	$WshShell = New-Object -comObject WScript.Shell

	$instrumentDataShortcut = $WshShell.CreateShortcut("$USERHOME_PATH\Desktop\Session Data.lnk")

	$instrumentDataShortcut.TargetPath = "$LOCAL_SESSION_DATA"

	$instrumentDataShortcut.Save()

	
	# Set desktop item to machine instrument setup

	$WshShell = New-Object -comObject WScript.Shell

	$instrumentDataShortcut = $WshShell.CreateShortcut("$USERHOME_PATH\Desktop\Instrument Setup.lnk")

	$instrumentDataShortcut.TargetPath = "$INSTRUMENT_SETUP_PATH"

	$instrumentDataShortcut.Save()
}


function appendLogs {

	# Assign user log path

	$isUserInstrumentPath = Test-Path $DRIVE_INSTRUMENT_DATA
	
	if (!$isUserInstrumentPath) {

			New-Item -Path "$DRIVE_INSTRUMENT_DATA\log" -ItemType Directory
	}
	
	# Assign user log file

	$isUserLogPath = Test-Path $USER_LOG
	
	if (!$isUserLogPath) {

			New-Item -Path $USER_LOG -ItemType File
	}

	Write-Output "$(Get-Date) [Logon] $COMPUTER_NAME\$USERNAME" | Out-file $USER_LOG -append
}


<# Constants #>

$CONFIRM_WARNINGS = $false

$USERNAME = $env:UserName

$USER_DRIVE_PERMISSIONS = ':(OI)(CI)RX'

$USERHOME_PATH = $home

$INSTRUMENT_NAME = $env:InstrumentName

$COMPUTER_NAME = $env:ComputerName

$INSTRUMENT_SETUP_PATH = $env:InstrumentSetup

$USER_INSTRUMENT_PATH = "$USERHOME_PATH\instrument\$INSTRUMENT_NAME"


<# init #>

$isdrive = mapDrive

if ($isdrive) {
			
	$USER_DRIVE = assignUserDrive

	$DRIVE_INSTRUMENT_DATA = "$USER_DRIVE\$INSTRUMENT_NAME"

	$USER_LOG = "$DRIVE_INSTRUMENT_DATA\log\usage.log"
		
	if ($USER_DRIVE) {
		
		assignLocalDirectory

		$LOCAL_SESSION_DATA = assignSessionDirectory
			
		if ($LOCAL_SESSION_DATA) {
			
            # Set environment local instrument data path

			[Environment]::SetEnvironmentVariable("InstrumentDataLocal", $USER_INSTRUMENT_PATH, "User")

			[Environment]::SetEnvironmentVariable("InstrumentDataSession", $LOCAL_SESSION_DATA, "User")

			[Environment]::SetEnvironmentVariable("InstrumentDataDrive", $DRIVE_INSTRUMENT_DATA, "User")

			[Environment]::SetEnvironmentVariable("InstrumentLastLogon", $(Get-Date), "User")			

			assignLocalPolicies
			
			appendLogs
				
		} else {

			[Environment]::SetEnvironmentVariable("InstrumentDataLocal", "", "User")

			[Environment]::SetEnvironmentVariable("InstrumentDataDrive", "", "User")
		}			
	}
	
} else {
	
	exit 0
}
   

   


