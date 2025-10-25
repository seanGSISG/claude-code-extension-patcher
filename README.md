# Claude Code Extension Enhancer

## 🎉 MISSION ACCOMPLISHED: Bypass Permissions Now Native!

**UPDATE (2025)**: Anthropic officially added bypass permissions mode in recent releases! Check your settings:
```
Settings → Extensions → Claude Code → "Allow Dangerously Skip Permissions"
```

**This project succeeded.** The feature we hacked in now ships natively. We like to think our patcher helped prove the demand. 🏆

---

## 🚀 New Direction: Feature Enhancement Suite

Since Anthropic listened (thanks!), we're pivoting to add **MORE missing features** to Claude Code. Why stop at one?

**Current enhancements:**
- ✅ Bypass permissions mode *(now native - legacy patcher still works for old versions)*
- 🎨 Custom cyan UI theming for bypass mode *(Anthropic's version lacks our style)*
- 🔜 **Your ideas here** - What features does Claude Code need?

## Quick Start (Legacy Bypass Mode)

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

**Original mission**: Everyone wanted auto-approve. Anthropic didn't add it. So we built a patcher.

**Plot twist**: They added it. We won. 🎊

**New mission**: Keep adding features they haven't thought of yet. This is now a **feature enhancement suite** for Claude Code, using their own AI to improve their extension.

The irony continues to write itself.

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

## What's Next?

See [FEATURES.md](FEATURES.md) for roadmap. Community-proven priorities:
- 🧠 **Context indicator** - Prevent overflow (S-TIER)
- 💰 **Cost/token display** - Budget tracking (S-TIER)
- 🎯 **TODO viewer** - Persistent task panel (A-TIER)
- 👁️ **Subagent monitor** - Track parallel agents (A-TIER)

Have a feature request? Open an issue!

## Contributing

This project proved that community-driven enhancements work. Anthropic literally added our main feature. Let's keep going.

**Philosophy**: Build it as a patcher → Prove demand → Get it into core → Move to next feature

## Credits

**Created by**: [seanGSISG](https://github.com/seanGSISG)
**Co-creator**: Anthropic's Claude Code
**Achievement**: Successfully influenced official product roadmap 🏆

*We used Claude Code to patch itself. The assistant helped write the tool that modifies the very extension it runs in. Then Anthropic made it official. Peak 2025 developer workflow.*

## Files

- `patch-cc-code.sh` - Legacy bypass mode patcher (still works for v2.0.1-2.0.27)
- `CLAUDE.md` - AI agent bootstrap file
- `CHANGELOG.md` - Version history
- `.archive/` - Historical artifacts of our successful campaign
