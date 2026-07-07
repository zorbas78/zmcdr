# zcmdr

A keyboard-driven dual-panel file manager for macOS. Native, fast, zero external dependencies.

## Features

- **Dual panels** — browse two directories side by side
- **Full keyboard control** — F1–F10 for all operations, arrow keys for navigation
- **File operations** — Copy, Move, Delete, Rename, Mkdir (with overwrite dialog and batch actions)
- **Built-in file viewer** — text/hex preview of files up to 1 MB (F3)
- **Navigation history** — back/forward per panel, breadcrumb path bar
- **AI file selection** — ask an LLM (Ollama or OpenAI-compatible) to select files for you. Read-only: the LLM only selects/deselects, never modifies files
- **4 themes** — Dark, WB 1.2 (Amiga), WB 2.0 (Amiga), Matrix
- **Status bar** — F-key labels as clickable buttons, file count, total size, free space

## Requirements

- macOS 14.0+
- Apple Silicon (M1+) or Intel

Optional:
- [Ollama](https://ollama.com) — for local LLM-based file selection
- OpenAI API key (or compatible provider) — for cloud-based file selection

## Build

Requires Xcode Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/zorbas78/zmcdr.git
cd zmcdr
make dmg
```

This produces `zcmdr-0.1.0.dmg`. Open it and drag `zcmdr.app` to `/Applications`.

### Other targets

| Command | Produces |
|---------|----------|
| `make app` | `zcmdr.app` bundle |
| `make dmg` | `zcmdr-0.1.0.dmg` |
| `make build` | Debug build in `.build/debug/` |
| `make run` | Build and launch |
| `make clean` | Remove build artifacts |

### F-keys

| Key | Action |
|-----|--------|
| F1 | Help placeholder |
| F2 | AI file selection |
| F4 | Edit placeholder |
| F5 | Copy |
| F6 | Move |
| F7 | Mkdir |
| F8 | Delete |
| F9 | Run terminal |
| F10 | Quit |
