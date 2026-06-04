param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Split-MarkdownFrontmatter {
    param([Parameter(Mandatory = $true)][string]$Content)

    $match = [regex]::Match(
        $Content,
        "\A---\r?\n(?<frontmatter>.*?)\r?\n---\r?\n?(?<body>.*)\z",
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    if (-not $match.Success) {
        throw "Markdown file has no valid YAML frontmatter."
    }

    return @{
        Frontmatter = $match.Groups["frontmatter"].Value
        Body = $match.Groups["body"].Value
    }
}

function Get-FrontmatterScalar {
    param(
        [Parameter(Mandatory = $true)][string]$Frontmatter,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $escapedKey = [regex]::Escape($Key)
    $match = [regex]::Match($Frontmatter, "(?m)^${escapedKey}:\s*(?<value>.+?)\s*$")
    if (-not $match.Success) {
        throw "Missing frontmatter key: $Key"
    }

    $value = $match.Groups["value"].Value.Trim()
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }

    return $value.Replace('\"', '"')
}

function ConvertTo-YamlQuotedString {
    param([Parameter(Mandatory = $true)][string]$Value)
    return ConvertTo-Json -InputObject $Value -Compress
}

function ConvertTo-TomlQuotedString {
    param([Parameter(Mandatory = $true)][string]$Value)

    $escaped = $Value.Replace("\", "\\").Replace('"', '\"')
    $escaped = $escaped.Replace("`r", "\r").Replace("`n", "\n").Replace("`t", "\t")
    return '"' + $escaped + '"'
}

$claudeSkillsRoot = Join-Path $ProjectRoot ".claude\skills"
$claudeAgentsRoot = Join-Path $ProjectRoot ".claude\agents"
$codexSkillsRoot = Join-Path $ProjectRoot ".agents\skills"
$codexAgentsRoot = Join-Path $ProjectRoot ".codex\agents"

if (-not (Test-Path -LiteralPath $claudeSkillsRoot)) {
    throw "Claude skills directory not found: $claudeSkillsRoot"
}
if (-not (Test-Path -LiteralPath $claudeAgentsRoot)) {
    throw "Claude agents directory not found: $claudeAgentsRoot"
}

New-Item -ItemType Directory -Path $codexSkillsRoot -Force | Out-Null
New-Item -ItemType Directory -Path $codexAgentsRoot -Force | Out-Null

$skillCompatibility = @'
## Codex Compatibility

This workflow is adapted from Claude Code Game Studios for Codex.

- Use Codex-native tools and obey the current user request plus `AGENTS.md`.
- Treat `AskUserQuestion` as a concise direct question to the user.
- Treat `Task` and agent-spawn directives as role consultation. Spawn matching
  Codex custom agents only when the user explicitly requests subagents,
  delegation, a team, or parallel agent work. Otherwise perform the role review
  locally.
- Role definitions live in `.codex/agents/`. Shared studio documents under
  `.claude/docs/` remain valid source material.
- References such as `/code-review` mean the matching Codex skill
  `code-review`; they are not Codex built-in slash commands.
- Claude-specific tool allowlists, model tiers, hooks, and permission syntax do
  not override Codex runtime policy.

---

'@

$skillCount = 0
Get-ChildItem -LiteralPath $claudeSkillsRoot -Directory | ForEach-Object {
    $sourceDirectory = $_.FullName
    $sourceSkill = Join-Path $sourceDirectory "SKILL.md"
    if (-not (Test-Path -LiteralPath $sourceSkill)) {
        return
    }

    $destinationDirectory = Join-Path $codexSkillsRoot $_.Name
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Get-ChildItem -LiteralPath $sourceDirectory -Force | Copy-Item -Destination $destinationDirectory -Recurse -Force

    $parts = Split-MarkdownFrontmatter ([System.IO.File]::ReadAllText($sourceSkill))
    $name = Get-FrontmatterScalar $parts.Frontmatter "name"
    $description = Get-FrontmatterScalar $parts.Frontmatter "description"

    $converted = @(
        "---"
        "name: $name"
        "description: $(ConvertTo-YamlQuotedString $description)"
        "---"
        ""
        $skillCompatibility
        $parts.Body
    ) -join "`n"

    Write-Utf8NoBom (Join-Path $destinationDirectory "SKILL.md") $converted
    $skillCount++
}

$agentCompatibility = @'
You are a Codex custom agent adapted from Claude Code Game Studios.

Follow the current user request and repository AGENTS.md first. Stay within the
assigned role and return a concise, evidence-based result to the parent agent.
Do not assume authority over the user. Do not spawn further agents unless the
user explicitly requested recursive delegation and the runtime permits it.

'@

$agentCount = 0
Get-ChildItem -LiteralPath $claudeAgentsRoot -File -Filter "*.md" | ForEach-Object {
    $parts = Split-MarkdownFrontmatter ([System.IO.File]::ReadAllText($_.FullName))
    $name = Get-FrontmatterScalar $parts.Frontmatter "name"
    $description = Get-FrontmatterScalar $parts.Frontmatter "description"
    $instructions = $agentCompatibility + $parts.Body

    if ($instructions.Contains("'''")) {
        throw "Agent instructions contain unsupported TOML literal delimiter: $($_.Name)"
    }

    $toml = @(
        "name = $(ConvertTo-TomlQuotedString $name)"
        "description = $(ConvertTo-TomlQuotedString $description)"
        "developer_instructions = '''"
        $instructions.TrimEnd()
        "'''"
        ""
    ) -join "`n"

    Write-Utf8NoBom (Join-Path $codexAgentsRoot ($name + ".toml")) $toml
    $agentCount++
}

Write-Output "Converted skills: $skillCount"
Write-Output "Converted agents: $agentCount"
