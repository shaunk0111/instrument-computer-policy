<# Returns User Group SharePoint URL #>
function Assign-SharePointGroupURL($groupIdentifier) {

    # Get Group Idetifier
    #$groupIdentifier = Get-SharePointGroupIdentifier $userAccount

    # Assign path
    if ($groupIdentifier) {

        # Realtive SharePoint path 
        $groupSharePointPath = "$DATA_ARCHIVE_PATH/$groupIdentifier"
	
	    $isPath = Resolve-PnPFolder -SiteRelativePath $groupSharePointPath

        # Error checking
        if ($isPath) {
                    
            # URL SharePoint path    
            $groupSharePointURL = "$BASE_SHAREPOINT_URL/$groupSharePointPath"

            Write-Host "$(Get-Date) [SharePoint] Assigned group path $groupSharePointURL"

            return $groupSharePointURL

        } else {

            Write-Host "$(Get-Date) [Error] User path $groupSharePointURL not found"

            return $null
        }
    }
}


<# Returns User SharePoint URL #>
function Assign-SharePointUserURL($userAccount) {

    # Get User identifier
    $userIdentifier = Get-SharePointUserIdentifer $userAccount

    # Get Group Idetifier
    $groupIdentifier = Get-SharePointGroupIdentifier $userAccount

    # Assign path
    if ($userIdentifier -and $groupIdentifier) {

        # Realtive SharePoint path 
        $userSharePointPath = "$DATA_ARCHIVE_PATH/$groupIdentifier/$userIdentifier"
	
	    $isPath = Resolve-PnPFolder -SiteRelativePath $userSharePointPath

        # Error checking
        if ($isPath) {
                    
            # URL SharePoint path    
            $userSharePointURL = "$BASE_SHAREPOINT_URL/$userSharePointPath"

            Write-Host "$(Get-Date) [SharePoint] Assigned user path $userSharePointURL"

            return $userSharePointURL

        } else {

            Write-Host "$(Get-Date) [Error] User path $userSharePointURL not found"

            return $null
        }
    }
}


<# Returns User Instrument SharePoint URL #>
function Assign-SharePointInstrumentURL($userAccount,$instrumentIdentifier) {

    # Get User identifier
    $userIdentifier = Get-SharePointUserIdentifer $userAccount

    # Get Group Idetifier
    $groupIdentifier = Get-SharePointGroupIdentifier $userAccount

    # Assign path
    if ($userIdentifier -and $groupIdentifier -and $instrumentIdentifier) {

        # Realtive SharePoint path 
        $userInstrumentSharePointPath = "$DATA_ARCHIVE_PATH/$groupIdentifier/$userIdentifier/$instrumentIdentifier"
	
	    $isPath = Resolve-PnPFolder -SiteRelativePath $userInstrumentSharePointPath

        # Error checking
        if ($isPath) {
                    
            # URL SharePoint path    
            $userInstrumentSharePointURL = "$BASE_SHAREPOINT_URL/$userInstrumentSharePointPath"

            Write-Host "$(Get-Date) [SharePoint] Assigned instrument path $userInstrumentSharePointURL"

            return $userInstrumentSharePointURL

        } else {

            Write-Host "$(Get-Date) [Error] Instrument path userInstrumentSharePointURL not found"

            return $null
        }
    }
}


<# Apply Group Permissions to Directory #>
function Apply-SharePointGroupPermissions($groupIdentifier) {

    $groupPath = "$DATA_ARCHIVE_PATH/$groupIdentifier"

    $groupFolderObject = Get-PnPFolder -Url $groupPath

    if ($groupFolderObject) {
        
        $securityGroupName = $GROUP_NAME_FRONT_TAG + $groupIdentifier

        $groupObject = Get-PnPGroup | ? Title -Like $securityGroupName

        if ($groupObject) {

            Set-PnPListItemPermission -List $groupPath -Identity $groupFolderObject.ListItemAllFields -Group $securityGroupName -AddRole 'Instrument'

            Write-Host "$(Get-Date) [SharePoint] Security Group $securityGroupName assigned to $groupPath"
        
        # Error group
        } else {

            Write-Host "$(Get-Date) [Error] Security Group $searchTerm not found"
        }
    
    # Error path
    } else {

        Write-Host "$(Get-Date) [Error] Path $searchTerm does not exist"
    }
}


