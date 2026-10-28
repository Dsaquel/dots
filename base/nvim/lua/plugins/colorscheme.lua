local flavours = { dark = "mocha", light = "latte" }
local path = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/nvim-flavour"

local function read_world()
  local fd = io.open(path, "r")
  local world = fd and fd:read("*l")
  if fd then fd:close() end
  return flavours[world] and world or "light"
end

local function apply()
  local flavour = flavours[read_world()]
  if vim.g.colors_name ~= "catppuccin-" .. flavour then
    pcall(vim.cmd.colorscheme, "catppuccin-" .. flavour)
  end
end

local function watch()
  local w = vim.uv.new_fs_event()
  if not w then return end
  local pending = false
  w:start(vim.fs.dirname(path), {}, function(_, name)
    if name ~= "nvim-flavour" or pending then return end
    pending = true
    vim.defer_fn(function()
      pending = false
      apply()
    end, 60)
  end)
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      transparent_background = true,
      float = { transparent = false, solid = false },
      styles = { comments = { "italic" }, conditionals = {} },
    },
    config = function(_, opts)
      require("catppuccin").setup(vim.tbl_deep_extend("force", opts, { flavour = flavours[read_world()] }))
      apply()
      watch()
      vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, { callback = apply })
    end,
  },
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = true,
    priority = 100,
    opts = function()
      return { transparent = true }
    end,
  },
}
