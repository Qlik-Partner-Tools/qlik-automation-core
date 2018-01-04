<#
Module:             qs-importData
Author:             Byron Ainsworth

Modified by:        Clint Carr
last updated:       10/11/2017
Modification History:
 - Sent output to Null
 - Changed Write-Host to Write-log

Intent: import reference data for Qlik Sense applications

Dependencies: 
 - Requires creation of ReferenceData and ContentLibrary folders under shared-content directory.

#>
if(!(Test-Path c:\qmi\QMIError)){
  Write-Log -Message "Starting qs-importData"

  ### Define Script Variables
    $srcData = "c:\shared-content"
    $dstData = "c:\QlikShare"

  ### Import Qlik Sense Reference Data
  If (Test-Path $($srcData + "\ReferenceData"))
  {
    Write-Log -Message "Importing Qlik Sense reference data"
    Copy-Item -Path $($srcData + "\ReferenceData") -Destination $($dstData + "\ReferenceData") -Recurse -Force

    ### Establish Qlik Sense Reference Data Connections
    Write-Log -Message "Creating Qlik Sense reference data connection"

    $resource = "/qrs/dataconnection"

    $json = (
      @{
        name = "data";
        connectionstring = $($dstData + "\ReferenceData");
        type = "folder";
    
      } | ConvertTo-Json -Compress -Depth 10 )
    
      Invoke-QlikPost -Path $resource -Body $json | Out-Null

  }else{
    Write-Log -Message  "Unable to import Qlik Sense application reference data as source folder missing"
  }


  ### Establish Qlik Sense Content Libraries

  If (Test-Path $($srcData + "\ContentLibraries"))
  {
    # Identify Content Libraries for import
    $arrContentLibraries = Get-ChildItem -Path $($srcData + "\ContentLibraries") -Directory

    # Create Content Libraries
    foreach ($objContentLibrary in $arrContentLibraries) {
      # Define loop variables
      $objName = $objContentLibrary.Name

      # Create Content Library
      Write-Log -Message  "Creating custom content library: $objName"
      $jsonContentLibrary = $(@{name = $objName} | ConvertTo-Json -Compress -Depth 10)
      Invoke-QlikPost -Path "/qrs/contentlibrary" -Body $jsonContentLibrary | Out-Null

      $objId = $(Invoke-QlikGet -Path "/qrs/contentlibrary" -Filter "name eq '$objName'").id

      # Create Security Rules
      Write-Log -Message  "Creating security rule for content library access: $objName"
      $resource = "/qrs/systemrule"

      $json = (@{
        name = "Grant everyone access to Content Library: $objName";
        category = "Security";
        rule = '((user.name like "*"))';
        type = "Custom";
        resourceFilter = "ContentLibrary_$objId";
        actions = 34;
        ruleContext = "BothQlikSenseAndQMC";
        disabled = $false;
        comment = "Content Library access";} | ConvertTo-Json -Compress -Depth 10)

      Invoke-QlikPost -Path $resource -Body $json | Out-Null;

      # Upload image files
      Write-Log -Message  "Uploading images to content library: $objName"
      $arrImages = Get-ChildItem -Path $($srcData + "\ContentLibraries\" + $objName)

      foreach($objImage in $arrImages) {

        $resource = $("/qrs/contentlibrary/" + $objName + "/uploadfile?externalpath=" + $objImage.Name + "&overwrite=false")
        Invoke-QlikUpload -Path $resource -Filename $objImage.FullName | Out-Null
      }
    }
  }else{
    Write-Log -Message "No custom Qlik Sense content libraries found to be imported"
  }
}