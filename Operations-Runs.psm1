function Get-TestRailRun
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [int]
        $RunId
    )

    PROCESS
    {
        $Uri = "get_run/$RunId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}

function Get-TestRailRuns
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('project_id')]
        [int]
        $ProjectId
    )

    PROCESS
    {
        $Uri = "get_runs/$ProjectId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}

function Set-TestRailRun
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [int]
        $RunId,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter(Mandatory=$false)]
        [int]
        $MilestoneId,

        [Parameter(Mandatory=$false)]
        [bool]
        $IncludeAll,

        [Parameter(Mandatory=$false)]
        [int[]]
        $CaseId
    )

    PROCESS
    {
        $Uri = "update_run/$RunId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        if ( $PSBoundParameters.ContainsKey("MilestoneId") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ milestone_id = $MilestoneId }
        }
        if ( $PSBoundParameters.ContainsKey("Name") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ name = $Name }
        }
        if ( $PSBoundParameters.ContainsKey("Description") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ description = $Description }
        }
        if ( $PSBoundParameters.ContainsKey("IncludeAll") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ include_all = $IncludeAll }
        }
        if ( $PSBoundParameters.ContainsKey("CaseId") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ case_ids = [String]::Join(",", $CaseId) }
        }

        if ( $Parameters.Count -ne 0 )
        {
            Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
        }
        else
        {
            Get-TestRailRun -RunId $RunId
        }
    }
}

function Stop-TestRailRun
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [int]
        $RunId
    )

    PROCESS
    {
        $Uri = "close_run/$RunId"
        Invoke-TestRailPostRequest -Uri $Uri
    }
}

function Start-TestRailRun
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('project_id','id')]
        [int]
        $ProjectId,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Alias('suite_id')]
        [int]
        $SuiteId,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description,

        [Parameter(Mandatory=$false)]
        [int]
        $MilestoneId,

        [Parameter(Mandatory=$true)]
        [int]
        $AssignedToId,

        [Parameter(Mandatory=$false)]
        [int[]]
        $CaseIds,

        [Parameter(Mandatory=$false)]
        [string[]]
        $Refs
    )

    PROCESS
    {
        $Uri = "add_run/$ProjectId"

        $Parameters = @{
            name = $Name
            description = $Description
            assignedto_id = $AssignedToId
        }

        if ( $PSBoundParameters.ContainsKey("SuiteId") )
        {
            $Parameters["suite_id"] = $SuiteId
        }
        if ( $PSBoundParameters.ContainsKey("MilestoneId") )
        {
            $Parameters["milestone_id"] = $MilestoneId
        }
        if ( $PSBoundParameters.ContainsKey("CaseIds") -and $CaseIds.Count -gt 0)
        {
            $Parameters["case_ids"] = $CaseIds
            $Parameters["include_all"] = $false
        }
        if ( $PSBoundParameters.ContainsKey("Refs") )
        {
            $Parameters["refs"] = [string]::Join(",", $Refs)
        }

        Invoke-TestRailPostRequest -Uri $Uri -Parameters $Parameters
    }
}

function Remove-TestRailRun
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [int]
        $RunId
    )

    PROCESS
    {
        $Uri = "delete_run/$RunId"
        $Parameters = @{}

        Invoke-TestRailPostRequest -Uri $Uri -Parameters $Parameters
    }
}
