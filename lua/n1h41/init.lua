local flutter = require("n1h41.flutter")

local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>nn", flutter.open_network_tab)
	vim.keymap.set("n", "<leader>nd", flutter.open_debugger_tab)
	vim.keymap.set("n", "<leader>np", flutter.open_provider_tab)
	vim.keymap.set("n", "<leader>ni", flutter.open_inspector_tab)
	vim.keymap.set("n", "<leader>fw", flutter.toggleWidgetSelctionMode, { desc = "Toggle widget selection mode" })
	vim.keymap.set("n", "<leader>fb", flutter.start_backend, { desc = "Start Flutter navigation Go backend" })
	vim.keymap.set("n", "<leader>fs", flutter.stop_backend, { desc = "Stop Flutter navigation Go backend" })
	flutter.create_commands()

	vim.api.nvim_create_autocmd("VimLeavePre", {
		callback = flutter.stop_backend,
		desc = "Stop Flutter backend on Neovim exit"
	})
end

return M
