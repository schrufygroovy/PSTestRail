function Get-TestRailProject
{
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('project_id')]
        [int]
        $ProjectId
    )

    PROCESS
    {
        $Uri = "get_project/$ProjectId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}

function Get-TestRailProjects
{
    param
    (
        [Parameter(Mandatory=$false)]
        [bool]
        $IsCompleted
    )

    $Uri = "get_projects"
    $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

    if ( $PSBoundParameters.ContainsKey("IsCompleted") )
    {
        Add-UriParameters -Parameters $Parameters -Hash @{ is_completed = [int]$IsCompleted }
    }

    Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
}
