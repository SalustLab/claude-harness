<#
.SYNOPSIS
  Behavioral evals for skills: runs real `claude -p` sessions against throwaway fixtures and checks which skills
  were activated, which commands were attempted and what the final answer says.
.DESCRIPTION
  For each eval (JSON array, see skill-creator SKILL.md) the runner:
    1. creates <temp>\<id>-<run>\work as a Git repo, an SVN working copy (svnadmin + file://) or a plain folder,
       committing "base" files and leaving "change" files as uncommitted modifications;
    2. copies the skills under test to a project .claude\skills (inside Git fixtures, hidden by .git/info/exclude,
       because Claude Code stops looking for project skills at the Git root; one level above SVN/plain fixtures) and
       the optional instructions file next to it as CLAUDE.md;
    3. runs claude -p with --setting-sources project (installed personal skills, plugins and user settings are not
       loaded), tools limited to Skill/Read/Grep/Glob/Bash plus the eval's opt-in extra_tools, the eval's allow_bash prefixes
       pre-approved, and permission mode auto (default; the auto classifier still blocks risky commands) or dontAsk;
    4. grades the stream-json transcript: a run fails if an asserted skill was not even loaded; then ACTIVATED /
       IGNORED / UNEXPECTED per skill, required and forbidden commands (attempts count, even when denied), regexes
       on the final answer.
  Each run costs real tokens. The user's ~/.claude/CLAUDE.md is still loaded as user memory.
  Windows PowerShell 5.1 compatible. Never touches ~/.claude or real repositories.
.EXAMPLE
  .\run-evals.ps1 -EvalFile ..\..\..\..\tests\skill-evals.json -Only svn-review-routing -Model sonnet
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$EvalFile,
    [string]$SkillsRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [string]$InstructionsFile,
    [string]$HookScript,
    [string]$Model = 'sonnet',
    [string[]]$Only,
    [int]$Runs = 1,
    [int]$Parallel = 3,
    [double]$MaxBudgetUsd = 2,
    [int]$TimeoutSec = 900,
    [ValidateSet('auto', 'dontAsk')][string]$PermissionMode = 'auto',
    [string]$OutDir,
    [switch]$KeepFixtures
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($exe in 'claude', 'git') { if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) { throw "'$exe' not found on PATH" } }
$evals = @((Get-Content -Raw -Encoding UTF8 $EvalFile) | ConvertFrom-Json | ForEach-Object { $_ })   # PS 5.1 does not unroll JSON arrays
if ($Only) { $Only = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() }); $evals = @($evals | Where-Object { $Only -contains $_.id }) }
if (-not $evals) { throw 'No evals selected.' }
if ($evals | Where-Object { $_.fixture.vcs -eq 'svn' }) {
    foreach ($exe in 'svn', 'svnadmin') { if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) { throw "'$exe' not found on PATH (needed by SVN fixtures)" } }
}
$SkillsRoot = (Resolve-Path $SkillsRoot).Path
$tmpRoot = Join-Path ([IO.Path]::GetTempPath()) ('skill-evals-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
if (-not $OutDir) { $OutDir = Join-Path $tmpRoot 'results' }
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Write-Utf8([string]$Path, [string]$Text) {
    New-Item -ItemType Directory -Force (Split-Path $Path -Parent) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, $utf8)
}
function Invoke-Native([string]$Exe, [string[]]$Arguments, [string]$Cwd) {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    Push-Location $Cwd
    try { $out = & $Exe @Arguments 2>&1 | Out-String; $code = $LASTEXITCODE } finally { Pop-Location; $ErrorActionPreference = $old }
    if ($code) { throw "$Exe $($Arguments -join ' ') failed ($code): $out" }
}
function Set-Files([string]$Dir, $Map) {
    if (-not $Map) { return }
    foreach ($p in $Map.PSObject.Properties) {
        $target = Join-Path $Dir ($p.Name -replace '/', '\')
        if ($null -eq $p.Value) { if (Test-Path $target) { Remove-Item $target -Force } }
        else { Write-Utf8 $target ([string]$p.Value) }
    }
}

function New-Fixture($Eval, [string]$Base) {
    $work = Join-Path $Base 'work'
    New-Item -ItemType Directory -Force $work | Out-Null
    $vcs = if ($Eval.fixture.vcs) { $Eval.fixture.vcs } else { 'none' }
    switch ($vcs) {
        'git' {
            Set-Files $work $Eval.fixture.base
            Invoke-Native git @('init', '-q') $work
            Invoke-Native git @('add', '-A') $work
            Invoke-Native git @('-c', 'user.name=eval', '-c', 'user.email=eval@localhost', '-c', 'commit.gpgsign=false', 'commit', '-q', '-m', 'base') $work
        }
        'svn' {
            $repo = Join-Path $Base 'repo'; $import = Join-Path $Base 'import'
            Invoke-Native svnadmin @('create', $repo) $Base
            New-Item -ItemType Directory -Force $import | Out-Null
            Set-Files $import $Eval.fixture.base
            $url = 'file:///' + ($repo -replace '\\', '/') + '/trunk'
            Invoke-Native svn @('import', '-q', $import, $url, '-m', 'base') $Base
            Remove-Item $work -Recurse -Force
            Invoke-Native svn @('checkout', '-q', $url, $work) $Base
            Remove-Item $import -Recurse -Force
        }
        'none' { Set-Files $work $Eval.fixture.base }
        default { throw "Unknown fixture vcs '$vcs' in eval $($Eval.id)" }
    }
    Set-Files $work $Eval.fixture.change
    $work
}

function Start-EvalRun($Eval, [int]$Run) {
    $base = Join-Path $tmpRoot ("{0}-{1}" -f $Eval.id, $Run)
    New-Item -ItemType Directory -Force $base | Out-Null
    $work = New-Fixture $Eval $base
    # Claude Code stops looking for project skills at the Git root, so Git fixtures get .claude/ and CLAUDE.md inside
    # the repo, hidden from `git status` through the local-only .git/info/exclude. SVN/plain fixtures use the parent.
    $proj = if ($Eval.fixture.vcs -eq 'git') { $work } else { $base }
    New-Item -ItemType Directory -Force (Join-Path $proj '.claude\skills') | Out-Null
    foreach ($d in Get-ChildItem $SkillsRoot -Directory) { Copy-Item $d.FullName (Join-Path $proj ".claude\skills\$($d.Name)") -Recurse }
    if ($InstructionsFile) { Copy-Item $InstructionsFile (Join-Path $proj 'CLAUDE.md') }
    if ($proj -eq $work) { [IO.File]::AppendAllText((Join-Path $work '.git\info\exclude'), "`n.claude/`nCLAUDE.md`n", $utf8) }
    Write-Utf8 (Join-Path $base 'prompt.txt') ([string]$Eval.prompt)

    $allow = @('Read', 'Grep', 'Glob', 'Skill', 'Bash(ls:*)', 'Bash(pwd:*)', 'Bash(cd:*)', 'Bash(echo:*)', 'Bash(true:*)')
    foreach ($b in @($Eval.allow_bash)) { if ($b) { $allow += "Bash($b`:*)" } }
    # Opt-in "extra_tools" (e.g. Edit, Write) lets an eval implement inside its throwaway fixture.
    $tools = (@('Skill', 'Read', 'Grep', 'Glob', 'Bash') + @($Eval.extra_tools | Where-Object { $_ })) -join ','
    $allow += @($Eval.extra_tools | Where-Object { $_ })
    $allowArgs = ($allow | ForEach-Object { '"' + $_ + '"' }) -join ' '
    $settingsArg = ''
    if ($HookScript) {
        $hook = @{ hooks = @{ UserPromptSubmit = @(@{ hooks = @(@{ type = 'command'; timeout = 10
                            command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$((Resolve-Path $HookScript).Path)`"" }) }) } }
        Write-Utf8 (Join-Path $base 'eval-settings.json') ($hook | ConvertTo-Json -Depth 10)
        $settingsArg = "--settings `"$base\eval-settings.json`""
    }
    $line = "set CLAUDECODE=&& claude -p --output-format stream-json --verbose --setting-sources project --no-session-persistence " +
        "--model $Model --max-budget-usd $MaxBudgetUsd --permission-mode $PermissionMode --tools `"$tools`" " +
        "--add-dir `"$proj\.claude`" $settingsArg --allowedTools $allowArgs " +
        "< `"$base\prompt.txt`" > `"$base\out.jsonl`" 2> `"$base\err.txt`""
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList "/d /s /c `"$line`"" -WorkingDirectory $work -WindowStyle Hidden -PassThru
    [pscustomobject]@{ Eval = $Eval; Run = $Run; Base = $base; Process = $p; Started = Get-Date }
}

function Get-Transcript([string]$Base) {
    $skills = New-Object System.Collections.ArrayList; $cmds = New-Object System.Collections.ArrayList
    $result = $null; $cost = $null; $turns = $null; $isError = $false; $loaded = @()
    $file = Join-Path $Base 'out.jsonl'
    if (Test-Path $file) {
        foreach ($l in [IO.File]::ReadAllLines($file, $utf8)) {
            if (-not $l.Trim()) { continue }
            try { $e = $l | ConvertFrom-Json } catch { continue }
            if ($e.type -eq 'system' -and $e.subtype -eq 'init') { $loaded = @($e.skills) }
            elseif ($e.type -eq 'assistant') {
                foreach ($c in @($e.message.content)) {
                    if ($c.type -ne 'tool_use') { continue }
                    switch ($c.name) {
                        'Skill' { $s = ([string]$c.input.skill).TrimStart('/'); if ($s.Contains(':')) { $s = $s.Split(':')[-1] }; [void]$skills.Add($s) }
                        'Read' { if ([string]$c.input.file_path -match '[\\/]\.claude[\\/]skills[\\/]([^\\/]+)[\\/]SKILL\.md$') { [void]$skills.Add($Matches[1]) } }
                        { $_ -in 'Bash', 'PowerShell' } { [void]$cmds.Add([string]$c.input.command) }
                    }
                }
            } elseif ($e.type -eq 'result') {
                $result = [string]$e.result; $cost = $e.total_cost_usd; $turns = $e.num_turns; $isError = [bool]$e.is_error
            }
        }
    }
    [pscustomobject]@{ Skills = @($skills | Select-Object -Unique); Commands = @($cmds); Result = $result; Cost = $cost; Turns = $turns; IsError = $isError; Loaded = $loaded }
}

function Test-EvalRun($Job) {
    $x = $Job.Eval.expect; $t = Get-Transcript $Job.Base
    $fail = New-Object System.Collections.ArrayList; $notes = New-Object System.Collections.ArrayList
    if ($null -eq $t.Result) {
        $err = if (Test-Path "$($Job.Base)\err.txt") { (Get-Content "$($Job.Base)\err.txt" -Raw -Encoding UTF8) } else { '' }
        [void]$fail.Add("no final result (timeout or CLI error): $($err.Trim())")
    } elseif ($t.IsError) { [void]$fail.Add('final result flagged is_error') }
    # An assertion about a skill the session never loaded proves nothing: fail the run as a setup problem.
    foreach ($s in @($x.skills_invoked) + @($x.skills_not_invoked)) {
        if ($s -and $t.Loaded -notcontains $s) { [void]$fail.Add("skill '$s' was not loaded in the session (fixture/setup problem)") } }
    $hit = 0
    foreach ($s in @($x.skills_invoked)) { if (-not $s) { continue }
        if ($t.Skills -contains $s) { $hit++; [void]$notes.Add("ACTIVATED $s") } else { [void]$fail.Add("IGNORED $s (expected activation)") } }
    if ($hit -ge 2) { [void]$notes.Add('CO-ACTIVATED ' + (@($x.skills_invoked) -join ' + ')) }
    foreach ($s in @($x.skills_not_invoked)) { if (-not $s) { continue }
        if ($t.Skills -contains $s) { [void]$fail.Add("UNEXPECTED $s (must not activate)") } }
    foreach ($r in @($x.commands_required)) { if (-not $r) { continue }
        if (-not ($t.Commands | Where-Object { $_ -match $r })) { [void]$fail.Add("required command not attempted: /$r/") } }
    foreach ($r in @($x.commands_forbidden)) { if (-not $r) { continue }
        foreach ($c in $t.Commands) { foreach ($part in ($c -split "`n")) { if ($part -match $r) { [void]$fail.Add("forbidden command attempted /$r/: $($part.Trim())") } } } }
    $text = [string]$t.Result
    foreach ($r in @($x.output_must_match)) { if ($r -and $text -notmatch $r) { [void]$fail.Add("answer does not match /$r/") } }
    foreach ($r in @($x.output_must_not_match)) { if ($r -and $text -match $r) { [void]$fail.Add("answer matches forbidden /$r/: $($Matches[0])") } }
    Copy-Item (Join-Path $Job.Base 'out.jsonl') (Join-Path $OutDir ("{0}-{1}.jsonl" -f $Job.Eval.id, $Job.Run)) -ErrorAction SilentlyContinue
    [pscustomobject]@{ id = $Job.Eval.id; run = $Job.Run; pass = ($fail.Count -eq 0); failures = @($fail); notes = @($notes)
        skills = $t.Skills; commands = $t.Commands; cost_usd = $t.Cost; turns = $t.Turns; answer = $text }
}

# Queue, run up to $Parallel at a time, grade as they finish.
$queue = New-Object System.Collections.Queue
foreach ($e in $evals) { for ($r = 1; $r -le $Runs; $r++) { $queue.Enqueue(@($e, $r)) } }
$running = New-Object System.Collections.ArrayList; $results = New-Object System.Collections.ArrayList
Write-Host "Model $Model - $($queue.Count) run(s) - temp $tmpRoot"
while ($queue.Count -or $running.Count) {
    while ($queue.Count -and $running.Count -lt $Parallel) { $q = $queue.Dequeue(); [void]$running.Add((Start-EvalRun $q[0] $q[1])) }
    Start-Sleep -Seconds 3
    foreach ($j in @($running)) {
        $timedOut = ((Get-Date) - $j.Started).TotalSeconds -gt $TimeoutSec
        if (-not $j.Process.HasExited -and -not $timedOut) { continue }
        if (-not $j.Process.HasExited) { & taskkill.exe /T /F /PID $j.Process.Id 2>&1 | Out-Null }
        $res = Test-EvalRun $j; [void]$results.Add($res); [void]$running.Remove($j)
        $tag = if ($res.pass) { 'PASS' } else { 'FAIL' }
        Write-Host ("{0}  {1} (run {2}) skills=[{3}] cost=`${4} turns={5}" -f $tag, $res.id, $res.run, ($res.skills -join ', '), $res.cost_usd, $res.turns)
        foreach ($n in $res.notes) { Write-Host "      $n" }
        foreach ($f in $res.failures) { Write-Host "      - $f" -ForegroundColor Red }
    }
}

$results | ConvertTo-Json -Depth 6 | Out-File (Join-Path $OutDir 'results.json') -Encoding utf8
$passed = @($results | Where-Object { $_.pass }).Count
$cost = ($results | Measure-Object -Property cost_usd -Sum).Sum
Write-Host ("RESULT evals={0} runs={1} passed={2} failed={3} cost=`${4:N2} results={5}" -f $evals.Count, $results.Count, $passed, ($results.Count - $passed), $cost, $OutDir)
if (-not $KeepFixtures) { Get-ChildItem $tmpRoot -Directory | Where-Object { $_.FullName -ne $OutDir } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
exit ([int]($passed -lt $results.Count))
