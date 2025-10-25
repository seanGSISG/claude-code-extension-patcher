# Cross-Platform Compatibility Guide

The Claude Code Extension Patcher now supports **Linux, macOS, and Windows** environments with automatic detection and custom path support.

## Supported Platforms

### Linux & WSL
Both scripts automatically detect extensions in:
- `~/.vscode/extensions` (VS Code)
- `~/.cursor/extensions` (Cursor)
- `~/.vscode-insiders/extensions` (VS Code Insiders)
- `~/.vscode-remote/extensions` (Dev Containers/Codespaces)
- `~/.vscode-server/extensions` (Remote SSH)
- `~/.vscode-oss/extensions` (VS Code OSS)
- `~/.local/share/code/extensions` (XDG standard)

### macOS
Automatically detects extensions in:
- `~/Library/Application Support/Code/User/extensions` (VS Code)
- `~/Library/Application Support/Cursor/User/extensions` (Cursor)
- `~/Library/Application Support/Code - Insiders/User/extensions` (VS Code Insiders)

### Windows (Git Bash, MSYS2, Cygwin)
Automatically detects extensions in:
- `$APPDATA/Code/User/extensions` (VS Code)
- `$APPDATA/Cursor/User/extensions` (Cursor)
- `$APPDATA/Code - Insiders/User/extensions` (VS Code Insiders)

**Note**: Windows support requires a Unix-like shell environment (Git Bash, MSYS2, or Cygwin) since the scripts are written in Bash.

## Custom Installation Paths

If your extension is installed in a non-standard location, you have two options:

### Option 1: Command-Line Argument

For the main patcher (searches within the provided directory):
```bash
./patch-cc-code.sh --extension-dir /path/to/extensions
```

For the UI enhancement script (provide full extension path):
```bash
./patch-cc-code-ui-enhanced.sh --extension-dir /path/to/anthropic.claude-code-2.0.27-linux-x64
```

### Option 2: Environment Variable

Set the environment variable before running:
```bash
# For one-time use
CLAUDE_CODE_EXTENSION_DIR=/path/to/extensions ./patch-cc-code.sh

# Or export for the session
export CLAUDE_CODE_EXTENSION_DIR=/path/to/extensions
./patch-cc-code.sh
./patch-cc-code-ui-enhanced.sh
```

## Priority Order

The scripts check for extension directories in this priority:

1. **Command-line argument** (`--extension-dir`)
2. **Environment variable** (`CLAUDE_CODE_EXTENSION_DIR`)
3. **Auto-detection** (based on OS)

## Help and Troubleshooting

### View all options
```bash
./patch-cc-code.sh --help
./patch-cc-code-ui-enhanced.sh --help
```

### Common Issues

**Script can't find extension directory:**
- Check which OS you're on: `uname -s`
- Manually locate your extension: Look for folders matching `anthropic.claude-code-*`
- Use custom path: `./patch-cc-code.sh --extension-dir /full/path/to/extensions`

**Permission errors:**
- Ensure the script is executable: `chmod +x patch-cc-code.sh`
- Check file permissions on extension directory

**Windows-specific:**
- Ensure you're using Git Bash, MSYS2, or Cygwin (not CMD or PowerShell)
- Perl must be available in your environment
- Path separators should use forward slashes (/) not backslashes (\)

## Examples

### Standard Usage (Auto-Detection)
```bash
# Linux/macOS/Windows (Git Bash)
./patch-cc-code.sh
./patch-cc-code-ui-enhanced.sh
```

### Custom Directory (Portable VS Code)
```bash
# If you have a portable VS Code installation
./patch-cc-code.sh --extension-dir /opt/vscode-portable/extensions
```

### Multiple Editors
```bash
# Patch Cursor
CLAUDE_CODE_EXTENSION_DIR=~/.cursor/extensions ./patch-cc-code.sh

# Patch VS Code
CLAUDE_CODE_EXTENSION_DIR=~/.vscode/extensions ./patch-cc-code.sh

# Patch Remote SSH instance
CLAUDE_CODE_EXTENSION_DIR=~/.vscode-server/extensions ./patch-cc-code.sh
```

### Windows (Git Bash)
```bash
# Standard installation
./patch-cc-code.sh

# Custom location (if needed)
./patch-cc-code.sh --extension-dir "$APPDATA/Code/User/extensions"
```

## Testing Your Environment

Run the script with `--help` to verify it works:
```bash
./patch-cc-code.sh --help
```

If you see the help message, your environment is properly configured!

## Platform-Specific Notes

### Linux/WSL
- Perl is usually pre-installed
- All paths work out of the box
- Dev Container and Codespaces fully supported

### macOS
- Perl is pre-installed
- Paths with spaces (like "Application Support") are properly handled
- Both Intel and Apple Silicon supported

### Windows
- **Requires Git Bash, MSYS2, or Cygwin**
- PowerShell and CMD are not supported (scripts are Bash, not batch files)
- Perl comes with Git Bash installation
- Environment variables like `$APPDATA` work in Git Bash

## Contributing

If you have a unique environment or installation path that isn't detected, please:
1. Open an issue with your OS and extension path
2. Submit a PR with the additional search path
3. Share your `uname -s` output and extension location
