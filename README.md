# Claude Code Extension Patcher

Patches the Claude Code extension to enable "Bypass Permissions" mode, which automatically approves all tool executions without prompting.

## 🎯 About This Script

**Future-proof patcher using regex patterns**

- ✅ **Auto-updates**: Works with future Claude Code versions automatically
- ✅ **Well-documented**: 400+ lines of detailed comments
- ✅ **No maintenance**: Handles variable name changes from minification
- ✅ **Multi-platform**: Linux, macOS, Windows (Git Bash/MSYS2/Cygwin)
- ✅ **Multi-editor**: VS Code, Cursor, Insiders, Dev Containers, Remote SSH
- ✅ **Custom paths**: Support for non-standard installation locations
- ✨ **NEW: UI Enhancements**: Optional visual improvements (soft amber instead of harsh red!)

**Requires**: Perl (usually pre-installed on Linux/Mac, available via Git Bash on Windows)

### 🎨 What's New in v2.1?

**Optional UI Enhancements** - All approved improvements now available!

Run `./patch-cc-code-ui-enhanced.sh` after patching to get:
- Soft amber color instead of harsh red
- Subtle left border indicator
- Gentle background tint
- Smooth hover effects
- Animated mode transitions

See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) for full details.

### 📦 Archived Version

The older version-specific script (`.archive/patch-cc-code-remote.sh`) is available for reference but no longer maintained. It required manual updates for each Claude Code version.

## 🚀 Quick Start

```bash
# Download the script
curl -O https://raw.githubusercontent.com/seanGSISG/claude-code-extension-patcher/main/patch-cc-code.sh

# Make it executable
chmod +x patch-cc-code.sh

# Run it
./patch-cc-code.sh

# To restore original (if needed)
./patch-cc-code.sh --restore
```

Or use wget:

```bash
wget https://raw.githubusercontent.com/seanGSISG/claude-code-extension-patcher/main/patch-cc-code.sh
chmod +x patch-cc-code.sh
./patch-cc-code.sh
```

## What It Does

The script modifies the Claude Code extension to:
1. Replace the "default" permission mode with "bypassPermissions"
2. Add "Bypass Permissions" to the mode cycling options
3. Update the UI to show "Bypass permissions" button text
4. Auto-approve all tool executions when in bypass mode

## 💡 Why Use This?

- **Faster Development**: Skip repetitive permission prompts during rapid iteration
- **Automation**: Allow Claude to work autonomously on tasks
- **Convenience**: Useful in trusted environments where you want Claude to move quickly

⚠️ **Warning**: Only use this in development environments you trust. This bypasses all safety prompts.

## 📦 Supported Editors & Platforms

The script automatically detects and supports:

### Linux & WSL
| Editor | Location |
|--------|----------|
| **Cursor** | `~/.cursor/extensions` |
| **VS Code** | `~/.vscode/extensions` |
| **VS Code Insiders** | `~/.vscode-insiders/extensions` |
| **Dev Containers** | `~/.vscode-remote/extensions` |
| **GitHub Codespaces** | `~/.vscode-remote/extensions` |
| **Remote SSH** | `~/.vscode-server/extensions` |
| **VS Code OSS** | `~/.vscode-oss/extensions` |
| **VS Code (XDG)** | `~/.local/share/code/extensions` |

### macOS
| Editor | Location |
|--------|----------|
| **VS Code** | `~/Library/Application Support/Code/User/extensions` |
| **Cursor** | `~/Library/Application Support/Cursor/User/extensions` |
| **VS Code Insiders** | `~/Library/Application Support/Code - Insiders/User/extensions` |

### Windows (Git Bash, MSYS2, Cygwin)
| Editor | Location |
|--------|----------|
| **VS Code** | `$APPDATA/Code/User/extensions` |
| **Cursor** | `$APPDATA/Cursor/User/extensions` |
| **VS Code Insiders** | `$APPDATA/Code - Insiders/User/extensions` |

