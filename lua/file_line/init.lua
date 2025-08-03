local M = {}

---@alias file_line.OnOpenFn  fun(name:string, line:number, col:number, bufnr:number):nil

---@alias file_line.IsFnameOpts "force"|true|false

---@class file_line.Options
local default_opts = {
    register = true,
    ---@type file_line.OnOpenFn?
    on_open = nil,
    ---@type file_line.IsFnameOpts?
    enable_isfname = false,
}

---comment
---@param opts any
---@return file_line.Options
local function applyDefaultOpts(opts)
    if not ({ ["table"] = true, ["nil"] = true })[type(opts)] then
        error("Options must be a table (or nil)")
    end
    if not opts then opts = {} end
    return vim.tbl_deep_extend("keep", default_opts, opts)
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
function M.openFileOnLine(name, line, col, winnr)
    name = vim.fn.fnameescape(name)
    if line == nil and col == nil then return false end
    local real_line = tonumber(line) or 0
    local real_col = tonumber(col) or 0
    if not vim.fn.filereadable(name) then return end

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
    local group = vim.api.nvim_create_augroup("file_line", {})
    vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
        group = group,
        pattern = "*",
        nested = true,
        callback = function(ev)
            local old_alt = vim.fn.bufnr('#')
            if M.openFileOnLine(M.filenameLineCol(ev.file)) then
                vim.cmd("bwipeout " .. ev.buf)
                if old_alt >= 0 then vim.fn.setreg('#', old_alt) end
            end
        end
    })
end

---@param opts file_line.IsFnameOpts?
function M.enableIsfname(opts)
    if not opts then return false end

    if vim.opt.isfname._info ~= vim.o.isfname and opts ~= "force" then return end
    vim.opt.isfname:append(":")
end

---@param opts file_line.Options
function M.setup(opts)
    opts = applyDefaultOpts(opts)
    if opts.register then M.register() end
    if opts.on_open then M.onOpen(opts.on_open) end
    M.enableIsfname(opts.enable_isfname)
end

return M
