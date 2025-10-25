#!/bin/bash

# ==============================================================================
# Claude Code UI Enhancements (Add-on Script)
# ==============================================================================
#
# This script applies ALL APPROVED UI improvements to Claude Code extension:
# ✅ Subtle bypass mode color (soft amber instead of harsh red)
# ✅ Subtle left border indicator for visual feedback
# ✅ Subtle background tint (5% opacity container highlight)
# ✅ Enhanced hover states with smooth transitions
# ✅ Animated mode transitions for professional polish
#
# IMPORTANT: Run the main patcher (patch-cc-code.sh) FIRST!
# This script only modifies the CSS for visual improvements.
#
# Created by: seanGSISG
# With assistance from: Anthropic's Claude Code (the irony is not lost on us)
#
# ==============================================================================

set -euo pipefail

# ==============================================================================
# PARSE COMMAND-LINE ARGUMENTS
# ==============================================================================

CUSTOM_EXTENSION_DIR=""

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
            # Will be handled in restore section below
            break
            ;;
        --help|-h)
            echo "Claude Code UI Enhancement Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --extension-dir PATH   Use custom extension directory"
            echo "  --restore             Restore original CSS styling"
            echo "  --help, -h            Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  CLAUDE_CODE_EXTENSION_DIR   Override default extension directory"
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

echo "🎨 Claude Code UI Enhancements"
echo ""

# ==============================================================================
# DETECT EXTENSION DIRECTORY
# ==============================================================================

# Priority: 1) CLI arg, 2) Env var, 3) Auto-detect
if [ -n "$CUSTOM_EXTENSION_DIR" ]; then
    base_extension_dir="$CUSTOM_EXTENSION_DIR"
elif [ -n "${CLAUDE_CODE_EXTENSION_DIR:-}" ]; then
    base_extension_dir="$CLAUDE_CODE_EXTENSION_DIR"
else
    # Auto-detect based on OS
    os_type=$(uname -s 2>/dev/null || echo "Unknown")

    # Build search paths based on OS
    case "$os_type" in
        Linux|Darwin)
            search_paths=(
                "$HOME/.vscode-remote/extensions"
                "$HOME/.vscode/extensions"
                "$HOME/.cursor/extensions"
                "$HOME/.vscode-insiders/extensions"
                "$HOME/.vscode-server/extensions"
                "$HOME/.vscode-oss/extensions"
                "$HOME/.local/share/code/extensions"
            )
            if [ "$os_type" = "Darwin" ]; then
                search_paths+=(
                    "$HOME/Library/Application Support/Code/User/extensions"
                    "$HOME/Library/Application Support/Cursor/User/extensions"
                )
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            appdata="${APPDATA:-$HOME/AppData/Roaming}"
            search_paths=(
                "$appdata/Code/User/extensions"
                "$appdata/Cursor/User/extensions"
            )
            ;;
        *)
            search_paths=(
                "$HOME/.vscode-remote/extensions"
                "$HOME/.vscode/extensions"
                "$HOME/.cursor/extensions"
            )
            ;;
    esac

    # Find Claude Code extension
    set +e
    for search_path in "${search_paths[@]}"; do
        if [ -d "$search_path" ]; then
            found=$(find "$search_path" -maxdepth 1 -type d -name "anthropic.claude-code-*" 2>/dev/null | sort -V | tail -n 1)
            if [ -n "$found" ]; then
                base_extension_dir="$found"
                break
            fi
        fi
    done
    set -e
fi

# Validate that we found an extension directory
if [ -z "${base_extension_dir:-}" ] || [ ! -d "$base_extension_dir" ]; then
    echo "❌ Claude Code extension not found"
    echo ""
    echo "OS detected: $(uname -s 2>/dev/null || echo 'Unknown')"
    echo ""
    echo "You can specify the extension directory using:"
    echo "  • Command line: $0 --extension-dir /path/to/anthropic.claude-code-*"
    echo "  • Environment:  CLAUDE_CODE_EXTENSION_DIR=/path/to/extension $0"
    echo ""
    echo "Extension is typically located at:"
    echo "  Linux/WSL: ~/.vscode/extensions/anthropic.claude-code-*"
    echo "  macOS:     ~/Library/Application Support/Code/User/extensions/anthropic.claude-code-*"
    echo "  Windows:   \$APPDATA/Code/User/extensions/anthropic.claude-code-*"
    exit 1
fi

extension_dir="$base_extension_dir"
echo "📦 Found extension: $(basename "$extension_dir")"
echo ""

css_file="$extension_dir/webview/index.css"

# Handle restore
if [ "${1:-}" = "--restore" ]; then
    echo "🔄 Restoring original CSS..."
    echo ""

    if [ -f "$css_file.backup-original" ]; then
        cp "$css_file.backup-original" "$css_file"
        echo "✅ Restored original CSS styling"
        echo ""
        echo "🔄 Please reload the window to see changes"
        echo "   (Cmd/Ctrl+Shift+P → 'Developer: Reload Window')"
    else
        echo "⚠️  No CSS backup found"
        echo "   Cannot restore - original CSS backup doesn't exist"
    fi
    exit 0
