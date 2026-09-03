# GitHub Copilot Instructions

All AI assistant behavior, architectural standards, and workflow rules are centrally maintained in [AGENTS.md](../AGENTS.md).

## Critical Guidelines
1. **Source of Truth**: Refer to `AGENTS.md` before making architectural or logic changes.
2. **Dual-Platform Balance**:
   - Web PWA/H5: `index.html` (single-file canvas game engine) & `preview.html` (always keep identical).
   - Swift/iOS: `SingleFile_CoupleGamesApp.swift` (self-contained) & `Sources/CoupleGamesCore/`.
3. **No Heavy Dependencies**: Avoid adding npm dependencies, build step pipelines, or unnecessary backend requirements.
4. **Touch & Haptics**: Support multi-touch concurrency on one screen and graceful vibration fallback.
5. **Progress Updates**: Maintain `PROJECT_STATUS.md` and `HANDOFF.md`.
