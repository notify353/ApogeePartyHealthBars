[CmdletBinding()]
param([string]$Version, [switch]$ConfirmProduction)
throw 'Distribution publication is disabled even with -ConfirmProduction. Complete RELEASING.md gates and obtain explicit tag approval after a reviewed publisher exists. No files, refs or remote state changed.'
