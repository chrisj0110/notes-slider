---@class Config
---@field tag string|nil custom tag to use
---@field auto_save boolean|nil whether to save the buffer once tweaking it
---@field horizontal_split_size integer|nil how tall the horizontal notes buffer is
---@field vertical_split_size integer|nil how wide the vertical notes buffer is
---@field scratch_file_prefix string|nil default notes file prefix
---@field scratch_file_extension string|nil default notes file extension
---@field scratch_file_dir string|nil default dir to save notes file
local M = {}

---@type integer
local horizontal_split_size = 15
---@type integer
local vertical_split_size = 70
---@type string
local scratch_file_prefix = 'scratch-'
---@type string
local scratch_file_extension = 'txt'
---@type string
local scratch_file_dir = os.getenv("HOME") or "~"

---Set values based on user's configuration
---@param config Config
function M.setup(config)
    if config and config.horizontal_split_size then
        horizontal_split_size = config.horizontal_split_size
    end
    if config and config.vertical_split_size then
        vertical_split_size = config.vertical_split_size
    end

    if config and config.scratch_file_prefix then
        scratch_file_prefix = config.scratch_file_prefix
    end

    if config and config.scratch_file_extension then
        scratch_file_extension = config.scratch_file_extension
    end

    if config and config.scratch_file_dir then
        scratch_file_dir = config.scratch_file_dir
    end
end

vim = vim

-- Save cursor position per buffer
---@type table<integer, { [1]: integer, [2]: integer}>
local cursor_positions = {}

---get name of the current tmux session, or empty string
---@return string
local function get_tmux_session_name()
    -- Run the tmux command to get the session name
    ---@type file*?
    local handle = io.popen("tmux display-message -p '#S'")
    if handle == nil then
        return ""
    end
    ---@type string
    local session_name = handle:read("*a")
    handle:close()

    -- Trim any trailing whitespace
    session_name = session_name:gsub("%s+", "")
    return session_name
end

---toggle the window open/closed with the file name generated from tmux session name
---@param vertical boolean whether it's a vertical split or horizontal split
---@param after boolean whether the notes buffer will come below/right of the current buffer
function M.toggle_scratch_using_tmux_name(vertical, after)
    M.toggle_scratch(vertical, after, get_tmux_session_name())
end

---open a vertical split
---@param file_or_buf string file name or buffer number (string)
---@param is_buf boolean whether file_or_buf is a buffer or not
---@param after boolean whether the notes buffer will come below/right of the current buffer
---@param split_size integer the size of the window to open the notes buffer in
local function open_vertical_split(file_or_buf, is_buf, after, split_size)
    ---@type boolean
    local original_splitright = vim.o.splitright
    if after then
        vim.cmd('set splitright')
    else
        vim.cmd('set nosplitright')
    end

    if is_buf then
        vim.cmd('vsplit | buffer' .. file_or_buf)
    else
        vim.cmd('vsplit ' .. file_or_buf)
    end

    if after and not original_splitright then
        -- if after=true and it was nosplitright then set it to nosplitright
        vim.cmd('set nosplitright')
    elseif not after and original_splitright then
        -- if after=false and it was splitright then set it to splitright
        vim.cmd('set splitright')
    end

    vim.cmd('vertical resize ' .. split_size)
end

---open a horizontal split
---@param file_or_buf string file name or buffer number (string)
---@param is_buf boolean whether file_or_buf is a buffer or not
---@param after boolean whether the notes buffer will come below/right of the current buffer
---@param split_size integer the size of the window to open the notes buffer in
local function open_horizontal_split(file_or_buf, is_buf, after, split_size)
    ---@type boolean
    local original_splitbelow = vim.o.splitbelow
    if after then
        vim.cmd('set splitbelow')
    else
        vim.cmd('set nosplitbelow')
    end

    if is_buf then
        vim.cmd('split | buffer ' .. file_or_buf)
    else
        vim.cmd('split ' .. file_or_buf)
    end

    if after and not original_splitbelow then
        -- if after=true and it was nosplitbelow then set it to nosplitbelow
        vim.cmd('set nosplitbelow')
    elseif not after and original_splitbelow then
        -- if after=false and it was splitbelow then set it to splitbelow
        vim.cmd('set splitbelow')
    end

    vim.cmd('resize ' .. split_size)
end

---toggle open/closed the notes window
---@param vertical boolean whether it's a vertical split or horizontal split
---@param after boolean whether the notes buffer will come below/right of the current buffer
---@param scratch_file_name string inner part of the file name - can be tmux session name, or custom value
function M.toggle_scratch(vertical, after, scratch_file_name)
    local scratch_file = scratch_file_dir .. "/" .. scratch_file_prefix .. scratch_file_name .. "." .. scratch_file_extension

    ---@type integer
    local buf = vim.fn.bufnr(scratch_file)
    if buf == -1 then
        if vertical then
            open_vertical_split(scratch_file, false, after, vertical_split_size)
        else
            open_horizontal_split(scratch_file, false, after, horizontal_split_size)
        end
    else
        -- Save cursor position before closing the buffer
        if vim.api.nvim_buf_is_loaded(buf) then
            cursor_positions[buf] = vim.api.nvim_win_get_cursor(0)
        end

        -- Close the window containing the scratch file if it's open
        ---@type integer[]
        local wins = vim.api.nvim_list_wins()
        for _, win in ipairs(wins) do
            if vim.api.nvim_win_get_buf(win) == buf then
                vim.cmd('bdelete ' .. buf)
                return
            end
        end
        -- if the buffer exists but not in a window, open in a new split
        if vertical then
            open_vertical_split(tostring(buf), true, after, vertical_split_size)
        else
            open_horizontal_split(tostring(buf), true, after, horizontal_split_size)
        end
    end

    -- Restore cursor position if it was saved
    if vim.api.nvim_buf_is_loaded(buf) and cursor_positions[buf] then
        if cursor_positions[buf][1] > vim.api.nvim_buf_line_count(buf) then
            -- it wants to go to a line that is greater than the number of lines in the buffer, so go to the last line
            vim.api.nvim_win_set_cursor(0, {vim.api.nvim_buf_line_count(buf), 0})
        else
            vim.api.nvim_win_set_cursor(0, cursor_positions[buf])
        end
    end
end

return M
