function ConvertTo-TestRailTimeSpanString{
    param(
        [timespan]
        $TimeSpanValue
    )
    $stringBuilder = [System.Text.StringBuilder]::new()

    # milliseconds can't be tracked by TestRail
    if($TimeSpanValue.Milliseconds -gt 500){
        $oneSecond = New-TimeSpan -Seconds 1
        $TimeSpanValue = $TimeSpanValue.Add($oneSecond)
    }

    if($TimeSpanValue.Hours -gt 0){
        [void]$stringBuilder.Append("$($TimeSpanValue.Hours)h")
    }
    if($TimeSpanValue.Minutes -gt 0){
        [void]$stringBuilder.Append(" $($TimeSpanValue.Minutes)m")
    }
    if($TimeSpanValue.Seconds -gt 0){
        [void]$stringBuilder.Append(" $($TimeSpanValue.Seconds)s")
    }
    return $stringBuilder.ToString().Trim()
}

function Get-TestRailResults
{
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [int]
        $TestId,

        [Parameter(Mandatory=$false)]
        [int]
        $Limit,

        [Parameter(Mandatory=$false)]
        [int]
        $Offset,

        [Parameter(Mandatory=$false)]
        [int[]]
        $StatusId
    )

    PROCESS
    {
        $Uri = "get_results/$TestId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        if ( $PSBoundParameters.ContainsKey("Offset") -and (-not $PSBoundParameters.ContainsKey("Limit") ) )
        {
            throw New-Object System.ArgumentException -ArgumentList "Cannot specify Offset without Limit"
        }

        if ( $PSBoundParameters.ContainsKey("Limit") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ limit = $Limit }

            if ( $PSBoundParameters.ContainsKey("Offset") )
            {
                Add-UriParameters -Parameters $Parameters -Hash @{ offset = $Offset }
            }
        }

        if ( $PSBoundParameters.ContainsKey("StatusId") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ status_id = [String]::Join(",", $StatusId ) }
        }

        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}

function Get-TestRailResultsForCase
{
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [int]
        $RunId,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('case_id')]
        [int]
        $CaseId,

        [Parameter(Mandatory=$false)]
        [int]
        $Limit,

        [Parameter(Mandatory=$false)]
        [int]
        $Offset,

        [Parameter(Mandatory=$false)]
        [int[]]
        $StatusId
    )

    PROCESS
    {
        $Uri = "get_results_for_case/$RunId/$CaseId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        if ( $PSBoundParameters.ContainsKey("Offset") -and (-not $PSBoundParameters.ContainsKey("Limit") ) )
        {
            throw New-Object System.ArgumentException -ArgumentList "Cannot specify Offset without Limit"
        }

        if ( $PSBoundParameters.ContainsKey("Limit") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ limit = $Limit }

            if ( $PSBoundParameters.ContainsKey("Offset") )
            {
                Add-UriParameters -Parameters $Parameters -Hash @{ offset = $Offset }
            }
        }

        if ( $PSBoundParameters.ContainsKey("StatusId") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ status_id = [String]::Join(",", $StatusId ) }
        }

        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}

function Get-TestRailResultsForRun
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('id')]
        [int]
        $RunId,

        [Parameter(Mandatory=$false)]
        [DateTime]
        $CreatedBefore,

        [Parameter(Mandatory=$false)]
        [DateTime]
        $CreatedAfter,

        [Parameter(Mandatory=$false)]
        [int]
        $CreatedBy,

        [Parameter(Mandatory=$false)]
        [int]
        $Limit,

        [Parameter(Mandatory=$false)]
        [int]
        $Offset,

        [Parameter(Mandatory=$false)]
        [int[]]
        $StatusId
    )

    PROCESS
    {
        $Uri = "get_results_for_run/$RunId"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        if ( $PSBoundParameters.ContainsKey("Offset") -and (-not $PSBoundParameters.ContainsKey("Limit") ) )
        {
            throw New-Object System.ArgumentException -ArgumentList "Cannot specify Offset without Limit"
        }

        if ( $PSBoundParameters.ContainsKey("CreatedAfter") )
        {
            $CreatedAfterTS = ConvertTo-UnixTimestamp -DateTime $CreatedAfter
            Add-UriParameters -Parameters $Parameters -Hash @{ created_after = $CreatedAfterTS }
        }

        if ( $PSBoundParameters.ContainsKey("CreatedBefore") )
        {
            $CreatedBeforeTS = ConvertTo-UnixTimestamp -DateTime $CreatedBefore
            Add-UriParameters -Parameters $Parameters -Hash @{ created_before = $CreatedBeforeTS }
        }

        if ( $PSBoundParameters.ContainsKey("CreatedBy") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ created_by = $CreatedBy }
        }

        if ( $PSBoundParameters.ContainsKey("Limit") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ limit = $Limit }

            if ( $PSBoundParameters.ContainsKey("Offset") )
            {
                Add-UriParameters -Parameters $Parameters -Hash @{ offset = $Offset }
            }
        }

        if ( $PSBoundParameters.ContainsKey("StatusId") )
        {
            Add-UriParameters -Parameters $Parameters -Hash @{ status_id = [String]::Join(",", $StatusId ) }
        }

        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}

