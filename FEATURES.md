# Claude Code Enhancement Roadmap

## Community Validation

**Source**: [cc-statusline](https://github.com/chongdashu/cc-statusline) (active npm package, v1.3.2)
**Proof**: 1000s of users installed a standalone tool just to get these features

---

## S-TIER: Community-Proven Features

| Feature | Impact | Difficulty | Proof |
|---------|--------|-----------|-------|
| **Context Window Indicator** | ⭐⭐⭐⭐⭐ | Easy | cc-statusline core |
| **Cost/Token Display** | ⭐⭐⭐⭐⭐ | Medium | cc-statusline core |
| **Session Timer** | ⭐⭐⭐⭐ | Medium | cc-statusline |
| **Model Display** | ⭐⭐⭐ | Easy | cc-statusline |
| **Status Line** | ⭐⭐⭐⭐ | Medium | cc-statusline purpose |

---

## A-TIER: User-Requested

| Feature | Impact | Difficulty |
|---------|--------|-----------|
| **Subagent Activity Monitor** | Very High | Hard |
| **TODO Viewer & Editor** | Very High | Medium-Hard |
| Keyboard Shortcuts | High | Medium |
| Auto-Save Sessions | High | Medium |
| Approval Whitelist | High | Medium |

---

## Implementation Plan

### v3.1 (Quick Wins)
- Context window indicator
- Model display

### v3.2 (High Value)
- Cost/token display
- Session timer

### v3.3 (Advanced)
- TODO viewer
- Subagent monitor
- Integrated status line

---

## Feature Details

### Context Window Indicator
```
🧠 Context: 83% [========--]
```
Read context usage → display progress bar in UI

### Cost/Token Display
```
💰 $49.00 ($16.55/h) | 14.6M tokens (279k tpm)
```
Intercept API responses → show cost + burn rate

### Session Timer
```
⌛ 3h 7m until reset at 01:00 (37%)
```
Track usage limits → countdown display

### Model Display
```
🤖 Sonnet 4 | v2.0.27
```
Read extension metadata → show in status

### TODO Viewer
Persistent panel with CRUD operations, syncs with TodoWrite, stores in `.claude/todos.json`

### Subagent Monitor
Live panel showing active agents, status, progress, kill controls

---

## Strategy

Build patcher → Prove demand → Anthropic adds natively → Next feature

**Success**: Bypass permissions now native (Settings → "Allow Dangerously Skip Permissions")
