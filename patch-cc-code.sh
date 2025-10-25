#!/bin/bash

# ==============================================================================
# Claude Code Extension Patcher
# ==============================================================================
#
# This script patches the Claude Code extension to add a "Bypass Permissions"
# mode that automatically approves all tool executions without prompting.
#
# Uses regex patterns instead of hardcoded variable names, making it resilient
# to minification changes across Claude Code updates.
#
# Compatible with:
#   - VS Code (Stable)
#   - VS Code Insiders
#   - Cursor
#   - VS Code Dev Containers / GitHub Codespaces
#
# Tested with Claude Code versions: v2.0.1, v2.0.10, v2.0.26, v2.0.27
# Should work with future versions unless Anthropic makes major architectural changes
#
# Created by: seanGSISG
# With assistance from: Anthropic's Claude Code (the irony is not lost on us)
#
# ==============================================================================

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# ==============================================================================
# FUNCTION: detect_extension_dir
# ==============================================================================
# Automatically detects which editor is installed and locates its extensions
# directory. Supports multiple editors and prioritizes in the order listed.
#
# Priority order:
#   1. Custom path from --extension-dir argument
#   2. CLAUDE_CODE_EXTENSION_DIR environment variable
#   3. Auto-detection based on OS and common paths
#
# Sets global variables:
#   EXTENSION_DIR - Path to the extensions directory
#   EDITOR_NAME   - Human-readable name of the detected editor
#
# Returns:
#   0 if a valid directory was found
#   1 if no extensions directory could be located
# ==============================================================================
detect_extension_dir() {
    local dirs=()

    # Check for environment variable override
    if [ -n "${CLAUDE_CODE_EXTENSION_DIR:-}" ]; then
        if [ -d "$CLAUDE_CODE_EXTENSION_DIR" ]; then
            EXTENSION_DIR="$CLAUDE_CODE_EXTENSION_DIR"
            EDITOR_NAME="Custom (from env)"
            return 0
        else
            echo "⚠️  Warning: CLAUDE_CODE_EXTENSION_DIR is set but directory doesn't exist: $CLAUDE_CODE_EXTENSION_DIR"
        fi
    fi

    # Detect OS and build appropriate search paths
    local os_type=$(uname -s 2>/dev/null || echo "Unknown")

    case "$os_type" in
        Linux|Darwin)
            # Unix-like systems (Linux, macOS, WSL)
            dirs=(
                "$HOME/.cursor/extensions:Cursor"
                "$HOME/.vscode/extensions:VS Code"
                "$HOME/.vscode-insiders/extensions:VS Code Insiders"
                "$HOME/.vscode-remote/extensions:Dev Container/Codespaces"
                "$HOME/.vscode-server/extensions:Remote SSH"
                "$HOME/.vscode-oss/extensions:VS Code OSS"
                "$HOME/.local/share/code/extensions:VS Code (XDG)"
                "$HOME/.local/share/code-insiders/extensions:VS Code Insiders (XDG)"
            )

            # macOS-specific paths
            if [ "$os_type" = "Darwin" ]; then
                dirs+=(
                    "$HOME/Library/Application Support/Code/User/extensions:VS Code (macOS)"
                    "$HOME/Library/Application Support/Code - Insiders/User/extensions:VS Code Insiders (macOS)"
                    "$HOME/Library/Application Support/Cursor/User/extensions:Cursor (macOS)"
                )
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows (Git Bash, MSYS2, Cygwin)
            local appdata="${APPDATA:-$HOME/AppData/Roaming}"
            local localappdata="${LOCALAPPDATA:-$HOME/AppData/Local}"
            dirs=(
                "$appdata/Code/User/extensions:VS Code (Windows)"
                "$appdata/Code - Insiders/User/extensions:VS Code Insiders (Windows)"
                "$appdata/Cursor/User/extensions:Cursor (Windows)"
                "$localappdata/Programs/Microsoft VS Code/extensions:VS Code System (Windows)"
            )
            ;;
        *)
            # Unknown OS - try common Unix paths as fallback
            dirs=(
                "$HOME/.cursor/extensions:Cursor"
                "$HOME/.vscode/extensions:VS Code"
                "$HOME/.vscode-insiders/extensions:VS Code Insiders"
                "$HOME/.vscode-remote/extensions:Dev Container"
            )
            ;;
    esac

    # Iterate through each potential directory
    for entry in "${dirs[@]}"; do
        # Split the entry into directory path and editor name
        IFS=':' read -r dir editor <<< "$entry"

        # Expand any variables in the path
        dir=$(eval echo "$dir")

        # Check if the directory exists
        if [ -d "$dir" ]; then
            EXTENSION_DIR="$dir"
            EDITOR_NAME="$editor"
            return 0
        fi
    done

    return 1  # No valid directory found
}

