param(
   
    [String]
    $groupParam, 
	
	[String]
    $baseDrive,
	
	[String]
    $securityGroupNamingConvention,
	
	[String]
    $securityGroupOU,
    
    [switch]
    $remove, 
    
    [switch]
    $add,

    [switch]
    $reportgroups,
    
    [switch]
    $mapdrive,
    
    [switch]
    $unmapdrive)


# Constants
$confirmWanrings = $true
$userName = $env:UserName
$groupDrivePermissions = ':(OI)(CI)RX'


<# Add Security Group #>
function createSecurityGroup ($groupIdentifier) {

    # Security Group attributes
    $securityGroupDescription = "Instrumentation Data Repository $baseDrive\$groupIdentifier"
    $securityGroupName =  $securityGroupNamingConvention + $groupIdentifier
    
    # Query Security Group groupIdentifier
    $groupIdentifierSearch = "*$groupIdentifier"
    $isSecurityGroup = Get-ADGroup -SearchBase $securityGroupOU -filter {GroupCategory -eq "Security" -and Name -like $securityGroupName } | Select -First 1
    #$securityGroupName = $isSecurityGroup | Select -ExpandProperty Name

    # Check Security Group
    if (!$isSecurityGroup) {

        # Create Security Group
        Write-Output "$(Get-Date) [Security Group] Assigned path: $securityGroupOU"
        New-ADGroup -Name $securityGroupName -SamAccountName $securityGroupName -GroupCategory Security -GroupScope Global -Path $securityGroupOU -Description $securityGroupDescription
        Write-Output "$(Get-Date) [Security Group] Assigned name: $securityGroupName"
        Write-Output "$(Get-Date) [Security Group] Assigned description: $securityGroupDescription"
        
        } else {
        
        Write-Output "$(Get-Date) [Security Group] Found: $securityGroupName"
    }
}


<# Add Group Shared Directory #>
function createGroupDirectory ($groupIdentifier) {

    # Shared Drive
    $groupDrivePath = "$baseDrive\$groupIdentifier"

    # Query Group Directory
    $isDrive = Test-Path -Path $groupDrivePath

    if (!$isDrive) {

        # Create new Shared Drive Path
		Write-Output "$(Get-Date) [Shared Drive] Created path: $groupDrivePath"
		New-Item -Path $groupDrivePath -ItemType Directory | Out-Null
            
    } else {
        
        Write-Output  "$(Get-Date) [Shared Drive] Path found: $groupDrivePath"
    }
}


<# Apply Security #>
function applyGroupSecurity ($groupIdentifier) {

    # Shared Drive
    $groupDrivePath = "$baseDrive\$groupIdentifier"

    # Query Security Group groupIdentifier
    $groupIdentifier = "*$groupIdentifier"
    $isSecurityGroup = Get-ADGroup -SearchBase $securityGroupOU -filter {GroupCategory -eq "Security" -and Name -like $groupIdentifier } | Select -First 1
    $securityGroupName = $isSecurityGroup | Select -ExpandProperty Name
    	
    if ($securityGroupName) {

        Write-Output "$(Get-Date) [Shared Drive] Assigned Security Group $securityGroupName"

		$grantPermissions = $securityGroupName + $groupDrivePermissions
		
        icacls $groupDrivePath /inheritance:d
        icacls $groupDrivePath /grant $grantPermissions /t
        icacls $groupDrivePath /grant "shared\Users" /t

    } else {
        Write-Output "$(Get-Date) [Error] Security Group not found"
        exit 0
    }

}

<# Get Groups Report #>
function getGroupReport {

    # Inital values
    $groupCount = 0

    # Return all security groups
    $dataGroups = Get-ADGroup -SearchBase $dataSearchBase -filter {GroupCategory -eq "Security"}

    if ($dataGroups) {
   
        Write-Output "$(Get-Date) [Report] Reporting Groups information..."

        # Iterate through groups
        foreach ($groupSearch in $dataGroups) {

            ++$groupCount
            $groupName = $groupSearch | Select -ExpandProperty Name
            Write-Output "$(Get-Date) [Report] Security Group Name: $groupName"
        }

        Write-Output "$(Get-Date) [Report] Total Groups: $groupCount"
    }
}


<# Groups Report #>
function mapDrive {

    New-PSDrive -Name "I" -PSProvider "FileSystem" -Persist -Root $baseDrive -Scope global | Out-Null
    Write-Output "$(Get-Date) [Shared Drive] Mapped $baseDrive"
}


<# Remove drive #>
function unmapDrive {
    
    Remove-PSDrive -Name "I" | Out-Null
    Write-Output "$(Get-Date) [Drive] Removed $baseDrive"
}


<# Create Instrumentation Data User Group #>
function provisionGroup ($groupIdentifier) {
   
    # Create Security Group
    Write-Output "$(Get-Date) [Provisioning Task] [User: $userName] Creating Instrumentation Data Security Groups..."
    createSecurityGroup $groupIdentifier

    # Create Group Directory
    Write-Output "$(Get-Date) [Provisioning Task] [User: $userName] Creating Instrumentation Data Drive..."
    createGroupDirectory $groupIdentifier

    # Work around - the time between creating a Security Group and applying it to a directory has limits
    Write-Output "$(Get-Date) [Provisioning Task] [User: $userName] Waiting for Security Group to process in AD..."
    Start-Sleep 30

    # Apply Security
    Write-Output "$(Get-Date) [Provisioning Task] [User: $userName] Applying Security Policies..."
    applyGroupSecurity $groupIdentifier
}


# init

# Map Instrumentation Drive
if ($mapdrive) {
    
    mapDrive

}

# Map Instrumentation Drive
if ($unmapdrive) {
    
    unmapDrive

}

Switch ($true) {
       
    $add { provisionGroup $groupParam }

    $reportgroups { groupsReport }
}


