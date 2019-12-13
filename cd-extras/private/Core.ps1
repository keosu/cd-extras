${Script:/} = [System.IO.Path]::DirectorySeparatorChar
$Script:undoStack = [System.Collections.Stack]::new()
$Script:redoStack = [System.Collections.Stack]::new()
enum CycleDirection { Undo; Redo }
$Script:cycleDirection = [CycleDirection]::Undo # used by Step-Between

$Script:logger = { Write-Verbose ($args[0] | ConvertTo-Json) }

function DefaultIfEmpty([scriptblock] $default) {
  Begin { $any = $false }
  Process { if ($_) { $any = $true; $_ } }
  End { if (!$any) { &$default } }
}

filter Truncate([int] $maxLength = $cde.MaxMenuLength) {
  $_.Substring(0, [Math]::Min($maxLength, $_.length))
}

filter IsRootedOrRelative {
  ($_ | IsRooted) -or ($_ | IsRelative)
}

filter IsRooted {
  [System.IO.Path]::IsPathRooted($_) -or
  $_ -match '~(/|\\)*' # also consider the path rooted if it's relative to home
}

filter IsRelative {
  $_ -match '^+\.' # e.g. starts with ./, ../, ...
}

filter IsDescendedFrom($maybeAncestor) {
  ($_ | Get-Ancestors).Path -contains ($maybeAncestor | Resolve-Path)
}

filter NormaliseAndEscape {
  $_ | Normalise | Escape
}

filter Normalise {
  $_ -replace '/|\\', ${/}
}

filter Escape {
  [regex]::Escape($_)
}

filter RemoveSurroundingQuotes {
  ($_ -replace "^'", '') -replace "'$", ''
}

filter SurroundAndTerminate($trailChar) {
  if ($_ -notmatch ' |\[|\]') { "$_$trailChar" }
  else { "'$_$trailChar'" }
}

filter RemoveTrailingSeparator {
  $_ -replace "[/\\]$", ''
}

filter EscapeWildcards {
  [WildcardPattern]::Escape($_)
}

function GetStackIndex([array]$stack, [string]$namepart) {
  (
    $items = $stack -eq $namepart # full path match
  ) -or (
    $items = $stack | ? { ($_ | Split-Path -Leaf) -eq $namepart } # full leaf match
  ) -or (
    $items = $stack | ? { ($_ | Split-Path -Leaf) -Match "^$namepart" } # leaf starts with
  ) -or (
    $items = $stack -match ($namepart | NormaliseAndEscape) # anything...
  ) | Out-Null

  [array]::indexOf($stack, ($items | select -First 1))
}

function IndexedComplete() {
  Begin { $items = @() }
  Process { $items += $_ }
  End {
    $items | % {
      $itemText = if ($cde.MenuCompletion -and @($items).Count -gt 1) { "$($_.n)" }
      else { $_.path | SurroundAndTerminate }

      [Management.Automation.CompletionResult]::new(
        $itemText,
        "$($_.n). $($_.name)",
        [Management.Automation.CompletionResultType]::ParameterValue,
        "$($_.n). $($_.path)"
      )
    }
  }
}

function IndexPaths(
  [array]$xs,
  $rootLabel = 'root' # this on happens on *nix
) {
  $xs = $xs | ? { $_ -ne '' }
  if (!$xs.Length) { return }

  1..$xs.Length | % {
    [IndexedPath] @{
      n    = $_
      Name = $xs[$_ - 1] | Split-Path -Leaf | DefaultIfEmpty { $rootLabel }
      Path = $xs[$_ - 1]
    }
  }
}

function RegisterCompletions([string[]] $commands, $param, $target) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName $param -ScriptBlock $target
}

function WriteLog($message) {
  &$logger $message
}