<# Add User to Instrumentation Group #>
function Provision-SharePointUser($userAccount,$groupIdentifer) {

    # Remove from any existing groups

    $webObject = Get-PnPWeb

    $userAccountSearch = "i:0#.f|membership|$userAccount"

    $userObject = Get-PnPUser -Identity $userAccountSearch

    if ($userObject) {

        $groupName = "$GROUP_NAME_FRONT_TAG$groupIdentifer"

        $groupObject = Get-PnPGroup $groupName

        if ($groupObject) {

            # Group found
        
            Add-PnPUserToGroup -LoginName $userAccount -Identity $groupObject -Web $webObject

            Write-Host "$(Get-Date) [SharePoint] $userAccount assigned to $groupName"

        } else {

            # Group not found - set to default group

            $groupName = "$GROUP_NAME_FRONT_TAG$DEFAULT_GROUP"

            $groupObject = Get-PnPGroup $groupName

            Add-PnPUserToGroup -LoginName $userAccount -Identity $groupObject -Web $webObject

            Write-Host "$(Get-Date) [SharePoint] $userAccount assigned to $DEFAULT_GROUP"
        }
    }
}


<# Add Instrumentation Group #>
function Provision-SharePointGroup($groupIdentifer) {
    
    # Build group name
    $securityGroupName =  $GROUP_NAME_FRONT_TAG + $groupIdentifer

    # Create Site Group
    New-PnPGroup -Title $securityGroupName

    # Assign Directory
    Assign-SharePointGroupURL $groupIdentifer
    
    # Apply Security
    Apply-SharePointGroupPermissions $groupIdentifer

    Write-Host "$(Get-Date) [SharePoint] $groupIdentifer assigned as $securityGroupName"
}


<# Returns User #>
function Get-SharePointUserIdentifer($userAccount) {

    $userAccountSearch = "i:0#.f|membership|$userAccount"

    $userObject = Get-PnPUser -Identity $userAccountSearch

    if ($userObject) {
        
        $userIdentifer = Select-String  -InputObject $userAccount -Pattern ".+?(?=@)" | %{ $_.Matches } | %{ $_.Value }

        return $userIdentifer

    } else {

         return $null
    }
}


<# Returns Group #>
function Get-SharePointGroupIdentifier($userAccount) {

    $webObject = Get-PnPWeb

    $searchTerm = $GROUP_NAME_FRONT_TAG + "*"

    $groupsObject = Get-PnPGroup -Web $webObject | ? Title -Like $searchTerm

    $measure = $groupsObject | Measure-Object

    # Search groups for user
    foreach($group in $groupsObject) {

        $members = Get-PnPGroupMembers -Identity $group -Web $webObject

        foreach($member in $members) {

            if($($member.email) -eq $userAccount) {

                $foundGroup = $group

                ++$count
            }
        }
    }

    # Error checking groups
    if ($count -eq 1) {

       $groupIdentifer = Select-String  -InputObject $($group.title) -Pattern "([^_]*)$" | %{ $_.Matches } | %{ $_.Value }

       return $groupIdentifer
  

    } elseif ($count -eq 0) {

        # Error - Set to default chemistry-operations-global
            
        Write-Host "$(Get-Date) [SharePoint] Not in group set to default"

        Add-SharePointUser $userAccount $defaultGroup | Write-Host
        
        return $DEFAULT_GROUP 
           

    } elseif ($count -gt 1) { 

        # Error - Set to default chemistry-operations-global
            
        Write-Host "$(Get-Date) [Error] User found in $($measure.count) groups, must be in 1 group"

        Add-SharePointUser $userAccount $defaultGroup | Write-Host
        
        return $DEFAULT_GROUP
        
    } else {

        # Error - Set to default chemistry-operations-global

        Write-Host "$(Get-Date) [Error] Group error occured"

        Add-SharePointUser $userAccount $defaultGroup | Write-Host
        
        return $DEFAULT_GROUP
    }
} 


<# Initalise SharePoint Connection #>
function Init-SharePointConnection($credentialsSharePoint) {

    $connectionSharePoint = Connect-PnPOnline -Url $BASE_SHAREPOINT_URL -Credentials $credentialsSharePoint -ReturnConnection

        
    if ($connectionSharePoint) {

        Write-Host "$(Get-Date) [SharePoint] Connection established"

    } else {

        Write-Host "$(Get-Date) [Error] SharePoint failed to connect"
    }

    return $connectionSharePoint 
}