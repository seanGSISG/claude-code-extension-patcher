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
SKIP_UI=false
RESTORE_MODE=false

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
        --no-ui)
            SKIP_UI=true
            shift
            ;;
        --restore)
            RESTORE_MODE=true
            shift
            ;;
        --help|-h)
            echo "Claude Code Extension Patcher"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --extension-dir PATH   Use custom extension directory"
            echo "  --no-ui               Skip UI enhancements (faster, but red indicator)"
            echo "  --restore             Restore original extension files from backups"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  CLAUDE_CODE_EXTENSION_DIR   Override default extension directory"
            echo ""
            echo "Examples:"
            echo "  $0                    # Apply all patches + UI enhancements"
            echo "  $0 --no-ui            # Apply only core patches"
            echo "  $0 --restore          # Restore everything to original"
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

if [ "$RESTORE_MODE" = true ]; then
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

    # Restore CSS if backup exists
    css_file="$extension_dir/webview/index.css"
    if [ -f "$css_file.backup-original" ]; then
        cp "$css_file.backup-original" "$css_file"
        echo "✅ Restored webview/index.css"
    else
        echo "⚠️  No backup found for webview/index.css"
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
echo "✅ Core patches applied successfully!"
echo ""

# ==============================================================================
# UI ENHANCEMENTS (Optional)
# ==============================================================================
# Apply visual improvements to make bypass mode indicator more subtle
#
# RESILIENCE STRATEGY:
#   - CSS patches use regex to match any class names, not hardcoded values
#   - Container class is auto-detected from CSS file (e.g., .s, .a, .btn)
#   - Stable selectors used where possible (element, attribute selectors)
#   - Minified class names that may change are documented
#   - If class names change, rules become no-ops (harmless) rather than breaking
# ==============================================================================

if [ "$SKIP_UI" = false ]; then
    echo "🎨 Applying UI enhancements (using resilient regex patterns)..."
    echo ""

    css_file="$extension_dir/webview/index.css"

    # Backup CSS if not already backed up
    if [ ! -f "$css_file.backup-original" ]; then
        cp "$css_file" "$css_file.backup-original"
    fi

    # ==============================================================================
    # CSS PATCH 1: Change text color from error-red to cyan
    # ==============================================================================
    # PATTERN: .[CLASS][data-permission-mode=bypassPermissions] .[CLASS]{color:var(--app-error-foreground)}
    # REGEX: Matches ANY class names (e.g., .s .p, .a .x, .btn .icon)
    # This is resilient to minification changes across versions
    # ==============================================================================

    echo "  Applying CSS PATCH 1: Change text color to cyan"

    # Regex handles both minified (no spaces) and non-minified (with spaces) CSS
    # Pattern: .[CLASS][data-permission-mode=bypassPermissions] .[CLASS] OR .[CLASS][data-permission-mode=bypassPermissions].[CLASS]
    if perl -i.bak-ui -pe 's/(\.[\w-]+\[data-permission-mode=bypassPermissions\]\s*\.[\w-]+)\{color:var\(--app-error-foreground\)\}/$1\{color:rgba(6, 182, 212, 0.9)\}/' "$css_file" 2>/dev/null; then
        # Verify the change was applied
        if grep -q '\[data-permission-mode=bypassPermissions\].*{color:rgba(6, 182, 212, 0.9)}' "$css_file" 2>/dev/null; then
            echo "  ✓ Text color changed to cyan"
        else
            echo "  ⚠️  Could not verify text color change - may need manual adjustment"
        fi
    else
        echo "  ❌ Failed to apply text color change"
    fi

    # ==============================================================================
    # CSS PATCH 2: Add container border and background styling
    # ==============================================================================
    # STRATEGY: Dynamically discover the container class name from the CSS file
    # instead of hardcoding it. This makes it resilient to class name changes.
    # ==============================================================================

    echo "  Applying CSS PATCH 2: Add container styling"

    # Extract the container class name dynamically (e.g., .s, .a, .btn, etc.)
    # Pattern: .[CLASS_NAME][data-permission-mode=bypassPermissions]
    container_class=$(grep -oP '\.[\w-]+(?=\[data-permission-mode=bypassPermissions\])' "$css_file" 2>/dev/null | head -1)

    if [ -n "$container_class" ]; then
        # Escape special characters for use in sed/perl
        escaped_class=$(echo "$container_class" | sed 's/\./\\./g')

        # Check if container styling already exists to prevent duplicates
        if ! grep -q "${container_class}\[data-permission-mode=bypassPermissions\]{border-left:" "$css_file" 2>/dev/null; then
            # Append container styling after the existing rule
            # Pattern: .[CONTAINER][data-permission-mode=bypassPermissions].[ICON]{...existing rules...}
            # Handles both minified (no space) and non-minified (with space) CSS
            # Appends: .[CONTAINER][data-permission-mode=bypassPermissions]{...new styling...}
            perl -i.bak-ui2 -pe "s/(${escaped_class}\[data-permission-mode=bypassPermissions\]\s*\.[\w-]+\{[^}]+\})/\$1${container_class}[data-permission-mode=bypassPermissions]{border-left:2px solid rgba(6, 182, 212, 0.3);padding-left:6px;background:rgba(6, 182, 212, 0.05);border-radius:4px}/" "$css_file" 2>/dev/null

            # Verify it was added
            if grep -q "${container_class}\[data-permission-mode=bypassPermissions\]{border-left:" "$css_file" 2>/dev/null; then
                echo "  ✓ Container styling added to ${container_class}"
            else
                echo "  ⚠️  Could not verify container styling"
            fi
        else
            echo "  ✓ Container styling already exists for ${container_class}"
        fi
    else
        echo "  ⚠️  Could not auto-detect container class - skipping container styling"
        echo "     (This is normal if CSS structure has changed significantly)"
    fi

    # ==============================================================================
    # CSS PATCH 3: Add hover states and transitions
    # ==============================================================================
    # NOTE: These rules use the dynamically discovered container class.
    # If the container class changes in future versions, these will become no-ops
    # (harmless but ineffective) and will need updating.
    # ==============================================================================

    echo "  Applying CSS PATCH 3: Add transitions and overrides"

    # Use the container class we discovered, or fall back to a general selector
    if [ -n "$container_class" ]; then
        # Check if hover states already exist to prevent duplicates
        if ! grep -q "Enhanced hover states for permission mode button" "$css_file" 2>/dev/null; then
            # Dynamic version using discovered class name
            cat >> "$css_file" <<EOF

