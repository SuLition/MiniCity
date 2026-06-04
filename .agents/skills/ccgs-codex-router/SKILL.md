---
name: ccgs-codex-router
description: "Route game-development work through the Codex adaptation of Claude Code Game Studios. Use when the user asks to use the studio system, choose a studio workflow, coordinate game-development roles, or determine the next production step."
---

# CCGS Codex Router

Route the request to the smallest matching workflow under `.agents/skills/`.
Read only the selected workflow unless another workflow is explicitly needed.

## Routing

- New or unclear project direction: `start`, `brainstorm`, `quick-design`
- Existing project adoption or status: `adopt`, `project-stage-detect`,
  `reverse-document`
- Game/system design: `map-systems`, `design-system`, `design-review`,
  `balance-check`
- Architecture: `create-architecture`, `architecture-decision`,
  `architecture-review`, `create-control-manifest`
- Production planning: `create-epics`, `create-stories`, `sprint-plan`,
  `sprint-status`, `estimate`
- Implementation: `dev-story`, `story-readiness`, `story-done`
- QA and review: `code-review`, `qa-plan`, `smoke-check`,
  `regression-suite`, `playtest-report`, `vertical-slice`
- Release: `release-checklist`, `launch-checklist`, `hotfix`,
  `day-one-patch`, `patch-notes`, `changelog`
- Art, UX, and content: `art-bible`, `asset-spec`, `asset-audit`,
  `ux-design`, `ux-review`, `localize`
- Explicit multi-agent team request: use the matching `team-*` workflow and
  matching custom agents from `.codex/agents/`.

## Codex Rules

- Follow `AGENTS.md` and the current user request first.
- Do not spawn custom agents unless the user explicitly requests subagents,
  delegation, a team, or parallel work.
- When no workflow is an exact fit, apply the closest workflow locally and
  state the assumption briefly.
