vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	command = "set nopaste",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "markdown" },
	callback = function()
		vim.opt.conceallevel = 0
	end,
})
