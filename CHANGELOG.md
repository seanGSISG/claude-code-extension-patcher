# Changelog

## v2.1 - 2025-01-25

### New: Cross-Platform Support! 🌍

Both scripts now support **Linux, macOS, and Windows** environments with automatic detection.

#### Platform Support
- ✅ **Linux & WSL**: All VS Code variants, Cursor, Remote SSH, OSS builds
- ✅ **macOS**: Native paths with proper Application Support detection
- ✅ **Windows**: Git Bash, MSYS2, Cygwin environments

#### Custom Installation Paths
- Command-line argument: `--extension-dir /custom/path`
- Environment variable: `CLAUDE_CODE_EXTENSION_DIR=/custom/path`
- Helpful error messages with platform-specific guidance

#### Auto-Detection
The scripts automatically search these locations based on your OS:

**Linux/WSL**: `~/.vscode/extensions`, `~/.cursor/extensions`, `~/.vscode-remote/extensions`, `~/.vscode-server/extensions`, `~/.vscode-oss/extensions`, `~/.local/share/code/extensions`

**macOS**: `~/Library/Application Support/Code/User/extensions`, `~/Library/Application Support/Cursor/User/extensions`

**Windows**: `$APPDATA/Code/User/extensions`, `$APPDATA/Cursor/User/extensions`

### New: UI Enhancements! 🎨

**New Script**: `patch-cc-code-ui-enhanced.sh`

Adds optional visual improvements to make bypass mode less alarming and more professional.

#### All Approved Enhancements
- ✅ **Subtle Bypass Mode Color**: Soft amber (90% opacity) instead of harsh red
- ✅ **Subtle Left Border Indicator**: 2px amber border at 30% opacity
- ✅ **Subtle Background Tint**: 5% opacity amber background
- ✅ **Enhanced Hover States**: Smooth transitions on interaction
- ✅ **Animated Mode Transitions**: 200ms smooth color changes

#### Benefits
- Aligns with Claude's brand orange
- Reduces eye strain during long sessions
- Less alarming, more professional
- Better visual hierarchy and feedback

#### Documentation
- Added `UI_ENHANCEMENTS.md` - Comprehensive UI analysis
- Color psychology explanation
- Before/after comparisons
- Manual modification instructions

#### Usage
```bash
# Apply main patches first
./patch-cc-code.sh

# Then apply UI enhancements (optional)
./patch-cc-code-ui-enhanced.sh

# Restore UI to default
./patch-cc-code-ui-enhanced.sh --restore

# Custom paths
./patch-cc-code.sh --extension-dir /path/to/extensions
CLAUDE_CODE_EXTENSION_DIR=/path ./patch-cc-code-ui-enhanced.sh
```

---

## v2.0 - 2025-01-25

### Breaking Changes
- **Renamed script**: `patch-cc-code-remote-v2.sh` → `patch-cc-code.sh`
- Old version-specific script moved to `.archive/patch-cc-code-remote.sh`

### New Features
- Future-proof regex-based pattern matching
- Works across Claude Code versions automatically
- 400+ lines of comprehensive documentation
- No manual updates needed for routine version changes

### Credits Update
- Updated credits to reflect:
  - **Created by**: seanGSISG
  - **With assistance from**: Anthropic's Claude Code (the irony is not lost on us)
- Removed original ColeMurray credit per author request

### Documentation
- Updated README.md with simplified structure
- Enhanced UPGRADE_NOTES.md with technical details
- Added inline comments explaining each patch in detail

### Tested With
- ✅ Claude Code v2.0.1
- ✅ Claude Code v2.0.10
- ✅ Claude Code v2.0.26
- ✅ Claude Code v2.0.27

---

## v1.0 - Previous Versions

### Features
- Version-specific pattern matching
- Support for v2.0.1, v2.0.10, v2.0.26, v2.0.27
- Multi-editor support (Cursor, VS Code, Insiders, Dev Containers)
- Automatic backup and restore functionality

### Archived
- The version-specific script is now in `.archive/` for reference
- No longer actively maintained
- Kept for educational purposes and version history
