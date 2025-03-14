local M = {}

-- Helper function to execute shell commands and capture the output
local function execute(cmd)
  local handle = io.popen(cmd)
  local result = handle:read '*a'
  handle:close()
  return result:gsub('\n$', '') -- Remove trailing newline
end

-- Function to generate the GitHub URL
function M.get_github_url(start_line, end_line)
  local filepath = vim.fn.expand '%:p' -- Full path to the current file
  if filepath == '' then
    print 'No file in the buffer.'
    return
  end

  local git_root = execute 'git rev-parse --show-toplevel'
  if git_root == '' then
    print 'Not a Git repository.'
    return
  end

  local remote_url = execute 'git config --get remote.origin.url'
  if not remote_url:match 'github.com' then
    print 'Remote is not hosted on GitHub.'
    return
  end

  -- Convert remote URL to HTTPS format if needed
  remote_url = remote_url:gsub('.git$', '')
  remote_url = remote_url:gsub(':', '/'):gsub('git@github.com', 'https://github.com')

  local relative_path = filepath:sub(#git_root + 2) -- Relative path to the file from the Git root
  local branch_name = execute 'git rev-parse --abbrev-ref HEAD'

  if branch_name == 'HEAD' then
    branch_name = execute 'git rev-parse HEAD' -- Use commit hash for detached HEAD
  end

  local github_url
  -- If lines are selected, create a URL with the range
  if start_line ~= end_line then
    github_url = string.format('%s/blob/%s/%s#L%d-L%d', remote_url, branch_name, relative_path, start_line, end_line)
  else
    -- Otherwise, create a URL for the single line
    github_url = string.format('%s/blob/%s/%s#L%d', remote_url, branch_name, relative_path, start_line)
  end

  print('GitHub URL: ' .. github_url)
end

-- Command to display the GitHub URL with the -range attribute
function M.setup()
  vim.api.nvim_create_user_command('ShowGitHubURL', function(opts)
    local start_line = opts.line1
    local end_line = opts.line2
    M.get_github_url(start_line, end_line)
  end, { range = true })
end

return M
