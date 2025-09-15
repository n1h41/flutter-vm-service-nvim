local flutter = require("n1h41.flutter")

local M = {}

function M.setup()
  vim.keymap.set("n", "<leader>ne", flutter.convert_class_name_to_entity_class_name)
  vim.keymap.set("n", "<leader>nm", flutter.convert_class_name_to_model_class_name)
  vim.keymap.set("n", "<leader>nn", flutter.open_network_tab)
  vim.keymap.set("n", "<leader>nd", flutter.open_debugger_tab)
  vim.keymap.set("n", "<leader>np", flutter.open_provider_tab)
  vim.keymap.set("n", "<leader>fw", flutter.navigate_to_selected_widget, { desc = "Navigate to selected Flutter widget" })
  vim.keymap.set("n", "<leader>fh", flutter.check_health, { desc = "Check Flutter navigation backend health" })
  flutter.create_commands()
end

return M
