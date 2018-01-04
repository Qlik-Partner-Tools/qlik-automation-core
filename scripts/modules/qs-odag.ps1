<#
Module:             qs-odag
Author:             Manuel Romero
Modified by:        Clint Carr
Modification History:
 - Added Logging
 - Added comments
 - Set output to Null
last updated:       10/11/2017
Intent: Configure and start ODAG
#>

Trap {
	Write-Log -Message $_.Exception.Message -Severity "Error"
  	Break
}

if(!(Test-Path c:\qmi\QMIError)){
    Write-Log -Message "Starting qs-odag.ps1"

    # Enable ODAG
    Write-Log -Message 'Enabling ODAG in QMC.'
    Connect-Qlik -usedefaultcredentials | Out-Null
    Update-QlikOdag -enabled $true -maxConcurrentRequests 5  | Out-Null

    Write-Log -Message "creating folder to store QVD files"
    New-Item -ItemType directory -Path "C:\odag\data" -force  | Out-Null

    expand-archive "c:\vagrant\files\ODAG_Course.zip" "c:\odag\data\" -Force  | Out-Null
    #create dataconnection to c:\odag\data\
    Write-Log -Message "Creating Data connection for ODAG Demo data"
    New-QlikDataConnection -name "ODAG_DATA (qmi-qs-odag_qlik)" -connectionstring "c:\\odag\\data\\" -type Folder  | Out-Null
    # create system rule for Vagrant user
    Write-Log -Message "Creating System rule to give Vagrant user access to all applications"
    $systemRuleJson = (@{
        name = "_Grant LORD status to Vagrant";
        category = "Security";
        rule = '((user.name="vagrant"))';
        type = "Custom";
        resourceFilter = "*";
        actions = 511;
        ruleContext = "BothQlikSenseAndQMC";
        disabled = $false;
        comment = "Gives vagrant user to EVERYTHING";} | ConvertTo-Json -Compress -Depth 10)
    Invoke-QlikPost "/qrs/SystemRule" $systemRuleJson  | Out-Null

    # Create ODAG Link
    CreateOdagLink -odagLinkName "ODAGLink" -selectionAppName "Sales and Inventory Selections" -detailsAppName "Sales Details" -sheet2OpenName "Sales Details" -odagLinkExpression "count(distinct ProductName)" -rowsLimit 50 -appsLimit 5 -retentionTime "P1D" -sheetEmbedName "Dashboard and Selection Sheet"
}