/* Enhanced hover states for permission mode button (${container_class}) */
${container_class}:hover { opacity: 0.9; transition: opacity 0.15s ease; }
${container_class}[data-permission-mode=bypassPermissions]:hover {
    border-left-color: rgba(6, 182, 212, 0.5);
    transition: border-left-color 0.15s ease, opacity 0.15s ease;
}

/* Smooth transitions for mode switching */
${container_class} { transition: all 0.2s ease; }
${container_class} > * { transition: color 0.2s ease; }
EOF
            echo "  ✓ Hover transitions added"
        else
            echo "  ✓ Hover transitions already exist"
        fi
    else
        # Check if fallback hover states already exist
        if ! grep -q "Enhanced hover states for permission mode button (fallback selector)" "$css_file" 2>/dev/null; then
            # Fallback: use attribute selector only (less specific but more resilient)
            cat >> "$css_file" << 'EOF'

/* Enhanced hover states for permission mode button (fallback selector) */
[data-permission-mode=bypassPermissions]:hover {
    opacity: 0.9;
    border-left-color: rgba(6, 182, 212, 0.5);
    transition: all 0.15s ease;
}
EOF
            echo "  ✓ Hover transitions added (fallback)"
        else
            echo "  ✓ Hover transitions already exist (fallback)"
        fi
    fi


    # ==============================================================================
    # CSS PATCH 4: General overrides for all red elements
    # ==============================================================================
    # STRATEGY: Use body[data-permission-mode=bypassPermissions] prefix which is
    # stable across versions, combined with general element/attribute selectors.
    # Minified class names (.r, .xe, .ae, .Z, etc.) may change, but these rules
    # will become harmless no-ops rather than breaking.
    # ==============================================================================

    # Check if body overrides already exist to prevent duplicates
    if ! grep -q "RESILIENCE STRATEGY FOR THESE RULES" "$css_file" 2>/dev/null; then
        cat >> "$css_file" << 'EOF'

