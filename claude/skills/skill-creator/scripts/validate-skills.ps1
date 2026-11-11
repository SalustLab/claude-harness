<#
.SYNOPSIS
  Static validation of a folder of Claude Code skills (one sub-folder per skill). Read-only.
.DESCRIPTION
  Errors (exit 1): missing/invalid frontmatter, name/folder mismatch, bad name or description, hidden Unicode,
  load-time shell expansion in SKILL.md, broken local file references, invalid or cyclic metadata.invokes graph.
  Warnings: long body, CRLF/BOM, allowed-tools or hooks grants, unknown frontmatter keys, built-in name collisions.
  Windows PowerShell 5.1 compatible.
.EXAMPLE
  .\validate-skills.ps1 -Root ..\..         # validate the skills folder that contains skill-creator
  .\validate-skills.ps1 -Root C:\x\skills -List
#>
[CmdletBinding()]
param(
    [string]$Root = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [switch]$List
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$KnownKeys = @('name', 'description', 'when_to_use', 'argument-hint', 'arguments', 'disable-model-invocation', 'user-invocable',
    'allowed-tools', 'disallowed-tools', 'model', 'effort', 'context', 'agent', 'background', 'hooks', 'paths', 'shell',
    'metadata', 'license', 'compatibility', 'version')
$BuiltinNames = @('code-review', 'review', 'security-review', 'simplify', 'debug', 'init', 'loop', 'schedule', 'run',
    'claude-api', 'update-config', 'keybindings-help', 'fewer-permission-prompts', 'workflow-authoring', 'plugin-authoring',
    'dataviz', 'help', 'clear', 'compact', 'config', 'model', 'memory', 'mcp', 'login', 'logout', 'cost', 'usage', 'agents')
$NeverTargets = @('coding-skill-router', 'release-readiness')
$script:errors = 0; $script:warnings = 0
function Err([string]$Skill, [string]$Msg) { $script:errors++; Write-Host "ERROR $Skill`: $Msg" -ForegroundColor Red }
function Wrn([string]$Skill, [string]$Msg) { $script:warnings++; Write-Host "WARN  $Skill`: $Msg" -ForegroundColor Yellow }

function Get-Unquoted([string]$v) {
    $v = $v.Trim()
    if ($v.Length -ge 2 -and $v.StartsWith('"') -and $v.EndsWith('"')) { return $v.Substring(1, $v.Length - 2).Replace('\"', '"') }
    if ($v.Length -ge 2 -and $v.StartsWith("'") -and $v.EndsWith("'")) { return $v.Substring(1, $v.Length - 2).Replace("''", "'") }
    $v
}

# Minimal frontmatter reader: top-level keys, block scalars, and the metadata map (invokes list, vcs).
function Read-Frontmatter([string[]]$Lines) {
    $fm = [ordered]@{}; $meta = [ordered]@{}; $key = $null; $block = $false
    foreach ($l in $Lines) {
        if ($l -match '^([A-Za-z][\w-]*):\s*(.*)$') {
            $key = $Matches[1]; $val = $Matches[2]
            $block = $val -match '^[>|][-+]?$'
            $fm[$key] = if ($block) { '' } else { Get-Unquoted $val }
        } elseif ($key -eq 'metadata' -and $l -match '^\s+([\w-]+):\s*(.*)$') {
            $meta[$Matches[1]] = $Matches[2].Trim()
        } elseif ($block -and $key -and $l -match '^\s+(.*)$') {
            $fm[$key] = ($fm[$key] + ' ' + $Matches[1]).Trim()
        }
    }
    $invokes = @()
    if ($meta.Contains('invokes')) {
        $raw = $meta['invokes']
        if ($raw -notmatch '^\[(.*)\]$') { $invokes = $null }
        else { $invokes = @($Matches[1].Split(',') | ForEach-Object { (Get-Unquoted $_) } | Where-Object { $_ }) }
    }
    [pscustomobject]@{ Fields = $fm; Meta = $meta; Invokes = $invokes }
}

function Test-HiddenChars([string]$Text) {
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $cat = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($Text, $i)
        if ($cat -eq 'Format' -or $cat -eq 'PrivateUse') {
            $cp = [char]::ConvertToUtf32($Text, $i)
            $line = ($Text.Substring(0, $i) -split "`n").Count
            return ('U+{0:X4} at line {1}' -f $cp, $line)
        }
        if ([char]::IsHighSurrogate($Text[$i])) { $i++ }
    }
    $null
}

if (-not (Test-Path $Root)) { throw "Skills folder not found: $Root" }
$skills = @(Get-ChildItem $Root -Directory | Where-Object { $_.Name -notin @('synced', 'node_modules') } | Sort-Object Name)
$graph = @{}; $rows = @()

