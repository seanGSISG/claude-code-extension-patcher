# Claude Code Extension Patcher

**TL;DR**: Adds the auto-approve mode that Anthropic forgot to include.

## Quick Start

```bash
curl -O https://raw.githubusercontent.com/seanGSISG/claude-code-extension-patcher/main/patch-cc-code.sh
chmod +x patch-cc-code.sh
./patch-cc-code.sh
# Reload VS Code (Ctrl+Shift+P → "Developer: Reload Window")
```

Done. Bypass mode now available in the extension.

## What This Does

Patches Claude Code extension to enable "Bypass Permissions" mode (auto-approves all tool executions). Also makes the UI less alarming because nobody wants their editor yelling at them in red.

**Options:**
```bash
./patch-cc-code.sh              # Full patch (recommended)
./patch-cc-code.sh --no-ui      # Skip amber styling (keeps red)
./patch-cc-code.sh --restore    # Undo everything
```

## Why This Exists

Everyone wants auto-approve. Anthropic didn't add it. So here we are, using their own AI to patch their extension.

The irony writes itself.

## Technical Details

- **Resilient**: Uses regex patterns, not hardcoded variable names. Survives minification changes.
- **Cross-platform**: Linux, macOS, Windows (Git Bash), WSL, Dev Containers, Remote SSH
- **Auto-detects**: Finds extensions in VS Code, Cursor, Insiders automatically
- **Tested**: v2.0.1, v2.0.10, v2.0.26, v2.0.27
- **Backed up**: Originals saved as `.backup-original`

**Regex Strategy Example:**
```bash
# Brittle (breaks on updates)
sed 's/permissionMode:O="default"/permissionMode:O/g'

# Resilient (survives version changes)
perl -pe 's/(permissionMode:)([a-zA-Z])="default"/$1$2/g'
```

Minified JS changes variable names (`O` → `T` → `L`) between versions. We match structure patterns instead.

## Requirements

- Perl (pre-installed on Linux/Mac, bundled with Git Bash on Windows)
- Bash shell

## Platform Support

Auto-detects these paths:
- **Linux/WSL**: `~/.vscode/extensions`, `~/.cursor/extensions`, `~/.vscode-remote/extensions`
- **macOS**: `~/Library/Application Support/Code/User/extensions`
- **Windows**: `%APPDATA%/Code/User/extensions` (Git Bash required)

Custom path: `./patch-cc-code.sh --extension-dir /your/path`

## Warning

⚠️ **Bypasses ALL permission prompts.** Claude auto-approves everything. Use in trusted dev environments only.

## Credits

**Created by**: [seanGSISG](https://github.com/seanGSISG)
**Co-creator**: Anthropic's Claude Code

*Yes, we used Claude Code to patch itself. The assistant helped write the tool that modifies the very extension it runs in. If that's not peak 2025 developer workflow, we don't know what is.*

## Files

- `patch-cc-code.sh` - The patcher
- `CLAUDE.md` - AI agent bootstrap file
- `CHANGELOG.md` - Version history
- `.archive/` - Deprecated version-specific scripts
