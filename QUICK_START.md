# Quick Start Guide

## 🚀 Installation

### Step 1: Apply Base Patches

```bash
chmod +x patch-cc-code.sh
./patch-cc-code.sh
```

This patches Claude Code to enable "Bypass Permissions" mode.

### Step 2: Apply UI Enhancements (Optional but Recommended)

```bash
chmod +x patch-cc-code-ui-enhanced.sh
./patch-cc-code-ui-enhanced.sh
```

This makes the bypass mode indicator look professional instead of alarming.

### Step 3: Reload VS Code

- Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
- Type: `Developer: Reload Window`
- Press Enter

## ✅ Success!

You should now see:

**Footer Button**: `|[🟠] Bypass permissions`

Instead of: `[🔴] Bypass permissions`

The icon will be soft amber with a subtle left border and gentle background tint.

## 🎨 What Changed?

### Visual Changes (UI Enhanced)

| Feature | Before | After |
|---------|--------|-------|
| **Icon Color** | Harsh red (error color) | Soft amber (90% opacity) |
| **Border** | None | Subtle 2px left border (30% opacity) |
| **Background** | None | Gentle tint (5% opacity) |
| **Hover Effect** | None | Smooth opacity + border brighten |
| **Transitions** | Instant | Smooth 200ms animations |
| **Overall Feel** | Alarming, looks like error | Professional, brand-aligned |

### Functional Changes (Base Patch)

- Bypass mode available as first option
- Automatically approves all tool executions
- No permission prompts in bypass mode
- Can cycle modes with `Shift+Tab`

## 🔄 Mode Cycling

Press `Shift+Tab` or click the footer button to cycle through:

1. **Bypass permissions** (auto-approve all) 🟠
2. **Edit automatically** (auto-approve edits) 
3. **Plan mode** (review before execution) 🔵

## 🛠️ Restore Options

### Restore Everything (Remove all patches)
```bash
./patch-cc-code.sh --restore
```

### Restore Just UI (Keep bypass mode, revert to red icon)
```bash
./patch-cc-code-ui-enhanced.sh --restore
```

## 📚 Documentation

- **[README.md](README.md)** - Full documentation
- **[UI_ENHANCEMENTS.md](UI_ENHANCEMENTS.md)** - UI design decisions
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Technical details
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[UPGRADE_NOTES.md](UPGRADE_NOTES.md)** - Technical deep-dive

## ⚠️ Important Notes

- **Extension Updates**: Re-run both scripts after Claude Code updates
- **Security**: Only use bypass mode in trusted development environments
- **Backup**: Original files are automatically backed up
- **Compatibility**: Works with v2.0.1, v2.0.10, v2.0.26, v2.0.27+

## 🎯 Supported Editors

Auto-detects:
- VS Code (`~/.vscode/extensions`)
- Cursor (`~/.cursor/extensions`)
- VS Code Insiders (`~/.vscode-insiders/extensions`)
- Dev Containers (`~/.vscode-remote/extensions`)

## 💡 Tips

1. **First Time**: Run base patch first, then UI enhancements
2. **Updates**: If Claude Code updates, re-run both scripts
3. **Customization**: Edit `webview/index.css` for custom colors
4. **Testing**: Try the restore commands to verify backups work

## 🐛 Troubleshooting

### Changes don't appear
- Make sure you reloaded the window
- Check the extension version is supported
- Verify patches applied without errors

### Extension breaks on update
- Claude Code updates overwrite patches
- Simply re-run the scripts
- Your backups are safe

### Want to adjust colors
1. Find: `~/.vscode-remote/extensions/anthropic.claude-code-*/webview/index.css`
2. Search for: `rgba(217, 119, 87`
3. Adjust opacity values to taste

## 🤝 Credits

**Created by**: seanGSISG  
**With assistance from**: Anthropic's Claude Code

The irony of using Claude to patch Claude is not lost on us. 😄

---

**Enjoy your enhanced Claude Code experience!** 🎨✨
