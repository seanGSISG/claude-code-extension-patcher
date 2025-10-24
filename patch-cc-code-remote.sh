#!/bin/bash

# ==============================================================================
# Patch Claude Code Extension for Bypass Permissions
# ==============================================================================
#
# This script patches the Claude Code extension to add a "Bypass Permissions"
# mode that automatically approves all tool executions without prompting.
#
# Compatible with versions:
#   - v2.0.1   (Initial pattern detection)
#   - v2.0.10  (Minor variable name changes)
#   - v2.0.26+ (Significant code restructuring)
#
# Original script by: ColeMurray (https://gist.github.com/ColeMurray)
# Enhanced by: seanGSISG
#
# ==============================================================================

# Auto-detect extension directory and editor type
detect_extension_dir() {
    local dirs=(
        "$HOME/.cursor/extensions:Cursor"
        "$HOME/.vscode/extensions:VS Code"
        "$HOME/.vscode-insiders/extensions:VS Code Insiders"
        "$HOME/.vscode-remote/extensions:Dev Container"
    )

    for entry in "${dirs[@]}"; do
        IFS=':' read -r dir editor <<< "$entry"
        if [ -d "$dir" ]; then
            EXTENSION_DIR="$dir"
            EDITOR_NAME="$editor"
            return 0
        fi
    done

    return 1
}

if ! detect_extension_dir; then
    echo "❌ Could not find VS Code/Cursor extensions directory"
    echo "Searched in:"
    echo "  - $HOME/.cursor/extensions"
    echo "  - $HOME/.vscode/extensions"
    echo "  - $HOME/.vscode-insiders/extensions"
    echo "  - $HOME/.vscode-remote/extensions"
    exit 1
fi

echo "📍 Using: $EXTENSION_DIR ($EDITOR_NAME)"
EXTENSION_PATTERN="anthropic.claude-code-*"

