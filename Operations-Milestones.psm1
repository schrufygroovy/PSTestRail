function Get-TestRailMilestone
{
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('milestone_id')]
        [int]
        $MilestoneId
    )

    PROCESS
    {
        $Uri = "get_milestone/$MilestoneId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}

function Get-TestRailMilestones
{
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('project_id')]
        [int]
        $ProjectId,
        [Parameter(Mandatory=$false)]
        [bool]
        $IsCompleted,
        [Parameter(Mandatory=$false)]
        [bool]
        $IsStarted
    )

    PROCESS
    {
        $Uri = "get_milestones/$ProjectId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    
        if ( $PSBoundParameters.ContainsKey("IsCompleted") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ is_completed = if ( $IsCompleted -eq $true ) { 1 } else { 0 } } 
        }
    
        if ( $PSBoundParameters.ContainsKey("IsStarted") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ is_started = if ( $IsStarted -eq $true ) { 1 } else { 0 } } 
        }
    
        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}

function Add-TestRailMilestone
{
    param
    (
        [Parameter(Mandatory=$true)]
        [Alias('project_id')]
        [int]
        $ProjectId,
        [Parameter(Mandatory=$true)]
        [string]
        $Name,
        [Parameter(Mandatory=$false)]
        [string]
        $Description,
        [Parameter(Mandatory=$false)]
        [Alias('due_on')]
        [DateTime]
        $DueOn,
        [Parameter(Mandatory=$false)]
        [Alias('parent_id')]
        [int]
        $ParentId,
        [Parameter(Mandatory=$false)]
        [Alias('start_on')]
        [DateTime]
        $StartOn
    )

    PROCESS
    {
        $Uri = "add_milestone/$ProjectId"
        $Parameters = @{}

        $Parameters["name"] = $Name

        if ( $PSBoundParameters.ContainsKey("Description") )
        {
            $Parameters["description"] = $Description
        }
        
        if ( $PSBoundParameters.ContainsKey("DueOn") )
        {
            $DueOnTS = ConvertTo-UnixTimestamp -DateTime $DueOn
            $Parameters["due_on"] = $DueOnTS
        }
        
        if ( $PSBoundParameters.ContainsKey("ParentId") )
        {
            $Parameters["parent_id"] = $ParentId
        }

        if ( $PSBoundParameters.ContainsKey("StartOn") )
        {
            $StartOnTS = ConvertTo-UnixTimestamp -DateTime $StartOn
            $Parameters["start_on"] = $StartOnTS
        }

        Invoke-TestRailPostRequest -Uri $Uri -Parameters $Parameters
    }
}