# ==============================================================================
# PARSE COMMAND-LINE ARGUMENTS
# ==============================================================================

CUSTOM_EXTENSION_DIR=""

# Handle restore mode and custom paths
while [[ $# -gt 0 ]]; do
    case "$1" in
        --extension-dir)
            if [ -z "${2:-}" ]; then
                echo "❌ Error: --extension-dir requires a path argument"
                exit 1
            fi
            CUSTOM_EXTENSION_DIR="$2"
            shift 2
            ;;
        --restore)
            # Restore mode will be handled later
            shift
            ;;
        --help|-h)
            echo "Claude Code Extension Patcher"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --extension-dir PATH   Use custom extension directory"
            echo "  --restore             Restore original extension files from backups"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  CLAUDE_CODE_EXTENSION_DIR   Override default extension directory"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 --extension-dir ~/.vscode/extensions"
            echo "  $0 --restore"
            echo "  CLAUDE_CODE_EXTENSION_DIR=~/custom/path $0"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# ==============================================================================
# MAIN SCRIPT START
# ==============================================================================

# If custom directory provided, use it directly
if [ -n "$CUSTOM_EXTENSION_DIR" ]; then
    if [ -d "$CUSTOM_EXTENSION_DIR" ]; then
        EXTENSION_DIR="$CUSTOM_EXTENSION_DIR"
        EDITOR_NAME="Custom (from --extension-dir)"
    else
        echo "❌ Error: Specified directory does not exist: $CUSTOM_EXTENSION_DIR"
        exit 1
    fi
# Otherwise, attempt auto-detection
elif ! detect_extension_dir; then
    echo "❌ Could not find VS Code/Cursor extensions directory"
    echo ""
    echo "OS detected: $(uname -s 2>/dev/null || echo 'Unknown')"
    echo ""
    echo "You can specify a custom directory using:"
    echo "  • Command line: $0 --extension-dir /path/to/extensions"
    echo "  • Environment:  CLAUDE_CODE_EXTENSION_DIR=/path/to/extensions $0"
    echo ""
    echo "Common extension directory locations:"
    echo "  Linux/WSL:"
    echo "    • ~/.vscode/extensions"
    echo "    • ~/.cursor/extensions"
    echo "    • ~/.vscode-remote/extensions (Dev Containers/Codespaces)"
    echo "    • ~/.local/share/code/extensions"
    echo "  macOS:"
    echo "    • ~/Library/Application Support/Code/User/extensions"
    echo "    • ~/Library/Application Support/Cursor/User/extensions"
    echo "  Windows (Git Bash/MSYS2):"
    echo "    • \$APPDATA/Code/User/extensions"
    echo "    • \$APPDATA/Cursor/User/extensions"
    exit 1
fi

# Display which editor/directory we're using
echo "📍 Using: $EXTENSION_DIR ($EDITOR_NAME)"

# ==============================================================================
# LOCATE CLAUDE CODE EXTENSION
# ==============================================================================
# The extension directory name follows the pattern: anthropic.claude-code-VERSION-PLATFORM
# Example: anthropic.claude-code-2.0.27-linux-x64
#
# We use 'find' to locate it, then 'sort -V' for version sorting, and 'tail -n 1'
# to get the latest version if multiple are installed.
# ==============================================================================

extension_dir=$(find "$EXTENSION_DIR" -maxdepth 1 -type d -name "anthropic.claude-code-*" 2>/dev/null | sort -V | tail -n 1)