patch_extension() {
    local ext_path=$(find "$EXTENSION_DIR" -maxdepth 1 -type d -name "$EXTENSION_PATTERN" | head -n 1)

    if [ -z "$ext_path" ]; then
        echo "❌ Claude Code extension not found"
        return 1
    fi

    echo "📦 Found extension: $(basename "$ext_path")"

    local extension_js="$ext_path/extension.js"
    local webview_js="$ext_path/webview/index.js"

    # Backup originals if not already backed up
    if [ ! -f "$extension_js.original" ]; then
        echo "💾 Creating backup of extension.js"
        cp "$extension_js" "$extension_js.original"
    fi

    if [ ! -f "$webview_js.original" ]; then
        echo "💾 Creating backup of webview/index.js"
        cp "$webview_js" "$webview_js.original"
    fi

    # Check if already patched
    if grep -q 'permissionMode:o,' "$extension_js" 2>/dev/null || \
       grep -q 'permissionMode:L,' "$extension_js" 2>/dev/null; then
        if grep -q '\["bypassPermissions","acceptEdits","plan"\]' "$webview_js" 2>/dev/null; then
            echo "✅ Extension already patched"
            return 0
        fi
    fi

    echo "🔧 Applying patches..."

    # ==========================================================================
    # PATCH 1: extension.js - Remove hardcoded "default" permission mode
    # ==========================================================================
    #
    # This patch removes the hardcoded "default" value initialization for
    # permissionMode, allowing it to be set dynamically from config.
    #
    # Version History:
    #   v2.0.1:  permissionMode:o===void 0?"default":o
    #            - Uses variable 'o' with ternary operator
    #            - Falls back to "default" if undefined
    #
    #   v2.0.10: permissionMode:L="default"
    #            - Variable renamed from 'o' to 'L'
    #            - Direct assignment pattern
    #
    #   v2.0.26: permissionMode:T="default"
    #            - Variable renamed from 'L' to 'T'
    #            - Direct assignment pattern
    #
    # Target: Remove "default" assignment to allow bypass mode
    # ==========================================================================

    if grep -q 'permissionMode:o===void 0?"default":o' "$extension_js" 2>/dev/null; then
        # v2.0.1 pattern - ternary operator with fallback
        sed -i.bak 's/permissionMode:o===void 0?"default":o/permissionMode:o/g' "$extension_js"
        echo "  ✓ Patched extension.js (v2.0.1 pattern)"
    elif grep -q 'permissionMode:T="default"' "$extension_js" 2>/dev/null; then
        # v2.0.26 pattern - direct assignment to variable T
        sed -i.bak 's/permissionMode:T="default"/permissionMode:T/g' "$extension_js"
        echo "  ✓ Patched extension.js (v2.0.26 pattern)"
    else
        echo "  ⚠️  Could not find permissionMode pattern in extension.js"
    fi

    # ==========================================================================
    # PATCH 2: webview/index.js - Replace "default" in permission modes array
    # ==========================================================================
    #
    # This patch changes the available permission modes array to replace
    # "default" with "bypassPermissions" in the UI mode selector.
    #
    # Version History:
    #   v2.0.1:  Nye=["default","acceptEdits","plan"]
    #            - Array assigned to variable 'Nye'
    #            - Used in permission mode cycling logic
    #
    #   v2.0.10: Fye=["default","acceptEdits","plan"]
    #            - Variable renamed from 'Nye' to 'Fye'
    #            - Same structure and purpose
    #
    #   v2.0.26: ?["...","...","..."]:["default","acceptEdits","plan"]
    #            - Array no longer assigned to named variable
    #            - Now part of inline ternary expression
    #            - Conditional check for allowDangerouslySkipPermissions
    #            - Pattern: condition?[withBypass]:["default","acceptEdits","plan"]
    #
    # Target: Replace "default" with "bypassPermissions" in modes array
    # ==========================================================================

    if grep -q 'Nye=\["default","acceptEdits","plan"\]' "$webview_js" 2>/dev/null; then
        # v2.0.1 pattern - named variable Nye
        sed -i.bak 's/Nye=\["default","acceptEdits","plan"\]/Nye=["bypassPermissions","acceptEdits","plan"]/g' "$webview_js"
        echo "  ✓ Patched webview/index.js mode array (v2.0.1)"
    elif grep -q 'Fye=\["default","acceptEdits","plan"\]' "$webview_js" 2>/dev/null; then
        # v2.0.10 pattern - named variable Fye
        sed -i.bak 's/Fye=\["default","acceptEdits","plan"\]/Fye=["bypassPermissions","acceptEdits","plan"]/g' "$webview_js"
        echo "  ✓ Patched webview/index.js mode array (v2.0.10)"
    elif grep -q ':\["default","acceptEdits","plan"\]' "$webview_js" 2>/dev/null; then
        # v2.0.26 pattern - inline ternary array (no named variable)
        sed -i.bak 's/:\["default","acceptEdits","plan"\]/:["bypassPermissions","acceptEdits","plan"]/g' "$webview_js"
        echo "  ✓ Patched webview/index.js mode array (v2.0.26)"
    else
        echo "  ⚠️  Could not find mode array pattern in webview/index.js"
    fi

    # ==========================================================================
    # PATCH 3: webview/index.js - Initialize session permissionMode default
    # ==========================================================================
    #
    # This patch changes the initial/default permission mode when starting
    # a new session from "default" to "bypassPermissions".
    #
    # Version History:
    #   v2.0.1:  permissionMode=kn("default")
    #            - Uses helper function 'kn()' to create observable
    #            - Initializes with "default" mode
    #
    #   v2.0.10: permissionMode=kn("default")
    #            - Same pattern as v2.0.1
    #            - No changes in this area
    #
    #   v2.0.26: permissionMode=ln("default")
    #            - Helper function renamed from 'kn' to 'ln'
    #            - Still creates observable with default value
    #            - Function name change likely due to minification changes
    #
    # Target: Set default session mode to "bypassPermissions"
    # ==========================================================================

    if grep -q 'permissionMode=kn("default")' "$webview_js" 2>/dev/null; then
        # v2.0.1 & v2.0.10 pattern - uses kn() helper
        sed -i.bak3 's/permissionMode=kn("default")/permissionMode=kn("bypassPermissions")/g' "$webview_js"
        echo "  ✓ Patched webview/index.js session init"
    elif grep -q 'permissionMode=ln("default")' "$webview_js" 2>/dev/null; then
        # v2.0.26 pattern - uses ln() helper (renamed)
        sed -i.bak3 's/permissionMode=ln("default")/permissionMode=ln("bypassPermissions")/g' "$webview_js"
        echo "  ✓ Patched webview/index.js session init (v2.0.26)"
    else
        echo "  ⚠️  Could not find session permissionMode initialization"
    fi

    # ==========================================================================
    # PATCH 4: webview/index.js - Update UI button text and tooltip
    # ==========================================================================
    #
    # This patch updates the UI footer button that displays the current
    # permission mode. Changes both the visible text and tooltip.
    #
    # Version History:
    #   v2.0.1:  case"default":default:return(0,zr.jsxs)("button",...)
    #            - Uses zr.jsxs() for React JSX transformation
    #            - Button shows: "Ask before edits"
    #            - Tooltip: "Claude will ask before each edit..."
    #            - Icon component: Pye
    #            - Style class: Ph.footerButton
    #
    #   v2.0.10: case"default":default:return(0,zr.jsxs)("button",...)
    #            - Same pattern as v2.0.1
    #            - No changes in UI rendering
    #
    #   v2.0.26: case"default":default:return Vo.default.createElement(...)
    #            - Major change: Uses React.createElement() directly
    #            - No longer uses JSX transformation helpers
    #            - Different variable names:
    #              * Vo instead of zr (React reference)
    #              * Wa instead of Ph (CSS class names)
    #              * Iye instead of Pye (icon component for default mode)
    #              * yye (icon component for bypass mode)
    #            - Same functionality, different implementation
    #
    # Changes applied:
    #   - case"default" → case"bypassPermissions"
    #   - Button text: "Ask before edits" → "Bypass permissions"
    #   - Tooltip: "...will ask before each edit" → "...will skip all permission prompts"
    #   - Icon updated to match bypass mode
    #
    # ==========================================================================

    if grep -q 'case"default":default:return(0,zr.jsxs)("button",{type:"button",className:Ph.footerButton,onClick:e,title:"Claude will ask before each edit' "$webview_js" 2>/dev/null; then
        # v2.0.1 & v2.0.10 pattern - JSX with zr.jsxs()
        sed -i.bak2 's/case"default":default:return(0,zr.jsxs)("button",{type:"button",className:Ph.footerButton,onClick:e,title:"Claude will ask before each edit\. Click, or press Shift+Tab, to switch modes\.",children:\[(0,zr.jsx)(Pye,{}),(0,zr.jsx)("span",{children:"Ask before edits"})\]})/case"bypassPermissions":default:return(0,zr.jsxs)("button",{type:"button",className:Ph.footerButton,onClick:e,title:"Claude will skip all permission prompts. Click, or press Shift+Tab, to switch modes.",children:[(0,zr.jsx)(Pye,{}),(0,zr.jsx)("span",{children:"Bypass permissions"})]})/g' "$webview_js"
        echo "  ✓ Patched webview/index.js UI text"
    elif grep -q 'case"default":default:return Vo.default.createElement("button",{type:"button",className:Wa.footerButton,onClick:e,title:"Claude will ask before each edit' "$webview_js" 2>/dev/null; then
        # v2.0.26 pattern - React.createElement()
        sed -i.bak2 's/case"default":default:return Vo\.default\.createElement("button",{type:"button",className:Wa\.footerButton,onClick:e,title:"Claude will ask before each edit\. Click, or press Shift+Tab, to switch modes\."},Vo\.default\.createElement(Iye,null),Vo\.default\.createElement("span",null,"Ask before edits"))/case"bypassPermissions":default:return Vo.default.createElement("button",{type:"button",className:Wa.footerButton,onClick:e,title:"Claude will skip all permission prompts. Click, or press Shift+Tab, to switch modes."},Vo.default.createElement(yye,null),Vo.default.createElement("span",null,"Bypass permissions"))/g' "$webview_js"
        echo "  ✓ Patched webview/index.js UI text (v2.0.26)"
    else
        echo "  ⚠️  Could not find UI text pattern in webview/index.js"
    fi

    # Clean up .bak files
    rm -f "$extension_js.bak" "$webview_js.bak" "$webview_js.bak2" "$webview_js.bak3"

    echo "✅ Patching complete!"

    # Show appropriate reload instruction based on detected editor
    case "$EDITOR_NAME" in
        "Cursor")
            echo "🔄 Please reload Cursor (Cmd+Shift+P → 'Developer: Reload Window')"
            ;;
        "VS Code")
            echo "🔄 Please reload VS Code (Cmd+Shift+P → 'Developer: Reload Window')"
            ;;
        "VS Code Insiders")
            echo "🔄 Please reload VS Code Insiders (Cmd+Shift+P → 'Developer: Reload Window')"
            ;;
        "Dev Container")
            echo "🔄 Please reload the window (Cmd+Shift+P → 'Developer: Reload Window')"
            ;;
        *)
            echo "🔄 Please reload your editor (Cmd+Shift+P → 'Developer: Reload Window')"
            ;;
    esac

    return 0
}

restore_originals() {
    local ext_path=$(find "$EXTENSION_DIR" -maxdepth 1 -type d -name "$EXTENSION_PATTERN" | head -n 1)

    if [ -z "$ext_path" ]; then
        echo "❌ Extension not found"
        return 1
    fi

    if [ -f "$ext_path/extension.js.original" ]; then
        cp "$ext_path/extension.js.original" "$ext_path/extension.js"
        echo "✅ Restored extension.js"
    fi

    if [ -f "$ext_path/webview/index.js.original" ]; then
        cp "$ext_path/webview/index.js.original" "$ext_path/webview/index.js"
        echo "✅ Restored webview/index.js"
    fi
}

case "${1:-}" in
    --restore)
        restore_originals
        ;;
    --help)
        echo "Usage: $0 [--restore|--help]"
        echo ""
        echo "Options:"
        echo "  (none)     Patch the extension"
        echo "  --restore  Restore original files from backups"
        echo "  --help     Show this help message"
        ;;
    *)
        patch_extension
        ;;
esac
