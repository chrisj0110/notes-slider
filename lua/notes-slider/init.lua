---@class Config
---@field scratch_file_prefix string|nil default notes file prefix
---@field scratch_file_extension string|nil default notes file extension
---@field scratch_file_dir string|nil default dir to save notes file
local M = {}

---@type string
local scratch_file_prefix = 'scratch-'
---@type string
local scratch_file_extension = 'txt'
---@type string
local scratch_file_dir = os.getenv("HOME") or "~"

---Set values based on user's configuration
---@param config Config
function M.setup(config)
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

---@param scratch_file_name string inner part of the file name - can be tmux session name, or custom value
local function get_scratch_file(scratch_file_name)
    return scratch_file_dir .. "/" .. scratch_file_prefix .. scratch_file_name .. "." .. scratch_file_extension
end

---open in the current the window the file name generated from tmux session name
function M.open_notes_using_tmux_session_name()
    M.open_notes(get_tmux_session_name())
end

---open the notes file in the current window
---@param scratch_file_name string inner part of the file name - can be tmux session name, or custom value
function M.open_notes(scratch_file_name)
    vim.cmd('e ' .. get_scratch_file(scratch_file_name))
end

return M
