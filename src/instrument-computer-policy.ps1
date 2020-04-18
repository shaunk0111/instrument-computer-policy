
<# Install instrument-user #>
function instrument-user ($computers) {

	# Iterate through groups
	foreach ($computer in $computers) {

        $output = robocopy "$sharedDrivePolicy\instrument-user" "\\$computer\C$\_Install\instrument-user" /mir

        Write-Host $output

        Start-Sleep -s 1


        
		$RemoteResults = Invoke-Command -Credential $cred -ComputerName $computer -ScriptBlock { 

            Powershell "C:\_Install\instrument-user\instrument-user-installer.ps1 -install" 
        
            [PSCustomObject]@{ Result = $output;} 
        }
	}

    $output = foreach($computer in $computers){
    $present = $false
       foreach($result in $RemoteResults){
          if($computer -Match $result.PSComputerName){

                $result;
            };
        };

    };
    

     $output | Format-Table PSComputerName,Command,Result

}


<# Sets the instrument-user Credential #>
function install-instrument-user {

    <# Remove instrument-user installer from _Instal #>

    Write-Host "[Task] Remove instrument-user installer from _Install"

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {


        $isInstrumentUserPath = Test-Path "\\localhost\C$\_Install\instrument-user" 

        if ($isInstrumentUserPath) { Remove-Item "\\localhost\C$\_Install\instrument-user" -Recurse -Force }

        $output = robocopy "$sharedDrivePolicy\instrument-user" "\\localhost\C$\_Install\instrument-user" /mir
        
        $isInstrumentUserPath = Test-Path "\\localhost\C$\_Install\instrument-user" 

        [PSCustomObject]@{
            Result = "Test path: $isInstrumentUserPath"
            Command = 'Remove-Item "\\localhost\C$\_Install\instrument-user'
        }; 
    };

    $output = foreach($computer in $computerTargets){
        $present = $false
        foreach($result in $RemoteResults){
            if($computer -Match $result.PSComputerName){

                $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Command,Result


    <# Copy instrument-user installer into _Install #>
    
    Write-Host "[Task] Copy instrument-user installer into _Install"

	foreach ($computer in $computerTargets) { robocopy "$SHARED_DRIVE_PATH\policy\instrument-user" "\\$computer\C$\_Install\instrument-user" /mir /njh /njs /ndl /nc /ns }

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {
    
        $isInstrumentUserPath = Test-Path "\\localhost\C$\_Install\instrument-user" 


        [PSCustomObject]@{
            Result = "Test path: $isInstrumentUserPath"
            Command = 'Remove-Item robocopy "$SHARED_DRIVE_PATH\policy\instrument-user" "\\$computer\C$\_Install\instrument-user" /mir'
        }; 
    };

    $output = foreach($computer in $computerTargets){
        $present = $false
        foreach($result in $RemoteResults){
            if($computer -Match $result.PSComputerName){

                $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Command,Result


    <# Install instrument-user run instrument-user-installer.ps1  #>

    Write-Host "[Task] Install instrument-user"

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {

        $isInstrumentUserPath = Test-Path "\\localhost\C$\_Install\instrument-user" 

        if ($isInstrumentUserPath) { Powershell "C:\_Install\instrument-user\instrument-user-installer.ps1 -install" }
               
        $isInstrumentUserPath = Test-Path "C:\Program Files\Instrument instrument-user" 

        [PSCustomObject]@{
            Result = "Test path: $isInstrumentUserPath"
            Command = 'C:\_Install\instrument-user\instrument-user-installer.ps1 -install'
        }; 
    };

    $output = foreach($computer in $computerTargets){
        $present = $false
        foreach($result in $RemoteResults){
            if($computer -Match $result.PSComputerName){

                $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Command,Result	
}


<# Sets the instrument-user Credential #>
function set-instrument-user-credential ($SecureString) {

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName (Get-Content $computerTargets) -ScriptBlock { 

        $set = le -setcredentials "chemistry_instrument" $using:SecureString 
        $success = "*A command has been executed successfully*" 

        [PSCustomObject]@{
            Result = $set;
            Command = 'le -setcredentials "chemistry_kiosk" "********" '
        }; 
    };


    $output = foreach($computer in $computers){
        $present = $false
        foreach($result in $RemoteResults){
            if($computer -Match $result.PSComputerName){

                $result;
            };
        };

    };
    $output | Format-Table PSComputerName,Command,Result
	
}


function check-policy {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock { 

        $UserCheck = 'MCS\skoz2706'
                   
        $present = $false; 
        
        Get-LocalGroupMember -Group "Administrators" | ForEach-Object {

            if($_.Name -eq $UserCheck ){$present = $true;}
        };

        [PSCustomObject]@{
            IsAdmin = $present;
            WinRM = $true;
        }; 
    };

    $output = foreach($computer in $computers){
        $present = $false
        foreach($result in $RemoteResults){
            if($computer -Match $result.PSComputerName){
                $present = $true;
                $result;
                break;
            };
        };
        if(-Not $present) {
            [PSCustomObject]@{
                PSComputerName = $computer
                IsAdmin = $present;
                WinRM = $false;
            }; 
        };
    };
    $output | Format-Table PSComputerName,WinRM,IsAdmin

}


function assign-directory {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock { 

         # Base path
    
        $INSTRUMENT_PATH = "C:\_Instrument"

        # Assign log path
    
        $logPath = "$INSTRUMENT_PATH\log"
    
        $testLogPath = Test-Path $logPath 
    
        if (!$testLogPath) { New-Item -Path $logPath -ItemType Directory | Out-Null }


        # Assign config path
    
        $configPath = "$INSTRUMENT_PATH\config"
    
        $testConfigPath = Test-Path $configPath 
    
        if (!$testConfigPath) { New-Item -Path $configPath -ItemType Directory | Out-Null }


        # Assign data path
    
        $dataPath = "$INSTRUMENT_PATH\data"
    
        $testUserDataPath = Test-Path $dataPath | Out-Null
    
        if (!$testUserDataPath) { New-Item -Path $dataPath -ItemType Directory | Out-Null }

        
        $result = Test-Path "$INSTRUMENT_PATH"


               [PSCustomObject]@{
            Result = "Test path: $result"
            Command = "New Item C:\_Instrument"
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Command,Result

}



function assign-firefox-desktop {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock { 
          

        $PUBLIC_PATH = "C:\Users\Public"

        $DATA_PATH = "C:\Program Files\Mozilla Firefox\firefox.exe"

        $ARGS_OFFICE = "-private-window office.com"

          # Office / Private Browser link

	    $WshShell_Office = New-Object -comObject WScript.Shell

	    $officeShortcut = $WshShell_Office.CreateShortcut("$PUBLIC_PATH\Desktop\office.com.lnk")

	    $officeShortcut.TargetPath = "$DATA_PATH"

        $officeShortcut.Arguments = "$ARGS_OFFICE"

	    $officeShortcut.Save()	

        
        # Private Browser link

        $ARGS_PRIVATE = "-private-window sydney.edu.au"

        $WshShell_Private = New-Object -comObject WScript.Shell

	    $privateShortcut = $WshShell_Private.CreateShortcut("$PUBLIC_PATH\Desktop\firefox.lnk")

	    $privateShortcut.TargetPath = "$DATA_PATH"

        $privateShortcut.Arguments = "$ARGS_PRIVATE"

	    $privateShortcut.Save()	
		
		$result = Test-Path "$PUBLIC_PATH\Desktop\office.com.lnk"


               [PSCustomObject]@{
            Result = "Test path: $result"
            Command = "New item $PUBLIC_PATH\Desktop\office.com.lnk"
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Command,Result

}



function assign-public-desktop {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock { 
          

        $PUBLIC_PATH = "C:\Users\Public"

        $DATA_PATH = "C:\_Instrument\data"


        # Set desktop item to user shared drive

	    $WshShell = New-Object -comObject WScript.Shell

	    $sharedDriveShortcut = $WshShell.CreateShortcut("$PUBLIC_PATH\Desktop\Instrument Data.lnk")

	    $sharedDriveShortcut.TargetPath = "$DATA_PATH"

	    $sharedDriveShortcut.Save()	


        $result = Test-Path "$PUBLIC_PATH\Desktop\Instrument Data.lnk"


               [PSCustomObject]@{
            Result = "Test path: $result"
            Command = "New item $PUBLIC_PATH\Desktop\Instrument Data.lnk"
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Command,Result

}


function remove-user-desktop {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock { 

       
        $USERHOME_PATH = "C:\Users\chemistry_instrument"
            
        Remove-Item -Path "$USERHOME_PATH\Desktop\Instrument Data.lnk"

        $result = Test-Path "$USERHOME_PATH\Desktop\Instrument Data.lnk"


               [PSCustomObject]@{
            Result = "Test path: $result"
            Command = "Remove Item $USERHOME_PATH\Desktop\Instrument Data.lnk"
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Command,Result

}


function clean-public-desktop {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {    
        
        # Remove Public Desktop items

        $PUBLIC_DESKTOP = "C:\Users\Public\Desktop"
            
        Remove-Item -Path "$PUBLIC_DESKTOP\Adobe Acrobat DC.lnk"

        $isAdobePath = Test-Path "$PUBLIC_DESKTOP\Adobe Acrobat DC.lnk" | Out-Null
        
        Remove-Item -Path "$PUBLIC_DESKTOP\Adobe Creative Cloud.lnk"

        $isAdobeCloudPath = Test-Path "$PUBLIC_DESKTOP\Adobe Creative Cloud.lnk" | Out-Null

        Remove-Item -Path "$PUBLIC_DESKTOP\Zoom.lnk"

        $isAdobePath = Test-Path "$PUBLIC_DESKTOP\Zoom.lnk" | Out-Null

        # Test paths

        $isDesktopPath = ($isAdobePath -and $isAdobeCloudPath -and $isAdobePath)


               [PSCustomObject]@{
            Result = "Test path: $isDesktopPath"
            Command = "Remove Items $PUBLIC_DESKTOP"
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Command,Result

}


function report-instrument-user-maintenance {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {    
        
        
        $isEnabled = Get-ScheduledTask -TaskName "InstrumentProfileMaintenance" | Where state -EQ 'ready'

        if ($isEnabled) {
            
            $isEnabled = "Enabled"

        } else {

            $isEnabled = "Disabled"
        }

        $nextTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm K" -Date $(Get-ScheduledTask -TaskName "InstrumentProfileMaintenance" | Get-ScheduledTaskInfo | Select -ExpandProperty NextRunTime)

        $lastTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm K" -Date $(Get-ScheduledTask -TaskName "InstrumentProfileMaintenance" | Get-ScheduledTaskInfo | Select -ExpandProperty LastRunTime)

        $bootTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm K" -Date $(Get-CimInstance -ClassName win32_operatingsystem | select -ExpandProperty lastbootuptime)
        



        [PSCustomObject]@{

            State = "$isEnabled"

            ScheduledTask = "InstrumentProfileMaintenance"

            NextRunTime = $nextTime

            LastRunTime = $lastTime

            LastBootupTime = $bootTime


        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,ScheduledTask,State,LastRunTime,NextRunTime,LastBootupTime

}


function enable-instrument-user-maintenance {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {    
        

        Enable-ScheduledTask -TaskName "InstrumentProfileMaintenance" | Out-Null
        
        $isEnabled = Get-ScheduledTask -TaskName "InstrumentProfileMaintenance" | Where state -EQ 'ready'

        if ($isEnabled) {
            
            $isEnabled = "Enabled"

        } else {

            $isEnabled = "Disabled"
        }

        [PSCustomObject]@{

            State = "$isEnabled"

            ScheduledTask = "InstrumentProfileMaintenance"
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,ScheduledTask,State

}


function disable-instrument-user-maintenance {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {    
        
        Disable-ScheduledTask -TaskName "InstrumentProfileMaintenance" | Out-Null
        
        $isEnabled = Get-ScheduledTask -TaskName "InstrumentProfileMaintenance" | Where state -EQ 'ready'

        if ($isEnabled) { $isEnabled = "Enabled" } else { $isEnabled = "Disabled" }

        [PSCustomObject]@{

            State = "$isEnabled"

            ScheduledTask = "InstrumentProfileMaintenance"
        } 
    }

    $output = foreach($computer in $computerTargets){
    
    $present = $false
    
    foreach($result in $RemoteResults){
    
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,ScheduledTask,State

}


function report-administrators {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {    
        
        $admins = Get-LocalGroupMember -Group "Administrators"
        
        [PSCustomObject]@{

            Users = "$admins"

            Group = "Administrators"
        } 
    }


    $output = foreach($computer in $computerTargets) {

    $present = $false
    
    foreach($result in $RemoteResults){

        if($computer -Match $result.PSComputerName) {

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Group,Users
}


function report-user ($username) {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {    
        
        $isAdmin = Get-LocalGroupMember -Group "Administrators" |  Where name -EQ $using:username

        if ($isAdmin) { $isAdmin = $true } else { $isAdmin = $false }

        $isRDP = Get-LocalGroupMember -Group "Remote Desktop Users" |  Where name -EQ $using:username

        if ($isRDP) { $isRDP = $true } else { $isRDP = $false }

        $isWinRM = Get-LocalGroupMember -Group "Remote Management Users" |  Where name -EQ $using:username

        if ($isWinRM) { $isWinRM = $true } else { $isWinRM = $false }
        
        [PSCustomObject]@{

            User = $using:username

            Administrator = $isAdmin

            RemoteDesktopUsers = $isRDP

            RemoteManagementUsers = $isWinRM

        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,User,Administrator,RemoteDesktopUsers,RemoteManagementUsers

}


function add-local-groups ($users,$group) {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {
        
        $users = Add-LocalGroupMember -Group $using:group -Member $using:users

        $reportusers = Get-LocalGroupMember -Group $using:group
                
        [PSCustomObject]@{

            Users = $reportusers

            Group = $using:group
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Group,Users

}


function add-local-account () {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {
        
        $users = New-LocalUser -Name "chemistry_local" -Description "Description of this account." -NoPassword

        $reportusers = Get-LocalGroupMember -Group $using:group
                
        [PSCustomObject]@{

            Users = $reportusers

            Group = $using:group
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Group,Users

}



function remove-local-groups ($users,$group) {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {
        
        $users = Remove-LocalGroupMember -Group $using:group -Member $using:users

        $reportusers = Get-LocalGroupMember -Group $using:group
                
        [PSCustomObject]@{

            Users = $reportusers

            Group = $using:group
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Group,Users

}


function register-maitanence-time {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {

        Unregister-ScheduledTask "InstrumentProfileMaintenance" -Confirm:$false

        $time = New-ScheduledTaskTrigger -Daily -At '3am'
    
        $time = New-ScheduledTaskTrigger -Weekly -DaysOfWeek 'Sunday' -At '3am'
                
        $script = '-ExecutionPolicy Bypass -File "C:\Program Files\Instrument Kiosk\kiosk-maint.ps1"'

        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $script

        $principle = New-ScheduledTaskPrincipal "mcs\chemistry_instrument"

        $settings = New-ScheduledTaskSettingsSet

        $task = New-ScheduledTask -Action $action -Principal $principle -Trigger $time -Settings $settings

        Register-ScheduledTask "InstrumentProfileMaintenance" -InputObject $task

        Set-ScheduledTask "InstrumentProfileMaintenance" -InputObject $task
        
        $setTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm K" -Date $(Get-ScheduledTask -TaskName "KioskProfileMaintenance" | Get-ScheduledTaskInfo | Select -ExpandProperty NextRunTime)
              
        [PSCustomObject]@{

            NextRunTime = $setTime

            ScheduledTask = "KioskProfileMaintenance"
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,ScheduledTask,NextRunTime

}


function set-maitanence-time {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {

        Unregister-ScheduledTask "InstrumentProfileMaintenance" -Confirm:$false

        $time = New-ScheduledTaskTrigger -Daily -At '3am'
    
        $time = New-ScheduledTaskTrigger -Weekly -DaysOfWeek 'Sunday' -At '3am'
                
        $script = '-ExecutionPolicy Bypass -File "C:\Program Files\Instrument Kiosk\kiosk-maint.ps1"'

        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $script
        
        $principle = New-ScheduledTaskPrincipal "chemistry_instrument"

        $settings = New-ScheduledTaskSettingsSet

        $task = New-ScheduledTask -Action $action -Principal $principle -Trigger $time -Settings $settings

        Register-ScheduledTask "InstrumentProfileMaintenance" -InputObject $task

        Set-ScheduledTask -TaskName "InstrumentProfileMaintenance" -Trigger $time
        
        $setTime = Get-Date -Format "dddd MM/dd/yyyy HH:mm K" -Date $(Get-ScheduledTask -TaskName "InstrumentProfileMaintenance" | Get-ScheduledTaskInfo | Select -ExpandProperty NextRunTime)
              
        [PSCustomObject]@{

            NextRunTime = $setTime

            ScheduledTask = "InstrumentProfileMaintenance"
        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,ScheduledTask,NextRunTime

}




function report-software-center ($appName) {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {

         Write-Host Get-WmiObject -Namespace "root\ccm\ClientSDK" -Class CCM_Application  | Where {$_.Name -like "$using:appName*"} 

        
        $software = Get-WmiObject -Namespace "root\ccm\ClientSDK" -Class CCM_Application  | Where {$_.Name -like "$using:appName*"} 


        $name = $software | Select-Object -ExpandProperty Name

        $fullName = $software | Select-Object -ExpandProperty FullName

        $isInstalled = $software | Select-Object -ExpandProperty InstallState

        $isTarget = $software | Select-Object -ExpandProperty IsMachineTarget

                
        [PSCustomObject]@{

            Name = "$name"

            FullName = "$fullName"

            InstallState = "$isInstalled"

            IsTarget = $isTarget


        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,Name,InstallState,IsTarget

}


function install-chrome ($appName) {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {
        
        $software = $Application = Get-WmiObject -Namespace "root\ccm\ClientSDK" -Class CCM_Application | where {$_.Name -like "$using:appName*"} | Select-Object Id, Revision, IsMachineTarget, Name

        $AppID = $Application.Id
        
        $AppRev = $Application.Revision
        
        $AppTarget = $Application.IsMachineTarget
        
        ([wmiclass]'ROOT\ccm\ClientSdk:CCM_Application').Install($AppID, $AppRev, $AppTarget, 0, 'Normal', $False) | Out-Null   
                
        [PSCustomObject]@{

            SoftwareCenter = $software | Select-Object -ExpandProperty Name

            State = "Installing"
           

        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,SoftwareCenter,State

}

function install-sc-app ($appName) {
  

    $RemoteResults = Invoke-Command -Credential $cred -ComputerName $computerTargets -ScriptBlock {
        
        $software = $Application = Get-WmiObject -Namespace "root\ccm\ClientSDK" -Class CCM_Application | where {$_.Name -like "$using:appName*"} | Select-Object Id, Revision, IsMachineTarget, Name

        $AppID = $Application.Id
        
        $AppRev = $Application.Revision
        
        $AppTarget = $Application.IsMachineTarget
        
        ([wmiclass]'ROOT\ccm\ClientSdk:CCM_Application').Install($AppID, $AppRev, $AppTarget, 0, 'Normal', $False) | Out-Null   
                
        [PSCustomObject]@{

            SoftwareCenter = $software | Select-Object -ExpandProperty Name

            State = "Installing"
           

        } 
    }


    $output = foreach($computer in $computerTargets){
    $present = $false
    foreach($result in $RemoteResults){
        if($computer -Match $result.PSComputerName){

              $result;
            };
        };

    };

    $output | Format-Table PSComputerName,SoftwareCenter,State

}