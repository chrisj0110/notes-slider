local M = {}

local horizontal_split_size = '15'
local vertical_split_size = '70'
local scratch_file_prefix = 'scratch-'
local scratch_file_extension = 'txt'
local scratch_file_dir = os.getenv("HOME")

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
local cursor_positions = {}

local function get_tmux_session_name()
    -- Run the tmux command to get the session name
    local handle = io.popen("tmux display-message -p '#S'")
    if handle == nil then
        return ""
    end
    local session_name = handle:read("*a")
    handle:close()

    -- Trim any trailing whitespace
    session_name = session_name:gsub("%s+", "")
    return session_name
end

function M.toggle_scratch_using_tmux_name(vertical)
    M.toggle_scratch(vertical, get_tmux_session_name())
end

function M.toggle_scratch(vertical, scratch_file_name)
    local scratch_file = scratch_file_dir .. "/" .. scratch_file_prefix .. scratch_file_name .. "." .. scratch_file_extension

    local buf = vim.fn.bufnr(scratch_file)
    if buf == -1 then
        if vertical then
            vim.cmd('set splitright')
            vim.cmd('vsplit ' .. scratch_file)
            vim.cmd('set nosplitright')
            vim.cmd('vertical resize ' .. vertical_split_size)
        else
            vim.cmd('silent! split ' .. scratch_file)
            vim.cmd('resize ' .. horizontal_split_size)
        end
    else
        -- Save cursor position before closing the buffer
        if vim.api.nvim_buf_is_loaded(buf) then
            cursor_positions[buf] = vim.api.nvim_win_get_cursor(0)
        end

        -- Close the window containing the scratch file if it's open
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == buf then
                vim.cmd('bdelete ' .. buf)
                return
            end
        end
        -- if the buffer exists but not in a window, open in a new split
        if vertical then
            vim.cmd('set splitright')
            vim.cmd('vsplit | buffer ' .. buf)
            vim.cmd('set nosplitright')
            vim.cmd('vertical resize ' .. vertical_split_size)
        else
            vim.cmd('split | buffer ' .. buf)
            vim.cmd('resize ' .. horizontal_split_size)
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
