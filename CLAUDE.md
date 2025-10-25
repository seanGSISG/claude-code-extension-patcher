# AI Agent Bootstrap: Claude Code Enhancement Suite

## Mission
Build missing features for Claude Code extension via regex-based patches. Prove community demand → Anthropic adds natively → Move to next feature.

**Success**: Bypass permissions now native (Settings → "Allow Dangerously Skip Permissions")

## Current Focus
See [FEATURES.md](FEATURES.md) for roadmap. Priorities:
1. **Context window indicator** (S-TIER, Easy)
2. **Cost/token display** (S-TIER, Medium)
3. **TODO viewer** (A-TIER, Medium-Hard)
4. **Subagent monitor** (A-TIER, Hard)

## Key Files
- `patch-cc-code.sh` - Main patcher (4 JS + 4 CSS patches)
- `FEATURES.md` - Roadmap with community-validated priorities
- `CHANGELOG.md` - Version history
- `.archive/` - Historical docs and old patches

## Extension Targets
```
~/.vscode-remote/extensions/anthropic.claude-code-VERSION/
├── extension.js          # Backend logic
└── webview/
    ├── index.js          # Frontend UI, session state
    └── index.css         # Styling (single-line minified)
```

## Patching Strategy

### Resilient Regex Patterns
Minified code changes variable names per version (`o` → `L` → `T` → `O`). Use patterns that match structure, not names.

**Example**:
```bash
# BAD (breaks on minification)
sed 's/permissionMode:O="default"/permissionMode:O/g'

# GOOD (resilient)
perl -pe 's/(permissionMode:)([a-zA-Z])="default"/$1$2/g'
```

### Stable Selectors
- String literals: `"bypassPermissions"`, `"Ask before edits"`
- CSS attributes: `[data-permission-mode=bypassPermissions]`
- Element selectors: `button`, `svg`, `body`

### Variable Elements (auto-detect)
- Minified vars: `([a-zA-Z])`, `([a-z]{2})`
- CSS classes: `grep -oP '\.[\w-]+(?=\[data-permission-mode)'`

## Color Scheme (Bypass Mode)
- Text/icons: `rgba(6, 182, 212, 0.9)` (cyan)
- Borders: `rgba(6, 182, 212, 0.3)` (subtle)
- Backgrounds: `rgba(6, 182, 212, 0.05)` (wash)
- Hover: `rgba(6, 182, 212, 0.5)` (medium)

## Common Patterns
- CSS is single-line → use inline replacements
- Escape `{}` in perl: `\{color:...\}`
- Backups: `.backup-original` suffix
- Restore: `--restore` flag
- Skip UI: `--no-ui` flag

## Implementation Notes

### For New Features
1. **Locate data source** - Where does extension store this info?
2. **Choose injection point** - JS modification or CSS addition?
3. **Create resilient pattern** - Regex that survives minification
4. **Test across versions** - v2.0.1, v2.0.10, v2.0.26, v2.0.27
5. **Document in FEATURES.md** - Add to roadmap

### Difficulty Levels
- **Easy**: CSS modifications, reading displayed data
- **Medium**: JS string replacements, UI injections
- **Hard**: API interception, state management
- **Very Hard**: Real-time streaming control, deep integrations

## Next Steps

**v3.1 (Quick Wins)**:
- Read context usage from session state
- Display progress bar in UI
- Show model name from metadata

**v3.2 (High Value)**:
- Intercept API responses for cost data
- Parse token counts from responses
- Session timer from usage limits

**v3.3 (Advanced)**:
- TODO panel with CRUD operations
- Subagent lifecycle tracking
- Integrated status line system

## Philosophy
Community-driven feature development works. We influenced Anthropic's roadmap once. Let's do it again.
