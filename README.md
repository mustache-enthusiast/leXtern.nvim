# leXtern.nvim

A Neovim plugin for creating and managing SVG figures in LaTeX documents using Inkscape.

Inspired by [Gilles Castel](https://castel.dev/), whose articles on [taking lecture notes with LaTeX and Vim](https://castel.dev/post/lecture-notes-1/) and [drawing figures with Inkscape](https://castel.dev/post/lecture-notes-2/) established the workflow this plugin implements.

## Features

- Create SVG figures with automatic LaTeX figure environment generation
- Edit existing figures with captions preserved in metadata
- Insert LaTeX code for existing figures
- Automatic SVG to PDF+LaTeX export via filesystem watcher
- VimTeX integration for project root detection

## Requirements

- [Neovim](https://neovim.io/) 0.7+
- [Inkscape](https://inkscape.org/)
- [VimTeX](https://github.com/lervag/vimtex)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'mustache-enthusiast/lextern.nvim',
  config = function()
    require('lextern').setup({
      -- Directory creation behavior when figures/ doesn't exist
      -- "ask" (default): Prompt user whether to create directory
      -- "always": Automatically create directory without asking
      -- "never": Display error and stop (old behavior)
      dir_create_mode = "ask",
    })
  end,
}
```

## Configuration

leXtern can be configured by passing options to the `setup()` function:

```lua
require('lextern').setup({
  dir_create_mode = "ask",  -- "ask" | "always" | "never"
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `dir_create_mode` | string | `"ask"` | Controls what happens when the `figures/` directory doesn't exist:<br>• `"ask"` - Prompt user with confirmation dialog (default)<br>• `"always"` - Automatically create directory and notify<br>• `"never"` - Display error message and stop |

## Recommended Keybindings

```lua
vim.keymap.set('n', '<localleader>lc', ':LexternCreate<CR>', 
  vim.tbl_extend('force', opts, { desc = 'Create figure' }))
vim.keymap.set('v', '<localleader>lc', '"zy:LexternCreate <C-r>z<CR>', 
  vim.tbl_extend('force', opts, { desc = 'Create figure from selection' }))
vim.keymap.set('n', '<localleader>le', ':LexternEdit<CR>', 
  vim.tbl_extend('force', opts, { desc = 'Edit figure' }))
vim.keymap.set('n', '<localleader>li', ':LexternInsert<CR>', 
  vim.tbl_extend('force', opts, { desc = 'Insert figure code' }))
vim.keymap.set('n', '<localleader>lp', ':LexternPreamble<CR>', 
  vim.tbl_extend('force', opts, { desc = 'Insert preamble' }))
```

## Usage

### LaTeX Preamble

Quickly and easily add the required LaTeX packages and command to your document preamble using `:LexternPreamble` to copy necessary preamble elements to your neovim register. This is useful because not every document will need figures, and leaving out unnecessary preamble elements is a little cleaner.

If you prefer just leaving everything in a standard preamble, just use the following:

```latex
\usepackage{import}
\usepackage{xifthen}
\usepackage{pdfpages}
\usepackage{transparent}

\newcommand{\incfig}[1]{%
  \def\svgwidth{\columnwidth}
  \import{./figures/}{#1.pdf_tex}
}
```

### Creating Figures

```vim
:LexternCreate Figure Title
```

Creates `figures/figure-title.svg`, opens it in Inkscape, and inserts the following LaTeX code at the cursor:

```latex
\begin{figure}[ht]
    \centering
    \incfig{figure-title}
    \caption{Figure Title}
    \label{fig:figure-title}
\end{figure}
```

The figure title is stored as metadata in the SVG file and preserved across Inkscape edits (for the time being, there is no way to modify caption metadata after creation). The filesystem watcher starts automatically and exports the SVG to `figure-title.pdf` and `figure-title.pdf_tex` whenever you save in Inkscape.

Title sanitization converts to lowercase, replaces spaces with hyphens, removes special characters, and normalizes unicode (e.g., "My Café Figure!" becomes `my-cafe-figure`).

### Editing Figures

```vim
:LexternEdit
```

Displays a selection prompt with all figures in the `figures/` directory. Selecting a figure opens it in Inkscape and copies its LaTeX code to the unnamed register for pasting. The original caption from the figure's metadata is used in the generated code.

### Inserting Figures

```vim
:LexternInsert
```

Similar to `:LexternEdit` but only copies the LaTeX code to the register without opening Inkscape. Useful for inserting existing figures into your document.

### Filesystem Watcher

The watcher monitors the `figures/` directory and automatically runs Inkscape's command-line export whenever an SVG file is saved.

Manual controls:
```vim
:LexternWatch [directory]    " Start watching (auto-detects figures/ if no arg)
:LexternWatchStop            " Stop watching
:LexternStatus               " Display watcher status and export count
```

## Project Structure

leXtern expects a `figures/` directory relative to your LaTeX project root:

```
project/
├── main.tex
└── figures/
    ├── diagram.svg       (source)
    ├── diagram.pdf       (compiled)
    └── diagram.pdf_tex   (compiled)
```

With VimTeX active, the plugin uses `vim.b.vimtex.root` as the project root. Without VimTeX, it uses the directory of the current buffer.

## Technical Details

### Caption Metadata

Figure captions are stored as XML metadata inside the SVG file:

```xml
<metadata>
  <lextern:data xmlns:lextern="https://github.com/lextern/lextern.nvim" caption="Original Caption" />
</metadata>
```

This survives Inkscape edits, allowing `:LexternEdit` to regenerate LaTeX code with the original caption rather than the sanitized filename.

## Commands Reference

| Command | Description |
|---------|-------------|
| `:LexternCreate [title]` | Create figure (prompts if no title) |
| `:LexternEdit` | Edit existing figure |
| `:LexternInsert` | Insert existing figure code |
| `:LexternPreamble` | Copy LaTeX preamble to register |
| `:LexternWatch [dir]` | Start filesystem watcher |
| `:LexternWatchStop` | Stop filesystem watcher |
| `:LexternStatus` | Display watcher status |

## Acknowledgments

This plugin implements the workflow established by [Gilles Castel](https://castel.dev/). His original articles remain essential reading:
- [How I'm able to take notes in mathematics lectures using LaTeX and Vim](https://castel.dev/post/lecture-notes-1/)
- [How I draw figures for my mathematical lecture notes using Inkscape](https://castel.dev/post/lecture-notes-2/)

Based on concepts from [gillescastel/inkscape-figures](https://github.com/gillescastel/inkscape-figures).

## License

MIT License. See [LICENSE](LICENSE) for details.

## Status

This plugin is under active development. Future updates may introduce breaking changes. Pin to a specific version for stability.

---

*"The best way to take notes is the way that works for you." - Gilles Castel*
