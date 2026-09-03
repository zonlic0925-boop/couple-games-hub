# Claude Code Instructions

> **Single Source of Truth**: Please refer to [AGENTS.md](./AGENTS.md) for the complete, canonical project constitution and guidelines.

## Quick Key Rules for Claude Code
- **Project Structure**: Dual-engine couple games project (H5/PWA single-file in `index.html`, Native SwiftUI in `SingleFile_CoupleGamesApp.swift` and `Sources/CoupleGamesCore/`).
- **Sync Guard**: `preview.html` must remain identical to `index.html`.
- **Touch Principle**: Multi-touch isolation without touch conflicts or bounce scrolls (`touch-action: none`).
- **Status Tracking**: Keep [PROJECT_STATUS.md](./PROJECT_STATUS.md) and [HANDOFF.md](./HANDOFF.md) updated upon task completion.