if [ -z "$extension_dir" ]; then
    echo "❌ Claude Code extension not found in $EXTENSION_DIR"
    echo ""
    echo "Please install the Claude Code extension first."
    exit 1
fi

echo "📦 Found extension: $(basename "$extension_dir")"

# Define paths to the files we need to patch
extension_js="$extension_dir/extension.js"
webview_js="$extension_dir/webview/index.js"

# Verify both required files exist
if [ ! -f "$extension_js" ]; then
    echo "❌ extension.js not found at: $extension_js"
    exit 1
fi

if [ ! -f "$webview_js" ]; then
    echo "❌ webview/index.js not found at: $webview_js"
    exit 1
fi

# ==============================================================================
# RESTORE FUNCTIONALITY
# ==============================================================================
# If the --restore flag is provided, restore the original files from backups
# and exit. This allows users to undo the patches.
# ==============================================================================

if [ "${1:-}" = "--restore" ]; then
    echo "🔄 Restoring original files..."
    echo ""

    # Restore extension.js if backup exists
    if [ -f "$extension_js.backup-original" ]; then
        cp "$extension_js.backup-original" "$extension_js"
        echo "✅ Restored extension.js"
    else
        echo "⚠️  No backup found for extension.js"
    fi

    # Restore webview/index.js if backup exists
    if [ -f "$webview_js.backup-original" ]; then
        cp "$webview_js.backup-original" "$webview_js"
        echo "✅ Restored webview/index.js"
    else
        echo "⚠️  No backup found for webview/index.js"
    fi

    echo ""
    echo "🔄 Please reload the window to apply changes"
    echo "   (Cmd/Ctrl+Shift+P → 'Developer: Reload Window')"
    exit 0
fi

# ==============================================================================
# CREATE BACKUPS
# ==============================================================================
# Before making any changes, create backup copies of the original files.
# We only create backups if they don't already exist, so the original
# unmodified files are always preserved.
# ==============================================================================

if [ ! -f "$extension_js.backup-original" ]; then
    echo "💾 Creating backup of extension.js"
    cp "$extension_js" "$extension_js.backup-original"
else
    echo "ℹ️  Using existing backup of extension.js"
fi

if [ ! -f "$webview_js.backup-original" ]; then
    echo "💾 Creating backup of webview/index.js"
    cp "$webview_js" "$webview_js.backup-original"
else
    echo "ℹ️  Using existing backup of webview/index.js"
fi

echo ""
echo "🔧 Applying patches..."
echo ""

# ==============================================================================
# PATCH 1: extension.js - Remove default permissionMode assignment
# ==============================================================================
#
# WHAT THIS DOES:
# Changes the server-side permission mode from "default" to undefined, which
# allows the client-side mode to take precedence. This is necessary for the
# bypass mode to actually work.
#
# PATTERN EXPLANATION:
# The code uses a minified variable to store the permission mode. The variable
# name changes with each build (o, L, T, O, etc.) due to JavaScript minification.
#
# We use a regex pattern to match ANY single letter:
#   permissionMode:[LETTER]="default"  →  permissionMode:[LETTER]
#
# The pattern captures the variable letter using ([a-zA-Z]) and preserves it
# in the output using $2, effectively just removing the ="default" part.
#
# VERSION HISTORY:
#   v2.0.1:  permissionMode:o===void 0?"default":o
#   v2.0.10: permissionMode:L="default"
#   v2.0.26: permissionMode:T="default"
#   v2.0.27: permissionMode:O="default"
#   Future:  permissionMode:[?]="default"  ← This regex handles any letter
#
# ==============================================================================

echo "  Applying PATCH 1: extension.js (remove default permissionMode)"

