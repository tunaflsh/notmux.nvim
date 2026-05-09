vim.api.nvim_create_user_command(
  'Detach',
  function(a)
    if #a.fargs == 0 and not vim.g.servername then
      vim.notify('Missing name', vim.log.levels.ERROR)
      return
    end

    local servername = vim.fn.stdpath('run')..'/'..a.args
    if #a.fargs == 1 and servername ~= vim.g.servername then
      local obj = vim.system({'ln', '-s', vim.v.servername, servername}):wait()
      if 0 < obj.code then
        vim.notify(obj.stderr, vim.log.levels.ERROR)
        return
      end
      vim.g.servername = servername
      local gid = vim.api.nvim_create_augroup('vimrc-detach', { clear = true })
      vim.api.nvim_create_autocmd('VimLeave', { command = '!rm '..servername, group = gid })
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
    local run = vim.fn.stdpath('run')

    if #a.fargs == 1 then
      local servername = vim.uv.fs_realpath(run..'/'..a.args)
      if servername:match('nvim.(%d+).(%d+)') then
        vim.cmd.connect({ servername, bang = not vim.g.servername })
      end
    end

    local scanner = vim.uv.fs_scandir(run)
    while scanner do
      local name, type = vim.uv.fs_scandir_next(scanner)
      if not name then break end
      if type == 'link' then
        local servername = vim.uv.fs_realpath(run..'/'..name)
        if servername:match('nvim.(%d+).(%d+)') then
          vim.cmd.connect({ servername, bang = not vim.g.servername })
        end
      end
    end

    vim.notify('No socket to attach to', vim.log.levels.ERROR)
  end,
  {
    nargs = '?',
    desc = 'attach to a socket after it was :Detach',
  })
