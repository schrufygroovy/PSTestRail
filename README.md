## Getting Started

First, import the module:

    PS> Import-Module .\PSTestRail

Use the `Initialize-TestRailSession` to initialise the module with your TestRail API credentials (you must have API access enabled). There are two equivalent parameter sets for the `Initialize-TestRailSession`

    PS> Initialize-TestRailSession [-Uri] <uri> [-User] <string> [-Password] <string>

and

    PS> Initialize-TestRailSession [-Uri] <uri> [-User] <string> [-ApiKey] <string>

Since the TestRail API doesn't distinguish between your normal login password and a configured API Key, `-ApiKey` is just an alias for `-Password`, but helps to make your intentions clear when scripting.

There's no return value here - it just sets up an internal instance of the .Net TestRail API Client. This means you won't get an error if you pass bogus information until the first time you try an API operation.

If you have a hosted TestRail subscription, your Uri will be `https://<tenantname>.testrail.net/`. The API endpoint suffix is added by the client.

## Simple Usage

Initialise the TestRail session

    PS> Initialize-TestRailSession -Uri https://tenant.testrail.net/ -User someuser -ApiKey myapikey

Enumerate completed projects (`-IsCompleted` defaults to `$false`)

    PS> Get-TestRailProjects -IsCompleted $true

Enumerate Test Suites associated with a project

    PS> Get-TestRailSuites -ProjectId 76

 or even

    PS> Get-TestRailProject -ProjectId 76 | Get-TestRailSuites

or perhaps

    PS> Get-TestRailProjects | Where name -eq "My Project" | Get-TestRailSuites

### Conduct a new Test Run

    PS> $project = Get-TestRailProjects | Where name -eq "My Project"
    PS> $suite = Get-TestRailSuites -ProjectId $project.id | Where name -eq "Test Suite"
    PS> $run = Start-TestRailRun -ProjectId $project.id -SuiteId $suite.id -Name "My Test Run" -AssignedTo 1 -Description "A test run where I test things" -CaseId 17,36,142,86
    # Do some tests
    PS> $results = @()
    PS> $results += New-TestRailResult -CaseId 17 -StatusId 1 -Comment "Everything was fine" -Elapsed "3m" -CustomFields @{ "custom_colour" = "Blue" }
    PS> $results += New-TestRailResult -CaseId 36 -StatusId 2 -Comment "Something useful about the test case" -CustomFields @{ "detail" = "The custom_ prefix will be added automatically"; colour = "Yellow" }
    PS> Add-TestRailResultsForCases -RunId $run.id -Results $results
    PS> Stop-TestRailRun -RunId $run.id

## Return Values

To call the TestRail Api I am using `Invoke-RestMethod` and I am just returning the results from this call forward. (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod?view=powershell-7#outputs).


## Credits
Credits to original owner of this: https://github.com/wermspowke/PSTestRail

## Cmdlet Naming

This module tries to use Powershell Verbs properly. If the TestRail API method conflicts with the Powershell meaning of the Verb then I've used the Powershell convention. This hopefully makes it less confusing to people already familiar with Powershell.

For example: The TestRail API has `update_run` for changing the properties of an existing Test Run definition, but the Powershell `Set` verb is more appropriate than the `Update` verb in my opinion; hence `Set-TestRailRun`.

Likewise, the API operation `add_run` creates a new Test Run, but `New-TestRailRun` is more appropriate.

Generally:

* `Add-` to create a new instance or instances of a thing in TestRail, e.g. `Add-TestRailResult`, `Add-TestRailResultsForCases`
* `Start/Stop-` to start/begin or conclude/end a session (e.g. Test Run), e.g. `Start-TestRailRun`, `Stop-TestRailRun`
* `Get-` to retrieve a resource, e.g. `Get-TestRailProjects`, `Get-TestRailTests`
* `New-` create a new instance of a resource, e.g. `New-TestRailResult`
* `Set-` change the data associated with an existing resource, e.g. `Set-TestRailRun`

## Troubleshooting

This is still a work in progress, so there are going to be bugs. To help with bug reports please use the module like this and include the information in your issue report:

    PS> Import-Module .\PSTestRail
    PS> Set-TestRailDebug -Enabled:$true
    PS> $DebugPreference = "Continue"
    # Now use as normal

To disable debugging simply set debug mode to disabled:

    PS> Set-TestRailDebug -Enabled:$false

though thanks to the `$DebugPreference` setting you might continue to see debug information from other cmdlets outside of the `PSTestRail` module. The *normal* state of `$DebugPreference` is `SilentlyContinue` so set it back to that to completely unwind changes made above.

    PS> $DebugPreference = "SilentlyContinue"

While debugging is enabled you will see some more verbose output including the full request URI and the parsed response:

    PS> Get-TestRailProjects
    DEBUG: Invoke-TestRailGetRequest: Uri: get_projects
    DEBUG: Invoke-TestRailGetRequest: Result: @{id=1; name=Test Project; show_announcement=False; is_completed=False; completed_on=; suite_mode=1; url=https://tenant.testrail.net/index.php?/projects/overview/1}

## Notes

### Start/Stop vs Open/Close

I'm in two minds with `Start-`/`Stop-TestRailRun`. There's an argument that it should be `Open-`/`Close-TestRailRun` instead, except that once you stop (or close) a Test Run in TestRail you can't re-open it to make changes. TestRail's own nomenclature talks about closing Runs down, but then it's confused because you create a new run with `add_run` and anyway I've already said I'm ignoring TestRail's verbs in favour of doing the right thing by PowerShell. `Start-` and `Stop-` are *Lifecycle* verbs so I'll stick with those semantics for now.