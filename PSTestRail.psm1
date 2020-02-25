class APIClient
{
    [ValidateNotNullOrEmpty()][string]
    $Url
    [ValidateNotNullOrEmpty()][string]
    $UserName
    [ValidateNotNullOrEmpty()][string]
    $Password

    [PSObject]
    SendGet(
        [string]
        $Uri
    ){
        return $this.SendRequest("GET", $Uri, $null)
    }

    [PSObject]
    SendPost(
        [string]
        $Uri,
        [HashTable]
        $Parameters = @{}
    ){
        return $this.SendRequest("POST", $Uri, $Parameters)
    }

    [PSObject]
    SendPostAttachment(
        [string]
        $Uri,
        [string]
        $FilePath
    ){
        if(-not(Test-Path $FilePath -PathType Leaf)){
            throw "Given $FilePath was not a file."
        }
        $arguments = $this.GetDefaultRestMethodArguments("POST", $Uri)
        $arguments["ContentType"] = "multipart/form-data"
        $arguments["Form"] = @{
            attachment = Get-Item -Path $FilePath
        }
        return (Invoke-RestMethod @arguments)
    }

    [PSObject]
    SendRequest(
        [string]$Method,
        [string]$Uri,
        [PSObject]$Data
    ){
        $arguments = $this.GetDefaultRestMethodArguments($Method, $Uri)
        $arguments["ContentType"] = "application/json"

        # we have to set a body because of powershell bug https://github.com/PowerShell/PowerShell/issues/9473
        $arguments["Body"] =  `
            if($Method -eq "POST" -and (!!$Data)){
                ConvertTo-Json -InputObject $Data
            } else {
                ""
            }

        return (Invoke-RestMethod @arguments)
    }

    [Hashtable]
    GetDefaultRestMethodArguments(
        [string]$Method,
        [string]$Uri
    ){
        $base64AuthInfo = $this.GetBase64AuthInfo()
        return @{
            Headers = @{
                Authorization=("Basic $base64AuthInfo")
            };
            Method = $Method;
            Uri = $this.GetAbsoluteUri($Uri)
        }
    }

    [string]
    GetAbsoluteUri(
        [string]$Uri
    ){
        return "{0}index.php?/api/v2/{1}" -f $this.Url, $Uri
    }

    [string]
    GetBase64AuthInfo(){
        return [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $this.UserName, $this.Password)))
    }
}
$Script:ApiClient = $null
$Script:Debug = $false

function Initialize-TestRailSession
{
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [Uri]
        $Uri,

        [Parameter(Mandatory=$true, Position=1)]
        [String]
        $User,

        [Parameter(Mandatory=$true, Position=2)]
        [Alias("ApiKey")]
        [String]
        $Password
    )
    $Script:ApiClient = [ApiClient]@{
        Url = $Uri
        UserName = $User
        Password = $Password
    }
}

function ConvertTo-UnixTimestamp
{
    param
    (
        [Parameter(Mandatory=$true)]
        [DateTime]
        $DateTime,

        [Parameter(Mandatory=$false)]
        [switch]
        $UTC
    )

    $Kind = [DateTimeKind]::Local

    if ( $UTC.IsPresent )
    {
        $Kind = [DateTimeKind]::Utc
    }

    [int](( $DateTime - (New-Object DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, $Kind) ).TotalSeconds)
}

function ConvertFrom-UnixTimestamp
{
    param
    (
        [Parameter(Mandatory=$true, ParameterSetName="Timestamp")]
        [int]
        $Timestamp,

        [Parameter(Mandatory=$true, ParameterSetName="TimestampMS")]
        [long]
        $TimestampMS,

        [Parameter(Mandatory=$false)]
        [switch]
        $UTC
    )

    $Kind = [DateTimeKind]::Local

    if ( $UTC.IsPresent )
    {
        $Kind = [DateTimeKind]::Utc
    }

    switch ( $PSCmdlet.ParameterSetName )
    {
        "Timestamp" {
            (New-Object DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, $Kind).AddSeconds($Timestamp)
        }

        "TimestampMS" {
            (New-Object DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, $Kind).AddMilliseconds($TimestampMS)
        }
    }
}

function Set-TestRailDebug
{
    param
    (
        [Parameter(Mandatory=$true)]
        [bool]
        $Enabled
    )

    $Script:Debug = $Enabled
}

function Get-TestRailDebug
{
    $Script:Debug
}

function Invoke-TestRailGetRequest
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Uri,

        [Parameter(Mandatory=$false)]
        [System.Collections.Specialized.NameValueCollection]
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    )

    if ( $null -eq $Script:ApiClient )
    {
        throw New-Object Exception -ArgumentList "You must call Initialize-TestRailSession first"
    }

    $RealUri = $Uri
    if ( -not [String]::IsNullOrEmpty($Parameters.ToString()) )
    {
        $RealUri += [String]::Format("&{0}", $Parameters.ToString())
    }

    Write-ToDebug -Message "$($MyInvocation.MyCommand.Name): Uri: $RealUri"

    $Result = $Script:ApiClient.SendGet($RealUri)
    Write-ToDebug -Message "$($MyInvocation.MyCommand.Name): Result: '$($Result | ConvertTo-Json -Depth 99)'"

    return $Result
}

function Invoke-TestRailPostRequest
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Uri,

        [Parameter(Mandatory=$false)]
        [HashTable]
        $Parameters = @{}
    )

    if ( $null -eq $Script:ApiClient )
    {
        throw New-Object Exception -ArgumentList "You must call Initialize-TestRailSession first"
    }

    Write-ToDebug -Message "$($MyInvocation.MyCommand.Name): Uri: $Uri"
    Write-ToDebug -Message "$($MyInvocation.MyCommand.Name): Parameters: $($Parameters | ConvertTo-Json -Depth 99 )"

    $Result = $Script:ApiClient.SendPost($Uri, $Parameters)
    Write-ToDebug -Message "$($MyInvocation.MyCommand.Name): Result: '$($Result | ConvertTo-Json -Depth 99)'"

    return $Result
}

function Invoke-TestRailPostAttachmentRequest
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Uri,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]
        $File
    )

    if ( $null -eq $Script:ApiClient )
    {
        throw New-Object Exception -ArgumentList "You must call Initialize-TestRailSession first"
    }

    Write-ToDebug -Message "$($MyInvocation.MyCommand.Name): Uri: $Uri"
    Write-ToDebug -Message "$($MyInvocation.MyCommand.Name): File: $File"

    $Result = $Script:ApiClient.SendPostAttachment($Uri, $File)
    Write-ToDebug -Message "$($MyInvocation.MyCommand.Name): Result: '$($Result | ConvertTo-Json -Depth 99)'"

    return $Result
}

function Add-UriParameters
{
    param (
        [Parameter(Mandatory=$true)]
        [System.Collections.Specialized.NameValueCollection]
        $Parameters,
        
        [Parameter(Mandatory=$true)]
        [HashTable]
        $Hash
    )

    if ($null -eq $Parameters)
    {
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    }

    $Hash.Keys | ForEach-Object {
        $Key = $_;

        if ($Hash.$_ -is [Array])
        {
            $Key = $_; $Hash.$Key | ForEach-Object { $Parameters.Add( $Key, $_ ) }
        }
        else
        {
            $Parameters.Add( $Key, $Hash.$Key )
        }
    }
}

function Get-TestRailApiClient
{
    $Script:ApiClient
}

function Write-ToDebug
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ParameterSetName="Simple")]
        [string]
        $Message,

        [Parameter(Mandatory=$true, ParameterSetName="Complex")]
        [string]
        $Format,

        [Parameter(Mandatory=$true, ParameterSetName="Complex")]
        [object[]]
        $Parameters
    )

    if( $Script:Debug -eq $true )
    {
        switch  ($PSCmdlet.ParameterSetName)
        {
            "Simple"
            {
                Write-Debug -Message $Message
            }
            "Complex"
            {
                Write-Debug -Message ($Format -f $Parameters)
            }
        }
    }
}