### Custom Installation Paths

If your extension is in a non-standard location, you can specify it:

**Via command-line argument:**
```bash
./patch-cc-code.sh --extension-dir /path/to/extensions
./patch-cc-code-ui-enhanced.sh --extension-dir /path/to/anthropic.claude-code-*
```

**Via environment variable:**
```bash
export CLAUDE_CODE_EXTENSION_DIR=/path/to/extensions
./patch-cc-code.sh
```

## ✅ Tested Versions

- ✅ v2.0.1
- ✅ v2.0.10
- ✅ v2.0.26
- ✅ v2.0.27
- ✅ **Should work with future versions** (unless major architectural changes)

## 🔧 Usage

### Apply Patch
```bash
./patch-cc-code.sh
```

### Restore Original
```bash
./patch-cc-code.sh --restore
```

### Optional: Apply UI Enhancements
After running the main patcher, you can optionally apply UI improvements:

```bash
./patch-cc-code-ui-enhanced.sh
```

This makes the bypass mode indicator more subtle (soft amber instead of harsh red) and adds smooth transitions. See [UI_ENHANCEMENTS.md](UI_ENHANCEMENTS.md) for details.

## What Gets Modified

The script patches two files in your Claude Code extension:
- `extension.js` - Removes hardcoded "default" mode initialization
- `webview/index.js` - Updates mode array, session initialization, and UI text

Original files are backed up with `.original` extension.

## After Patching

1. Reload your editor (Cmd+Shift+P → "Developer: Reload Window")
2. Press `Shift+Tab` to cycle through permission modes
3. Select "Bypass permissions" mode
4. Claude will now auto-approve all operations

## 📁 Repository Structure

- `patch-cc-code.sh` - Main patcher script (universal regex-based)
- `patch-cc-code-ui-enhanced.sh` - Optional UI enhancements (softer colors, better UX)
- `.archive/patch-cc-code-remote.sh` - Old version-specific script (no longer maintained)
- `README.md` - This file
- `UI_ENHANCEMENTS.md` - Detailed UI improvement documentation
- `UPGRADE_NOTES.md` - Technical documentation
- `CHANGELOG.md` - Version history
- `extension.js` - Reference copy of extension.js from v2.0.26
- `index.js` - Reference copy of webview/index.js from v2.0.26

## 📝 Important Notes

- The script auto-detects your editor and extension directory
- Backups are created automatically before patching
- You can safely re-run the script - it detects if already patched
- Run with `--restore` to undo all changes
- The old version-specific script is archived but kept for reference

## 🔍 How The Universal Script Works

The universal script uses **regex patterns** instead of hardcoded variable names:

```bash
# ❌ Version-specific (breaks on updates)
sed 's/permissionMode:O="default"/permissionMode:O/g'  # Only works for v2.0.27

# ✅ Universal (works across versions)
perl -pe 's/(permissionMode:)([a-zA-Z])="default"/$1$2/g'  # Works for any variable
```

### Why This Works

JavaScript minification changes variable names (`O`, `T`, `L`, `o`) but keeps:
- ✅ String literals: `"default"`, `"bypassPermissions"`, `"Ask before edits"`
- ✅ Code structure: `permissionMode:[variable]="default"`
- ✅ Function patterns: `permissionMode=[xx]("default")`

The universal script matches the **structure**, not the **variable names**.

See [UPGRADE_NOTES.md](UPGRADE_NOTES.md) for detailed technical explanation.

## 📚 Documentation

- **[README.md](README.md)** (this file) - Quick start and overview
- **[UPGRADE_NOTES.md](UPGRADE_NOTES.md)** - Detailed technical documentation
- **Script comments** - Both scripts have extensive inline documentation

## 🤝 Credits

**Created by**: seanGSISG

**With assistance from**: Anthropic's Claude Code (the irony is not lost on us)

This patcher was built with help from Claude to patch Claude. Meta? Yes. Useful? Also yes.
