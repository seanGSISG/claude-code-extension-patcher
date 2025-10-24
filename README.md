# Claude Code Extension Patcher

This script patches the Claude Code extension to add a "Bypass Permissions" mode that automatically approves all tool executions without prompting.

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
- ✅ v2.0.26+

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
