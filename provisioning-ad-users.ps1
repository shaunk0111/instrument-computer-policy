param(
    [String]
    $usernameParam,
    
    [String]
    $groupParam, 
    
    [switch]
    $remove, 
    
    [switch]
    $add,

    [switch]
    $reportgroups)

<# Remove User from Groups #>
function removeUser ($userName) {

    # Inital values
    $groupCount = 0

    # Search for user
    $user = Get-ADUser $userName
    $user = $user | Select -ExpandProperty Name

    if ($user) {
   
        Write-Host "$(Get-Date) [User] Removing $user from any groups..."

        # Return all security groups
        $dataGroups = Get-ADGroup -SearchBase $securityGroupOU -filter {GroupCategory -eq "Security"}

        # Iterate through groups
        foreach ($groupSearch in $dataGroups) {
	
            $members = Get-ADGroupMember -Identity $groupSearch -Recursive | Select -ExpandProperty SamAccountName
            $groupName = $groupSearch | Select -ExpandProperty Name

	        # Remove from group
            if ($members -contains $user) {
                ++$groupCount
                Write-Host "$(Get-Date) [User] Removed from $groupName"
                Remove-ADGroupMember -Identity $groupName -Members "$user" -Confirm:$confirmWanrings
	        }
        }
        Write-Host "[Remove User] Total removed: $groupCount"
    }
}


<# Add User to Group #>
function addUser ($userName,$groupName) {
    
   # Inital values
   $groupCount = 0

   # Search for user
   $user = Get-ADUser $userName

   if ($user) {

        # Search for group
        $searchGroup = "*" + $groupName
        $foundGroup = Get-ADGroup -SearchBase $securityGroupOU -Filter { name -like $searchGroup }
        $groupName = $foundGroup | Select -ExpandProperty Name

        # Add user to group
        if ($foundGroup) {

            Write-Host "$(Get-Date) [User] Adding $userName to group..."

            Add-ADGroupMember -Identity $foundGroup -Members $user

            Write-Host "$(Get-Date) [User] Added $userName to $groupName"

            ++$groupCount

        # Group not found
        } else {

            Write-Host "$(Get-Date) [User] Group $foundGroup not found"
        }
        Write-Host "$(Get-Date) [User] Total added: $groupCount"

   # User not found
   } else {

        Write-Host "$(Get-Date) [User] $user not found"
        Write-Host "$(Get-Date) [User] Total added: $groupCount"
   }
}


<# User Report #>
function userReport($username) {

    # Inital values
    $isMember = $false

    # Search for user
    $userDistinguishedName = Get-ADUser $username
    $user = $userDistinguishedName | Select -ExpandProperty Name

    if ($user) {

        Write-Host "$(Get-Date) [Report] Reporting User information..."

        # Search for group
        $dataGroups = Get-ADGroup -SearchBase $securityGroupOU -filter {GroupCategory -eq "Security"}

        # Iterate through groups
        foreach ($groupSearch in $dataGroups) {
	
            $members = Get-ADGroupMember -Identity $groupSearch -Recursive | Select -ExpandProperty SamAccountName

            # Get group information
            if ($members -contains $user) {
                ++$groupCount
		        $isMember = $true
                $groupDistinguishedName  = $groupSearch | Select -ExpandProperty DistinguishedName
                $groupName = $groupSearch | Select -ExpandProperty Name
		        $groupIdentifier = $groupSearch | Select -ExpandProperty Name | Select-String -Pattern "([^_]*)$" | %{ $_.Matches } | %{ $_.Value }
	        }
        }

        # User is not in a group
        if ($isMember) {
            
            Write-Host "$(Get-Date) [Report] User Name: $user"
            Write-Host "$(Get-Date) [Report] User DistinguishedName: $userDistinguishedName"
            Write-Host "$(Get-Date) [Report] Group ID: $groupIdentifier"
            Write-Host "$(Get-Date) [Report] Group Name: $groupName"
            Write-Host "$(Get-Date) [Report] Group DistinguishedName: $groupDistinguishedName"
            Write-Host "$(Get-Date) [Report] Group Count: $groupCount"

	    } else {

            Write-Host "$(Get-Date) [Report] $username is not in a group"
        }
           
    # Username not in AD
    } else {

        Write-Host "$(Get-Date) [Report] $username not found in AD"    
    }
}


