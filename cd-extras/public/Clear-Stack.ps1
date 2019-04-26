<#
.SYNOPSIS
Clear the items in the cd-extras history stack.

.PARAMETER Undo
Clear contents of the Undo stack only.

.PARAMETER Redo
Clear contents of the Redo stack only.
#>

function Clear-Stack {

  [CmdletBinding()]
  param(
    [switch] $Undo,
    [switch] $Redo
  )

  if ($Undo -or !($Undo -or $Redo)) { $undoStack.Clear() }
  if ($Redo -or !($Undo -or $Redo)) { $redoStack.Clear() }
}