function Add-TestRailResult
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [Alias('id')]
        [int]
        $TestId,

        [Parameter(Mandatory=$true)]
        [int]
        $StatusId,

        [Parameter(Mandatory=$false)]
        [string]
        $Comment,

        [Parameter(Mandatory=$false)]
        [string]
        $Version,

        [Parameter(Mandatory=$false)]
        [TimeSpan]
        $Elapsed,

        [Parameter(Mandatory=$false)]
        [string[]]
        $Defects,

        [Parameter(Mandatory=$false)]
        [int]
        $AssignedToId,

        [Parameter(Mandatory=$false)]
        [HashTable]
        $CustomFields = @{}
    )

    PROCESS
    {
        $Uri = "add_result/$RunId"
        $Parameters = @{}

        $Parameters.Add("status_id", $StatusId)

        if ( $PSBoundParameters.ContainsKey("Comment") )
        {
            $Parameters.Add("comment", $Comment)
        }

        if ( $PSBoundParameters.ContainsKey("Version") )
        {
            $Parameters.Add("version", $Version)
        }

        if ( $PSBoundParameters.ContainsKey("Elapsed") )
        {
            $ElapsedString = ConvertTo-TestRailTimeSpanString -TimeSpanValue $Elapsed
            $Parameters.Add("elapsed", $ElapsedString)
        }

        if ( $PSBoundParameters.ContainsKey("Defects") )
        {
            $Parameters.Add("defects", ([String]::Join(",", $Defects)))
        }

        if ( $PSBoundParameters.ContainsKey("AssignedToId") )
        {
            $Parameters.Add("assignedto_id", $AssignedToId)
        }

        $CustomFields.Keys |% {
            $Key = $_
            if ( $Key -notmatch "^custom_" )
            {
                $Key = "custom_" + $Key
            }

            $Parameters.Add($Key, $CustomFields[$_])
        }

        Invoke-TestRailPostRequest -Uri $Uri -Parameters $Parameters
    }
}

function Add-TestRailResultForCase
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [Alias('id')]
        [int]
        $RunId,

        [Parameter(Mandatory=$true)]
        [int]
        $CaseId,

        [Parameter(Mandatory=$true)]
        [int]
        $StatusId,

        [Parameter(Mandatory=$false)]
        [string]
        $Comment,

        [Parameter(Mandatory=$false)]
        [string]
        $Version,

        [Parameter(Mandatory=$false)]
        [TimeSpan]
        $Elapsed,

        [Parameter(Mandatory=$false)]
        [string[]]
        $Defects,

        [Parameter(Mandatory=$false)]
        [int]
        $AssignedToId,

        [Parameter(Mandatory=$false)]
        [HashTable]
        $CustomFields = @{}
    )

    PROCESS
    {
        $Uri = "add_result_for_case/$RunId/$CaseId"
        $Parameters = @{}

        $Parameters.Add("status_id", $StatusId)

        if ( $PSBoundParameters.ContainsKey("Comment") )
        {
            $Parameters.Add("comment", $Comment)
        }

        if ( $PSBoundParameters.ContainsKey("Version") )
        {
            $Parameters.Add("version", $Version)
        }

        if ( $PSBoundParameters.ContainsKey("Elapsed") )
        {
            $ElapsedString = ConvertTo-TestRailTimeSpanString -TimeSpanValue $Elapsed
            $Parameters.Add("elapsed", $ElapsedString)
        }

        if ( $PSBoundParameters.ContainsKey("Defects") )
        {
            $Parameters.Add("defects", ([String]::Join(",", $Defects)))
        }

        if ( $PSBoundParameters.ContainsKey("AssignedToId") )
        {
            $Parameters.Add("assignedto_id", $AssignedToId)
        }

        $CustomFields.Keys | ForEach-Object {
            $Key = $_
            if ( $Key -notmatch "^custom_" )
            {
                $Key = "custom_" + $Key
            }

            $Parameters.Add($Key, $CustomFields[$_])
        }

        Invoke-TestRailPostRequest -Uri $Uri -Parameters $Parameters
    }
}