foreach ($dir in $skills) {
    $n = $dir.Name; $md = Join-Path $dir.FullName 'SKILL.md'
    if (-not (Test-Path $md)) { Err $n 'SKILL.md not found'; continue }
    $bytes = [IO.File]::ReadAllBytes($md)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { Wrn $n 'SKILL.md has a UTF-8 BOM' }
    $text = $utf8.GetString($bytes).TrimStart([char]0xFEFF)
    if ($text.Contains("`r")) { Wrn $n 'SKILL.md has CRLF line endings (repo convention: LF)' }
    $lines = $text.Replace("`r", '') -split "`n"
    if ($lines[0] -ne '---') { Err $n 'frontmatter must start on line 1 with ---'; continue }
    $end = [Array]::IndexOf($lines, '---', 1)
    if ($end -lt 0) { Err $n 'frontmatter is not closed with ---'; continue }
    $fm = Read-Frontmatter $lines[1..($end - 1)]
    $f = $fm.Fields

    # name / description
    if (-not $f.Contains('name') -or -not $f['name']) { Err $n "missing 'name'" }
    elseif ($f['name'] -cne $n) { Err $n "name '$($f['name'])' does not match folder '$n'" }
    elseif ($f['name'] -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or $f['name'].Length -gt 64) { Err $n "name '$($f['name'])' must be kebab-case, at most 64 chars" }
    if (-not $f.Contains('description') -or -not $f['description']) { Err $n "missing 'description'" }
    else {
        $d = $f['description']
        if ($d.Length -gt 1024) { Err $n "description has $($d.Length) chars (max 1024)" }
        if ($d -match '[<>]') { Err $n 'description contains angle brackets' }
        $total = $d.Length + $(if ($f.Contains('when_to_use')) { $f['when_to_use'].Length } else { 0 })
        if ($total -gt 1536) { Wrn $n "description + when_to_use = $total chars; listing truncates at 1536" }
    }
    foreach ($k in $f.Keys) { if ($KnownKeys -notcontains $k) { Wrn $n "unknown frontmatter key '$k'" } }
    if ($f.Contains('allowed-tools')) { Wrn $n "allowed-tools pre-approves tools ($($f['allowed-tools'])); justify or remove" }
    if ($f.Contains('hooks')) { Wrn $n 'frontmatter hooks run shell commands while the skill is active; confirm they are intended' }
    if ($BuiltinNames -contains $n) { Wrn $n "name collides with a built-in command/skill and replaces it" }

    # body
    $bodyLines = $lines.Count - $end - 1
    if ($bodyLines -gt 500) { Wrn $n "body has $bodyLines lines (recommended under 500)" }
    $body = ($lines[($end + 1)..($lines.Count - 1)] -join "`n")
    if ($body -match '!`[^`\n]+`') { Err $n "load-time shell expansion syntax found: $($Matches[0])" }

    # local references: markdown links and backticked bundled paths
    $refs = @()
    foreach ($m in [regex]::Matches($body, '\]\(([^)\s#]+)(#[^)]*)?\)')) { $refs += $m.Groups[1].Value }
    foreach ($m in [regex]::Matches($body, '`((references|agents|scripts|languages|infrastructure|assets)/[\w./-]+)`')) { $refs += $m.Groups[1].Value }
    foreach ($r in ($refs | Sort-Object -Unique)) {
        if ($r -match '^(https?|mailto):' -or $r.Contains('<')) { continue }
        if (-not (Test-Path (Join-Path $dir.FullName $r))) { Err $n "referenced file not found: $r" }
    }

    # hidden characters in every text file of the skill
    foreach ($file in Get-ChildItem $dir.FullName -Recurse -File) {
        $b = [IO.File]::ReadAllBytes($file.FullName)
        if ([Array]::IndexOf($b, [byte]0) -ge 0) { continue }   # binary
        $t = $utf8.GetString($b)
        if ($t.Length -gt 0 -and $t[0] -eq [char]0xFEFF) { $t = $t.Substring(1) }
        $h = Test-HiddenChars $t
        if ($h) { Err $n "hidden/format character $h in $($file.FullName.Substring($dir.FullName.Length + 1))" }
    }

    if ($null -eq $fm.Invokes) { Err $n 'metadata.invokes must be a flow list, e.g. [a, b]'; $graph[$n] = @() }
    else { $graph[$n] = @($fm.Invokes) }
    $rows += [pscustomobject]@{ Name = $n; DescChars = $(if ($f.Contains('description')) { $f['description'].Length } else { 0 }); Lines = $lines.Count
        Invokes = ($graph[$n] -join ', '); Vcs = $(if ($fm.Meta.Contains('vcs')) { $fm.Meta['vcs'] } else { '' }) }
}

# invocation graph: targets exist, never router/release-readiness, no cycles
foreach ($s in $graph.Keys) {
    foreach ($t in $graph[$s]) {
        if (-not $graph.ContainsKey($t)) { Err $s "metadata.invokes target not found: $t" }
        if ($NeverTargets -contains $t) { Err $s "metadata.invokes must not target $t" }
    }
}
$state = @{}
function Visit([string]$Node, [string[]]$Path) {
    if ($state[$Node] -eq 'done') { return }
    if ($state[$Node] -eq 'active') { Err $Node ("invocation cycle: " + (($Path + $Node) -join ' -> ')); return }
    $state[$Node] = 'active'
    foreach ($t in @($graph[$Node])) { if ($graph.ContainsKey($t)) { Visit $t ($Path + $Node) } }
    $state[$Node] = 'done'
}
foreach ($s in $graph.Keys) { Visit $s @() }

if ($List) { $rows | Format-Table -AutoSize | Out-String -Width 200 | Write-Host }
Write-Host ("RESULT skills={0} errors={1} warnings={2}" -f $skills.Count, $script:errors, $script:warnings)
exit ([int]($script:errors -gt 0))
