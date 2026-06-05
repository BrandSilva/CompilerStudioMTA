# Compiler Studio for MTA:SA v3.0

[![MTA:SA](https://img.shields.io/badge/MTA%3ASA-Compatible-blue)](https://multitheftauto.com/)
[![Version](https://img.shields.io/badge/version-3.0-green)](https://github.com/TridentSky/CompilerStudioMTA)
[![License](https://img.shields.io/badge/license-MIT-brightgreen)](https://github.com/TridentSky/CompilerStudioMTA)

**The most advanced and robust automatic compilation system for MTA:SA.**

**FORUM:** [Automatic Compiler - MTA:SA](https://forum.multitheftauto.com/topic/146252-automatic-compiler/)

**VIDEO DEMO:** [[Watch on YouTube]](https://youtu.be/9wFm3R8jGxc)

**DISCORD:** [Join the community](https://discord.gg/mjWuv7Zbyh)

---

## 🎯 Overview

Compiler Studio is a professional tool that compiles your MTA:SA Lua scripts directly from inside the game, using the official MTA compilation service. Pick one resource, several at once, or your **entire server** — it compiles, swaps the files in `meta.xml`, optionally protects them and restarts the resources for you.

Built with a modern multi-language HTML interface and a fast console command for power users.

---

## 🚀 What's New in v3.0

### ⚡ Direct Compile Commands (NEW)
Compile straight from chat/console — no panel needed:
```
/compiler                          Open the interactive panel
/compiler <resource>               Compile one resource (client)
/compiler <resource> <restart> <protect> <server>
/compiler MyGamemode 1 1 0         Compile + restart + protect (client)
/compiler all 1 1 1                Compile the WHOLE server (client + server)
```
Arguments (`0` = off, `1` = on): `restart`, `protect` (`cache=false`), `server`.

### 🧱 Robust Compilation Engine (NEW)
- **Sequential queue** prevents overlapping/conflicting compilations
- **Anti-spam cooldowns** on commands and list requests
- **Companion detection** — recompiles from the original `.lua` source even when only the `.luac` is referenced
- **Already-compiled detection** — skips files that are already bytecode (no double compilation)
- **Path-traversal validation** before touching any file

### 🌍 5 Languages (NEW)
Now ships with **English, Spanish, Portuguese, Turkish and Arabic** — switch live from the title bar.

### 🎨 Refined Interface
- Real-time **search + status filters** (All / Compiled / Uncompiled / Protected)
- Visual **progress bar** with per-file progress reporting
- Draggable window, confirmation modal, color-coded status badges

---

## ✨ Features

- **Modern HTML interface** with multi-language support (EN / ES / PT / TR / AR)
- **Bulk compilation** — select multiple scripts or compile the entire server in one click
- **Smart meta.xml auto-update** with cache-protection options (`cache="false"`)
- **Automatic resource restart** after compilation (optional, per task)
- **Real-time progress tracking** and full error handling with color-coded chat feedback
- **Customizable compilation** per selection — client only, server only, or both
- **Fast console commands** for compiling without opening the UI
- **ACL-protected** — only authorized admins can compile

---

## 🛠️ How It Works

1. The tool reads every running resource's `meta.xml` and lists their client/server scripts.
2. You select what to compile and your options (client / server / protect / restart).
3. Each `.lua` file is sent to the **official MTA compiler** (`https://luac.mtasa.com`) with maximum obfuscation.
4. The returned bytecode is written as a `.luac` file and the reference in `meta.xml` is updated automatically.
5. With **Protect** enabled, client scripts get `cache="false"` so they load into RAM instead of being cached to disk.
6. With **Restart** enabled, affected resources are restarted automatically once compilation finishes.

> The compiler resource never restarts itself, so your session is never interrupted mid-job.

---

## 🔧 Quick Installation

### 1. Add Resource
Extract to your server `resources` folder.

### 2. Configure ACL
Add to `acl.xml`:
```xml
<group name="Admin">
    <acl name="Admin"></acl>
    <object name="resource.automatic_compiler"></object>
</group>
```

### 3. Configure Settings
Edit `compilerS.lua` and set your ACL group:
```lua
local permissionACL = "Admin"  -- Change to your ACL group
```

### 4. Start & Use
```
start automatic_compiler
```
In-game: `/compiler` (panel) or `/compiler <resource> <restart> <protect> <server>` (direct).

---

## ⚙️ Configuration

| Setting | File | Default | Description |
|---|---|---|---|
| `permissionACL` | `compilerS.lua` | `"Admin"` | ACL group required to compile |

The interface language is selectable live and synced between client and server.

---

## 📋 Usage Examples

| Command | Result |
|---|---|
| `/compiler` | Open the interactive panel |
| `/compiler TSchat` | Compile `TSchat` client scripts |
| `/compiler TSchat 1 0 0` | Compile + restart `TSchat` |
| `/compiler TSchat 1 1 0` | Compile + restart + protect (`cache=false`) |
| `/compiler all 1 1 1` | Compile every resource on the server (client + server) and restart |

---

## 🛡️ Safety & Robustness

- **ACL permission check** on every action; guest accounts rejected
- **Single-job queue** — no concurrent compilations corrupting files
- **Anti-spam** cooldowns (1000 ms list / 1500 ms command)
- **Path-traversal protection** on all resource and file paths
- **Compiled-file detection** avoids recompiling existing bytecode
- **Detailed, color-coded** error reporting (connection, syntax, missing file, meta update, etc.)

---

## 🌍 Supported Languages

🇬🇧 English | 🇪🇸 Spanish | 🇧🇷 Portuguese | 🇹🇷 Turkish | 🇸🇦 Arabic

---

## 🔄 Version History

**v3.0 (2026)** — Direct `/compiler` console commands, robust sequential queue with anti-spam, companion (`.luac` → `.lua`) recompilation, already-compiled detection, path-traversal validation, 5 languages (added TR/AR), refined UI with live search/filters and progress bar

**v1.5.x (2025)** — Trigger-conflict fixes and minor bug fixes

**v1.2.x (2025)** — Arabic & Turkish languages added

**v1.0.0 (2025)** — First public release

---

## 📞 Contact & Support

**Developer:** BranD - Trident Sky Company
**Email:** tridentskycompany@gmail.com
**Discord:** [discord.gg/mjWuv7Zbyh](https://discord.gg/mjWuv7Zbyh) (BrandSilva)
**Forum:** [MTA:SA Forum Topic](https://forum.multitheftauto.com/topic/146252-automatic-compiler/)

---

## 📜 License

Released under the **MIT License** — see [LICENSE](LICENSE).

© 2026 Brando Silva — Trident Sky Company. Free for the MTA:SA community.

---

## 🙏 Credits

- **BranD** — Author, core architecture and all base code
- **MTA:SA Team** — Official Lua compiler service and platform
- **Community** — Feedback and testing
- **Claude (Anthropic)** — AI assistant that helped polish and refine the code

---

⭐ **If this saves you time, star the repository and share it with the MTA community!**

---

*Developed with ❤️ for the MTA:SA community*
