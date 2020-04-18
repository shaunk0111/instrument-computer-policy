<# Assign Instrument Directories #>
function assignDirectories {

	# Create instrument path

	$testInstrumentPath = Test-Path $INSTRUMENT_SETUP_PATH 

	if (!$testInstrumentPath) {

		New-Item -Path $INSTRUMENT_SETUP_PATH -ItemType Directory 
	}
	
	# Assign method path

	$testMethodPath = Test-Path $INSTRUMENT_METHODS_PATH 

	if (!$testMethodPath) {

		New-Item -Path $INSTRUMENT_METHODS_PATH -ItemType Directory 
	}

	# Create config path

	$testConfigPath = Test-Path $INSTRUMENT_CONFIG_PATH 

	if (!$testConfigPath) {

		New-Item -Path $INSTRUMENT_CONFIG_PATH -ItemType Directory 
	}

	# Create data path

	$isLogPath = Test-Path $INSTRUMENT_LOG_PATH 

	if (!$isLogPath) {
			
	   New-Item -Path $INSTRUMENT_LOG_PATH -ItemType Directory 
	}
}

<# Assign Instrument Environments #>
function assignEnvironments {
			
	# Set environment machine instrument paths

	[Environment]::SetEnvironmentVariable("InstrumentSetup", $INSTRUMENT_SETUP_PATH, "Machine")

	[Environment]::SetEnvironmentVariable("InstrumentMethods", $INSTRUMENT_METHODS_PATH, "Machine")

	[Environment]::SetEnvironmentVariable("InstrumentConfig", $INSTRUMENT_CONFIG_PATH, "Machine")

	[Environment]::SetEnvironmentVariable("InstrumentLog", $INSTRUMENT_LOG_PATH, "Machine")
}


<#Constants#>

$INSTRUMENT_SETUP_PATH = "C:\ProgramData\Instrument"

$INSTRUMENT_METHODS_PATH = "$INSTRUMENT_SETUP_PATH\methods"

$INSTRUMENT_CONFIG_PATH = "$INSTRUMENT_SETUP_PATH\config"

$INSTRUMENT_LOG_PATH = "$INSTRUMENT_SETUP_PATH\log"


<#init#>

assignDirectories

assignEnvironments