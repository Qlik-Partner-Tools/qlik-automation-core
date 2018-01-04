<#
Module:             UtilsQMI
Author:             Manuel Romero
                    Clint Car

Modified by:        -
last updated:       11/10/2017

Modification History:
 -

Intent: One place for common functions across modules we don't want in qmiCLI

Dependencies:
 -
#>

Function CreateOdagLink
{
    param (
        [string]$odagLinkName,
        [string]$selectionAppName,
        [string]$detailsAppName,
        [string]$sheet2OpenName,
        [string]$odagLinkExpression,
        [int]$rowsLimit,
        [int]$appsLimit,
        [string]$retentionTime,
        [string]$sheetEmbedName
    )


    PROCESS {

        Trap {
            Write-Log -Message "Error in function CreateOdagLink" -Severity "Error"
            Write-Log -Message $_.Exception.Message -Severity "Error"
            Break
        }

        Write-Log -Message "Installing NodeJs"
        cinst nodejs.install --version 6.4.0  | Out-Null

        if ( -Not (Test-Path C:\OdagEnigma) ) {
            Write-Log -Message "Unzipping Node EnigmaJS"
            Expand-Archive -LiteralPath C:\installation\EnigmaModule.zip -DestinationPath C:\OdagEnigma -Force  | Out-Null
        }

        # Create ODAG Link
        Write-Log -Message "Adding ODAG Link"
        $rawOutput = $true
        $detailApp = $(Get-QlikApp -filter "name eq '$detailsAppName'").id
        $selectionApp = $(Get-QlikApp -filter "name eq '$selectionAppName'").id
        $sheetID = $(Invoke-QlikGet "/qrs/app/object" -filter "name eq '$sheet2OpenName' and objectType eq 'sheet'").engineObjectId
        $data = (@{"name"=$odagLinkName;
            "templateApp"=$detailApp;
            "rowEstExpr"=$odagLinkExpression;
            "properties"=@{
                "rowEstRange"=@(@{"context"="*";"highBound"=$rowsLimit});
                "genAppLimit"=@(@{"context"="User_*";"limit"=$appsLimit});
                "appRetentionTime"=@(@{"context"="User_*";"retentionTime"=$retentionTime});
                "targetSheet"=@(@{"context"="User_*";"sheetId"=$sheetID})};
            "selectionApp"=$selectionApp}) | ConvertTo-Json -Compress -Depth 10

        $result = $(Invoke-QlikPost "/api/odag/v1/links" $data)
        $odagLinkRef = $result.objectDef.id


        Write-Log -Message "ODAG link added $odagLinkRef"

        $sheetSelectionID = $(invoke-qlikget "/qrs/app/object" -filter "name eq '$sheetEmbedName' and objectType eq 'sheet'").engineObjectId


        # EnigmaJS to attach this link to apps and sheet using APIs
        C:\OdagEnigma\run.bat $odagLinkRef $odagLinkName $sheetSelectionID $selectionAppName $detailsAppName

        return $odagLinkRef
    }
}