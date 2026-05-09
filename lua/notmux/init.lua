local function _error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end


local cache = vim.fn.stdpath('cache')..'/notmux.nvim/'
local suc, msg, err = vim.uv.fs_mkdir(cache, tonumber('755', 8))
if not suc and err ~= 'EEXIST' then _error('notmux: '..msg) return end


local function get_sessions()
  local dir, msg, err = vim.uv.fs_opendir(cache)
  if not dir then return nil, msg, err end

  local files = {}
  while true do
    local entries = dir:readdir()
    if not entries then break end
    vim.list_extend(files, entries)
  end
  dir:closedir()

  return vim.iter(files):map(function(entry)
    local name, type = entry.name, entry.type
    if 'link' ~= type then return nil end

    path = cache..name
    real, msg, err = vim.uv.fs_realpath(path)
    if real and real:match('nvim.(%d+).(%d+)') then
      return name, real
    end

    if err == 'ENOENT' then
      suc, msg, err = vim.uv.fs_unlink(path)
    end
    if not suc then _error(msg) end
    return nil
  end)
  :filter(function(name, real) return name end)
end


local function clean_broken_symlinks()
  get_sessions():last()
end


vim.api.nvim_create_user_command(
  'Sessions',
  function()
    for name, session in get_sessions() do
      print(name)
    end
  end,
  {
    nargs = 0,
    desc = 'List sessions'
  }
)


vim.api.nvim_create_user_command(
  'Detach',
  function(a)
    if 0 == #a.fargs and not vim.g.servername then
      _error('Missing name') return
    elseif 1 == #a.fargs then
      local name = cache..a.args

      if vim.g.servername then
        suc, msg, err = vim.uv.fs_rename(vim.g.servername, name)
      else
        clean_broken_symlinks()
        suc, msg, err = vim.uv.fs_symlink(vim.v.servername, name)
      end
      if not suc then _error(msg) return end

      vim.g.servername = name
      local gid = vim.api.nvim_create_augroup('notmux', { clear = true })
      vim.api.nvim_create_autocmd('VimLeave', { command = '!rm '..name, group = gid })
    end

    vim.cmd.detach()
  end,
  {
    nargs = '?',
    desc = 'name the socket and detach',
  })


vim.api.nvim_create_user_command(
  'Attach',
  function(a)
    local sessions, msg, err = get_sessions()
    if not sessions then _error(msg) return end

    local name, session
    if #a.fargs == 1 then
      name, session = sessions:find(function(name, real)
        return name == a.args
      end)
      if not session then _error('No session '..a.args) return end
    else
      name, session = sessions:next()
      if not name then
        _error('No sessions') return
      elseif sessions:next() then
        _error('More than one session. Please specify') return
      end
    end

    vim.cmd.connect({ session, bang = not vim.g.servername })
  end,
  {
    nargs = '?',
    desc = 'attach to a socket after it was :Detach',
  })
