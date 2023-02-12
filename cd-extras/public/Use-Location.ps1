<#
.SYNOPSIS
Navigating to a history location

.PARAMETER n
The number of locations to undo.

.PARAMETER NamePart
Partial path name to choose from undo stack.

.EXAMPLE
PS C:\Windows\System32> # Move backward to the previous location
PS C:\Windows\System32> cd ..
PS C:\Windows> Undo-Location # (cd-)
PS C:\Windows\System32> _

.EXAMPLE
PS C:\Windows\System32> # Move backward to the 2nd last location
PS C:\Windows\System32> cd ..
PS C:\Windows\> cd ..
PS C:\> cd- 2
PS C:\Windows\System32> _

.EXAMPLE
PS C:\Windows\System32> # Move backward by name
PS C:\Windows\System32> cd ..
PS C:\Windows\> cd ..
PS C:\> cd- sys
PS C:\Windows\System32> _

.LINK
Redo-Location
Undo-Location
Get-Stack
#>
function Use-Location {
  [OutputType([void], [Management.Automation.PathInfo])]
  [CmdletBinding(DefaultParameterSetName = 'n')]
  param(
    [Parameter(ParameterSetName = 'n', Position = 0)]
    [byte] $n = 1,

    [Parameter(ParameterSetName = 'named', Position = 0, Mandatory, ValueFromPipeline)]
    [string] $NamePart,

    [switch] $PassThru
  )

  if ($PSCmdlet.ParameterSetName -eq 'n' -and $n -ge 1) {
    1..$n | % {
      if ($undoStack.Count) {
        $redoStack.Push($PWD.Path)
        $undoStack.Pop() | EscapeWildcards | Set-Location -PassThru:$PassThru -ErrorAction Ignore
      }
    }
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') { 
    Set-Location $match
  }
}
