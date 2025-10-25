# AI Agent Bootstrap: Claude Code Extension Patcher

## Purpose
Patches Anthropic's Claude Code VSCode extension to add auto-approve "Bypass Permissions" mode. Users want to disable tool execution prompts.

## Core Strategy: Resilient Regex Patching
- **Problem**: Minified code changes variable/class names between versions (v2.0.1: `o`, v2.0.10: `L`, v2.0.26: `T`, v2.0.27: `O`)
- **Solution**: Regex patterns match ANY variable names instead of hardcoded values
- **Example**: `permissionMode:([a-zA-Z])="default"` matches any single-letter variable

## Key Files
- `patch-cc-code.sh`: Main patcher (4 JS patches + 4 CSS patches). Cross-platform bash script.
- `extension.js`: Backend permission logic
- `webview/index.js`: Frontend UI and session state
- `webview/index.css`: Visual styling (minified, no line breaks)

## Patch Mechanics

### JavaScript Patches (RESILIENT)
1. **PATCH 1** (extension.js): `permissionMode:([a-zA-Z])="default"` → `permissionMode:$1` - Removes server-side default
2. **PATCH 2** (webview/index.js): `["default","acceptEdits","plan"]` → `["bypassPermissions","acceptEdits","plan"]` - Adds mode to array
3. **PATCH 3** (webview/index.js): `permissionMode=([a-z]{2})("default")` → `$1("bypassPermissions")` - Changes session init
4. **PATCH 4** (webview/index.js): Multiple string replacements for UI text/tooltips

### CSS Patches (RESILIENT)
1. **CSS PATCH 1**: Regex `(\.[\w-]+\[data-permission-mode=bypassPermissions\]\s*\.[\w-]+)\{color:var\(--app-error-foreground\)\}` changes red to amber
2. **CSS PATCH 2**: Auto-detects container class name from file, appends border/background styling
3. **CSS PATCH 3**: Adds transitions using discovered class name
4. **CSS PATCH 4**: Appends general overrides with stable selectors (`body[data-permission-mode=bypassPermissions]`)

## Resilience Elements
**STABLE** (won't break):
- String literals: `"default"`, `"bypassPermissions"`, `"Ask before edits"`
- CSS attributes: `[data-permission-mode=bypassPermissions]`
- Element selectors: `button`, `svg`, `body`
- CSS variables: `var(--app-error-foreground)`

**VARIABLE** (handled):
- Minified vars: `([a-zA-Z])`, `([a-z]{2})` patterns
- CSS classes: Auto-detected via `grep -oP '\.[\w-]+(?=\[data-permission-mode)'`
- Whitespace: `\s*` handles both minified/non-minified

## Important Patterns
- CSS is single-line minified (no line breaks)
- Must escape `{}` in perl replacement strings: `\{color:...\}`
- Backups use `.backup-original` suffix
- `--restore` flag reverses all patches
- `--no-ui` skips CSS patches (faster, keeps red indicator)

## Version Compatibility
Tested: v2.0.1, v2.0.10, v2.0.26, v2.0.27
Strategy: Patterns degrade gracefully - failed matches become no-ops, not breaks

## Color Scheme
Bypass mode uses amber instead of red:
- `rgba(217, 119, 87, 0.9)` - text/icons
- `rgba(217, 119, 87, 0.3)` - borders
- `rgba(217, 119, 87, 0.05)` - backgrounds

## Common Issues
1. Red UI still showing? CSS class names changed - CSS rules become no-ops
2. Perl syntax errors? Missing `\` before `{}` in replacements
3. Patches not applying? Check if string literals changed in new version
