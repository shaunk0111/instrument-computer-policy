<# Unmap Drive #>
function unmapDrive {
    
    Remove-PSDrive -Name "U" | Out-Null
}


<# Sync User Drive #>
function syncUserDrive {
 
	# Sync files
 
	$sync_log = robocopy $LOCAL_INSTRUMENT_DATA $DRIVE_INSTRUMENT_DATA /e /sec

    return $sync_log
}


<# Get sync total time #>
function getTime ($sync_log) {

	# Get total time

	$roboTotalTime = $sync_log -match '^(?= *?\b(Times)\b)((?!    Files).)*$'

	$roboTotalTime = $roboTotalTime -split "\s+"

	$sync_time = $roboTotalTime | Select -Index 3

    return $sync_time
}


<# Get Sync total bytes #>
function getBytes ($sync_log) {
 
	# Get total bytes

	$roboTotalBytes = $sync_log -match '^(?= *?\b(Bytes)\b)((?!    Files).)*$'

	$roboTotalBytes = $roboTotalBytes -split "\s+"

	$sync_bytes = $roboTotalBytes | Select -Index 3

    return $sync_bytes
}


<# Get users total hours #>
function calculateUserUsage {

	$lastLogout = Get-Date
	
	[Environment]::SetEnvironmentVariable("InstrumentLastLogout", $lastLogout, "User")

	$lastLogon = [DateTime]$env:InstrumentLastLogon
	
	$user_time = [math]::Round((New-TimeSpan -Start $lastLogon -End $lastLogout | Select -ExpandProperty "TotalHours"), 3)

	Write-Output "$(Get-Date) [Logoff] $COMPUTER_NAME\$USERNAME Hours:$USER_TIME" | Out-file $USER_LOG -append

    return $user_time
}


<# Remove local user policies #>
function removeLocalPolicies {
	
	# Remove shared user path to desktop

	Remove-Item "$USERHOME_PATH\Desktop\Shared Drive.lnk"
	
	# Remove local local instrument data path to desktop

	Remove-Item "$USERHOME_PATH\Desktop\Session Data.lnk"
	
	# Remove local local instrument data path to desktop

	Remove-Item "$USERHOME_PATH\Desktop\Instrument Setup.lnk"
}


<# Append Sync Logs #>
function appendSyncLogs {
	
	$isSyncLogPath = Test-Path $SYNC_LOG
	
	if (!$isSyncLogPath) {

			New-Item -Path $SYNC_LOG -ItemType File
	}

	Write-Output "$(Get-Date) [Sync] $COMPUTER_NAME\$USERNAME Bytes:$SYNC_BYTES" | Out-file $SYNC_LOG -append
}


<# Append Robo Logs #>
function appendRoboLogs {
	
	$isRoboLogPath = Test-Path $ROBO_LOG
	
	if (!$isRoboLogPath) {

			New-Item -Path $ROBO_LOG -ItemType File
	}

	Write-Output $ROBO_OUTPUT | Out-file $ROBO_LOG -append
}


<# Constants #>

$CONFIRM_WARNINGS = $false

$LOCAL_INSTRUMENT_DATA = $env:InstrumentDataLocal

$DRIVE_INSTRUMENT_DATA = $env:InstrumentDataDrive

$COMPUTER_NAME = $env:ComputerName

$USERNAME = $env:UserName

$USERHOME_PATH = $home

$USER_LOG = "$DRIVE_INSTRUMENT_DATA\log\usage.log"

$SYNC_LOG = "$DRIVE_INSTRUMENT_DATA\log\sync.log"

$ROBO_LOG = "$DRIVE_INSTRUMENT_DATA\log\robo.log"


<# init #>

$USER_TIME = calculateUserUsage

$ROBO_OUTPUT = syncUserDrive

$SYNC_TIME = getTime $ROBO_OUTPUT

$SYNC_BYTES = getBytes $ROBO_OUTPUT

appendSyncLogs

appendRoboLogs

unmapDrive

removeLocalPolicies