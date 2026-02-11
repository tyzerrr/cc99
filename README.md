# cc99

Neovim plugin for scoped AI-assisted code editing, powered by Claude Code CLI.

> Special thanks to [ThePrimeagen](https://github.com/ThePrimeagen) and his [99](https://github.com/ThePrimeagen/99) plugin for the inspiration behind this project.

## What Makes cc99 Different

Unlike traditional inline AI plugins that embed the entire file into the prompt, cc99 gives Claude **read-only tool access** (`Read`, `Grep`, `Glob`, `LS`). Claude explores the codebase on its own and gathers only the context it needs. This means:

- **Smaller prompts** — only the selected code and user instruction are sent
- **Smarter context** — Claude finds relevant code across the project, not just the current file
- **Real-time progress** — see what Claude is doing (reading files, searching, analyzing) as it works

## Features

- **Visual selection replacement** — select code, describe what you want, Claude replaces it
- **Streaming status display** — animated spinner + live progress messages via extmark virtual lines
- **Async execution** — non-blocking, keep editing while Claude works
- **Auto project analysis** — generates `.cc99/CC99.md` on first run for project-level context
- **`<CODE>` stream parsing** — status lines shown before `<CODE>`, replacement code extracted from within

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "your-username/cc99",
    config = function()
        require("cc99").setup()
    end,
}
```

### Prerequisites

- Neovim 0.10+
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated

## Usage

1. **Select code** in visual mode
2. Press `<leader>ccm` to mark the selection and open the prompt window
3. Type your instruction in the floating window
4. Press `<leader>ccx` to execute
5. Watch Claude's progress in virtual lines below your selection
6. Code is replaced automatically when done
7. `u` to undo if needed

## Keybindings

| Mode | Key | Action |
|------|-----|--------|
| Visual | `<leader>ccm` | Mark selection and open prompt window |
| Normal | `<leader>ccx` | Execute Claude with current prompt |
| Normal | `<leader>ccq` | Close prompt window |

## Configuration

```lua
require("cc99").setup({
    window = {
        relative = "editor",
        border = "rounded",
        style = "minimal",
        title = "cc99",
        title_pos = "center",
    },
})
```

## License

MIT
