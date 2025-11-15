local status, flutter_dev_tools = pcall(require, "flutter-tools.dev_tools")
if not status then
	vim.notify("flutter-tools.nvim not found.")
	return
end

local utils = require("flutter-tools.utils")

local function splitUrl(url)
	local parts = {}
	for part in url:gmatch("[^?]+") do
		table.insert(parts, part)
	end
	return parts
end

local M = {}

-- Backend configuration for Flutter Navigation
local config = {
	backend_binary = "flutter-vm-service",
}

local backend_job_id = nil
local widgetSelectionMode = false

function M.setup(opts)
	if opts then
		config = vim.tbl_deep_extend("force", config, opts)
	end
end

function M.stop_backend()
	if backend_job_id then
		vim.fn.jobstop(backend_job_id)
		vim.notify("Stopped Flutter navigation backend")
		backend_job_id = nil
	end
end

function M.open_network_tab()
	local profiler_url = flutter_dev_tools.get_profiler_url()
	if profiler_url == nil then
		vim.notify("profiler_url is nil")
		return
	end
	local parts = splitUrl(profiler_url)
	local url = parts[1]
	local query = parts[2]
	local network_tab_url = url .. "network?" .. query
	vim.notify("Opening network tab: " .. network_tab_url)
	vim.fn.jobstart({ utils.open_command(), network_tab_url }, { detach = true })
end

function M.open_debugger_tab()
	-- split at before the first question mark
	local profiler_url = flutter_dev_tools.get_profiler_url()
	if profiler_url == nil then
		vim.notify("profiler_url is nil")
		return
	end
	local parts = splitUrl(profiler_url)
	local url = parts[1]
	local query = parts[2]
	local debugger_tab_url = url .. "debugger?" .. query
	vim.notify("Opening network tab: " .. debugger_tab_url)
	vim.fn.jobstart({ utils.open_command(), debugger_tab_url }, { detach = true })
end

function M.open_provider_tab()
	local profiler_url = flutter_dev_tools.get_profiler_url()
	if profiler_url == nil then
		vim.notify("profiler_url is nil")
		return
	end
	local parts = splitUrl(profiler_url)
	local url = parts[1]
	local query = parts[2]
	local provider_tab_url = url .. "provider_ext?" .. query
	vim.notify("Opening network tab: " .. provider_tab_url)
	vim.fn.jobstart({ utils.open_command(), provider_tab_url }, { detach = true })
end

function M.open_inspector_tab()
	local profiler_url = flutter_dev_tools.get_profiler_url()
	if profiler_url == nil then
		vim.notify("profiler_url is nil")
		return
	end
	local parts = splitUrl(profiler_url)
	local url = parts[1]
	local query = parts[2]
	local inspector_tab_url = url .. "inspector?" .. query
	vim.notify("Opening inspector tab: " .. inspector_tab_url)
	vim.fn.jobstart({ utils.open_command(), inspector_tab_url }, { detach = true })
end

function M.toggleWidgetSelctionMode()
	if backend_job_id then
		if widgetSelectionMode then
			vim.fn.chansend(backend_job_id, "flutter.disableWidgetSelection")
		else
			vim.fn.chansend(backend_job_id, "flutter.enableWidgetSelection")
		end
	end
end

local function extract_vm_service_url(profiler_url)
	local uri = profiler_url:match("[?&]uri=([^&]+)")
	return uri
end

function M.start_backend()
	local profiler_url = flutter_dev_tools.get_profiler_url()
	if not profiler_url then
		vim.notify("profiler_url is nil", vim.log.levels.ERROR)
		return
	end
	local vm_service_url = extract_vm_service_url(profiler_url)
	if not vm_service_url then
		vim.notify("Could not extract vm-service URL from profiler_url", vim.log.levels.ERROR)
		return
	end

	-- Get Neovim server socket path
	vim.fn.serverstart('/tmp/nvim.flutter')
	local nvim_server = vim.v.servername
	if not nvim_server or nvim_server == "" then
		vim.notify(
			"Warning: Neovim server name not set. Push mode (auto-navigation) won't work. Start nvim with --listen /tmp/nvim.sock",
			vim.log.levels.WARN)
		nvim_server = "/tmp/nvim.flutter"
	end

	local binary = config.backend_binary or "flutter-vm-service"
	local cmd = {
		binary,
		"--url", vm_service_url,
	}
	vim.notify("Starting Flutter navigation backend with: " .. table.concat(cmd, " "))

	if backend_job_id then
		M.stop_backend()
	end

	backend_job_id = vim.fn.jobstart(cmd, {
		-- detach = true,
		on_exit = function(_, code)
			if code == 0 then
				vim.notify("Flutter navigation backend started successfully", vim.log.levels.INFO)
			else
				vim.notify("Failed to start Flutter navigation backend", vim.log.levels.ERROR)
			end
		end
	})
end

function M.create_commands()
	vim.api.nvim_create_user_command("FlutterToggleWidgetSelection", M.toggleWidgetSelctionMode, {
		desc = "Toggle widget selection mode"
	})

	vim.api.nvim_create_user_command("FlutterBackendStart", M.start_backend, {
		desc = "Start Flutter navigation Go backend"
	})
end

return M