# Use Perl for reliable cross-platform regex with capture groups
# -i.bak creates a backup with .bak extension
# -pe means "process and print each line"
# Capture group 1: (permissionMode:) - the prefix we want to keep
# Capture group 2: ([a-zA-Z]) - the variable letter we want to preserve
# Replacement: $1$2 - puts them back together without ="default"
if perl -i.bak -pe 's/(permissionMode:)([a-zA-Z])="default"/$1$2/g' "$extension_js" 2>/dev/null; then
    # Verify the patch worked by checking if we now have permissionMode:[letter] without ="default"
    if grep -q 'permissionMode:[a-zA-Z]$\|permissionMode:[a-zA-Z],\|permissionMode:[a-zA-Z]}' "$extension_js" 2>/dev/null; then
        echo "  ✓ Removed default assignment (variable assignment pattern)"
    else
        # Try the older ternary operator pattern as a fallback
        # This pattern: permissionMode:o===void 0?"default":o  →  permissionMode:o
        perl -i.bak -pe 's/(permissionMode:)([a-zA-Z])===void 0\?"default":\2/$1$2/g' "$extension_js"
        if grep -q 'permissionMode:[a-zA-Z]$\|permissionMode:[a-zA-Z],\|permissionMode:[a-zA-Z]}' "$extension_js" 2>/dev/null; then
            echo "  ✓ Removed default assignment (ternary operator pattern)"
        else
            echo "  ⚠️  Could not verify PATCH 1 - extension.js may not be patched correctly"
        fi
    fi
else
    echo "  ❌ PATCH 1 FAILED - perl not available"
    echo "     Please install perl to use this script"
    exit 1
fi

# ==============================================================================
# PATCH 2: webview/index.js - Replace "default" in permission modes array
# ==============================================================================
#
# WHAT THIS DOES:
# Changes the first element of the available permission modes array from
# "default" to "bypassPermissions". This makes bypass mode the first option
# in the UI dropdown and ensures it's a valid mode.
#
# PATTERN EXPLANATION:
# This pattern has been stable across all versions - the array structure and
# string literals don't change with minification:
#
#   :["default","acceptEdits","plan"]  →  :["bypassPermissions","acceptEdits","plan"]
#
# This is a simple string replacement with no regex needed.
#
# VERSION HISTORY:
#   All versions: Uses the same pattern
#
# ==============================================================================

echo "  Applying PATCH 2: webview/index.js (update modes array)"

# Simple string replacement - this pattern doesn't change across versions
perl -i.bak2 -pe 's/:\["default","acceptEdits","plan"\]/:\["bypassPermissions","acceptEdits","plan"\]/g' "$webview_js"

# Verify the change was applied
if grep -q ':\["bypassPermissions","acceptEdits","plan"\]' "$webview_js" 2>/dev/null; then
    echo "  ✓ Updated permission modes array"
else
    echo "  ⚠️  Could not verify PATCH 2 - modes array may not be updated"
fi

# ==============================================================================
# PATCH 3: webview/index.js - Session initialization
# ==============================================================================
#
# WHAT THIS DOES:
# Sets the default permission mode for new sessions to "bypassPermissions"
# instead of "default". This ensures that when the extension initializes,
# it starts in bypass mode rather than ask-before-edit mode.
#
# PATTERN EXPLANATION:
# The session initialization uses a helper function to create an observable.
# The function name changes with minification, but it's always two lowercase
# letters:
#
#   permissionMode=[xx]("default")  →  permissionMode=[xx]("bypassPermissions")
#
# Where [xx] can be: kn, ln, cn, or any other two-letter combination
#
# The regex [a-z]{2} matches exactly two lowercase letters, and we capture
# it to preserve the function name in the output.
#
# VERSION HISTORY:
#   v2.0.1-10: permissionMode=kn("default")
#   v2.0.26:   permissionMode=ln("default")
#   v2.0.27:   permissionMode=cn("default")
#   Future:    permissionMode=[??]("default")  ← This regex handles any combo
#
# ==============================================================================

echo "  Applying PATCH 3: webview/index.js (session initialization)"

# Capture group 1: (permissionMode=) - the prefix
# Capture group 2: ([a-z]{2}) - exactly two lowercase letters (the function name)
# Replacement: $1$2("bypassPermissions") - preserves the function name, changes the argument
perl -i.bak3 -pe 's/(permissionMode=)([a-z]{2})\("default"\)/$1$2("bypassPermissions")/g' "$webview_js"

# Verify the change was applied
if grep -q 'permissionMode=[a-z][a-z]("bypassPermissions")' "$webview_js" 2>/dev/null; then
    echo "  ✓ Updated session initialization to bypassPermissions"
else
    echo "  ⚠️  Could not verify PATCH 3 - session init may not be updated"
