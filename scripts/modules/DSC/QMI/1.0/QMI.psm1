<#
Module:             QlikCLI
Author:             Clint Carr
                    Byron Ainsworth

Modified by:        -
last updated:       10/10/2017

Modification History:
 - 

Intent: Provide prepackaged commands to facilitate common QMI activities

Dependencies: 
 - 

#>

function Write-Log
{
    param (
        [Parameter(Mandatory)]
        [string]$Message,
        [Parameter()]
        [ValidateSet('Info','Warn','Error')]
        [string]$Severity = 'Info'
    )
    
    $line = [pscustomobject]@{
        'DateTime' = (Get-Date)
        'Severity' = $Severity
        'Message' = $Message
        
    }
    Write-Host "$($line.DateTime) [$($line.Severity)]: $($line.Message)"
    $line | Export-Csv -Path c:\vagrant\QMIProvision.log -Append -NoTypeInformation
}

Function Backup-QMIAppsSerial
{
  param (
    [Parameter()]
    [string]$Source = 'c:\QlikShare\apps\',
    [Parameter()]
    [string]$Destination = '\\VBOXSVR\shared-content\apps'
  )

  Write-Log -Message "Commencing export process for local Qlik Sense Apps repository" -Severity 'Info'

  ### Get Apps
  Write-Log -Message "Identifying eligible local Qlik Sense Apps" -Severity 'Info'
  $arrApps = Get-QlikApp | ? {$_.stream.name -ne 'monitoring apps'}
  Write-Log -Message "Qlik Sense Apps identified: $($arrApps.Count)" -Severity 'Info'

  Foreach($objApp in $arrApps){
    If($objApp.Published -eq $True){
        If(Test-Path -Path $($Destination + '\' + $objApp.stream.name)){ 
        }
        else{
          Write-Log -Message "Identified new stream $($objApp.stream.name). Creating central stream repository" -Severity 'Info'
          New-Item -ItemType Directory -Path $($Destination + '\' + $objApp.stream.name) -Force
        }
        $objApp | Export-QlikApp -filename $($Destination + '\' + $($objApp.stream.name) + '\' +$objApp.name + '.qvf')
        Write-Log -Message "Qlik Sense Apps exported: $($objApp.Name)" -Severity 'Info'
    }else{
      $objApp | Export-QlikApp -filename $($Destination + '\' + $objApp.name + '.qvf')
      Write-Log -Message "Qlik Sense Apps exported: $($objApp.Name)" -Severity 'Info'
    }
  }

  Write-Log -Message "Concluding export process for local Qlik Sense Apps repository" -Severity 'Info'

}

Function Backup-QMIApps
{
  param (
    [Parameter()]
    [string]$Source = 'c:\QlikShare\apps\',
    [Parameter()]
    [string]$Destination = '\\VBOXSVR\shared-content\apps'
  )

  Write-Log -Message "Commencing export process for local Qlik Sense Apps repository" -Severity 'Info'




  workflow Export-App
  {
    param (
      [Parameter()]
      [string]$Source = 'c:\QlikShare\apps\',
      [Parameter()]
      [string]$Destination = '\\VBOXSVR\shared-content\apps'
    )

    ### Get Apps
    Write-Log -Message "Identifying eligible local Qlik Sense Apps" -Severity 'Info'
    $arrApps = Get-QlikApp | ? {$_.stream.name -ne 'monitoring apps'} #| Sort Name
    Write-Log -Message "Qlik Sense Apps identified: $($arrApps.Count)" -Severity 'Info'

    Foreach -Parallel ($objApp in $arrApps){

        Write-Log -Message "Qlik App export job: $($objApp.Name)" -Severity 'Info'

        If($objApp.Published -eq $True){
          If(Test-Path -Path $($Destination + '\' + $objApp.stream.name)){ 
          }
          else{
            Write-Log -Message "Identified new stream $($objApp.stream.name). Creating central stream repository" -Severity 'Info'
            New-Item -ItemType Directory -Path $($Destination + '\' + $objApp.stream.name) -Force
          }
          $objApp | Export-QlikApp -filename $($Destination + '\' + $($objApp.stream.name) + '\' +$objApp.name + '.qvf')
          Write-Log -Message "Qlik Sense Apps exported: $($objApp.Name)" -Severity 'Info'
        }
        else{
          $objApp | Export-QlikApp -filename $($Destination + '\' + $objApp.name + '.qvf')
          Write-Log -Message "Qlik Sense Apps exported: $($objApp.Name)" -Severity 'Info'
        }

    
    }

  }

  Export-App -Source $Source -Destination $Destination

  Write-Log -Message "Concluding export process for local Qlik Sense Apps repository" -Severity 'Info'

}

Function Backup-QMIExtensions
{
  param (
    [Parameter()]
    [string]$Source = 'C:\QlikShare\StaticContent\Extensions\',
    [Parameter()]
    [string]$Destination = '\\VBOXSVR\shared-content\extensions'
  )

  Write-Log -Message "Commencing export process for Extensions to from local $env:computername to central shared-content repository" -Severity 'Info'

  ## Verify source directory exists
  If (Test-Path $Source){
    Write-Log -Message "Confirmed local Extensions repository exists" -Severity 'Info'

    Try
    {
      $arrExtensions = Get-ChildItem -Path $Source | ? {$_.Name -notlike "idevio*"}
      foreach($objExtension in $arrExtensions){
        Compress-Archive -Path $objExtension.FullName -DestinationPath $($Destination + '\' + $objExtension.name + '.zip' ) -CompressionLevel 'Optimal' -Force
      }

      #$arrObjects | Copy-Item -Destination $Destination -Recurse -Force -Verbose
      Write-Log -Message "Concluding export process for Extensions repository" -Severity 'Info'
    }
    Catch
    {
      $_.Exception.Message
      $_.Exception.ItemName
      Write-Log -Message "Something went wrong with the file transfer. Confirm shared-content is available at $Destination" -Severity 'Error'
    }

  }else{
    Write-Log -Message "Local Extensions repository does not exist. If you have placed your local repository in a location other than $Source you can leverage the Source argument to override" -Severity 'Error'
    Exit
  }

}
 
Function Backup-QMIReferenceData
{
  param (
    [Parameter()]
    [string]$Source = 'c:\QlikShare\ReferenceData\',
    [Parameter()]
    [string]$Destination = '\\VBOXSVR\shared-content\ReferenceData'
  )

  Write-Log -Message "Commencing export process for ReferenceData to from local $env:computername to central shared-content repository" -Severity 'Info'

  ## Verify source directory exists
  If (Test-Path $Source){
    Write-Log -Message "Confirmed local ReferenceData repository exists" -Severity 'Info'

    Try
    {
      $arrObjects = Get-ChildItem -Path $Source
      $arrObjects | Copy-Item -Destination $Destination -Recurse -Force -Verbose
      Write-Log -Message "Concluding export process for ReferenceData repository" -Severity 'Info'
    }
    Catch
    {
      Write-Log -Message "Something went wrong with the file transfer. Confirm shared-content is available at $Destination" -Severity 'Error'
    }

  }else{
    Write-Log -Message "Local ReferenceData repository does not exist. If you have placed your local repository in a location other than $Source you can leverage the Source argument to override" -Severity 'Error'
    Exit
  }
}

Function Backup-QMIContentLibraries
{
  param (
    [Parameter()]
    [string]$Source = 'C:\QlikShare\StaticContent\Content\',
    [Parameter()]
    [string]$Destination = '\\VBOXSVR\shared-content\ContentLibrary'
  )

  Write-Log -Message "Commencing export process for ContentLibraries to from local $env:computername to central shared-content repository" -Severity 'Info'

  ## Verify source directory exists
  If (Test-Path $Source){
    Write-Log -Message "Confirmed local ContentLibraries repository exists" -Severity 'Info'

    Try
    {
      $arrObjects = Get-ChildItem -Path $Source
      $arrObjects | Copy-Item -Destination $Destination -Recurse -Force -Verbose
      Write-Log -Message "Concluding export process for ContentLibraries repository" -Severity 'Info'
    }
    Catch
    {
      Write-Log -Message "Something went wrong with the file transfer. Confirm shared-content is available at $Destination" -Severity 'Error'
    }
    
  }else{
    Write-Log -Message "Local ContentLibraries repository does not exist. If you have placed your local repository in a location other than $Source you can leverage the Source argument to override" -Severity 'Error'
    Exit
  }
}