# file_line.nvim


Support `file:line:column` syntax when opening files in neovim.

This is a rewrite of the this
[file-line](https://github.com/lervag/file-line/tree/master)[^1] plugin made to
be more flexible and easier to integrate into a modern Neovim config.

> [!TIP]
> The following line/column formats also work:
> * file(line)
> * file(line:column)
> * file:line:column:
> * file:line:column
> * file:line

## Installation

When using Lazy.nvim make sure not to lazy-load the plugin, or it will not work
when starting nvim.

```lua
{
    "dk949/file_line.nvim",
    main = "file_line",
    opts = {},
    lazy = false,
}

```

> [!NOTE]
> When not using lazy.nvim, make sure to call the `setup` function, passing it
> `nil` or a config as described below.

## Configuration

**Default config:**

```lua
{
    register = true, -- boolean
    on_open = nil, --  file_line.OnOpenFn?
    enable_gf = false, -- file_line.EnableGF?
}


-- file_line.OnOpenFn -- fun(name:string, line:number, col:number, bufnr:number):nil
-- file_line.EnableGF -- boolean|{ignore_pat:string[]}|{match_pat:string[]}
```

### `register`

Intercepts new files being edited with a name matching a pattern above and
interprets the line and column number.

### `on_open`

A callback to be invoked before the file is opened by the plugin. Not invoked
when the file is opened without the line, column pattern.

### `enable_gf`

This is added just for convenience, it maps `gf` to `gF` in normal mode, so that
`gf` opens files followed by line numbers. Note that this is not quite the same
pattern as is enabled by this plugin, this is (neo)vim built-in functionality.

If `enable_gf` is a table, it is expected to have one of two keys (but not
both!), `match_pat` or `ignore_pat`: This will match the file name will or will
not enable the mapping for that file respectively.

If `enable_gf` is `true`, it is enabled on all files.

## API

### `filenameLineCol`


Given a file name possibly with line and column on the end, returns them as
3 separate values. `line` and `col` could be `nil` if they were not present in
the file name, they will be numbers otherwise.

```lua
local name, line, col =  require "file_line".filenameLineCol(file_name)
```

### `openFileOnLine`

Open a file and jump to the line and column.

Last argument is optional, if supplied it is either the window id or a string
that can be interpreted by `winnr()`. This will be the window the file is opened
in. Current window if `nil`.

Returns `true` if the file was opened.

```lua
require "file_line".openFileOnLine(name, line, col, winnr)
```

## Legacy configuration

It is not necessary to use the `setup` function, you can also call the old
configuration functions directly.

> [!CAUTION]
> The preferred way is to use the `setup` function (or `opts` field in
> lazy.nvim). These are not currently deprecated, but they may be in the future.

```lua
-- same as passing `register = true` to setup
require "file_line".register()
```

```lua
-- same as passing `on_open = fn` to setup
require "file_line".onOpen(fn)
```

```lua
-- same as passing `enable_gf = opts` to setup
require "file_line".enableGf(opts)
```

[^1]: Which is itself a fork of [bogado's file-line](https://github.com/bogado/file-line).
