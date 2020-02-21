function Get-TestRailUsers
{
    param
    (
    )

    PROCESS
    {
        $Uri = "get_users"
        $Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        Invoke-TestRailGetRequest -Uri $Uri -Parameters $Parameters
    }
}