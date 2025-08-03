local M = {}

---@alias file_line.OnOpenFn  fun(name:string, line:number, col:number, bufnr:number):nil
---@alias file_line.EnableGF  boolean|{ignore_pat:string[]}|{match_pat:string[]}

---@class file_line.Options
local default_opts = {
    register = true,
    ---@type file_line.OnOpenFn?
    on_open = nil,
    ---@type file_line.EnableGF?
    enable_gf = false,
}

---comment
---@param opts any
---@return file_line.Options
local function applyDefaultOpts(opts)
    if not ({ ["table"] = true, ["nil"] = true })[type(opts)] then
        error("Options must be a table (or nil)")
    end
    if not opts then opts = {} end
    return vim.tbl_deep_extend("force", default_opts, opts)
end

---@type (fun(name:string, line:number, col:number, bufnr:number):nil)?
local _on_open = nil

---Given a file name with line and column numbers, split it into those components
---@param name string
---@return string
---@return string?
---@return string?
function M.filenameLineCol(name)
    -- If the input contains a parenthesis, try the (line) formats.
    if name:find("%(") then
        local file, line, col = name:match("^(.-)%((%d+):(%d+)%)$")
        if file then return file, line, col end

        file, line = name:match("^(.-)%((%d+)%)$")
        if file then return file, line, nil end
        -- Otherwise, if it contains a colon, try the colon-separated formats.
    elseif name:find(":") then
        local file, line, col = name:match("^(.-):(%d+):(%d+)$")
        if file then return file, line, col end

        file, line = name:match("^(.-):(%d+):$")
        if file then return file, line, nil end

        file, line = name:match("^(.-):(%d+)$")
        if file then return file, line, nil end

        return name:sub(1, name:find(":") - 1), nil, nil
    end

    -- No parenthesis or colon found; return the input as the filename.
    return name, nil, nil
end

---Given a file name, line, column and optional buffer, open the file at that location
---@param name string
---@param line string?
---@param col string?
--- Either nil (current window), window id, or a string accepted by winnr()
---@param winnr (string|integer)?
---@return boolean
function M.openFileOnLine(name, line, col, winnr)
    name = vim.fn.fnameescape(name)
    if line == nil and col == nil then return false end
    local real_line = tonumber(line) or 0
    local real_col = tonumber(col) or 0
    if vim.fn.filereadable(name) == 0 then return false end

    if winnr ~= nil then
        if type(winnr) == "string" then winnr = vim.fn.winnr(winnr) end
        vim.api.nvim_set_current_win(winnr)
    end

    vim.cmd("edit " .. name)
    local new_bufnr = vim.fn.bufnr()
    vim.cmd(tostring(real_line))
    vim.cmd("normal!" .. real_col .. "|")
    vim.cmd([[normal! zv]])
    vim.cmd([[normal! zz]])
    -- vim.cmd([[filetype detect]])
    if _on_open ~= nil then _on_open(name, real_line, real_col, new_bufnr) end
    return true
end

---Callback invoked when opening a file with openFileOnLine
---@param cb fun(name:string, line:number, col:number, bufnr:number):nil
function M.onOpen(cb)
    _on_open = cb
end

function M.register()
    local group = vim.api.nvim_create_augroup("file_line_register", {})
    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
        group = group,
        pattern = "*",
        nested = true,
        callback = function(ev)
            -- If this is a name of an existing file, don't try to parse it as a file:line:column name
            if vim.fn.filereadable(ev.file) == 1 then return end
            local old_alt = vim.fn.bufnr('#')
            if M.openFileOnLine(M.filenameLineCol(ev.file)) then
                vim.cmd("bdelete " .. ev.buf)
                if old_alt >= 0 then vim.fn.setreg('#', old_alt) end
            end
        end
    })
end

---@param buf integer?
local function setKeymap(buf)
    vim.keymap.set('n', "gf", "gF",
        {
            desc = "file_line.nvim: use gf to open files to a partucular line",
            buffer = buf,
        })
end

---@param opts file_line.EnableGF?
function M.enableGf(opts)
    if not opts then return end
    if opts == true then
        setKeymap()
        return
    end
    local pat
    if opts.ignore_pat and opts.match_pat then
        error("file_line.nvim: specify ignore_pat or match_pat, not both")
    elseif opts.match_pat then
        pat = opts.match_pat
    elseif opts.ignore_pat then
        pat = vim.iter(opts.ignore_pat)
            :map(function(p) return '{*}' .. '{' .. p .. '}\\@<!' end)
            :totable()
    else
        return
    end
    vim.api.nvim_create_autocmd("BufAdd", {
        group = vim.api.nvim_create_augroup("file_line_enable_gf", { clear = false }),
        pattern = pat,
        callback = function(args) setKeymap(args.buf) end,
    })
end

---@param opts file_line.Options
function M.setup(opts)
    opts = applyDefaultOpts(opts)
    if opts.register then M.register() end
    if opts.on_open then M.onOpen(opts.on_open) end
    M.enableGf(opts.enable_gf)
end

return M
