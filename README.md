# Claude Code Extension Patcher

This script patches the Claude Code extension to add a "Bypass Permissions" mode that automatically approves all tool executions without prompting.

## Quick Start

Download and run the script:

```bash
# Download the script
curl -O https://raw.githubusercontent.com/seanGSISG/claude-code-extension-patcher/main/patch-cc-code-remote.sh

# Make it executable
chmod +x patch-cc-code-remote.sh

# Run it
./patch-cc-code-remote.sh
```

Or use wget:
```bash
wget https://raw.githubusercontent.com/seanGSISG/claude-code-extension-patcher/main/patch-cc-code-remote.sh
chmod +x patch-cc-code-remote.sh
./patch-cc-code-remote.sh
```

## What It Does

The script modifies the Claude Code extension to:
1. Replace the "default" permission mode with "bypassPermissions"
2. Add "Bypass Permissions" to the mode cycling options
3. Update the UI to show "Bypass permissions" button text
4. Auto-approve all tool executions when in bypass mode

## Why Use This?

- **Faster Development**: Skip repetitive permission prompts during rapid iteration
- **Automation**: Allow Claude to work autonomously on tasks
- **Convenience**: Useful in trusted environments where you want Claude to move quickly

⚠️ **Warning**: Only use this in development environments you trust. This bypasses all safety prompts.

## Supported Editors

- ✅ Cursor
- ✅ VS Code
- ✅ VS Code Insiders
- ✅ Dev Containers / Codespaces

## Supported Versions

- ✅ v2.0.1
- ✅ v2.0.10
- ✅ v2.0.26+ (or until it breaks again, please open an issue)

## Usage

### Apply Patch
```bash
./patch-cc-code-remote.sh
```

### Restore Original
```bash
./patch-cc-code-remote.sh --restore
```

### Show Help
```bash
./patch-cc-code-remote.sh --help
```

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

## Files in This Directory

- `extension.js` - Copy of the original extension.js for reference
- `index.js` - Copy of the original webview/index.js for reference
- These files were used to update the patch patterns for v2.0.26

## Notes

- The script auto-detects your editor and extension directory
- Backups are created automatically before patching
- You can safely re-run the script - it detects if already patched
- Run with `--restore` to undo all changes

## Credits

Based on the original patch script by [ColeMurray](https://gist.github.com/ColeMurray).

**Enhancements in this version:**
- ✅ Auto-detection for multiple editors (Cursor, VS Code, VS Code Insiders, Dev Containers)
- ✅ Support for Claude Code v2.0.26+ with updated patterns
- ✅ Smart reload messages based on detected editor
- ✅ Improved error handling and user feedback
- ✅ Backward compatibility with v2.0.1 and v2.0.10