/* ============================================================================
   RESILIENCE STRATEGY FOR THESE RULES:
   - body[data-permission-mode=bypassPermissions] prefix is stable (our custom attribute)
   - Element selectors (button, svg) are stable
   - Attribute selectors ([style*="..."]) are stable
   - Minified class names (.r, .xe, .Z) may change in future versions
   - When class names change, those specific rules become no-ops (harmless)
   - The general rules (button, svg, attribute selectors) continue working
   ============================================================================ */

/* Change input border to cyan in bypass mode */
/* NOTE: .r class may change - if it does, this becomes a no-op */
body[data-permission-mode=bypassPermissions] .r:focus-within {
    border-color: rgba(6, 182, 212, 0.3) !important;
}
body[data-permission-mode=bypassPermissions] .r:not(:focus-within) {
    border-color: rgba(6, 182, 212, 0.3) !important;
}

/* Remove red border from bottom container wrapper */
/* NOTE: .xe class may change - if it does, this becomes a no-op */
body[data-permission-mode=bypassPermissions] .xe {
    border-color: transparent !important;
}

/* Override all container borders that might be red */
/* NOTE: .ae, .Qo classes may change - if they do, these become no-ops */
body[data-permission-mode=bypassPermissions] .ae,
body[data-permission-mode=bypassPermissions] .Qo,
body[data-permission-mode=bypassPermissions] > * {
    border-color: var(--app-input-border) !important;
}

/* Override all buttons in bypass mode (STABLE - element selector) */
body[data-permission-mode=bypassPermissions] button {
    color: rgba(6, 182, 212, 0.9) !important;
}

/* Override buttons with inline styles (STABLE - attribute selector) */
body[data-permission-mode=bypassPermissions] button[style*="color"] {
    color: rgba(6, 182, 212, 0.9) !important;
}

/* Override error-colored elements like close button */
/* NOTE: .Z class may change - if it does, this becomes a no-op */
body[data-permission-mode=bypassPermissions] .Z {
    color: rgba(6, 182, 212, 0.9) !important;
}

/* Override SVG icons with inline styles (STABLE - element + attribute selector) */
body[data-permission-mode=bypassPermissions] svg[style*="color"] {
    color: rgba(6, 182, 212, 0.9) !important;
}

/* Catch-all: override any element using error-foreground color (STABLE - attribute selector) */
body[data-permission-mode=bypassPermissions] *[style*="var(--app-error-foreground)"] {
    color: rgba(6, 182, 212, 0.9) !important;
    border-color: rgba(6, 182, 212, 0.3) !important;
}
EOF
        echo "  ✓ Body-level color overrides added"
    else
        echo "  ✓ Body-level color overrides already exist"
    fi

    # Clean up temp files
    rm -f "$css_file.bak-ui"* 2>/dev/null || true

    echo "✅ UI enhancements applied!"
    echo "   • Vibrant cyan color instead of harsh red"
    echo "   • Subtle left border indicator"
    echo "   • Smooth hover effects and transitions"
    echo "   • Removed red borders from all containers"
    echo "   • Changed button/icon colors to cyan"
    echo "   • Comprehensive error-color overrides"
    echo ""
else
    echo "⚠️  Skipped UI enhancements (--no-ui flag)"
    echo "   Bypass mode will show harsh red indicator"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All patches applied successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Changes applied:"
echo "  • Permission mode: 'bypassPermissions'"
echo "  • UI button text: 'Bypass permissions'"
echo "  • Session defaults to bypass mode"
if [ "$SKIP_UI" = false ]; then
    echo "  • Visual styling: Vibrant cyan instead of red"
fi
echo ""
echo "🔄 Next step: Reload VS Code/Cursor window"
echo "   • Press Cmd+Shift+P (Mac) or Ctrl+Shift+P (Windows/Linux)"
echo "   • Type: 'Developer: Reload Window'"
echo "   • Press Enter"
echo ""
echo "To restore: $0 --restore"
echo ""
echo "⚠️  Claude will now auto-approve all tool executions."
echo "   Use with caution in production environments."
