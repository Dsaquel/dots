return {
	{
		"danymat/neogen",
		keys = {
			{
				"<leader>cc",
				function()
					require("neogen").generate({})
				end,
				desc = "Neogen Comment",
			},
		},
		opts = { snippet_engine = "luasnip" },
	},

	{
		"nvim-mini/mini.bracketed",
		event = "BufReadPost",
		config = function()
			local bracketed = require("mini.bracketed")
			bracketed.setup({
				file = { suffix = "" },
				window = { suffix = "" },
				quickfix = { suffix = "" },
				yank = { suffix = "" },
				treesitter = { suffix = "n" },
			})
		end,
	},

	{
		"monaqa/dial.nvim",
		enabled = false,
	},

	{
		"nvim-mini/mini.surround",
		event = "BufReadPost",
		opts = {
			mappings = {
				add = "gsa",
				delete = "gsd",
				find = "gsf",
				find_left = "gsF",
				highlight = "gsh",
				replace = "gsr",
				update_n_lines = "gsn",
			},
		},
	},

	{
		"hedyhli/outline.nvim",
		keys = { { "<leader>cs", "<cmd>Outline<cr>", desc = "Symbols Outline" } },
		cmd = "Outline",
		opts = {
			position = "right",
		},
	},

	{
		"folke/snacks.nvim",
		opts = {
			scroll = { enabled = false },
			indent = { enabled = true },
			words = { enabled = true },
			lazygit = { enabled = true },
			gitbrowse = { enabled = true },
			scratch = { enabled = true },
		},
		keys = {
			{ "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
			{ "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse" },
			{ "<leader>.", function() Snacks.scratch() end, desc = "Scratch Buffer" },
			{ "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
		},
	},
}
