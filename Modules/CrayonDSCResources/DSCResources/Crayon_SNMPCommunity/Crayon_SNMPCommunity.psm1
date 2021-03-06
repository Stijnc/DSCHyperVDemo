function Get-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community,
		[parameter(Mandatory = $true)]
		[System.String]
		$Right,
		[parameter(Mandatory = $true)]
		[System.String]
		$Ensure
	)
    
    $Communities = [PSCustomObject](Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities").psbase.properties | ? { 
            $_.Name -notin @('PSDrive','PSProvider','PSCHildName','PSPath','PSParentPath') 
         } | Select Name,Value
    
    if ($Communities) {
        #Building the Hashtable
        $Script:CommunityList = ""
        $ofs = "="
        $Communities | % { $Script:CommunityList += ","+"$($_.Name,$_.Value)" }
    
        $ReturnValue = @{
            Community=$Script:CommunityList.substring(1)
            Right = $Right
            Ensure = $Ensure
        }
    }
    else {
        $ReturnValue = @{
            Community="None"
            Right = $Right
            Ensure = $Ensure
        }
    }
    $ReturnValue
}


function Set-TargetResource {
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community,

        [parameter(Mandatory = $true)]
		[ValidateSet("None","Notify","ReadOnly","ReadWrite","ReadCreate")]
		[System.String]
		$Right,

        [parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

     Switch ($Right) {
        "None" { $RightNumber = 1 }
        "Notify" { $RightNumber = 2 }
        "ReadOnly" { $RightNumber = 4 }
        "ReadWrite" { $RightNumber = 8 }
        "ReadCreate" { $RightNumber = 16 }
    }
    switch ($Ensure) {
        "Present" { 
            Write-Verbose "Addind community to the allowed list"
            New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities -Name $Community -Value $RightNumber -PropertyType DWORD -Force
            Restart-Service -Name SNMP
        }
        "Absent" {
            Write-Verbose "Removing community from the allowed list"
            if (Test-Path -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities\$community) {
                Remove-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities -Name $Community -Force
                Restart-Service -Name SNMP
            }
        }
    
    }
}


function Test-TargetResource {
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
		[System.String]
		$Community,

        [parameter(Mandatory = $true)]
		[ValidateSet("None","Notify","ReadOnly","ReadWrite","ReadCreate")]
		[System.String]
		$Right,

        [parameter(Mandatory = $true)]
		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure
	)

    $Communities = [PSCustomObject](Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities").psbase.properties | ? { 
            $_.Name -notin @('PSDrive','PSProvider','PSCHildName','PSPath','PSParentPath') 
         } | Select Name,Value
    Switch ($Right) {
            "None" { $RightNumber = "1" }
            "Notify" { $RightNumber = "2" }
            "ReadOnly" { $RightNumber = "4" }
            "ReadWrite" { $RightNumber = "8" }
            "ReadCreate" { $RightNumber = "16" }
    }
    #Building the Hashtable
    if ($Communities) {
        $Communities | ? { $_.Name -eq $Community } | % { 
        [String]$RegistryRight = $_.Value
            if ($Ensure -eq "Present") {
                if ($RegistryRight.trim() -eq $RightNumber) { $Return = $true }
                else { $Return = $false }
            }
            elseif ($Ensure -eq "Absent") {
                if ($RegistryRight.trim() -eq $RightNumber) { $Return = $false }
                else { $Return = $true }
            }
        }
    }
    else {
        $Return = $false
    }
    $Return
}


Export-ModuleMember -Function *-TargetResource