<# Returns User Group Identifier #>
function getGroupIdentifier($username) {

    # Inital values
    $isMember = $false

    # Search for user
    $userDistinguishedName = Get-ADUser $username
    $user = $userDistinguishedName | Select -ExpandProperty Name

    if ($user) {

        Write-Host "$(Get-Date) [Report] Reporting User information..."

        # Search for group
        $dataGroups = Get-ADGroup -SearchBase $securityGroupOU -filter {GroupCategory -eq "Security"}

        # Iterate through groups
        foreach ($groupSearch in $dataGroups) {
	
            $members = Get-ADGroupMember -Identity $groupSearch -Recursive | Select -ExpandProperty SamAccountName

            # Get group information
            if ($members -contains $user) {
                ++$groupCount
		        $isMember = $true
                $groupDistinguishedName  = $groupSearch | Select -ExpandProperty DistinguishedName
                $groupName = $groupSearch | Select -ExpandProperty Name
		        $groupIdentifier = $groupSearch | Select -ExpandProperty Name | Select-String -Pattern "([^_]*)$" | %{ $_.Matches } | %{ $_.Value }
	        }
        }

        # User is not in a group
        if ($isMember) {
            
            Write-Host "$(Get-Date) [Report] Group ID: $groupIdentifier"
            return $groupIdentifier
            
	    } else {

            Write-Host "$(Get-Date) [Report] $username is not in a group"
            return $null
        }
           
    # Username not in AD
    } else {

        Write-Host "$(Get-Date) [Report] $username not found in AD"
        return $null    
    }
}


<# Returns User Identifier #>
function getUserIdentifier($username) {

    # Convention firstname.middlename.surname.unikey

    # Get properties 
	$givenName = Get-ADUser $username | Select -ExpandProperty 'GivenName'
    $surname = Get-ADUser $username | Select -ExpandProperty 'Surname'

    # Build string
    $fullName = $givenName + " " + $surname
    $fullName = $fullName -replace '\s+', "."
    $userIdentifier = $fullName + "." + $username
	$userIdentifier = $userIdentifier.ToLower()

    return $userIdentifier
}


<# Assign Group Shared Directory #>
function assignGroupDirectory ($basePath,$groupIdentifier) {

    # Query Base Directory
    $isBasePath = Test-Path -Path $basePath

    if (!$isBasePath) {

        New-Item -Path $basePath -ItemType Directory | Out-Null
        Write-Host "$(Get-Date) [Group] Created base path: $basePath"
    }

    # Group path
    $groupPath = "$basePath\$groupIdentifier"

    # Query Group Directory
    $isGroupDrive = Test-Path -Path $groupPath

    if (!$isGroupDrive) {
        
        New-Item -Path $groupPath -ItemType Directory | Out-Null
        Write-Host "$(Get-Date) [Group] Created group path: $groupPath"

        applyGroupSecurity $groupPath $groupIdentifier

        return $groupPath
        
     } else {

        Write-Host  "$(Get-Date) [Group] Group path found: $groupPath"
        return $groupPath
     }
}


<# Returns User's Group Identifier #>
function getGroupSharePointPath($groupIdentifier) {
    
	return "$dataArchivePathSharePoint/$groupIdentifier"
}


<# Assign Instrument Directory#>
function assignInstrumentDirectory ($userPath,$instrumentIdentifier) {

    # Create log path
    $userInstrumentPath = "$userPath\$instrumentIdentifier"
    $userLogPath = "$userInstrumentPath\log"
    $testLogPath = Test-Path $userLogPath 
    if (!$testLogPath) {

	    New-Item -Path $userLogPath -ItemType Directory | Out-Null
    }

    # Create config path
    $userConfigPath = "$userInstrumentPath\config"
    $testConfigPath = Test-Path $userConfigPath 
    if (!$testConfigPath) {

	    New-Item -Path $userConfigPath -ItemType Directory | Out-Null
    }

    # Create data path
    $userDataPath = "$userInstrumentPath\data"
    $testUserDataPath = Test-Path $userDataPath | Out-Null
    if (!$testUserDataPath) {
			
	   New-Item -Path $userDataPath -ItemType Directory | Out-Null
    }

    Write-Host "[User] Created instrument directory $userInstrumentPath"

    return $userInstrumentPath 
}


