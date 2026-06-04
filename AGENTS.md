# mini-city Codex Instructions

- 简洁回答，严谨高效，事实为准，禁止捏造；缺少关键事实时再提问。
- This repository contains a Codex adaptation of Claude Code Game Studios.
- Use matching workflows from `.agents/skills/` when relevant.
- Custom studio roles live in `.codex/agents/`. Spawn them only when the user
  explicitly requests subagents, delegation, a team, or parallel agent work.
- `.claude/docs/` and the existing project documents remain shared source
  material for both Claude Code and Codex.
- Preserve the existing Godot structure: `Scenes/`, `Scripts/`, `Resources/`,
  `Assets/`, `Docs/`, and `production/`.
- Keep system responsibilities separated; do not collapse gameplay systems
  into `MainController`.
- Do not overwrite `.claude/` when updating the Codex adaptation. Run
  `.codex/scripts/sync-claude-game-studios.ps1` to resync generated skills and
  custom agents.