function New-TestRailResult
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ParameterSetName="ResultForTest")]
        [int]
        $TestId,

        [Parameter(Mandatory=$true, ParameterSetName="ResultForCase")]
        [int]
        $CaseId,

        [Parameter(Mandatory=$true)]
        [int]
        $StatusId,

        [Parameter(Mandatory=$false)]
        [string]
        $Comment,

        [Parameter(Mandatory=$false)]
        [string]
        $Version,

        [Parameter(Mandatory=$false)]
        [TimeSpan]
        $Elapsed,

        [Parameter(Mandatory=$false)]
        [string[]]
        $Defects,

        [Parameter(Mandatory=$false)]
        [int]
        $AssignedToId,

        [Parameter(Mandatory=$false)]
        [HashTable]
        $CustomFields = @{}
    )

    PROCESS
    {
        $Parameters = @{}

        switch ($PSCmdlet.ParameterSetName)
        {
            "ResultForTest" { $Parameters.Add("test_id", $TestId) }
            "ResultForCase" { $Parameters.Add("case_id", $CaseId) }
        }

        $Parameters.Add("status_id", $StatusId)

        if ( $PSBoundParameters.ContainsKey("Comment") )
        {
            $Parameters.Add("comment", $Comment)
        }

        if ( $PSBoundParameters.ContainsKey("Version") )
        {
            $Parameters.Add("version", $Version)
        }

        if ( $PSBoundParameters.ContainsKey("Elapsed") )
        {
            $ElapsedString = ConvertTo-TestRailTimeSpanString -TimeSpanValue $Elapsed
            $Parameters.Add("elapsed", $ElapsedString)
        }

        if ( $PSBoundParameters.ContainsKey("Defects") )
        {
            $Parameters.Add("defects", ([String]::Join(",", $Defects)))
        }

        if ( $PSBoundParameters.ContainsKey("AssignedToId") )
        {
            $Parameters.Add("assignedto_id", $AssignedToId)
        }

        $CustomFields.Keys | ForEach-Object {
            $Key = $_
            if ( $Key -notmatch "^custom_" )
            {
                $Key = "custom_" + $Key
            }

            $Parameters.Add($Key, $CustomFields[$_])
        }

        $Parameters
    }
}

function Add-TestRailResultsForCases
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [Alias('id')]
        [int]
        $RunId,

        [Parameter(Mandatory=$true)]
        [HashTable[]]
        $Results
    )

    PROCESS
    {
        $Uri = "add_results_for_cases/$RunId"

        $NotCaseResults =  ($Results | Where-Object case_id -Eq $null).Length -ne 0
        if ( $NotCaseResults )
        {
            throw (New-Object ArgumentException -ArgumentList "Results must contain a 'case_id' property. Did you use New-TestRailResult -CaseId <x> ?")
        }

        $Parameters = @{}

        if ( $Results -is [Array] )
        {
            $Parameters = @{ results = $Results }
        }
        else
        {
            $Parameters = @{ results = @( $Results ) }
        }

        Invoke-TestRailPostRequest -Uri $Uri -Parameters $Parameters
    }
}

function Add-TestRailResults
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [Alias('id')]
        [int]
        $RunId,

        [Parameter(Mandatory=$true)]
        [HashTable[]]
        $Results
    )

    PROCESS
    {
        $Uri = "add_results/$RunId"

        $NotTestResults =  ($Results | Where-Object test_id -Eq $null).Length -ne 0
        if ( $NotTestResults )
        {
            throw (New-Object ArgumentException -ArgumentList "Results must contain a 'test_id' property. Did you use New-TestRailResult -TestId <x> ?")
        }

        $Parameters = @{}

        if ( $Results -is [Array] )
        {
            $Parameters = @{ results = $Results }
        }
        else
        {
            $Parameters = @{ results = @( $Results ) }
        }

        Invoke-TestRailPostRequest -Uri $Uri -Parameters $Parameters
    }
}

function Add-TestRailAttachmentToResult
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [Alias('result_id')]
        [int]
        $ResultId,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]
        $FilePath
    )
    PROCESS
    {
        $Uri = "add_attachment_to_result/$ResultId"
        Invoke-TestRailPostAttachmentRequest -Uri $Uri -File $FilePath
    }
}