fi

echo ""
echo "🎨 Applying UI enhancements..."
echo ""

# ==========================================================================
# UI ENHANCEMENT 1: More subtle bypass mode indicator
# ==========================================================================
#
# Current: Uses --app-error-foreground (bright red, harsh)
# Enhanced: Uses a muted orange/amber with opacity for subtlety
#
# This makes bypass mode noticeable but not alarming
# ==========================================================================

echo "  Applying ENHANCEMENT 1: Subtle bypass mode color"

# Backup CSS if not already backed up
if [ ! -f "$css_file.backup-original" ]; then
    cp "$css_file" "$css_file.backup-original"
    echo "  💾 Created CSS backup"
fi

# Change the harsh red error color to a more subtle amber/orange
perl -i.bak-ui -pe 's/\.s\[data-permission-mode=bypassPermissions\] \.p\{color:var\(--app-error-foreground\)\}/.s[data-permission-mode=bypassPermissions] .p{color:rgba(217, 119, 87, 0.9)}/' "$css_file"

if grep -q 'rgba(217, 119, 87, 0.9)' "$css_file"; then
    echo "  ✓ Changed bypass mode icon to subtle amber (90% opacity)"
else
    echo "  ⚠️  Could not verify bypass mode color change"
fi

# ==========================================================================
# UI ENHANCEMENT 2: Add subtle visual indicator to footer button
# ==========================================================================
#
# Adds a very subtle left border to the footer button when in bypass mode
# This provides additional visual feedback without being intrusive
# ==========================================================================

echo "  Applying ENHANCEMENT 2: Subtle border indicator"

# Add a rule for subtle border on bypass mode
# We'll add this right after the color rule we just modified
perl -i.bak-ui2 -pe 's/(\.s\[data-permission-mode=bypassPermissions\] \.p\{[^}]+\})/$1.s[data-permission-mode=bypassPermissions]{border-left:2px solid rgba(217, 119, 87, 0.3);padding-left:6px;background:rgba(217, 119, 87, 0.05);border-radius:4px}/' "$css_file"

if grep -q '.s\[data-permission-mode=bypassPermissions\]{border-left' "$css_file"; then
    echo "  ✓ Added subtle left border indicator"
    echo "  ✓ Added subtle background tint (5% opacity)"
else
    echo "  ⚠️  Could not verify border indicator"
fi

# ==========================================================================
# UI ENHANCEMENT 3: Improve hover state
# ==========================================================================
#
# Makes the footer button more responsive on hover
# ==========================================================================

echo "  Applying ENHANCEMENT 3: Enhanced hover state"

# Add hover enhancement for the permission mode button
cat >> "$css_file" << 'EOF'

/* Enhanced hover states for permission mode button */
.s:hover { opacity: 0.9; transition: opacity 0.15s ease; }
.s[data-permission-mode=bypassPermissions]:hover { 
    border-left-color: rgba(217, 119, 87, 0.5);
    transition: border-left-color 0.15s ease, opacity 0.15s ease;
}

/* Smooth transitions for mode switching */
.s { transition: all 0.2s ease; }
.s .p { transition: color 0.2s ease; }
EOF

echo "  ✓ Added enhanced hover states and smooth transitions"

# Clean up temporary files
rm -f "$css_file.bak-ui" "$css_file.bak-ui2" 2>/dev/null || true

echo ""
echo "✅ All approved UI enhancements applied successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "UI Changes Applied:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  ✅ Subtle Bypass Mode Color"
echo "     • Soft amber (90% opacity) instead of harsh red"
echo "     • Aligns with Claude's brand orange"
echo "     • Reduces eye strain and alarm"
echo ""
echo "  ✅ Subtle Left Border Indicator"
echo "     • 2px amber border at 30% opacity"
echo "     • Provides spatial awareness"
echo "     • Non-intrusive visual feedback"
echo ""
echo "  ✅ Subtle Background Tint"
echo "     • 5% opacity amber background"
echo "     • Creates visual 'zone' for mode"
echo "     • Extremely subtle container highlight"
echo ""
echo "  ✅ Enhanced Hover States"
echo "     • Smooth opacity transition on hover"
echo "     • Border brightens on hover (50% opacity)"
echo "     • Responsive, professional feel"
echo ""
echo "  ✅ Animated Mode Transitions"
echo "     • 200ms smooth color transitions"
echo "     • Reduces jarring mode switches"
echo "     • Polished, modern UI experience"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔄 NEXT STEP: Reload VS Code window to see changes"
echo "   • Press Cmd+Shift+P (Mac) or Ctrl+Shift+P (Win/Linux)"
echo "   • Type: 'Developer: Reload Window'"
echo "   • Press Enter"
echo ""
echo "💡 TIP: The bypass mode indicator should now appear as a"
echo "   soft amber color with a subtle left border and gentle"
echo "   background tint. Much less alarming than the red!"
