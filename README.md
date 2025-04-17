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
> * file:line

## Usage


### `register`

When opening new files, jump to the line and column if present at the end of the
file name.

```lua
require "file_line".register()
```

### `filenameLineCol`


Given a file name possibly with line and column on the end, returns them as 3
separate values. `line` and `col` could be `nil` if they were not present in the
file name, they will be numbers otherwise.

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

### `onOpen`

Callback invoked when a file is opened with `openFileOnLine`. `line` and `col`
are numbers, if column was not specified when opening the file is it is set to
0.

```lua
require "file_line".onOpen(function (name, line, col, bufnr)  end)
```



[^1]: Which is itself a fork of [bogado's file-line](https://github.com/bogado/file-line).