<# Apply Security #>
function applyUserSecurity ($username,$userPath) {

    Write-Host "$(Get-Date) [Security] Assigned User permissions"

    # It attempting to apply security group to user folder
    $userDrivePermissions = ':(OI)(CI)F'
    $grantPermissions = $username + $userDrivePermissions
		
    icacls $userPath /grant $grantPermissions /t | Out-Null
}


<# Apply Security #>
function applyGroupSecurity ($groupPath,$groupIdentifier) {

    # Query Security Group groupIdentifier
    $groupIdentifier = "*$groupIdentifier"
    $isSecurityGroup = Get-ADGroup -SearchBase $securityGroupOU -filter {GroupCategory -eq "Security" -and Name -like $groupIdentifier } | Select -First 1
    $securityGroupName = $isSecurityGroup | Select -ExpandProperty Name
    	
    if ($securityGroupName) {

        Write-Host "$(Get-Date) [Security] Assigned Security Group permissions $securityGroupName"

        # Group Permisisons 
        $groupDrivePermissions = ':(OI)(CI)RX'
		$grantPermissions = $securityGroupName + $groupDrivePermissions
		
        # Apply Permissions
        icacls $groupPath '/inheritance:d' | Out-Null
        icacls $groupPath '/remove' 'Users' | Out-Null
        icacls $groupPath '/remove' 'Authenticated Users' | Out-Null	
        icacls $groupPath '/remove' 'Everyone' | Out-Null	
        icacls $groupPath '/grant' $grantPermissions '/t' | Out-Null

    } else {
        Write-Host "$(Get-Date) [Error] Security Group not found"
        exit 0
    }

}


<# Move User into Data Security Group #>
function provisionUser($username,$groupIdentifier) {

    Write-Host "$(Get-Date) [Provisioning Task] [User: $userName] Add User to Instrumentation Data Security Group"
    
    # Set Base Path
    $basePath = "***" 

    # Default user
    if(!$username) {
        $username = "***"
    }

    # Remove user from all groups
    removeUser $username

    # Default group
    if(!$groupIdentifier) {
        $groupIdentifier = "chemistry-global"
    }

    # Add User to group
    addUser $username $groupIdentifier

    # Create User Directory
    createUserDirectory $username $groupIdentifier

    # Return report
    userReport $username
}


<# Remove User from Data Security Group #>
function provisionUserRemoval($username) {

    Write-Host "$(Get-Date) [Provisioning Task] [User: $userName] Remove User from Instrumentation Data Security Groups"

    # Set Base Path
    $basePath "***"
    
    # Default user
    if(!$username) {
        $username = "***"
    }

    # Remove user from all groups
    removeUser $username

    # Return report
    userReport $username
}


<# Remove User from Data Security Group #>
function provisionLocalInstrumentUser($username) {

    Write-Host "$(Get-Date) [Provisioning Task] [User: $userName] Build Local User Instrument Directory"

    # Set Base Path
    $basePath = "C:\Groups"

    # Get Local Environments
    $instrumentIdentifier = $env:InstrumentName
    $computer = $env:ComputerName
    $user = $env:UserName
    $userHome = $home
    
    # Return Group Identifier
    $groupIdentifier = getGroup $username

    # Assign group path
    $groupPath = assignGroupDirectory $basePath $groupIdentifier
    
    # Assign User path
    $userPath = assignUserDirectory $username $groupPath $groupIdentifier

    # Assign User Instrument Path
    $userInstrumentPath = assignInstrumentDirectory $userPath $instrumentIdentifier
}

# Local Machine Environments
$userName = $env:UserName
$confirmWanrings = $true
$userDrivePermissions = ':(OI)(CI)F'

# Environments
$instrumentIdentifier = $env:InstrumentName
$computer = $env:ComputerName
$userHome = $home