fi

# ==============================================================================
# PATCH 4: webview/index.js - UI button text and tooltip
# ==============================================================================
#
# WHAT THIS DOES:
# Updates the UI footer button that displays the current permission mode.
# This changes three things:
#   1. The case label from "default" to "bypassPermissions"
#   2. The tooltip text (hover text on the button)
#   3. The button label from "Ask before edits" to "Bypass permissions"
#
# PATTERN EXPLANATION:
# This patch is split into multiple steps because the variable names change
# (Bo, Vo, zr, etc.) but the strings stay the same. Rather than trying to
# match variable names, we match the stable string literals:
#
# Step 1: Change the switch case label
#   case"default":default:return  →  case"bypassPermissions":default:return
#
# Step 2: Change the tooltip text
#   title:"Claude will ask before each edit..."  →  title:"Claude will skip all permission prompts..."
#
# Step 3: Change the visible button text
#   "Ask before edits"  →  "Bypass permissions"
#
# This multi-step approach is more resilient than trying to match the entire
# React.createElement() or JSX pattern with changing variable names.
#
# VERSION HISTORY:
#   v2.0.1-10: Uses zr.jsxs() and zr.jsx() for JSX transformation
#   v2.0.26:   Uses Vo.default.createElement() with Wa, Iye variables
#   v2.0.27:   Uses Bo.default.createElement() with Ba, C1e variables
#   All:       String literals remain the same across versions
#
# ==============================================================================

echo "  Applying PATCH 4: webview/index.js (UI button text and tooltip)"

# Step 1: Change the case label from "default" to "bypassPermissions"
# This affects the switch statement that determines which button to render
perl -i.bak4 -pe 's/case"default":default:return/case"bypassPermissions":default:return/g' "$webview_js"

# Step 2: Change the tooltip text
# This is what users see when hovering over the mode button
perl -i.bak4 -pe 's/title:"Claude will ask before each edit\. Click, or press Shift\+Tab, to switch modes\."/title:"Claude will skip all permission prompts. Click, or press Shift+Tab, to switch modes."/g' "$webview_js"

# Step 3: Change the button text
# This changes both JSX and createElement patterns since we're matching the string
perl -i.bak4 -pe 's/"Ask before edits"/"Bypass permissions"/g' "$webview_js"
# Also handle the JSX children variant
perl -i.bak4 -pe 's/children:"Ask before edits"/children:"Bypass permissions"/g' "$webview_js"

# Verify all changes were applied
if grep -q 'case"bypassPermissions":default:return' "$webview_js" 2>/dev/null && \
   grep -q '"Bypass permissions"' "$webview_js" 2>/dev/null && \
   grep -q 'Claude will skip all permission prompts' "$webview_js" 2>/dev/null; then
    echo "  ✓ Updated UI button case, text, and tooltip"
else
    echo "  ⚠️  Could not verify PATCH 4 - UI may not be fully updated"
fi

# ==============================================================================
# CLEANUP
# ==============================================================================
# Remove all temporary .bak files created during the patching process
# We use || true to prevent the script from exiting if no .bak files exist
# ==============================================================================

rm -f "$extension_js.bak" "$webview_js.bak"* 2>/dev/null || true

# ==============================================================================
# SUCCESS MESSAGE
# ==============================================================================

echo ""
echo "✅ Patching complete!"
echo ""
echo "The following changes were applied:"
echo "  • Permission mode changed to 'bypassPermissions'"
echo "  • UI updated to show 'Bypass permissions' instead of 'Ask before edits'"
echo "  • Session defaults to bypass mode on startup"
echo ""
echo "🔄 Next steps:"
echo "  1. Reload the VS Code/Cursor window:"
echo "     • Press Cmd+Shift+P (Mac) or Ctrl+Shift+P (Windows/Linux)"
echo "     • Type 'Developer: Reload Window'"
echo "     • Press Enter"
echo ""
echo "  2. After reload, the footer button should show 'Bypass permissions'"
echo ""
echo "  3. To restore original behavior:"
echo "     bash $0 --restore"
echo ""
echo "📝 Note: Claude will now automatically approve all tool executions"
echo "   without prompting. Use with caution in production environments."
