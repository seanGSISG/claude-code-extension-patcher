#!/bin/bash

# Patch Claude Code Extension for Bypass Permissions
# Compatible with versions 2.0.1, 2.0.10, and 2.0.26+

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

    # Patch 1: extension.js - Remove hardcoded "default" permission mode
    # Pattern for v2.0.1: permissionMode:o===void 0?"default":o
    # Pattern for v2.0.10: permissionMode:L="default"
    # Pattern for v2.0.26: permissionMode:T="default"

    if grep -q 'permissionMode:o===void 0?"default":o' "$extension_js" 2>/dev/null; then
        # v2.0.1 pattern
        sed -i.bak 's/permissionMode:o===void 0?"default":o/permissionMode:o/g' "$extension_js"
        echo "  ✓ Patched extension.js (v2.0.1 pattern)"
    elif grep -q 'permissionMode:T="default"' "$extension_js" 2>/dev/null; then
        # v2.0.26 pattern
        sed -i.bak 's/permissionMode:T="default"/permissionMode:T/g' "$extension_js"
        echo "  ✓ Patched extension.js (v2.0.26 pattern)"
    else
        echo "  ⚠️  Could not find permissionMode pattern in extension.js"
    fi

    # Patch 2: webview/index.js - Change mode array
    # v2.0.1: Nye=["default","acceptEdits","plan"]
    # v2.0.10: Fye=["default","acceptEdits","plan"]

    if grep -q 'Nye=\["default","acceptEdits","plan"\]' "$webview_js" 2>/dev/null; then
        # v2.0.1 pattern
        sed -i.bak 's/Nye=\["default","acceptEdits","plan"\]/Nye=["bypassPermissions","acceptEdits","plan"]/g' "$webview_js"
        echo "  ✓ Patched webview/index.js mode array (v2.0.1)"
    elif grep -q 'Fye=\["default","acceptEdits","plan"\]' "$webview_js" 2>/dev/null; then
        # v2.0.10 pattern
        sed -i.bak 's/Fye=\["default","acceptEdits","plan"\]/Fye=["bypassPermissions","acceptEdits","plan"]/g' "$webview_js"
        echo "  ✓ Patched webview/index.js mode array (v2.0.10)"
    elif grep -q ':\["default","acceptEdits","plan"\]' "$webview_js" 2>/dev/null; then
        # v2.0.26 pattern - inline ternary array
        sed -i.bak 's/:\["default","acceptEdits","plan"\]/:["bypassPermissions","acceptEdits","plan"]/g' "$webview_js"
        echo "  ✓ Patched webview/index.js mode array (v2.0.26)"
    else
        echo "  ⚠️  Could not find mode array pattern in webview/index.js"
    fi

    # Patch 3: webview/index.js - Initialize session permissionMode to bypassPermissions
    if grep -q 'permissionMode=kn("default")' "$webview_js" 2>/dev/null; then
        sed -i.bak3 's/permissionMode=kn("default")/permissionMode=kn("bypassPermissions")/g' "$webview_js"
        echo "  ✓ Patched webview/index.js session init"
    elif grep -q 'permissionMode=ln("default")' "$webview_js" 2>/dev/null; then
        # v2.0.26 pattern
        sed -i.bak3 's/permissionMode=ln("default")/permissionMode=ln("bypassPermissions")/g' "$webview_js"
        echo "  ✓ Patched webview/index.js session init (v2.0.26)"
    else
        echo "  ⚠️  Could not find session permissionMode initialization"
    fi

    # Patch 4: webview/index.js - Update UI text
    if grep -q 'case"default":default:return(0,zr.jsxs)("button",{type:"button",className:Ph.footerButton,onClick:e,title:"Claude will ask before each edit' "$webview_js" 2>/dev/null; then
        # Pre-v2.0.26 pattern
        sed -i.bak2 's/case"default":default:return(0,zr.jsxs)("button",{type:"button",className:Ph.footerButton,onClick:e,title:"Claude will ask before each edit\. Click, or press Shift+Tab, to switch modes\.",children:\[(0,zr.jsx)(Pye,{}),(0,zr.jsx)("span",{children:"Ask before edits"})\]})/case"bypassPermissions":default:return(0,zr.jsxs)("button",{type:"button",className:Ph.footerButton,onClick:e,title:"Claude will skip all permission prompts. Click, or press Shift+Tab, to switch modes.",children:[(0,zr.jsx)(Pye,{}),(0,zr.jsx)("span",{children:"Bypass permissions"})]})/g' "$webview_js"
        echo "  ✓ Patched webview/index.js UI text"
    elif grep -q 'case"default":default:return Vo.default.createElement("button",{type:"button",className:Wa.footerButton,onClick:e,title:"Claude will ask before each edit' "$webview_js" 2>/dev/null; then
        # v2.0.26 pattern
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