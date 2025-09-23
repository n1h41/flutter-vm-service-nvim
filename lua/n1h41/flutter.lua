local status, flutter_dev_tools = pcall(require, "flutter-tools.dev_tools")
local actions = require('telescope.actions')
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
	backend_host = "localhost",
	backend_port = 8080,
	timeout = 5000, -- 5 seconds
	backend_binary = "/home/n1h41/dev/go/personal/flutter-dtd/flutter-dtd",
}

local backend_job_id = nil

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

function M.convert_class_name_to_model_class_name()
	local word = vim.fn.expand("<cword>")
	local pattern = "\\v(_\\$|\\<)?(" .. word .. ")(\\s|\\;|\\.|FromJson|\\(|\\>|\\?)"
	local replacement = "\\1\\2Model\\3"
	vim.cmd("%s/" .. pattern .. "/" .. replacement .. "/g")
	vim.notify("Converted class name: " .. word .. " --> " .. word .. "Model")
end

function M.convert_class_name_to_entity_class_name()
	local word = vim.fn.expand("<cword>")
	local pattern = "\\v(_\\$|\\<)?(" .. word .. ")(\\s|\\;|\\.|FromJson|\\(|\\>|\\?)"
	local replacement = "\\1\\2Model\\3"
	vim.cmd("%s/" .. pattern .. "/" .. replacement .. "/g")
	vim.notify("Converted class name: " .. word .. " --> " .. word .. "Entity")
end

function M.open_network_tab()
	-- split at before the first question mark
	local profiler_url = flutter_dev_tools.get_profiler_url()
	if profiler_url == nil then
		vim.notify("profiler_url is nil")
		return
	end
	-- split string
	local parts = splitUrl(profiler_url)
	--[[ for part in profiler_url:gmatch("[^?]+") do
    table.insert(parts, part)
  end ]]
	local url = parts[1]
	local query = parts[2]
	-- insert the string 'network' between the url and the query
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
	-- split string
	local parts = splitUrl(profiler_url)
	--[[ for part in profiler_url:gmatch("[^?]+") do
    table.insert(parts, part)
  end ]]
	local url = parts[1]
	local query = parts[2]
	-- insert the string 'debugger' between the url and the query
	local debugger_tab_url = url .. "debugger?" .. query
	vim.notify("Opening network tab: " .. debugger_tab_url)
	vim.fn.jobstart({ utils.open_command(), debugger_tab_url }, { detach = true })
end

function M.open_provider_tab()
	-- split at before the first question mark
	local profiler_url = flutter_dev_tools.get_profiler_url()
	if profiler_url == nil then
		vim.notify("profiler_url is nil")
		return
	end
	-- split string
	local parts = splitUrl(profiler_url)
	--[[ for part in profiler_url:gmatch("[^?]+") do
    table.insert(parts, part)
  end ]]
	local url = parts[1]
	local query = parts[2]
	-- insert the string 'provider' between the url and the query
	local provider_tab_url = url .. "provider_ext?" .. query
	vim.notify("Opening network tab: " .. provider_tab_url)
	vim.fn.jobstart({ utils.open_command(), provider_tab_url }, { detach = true })
end

-- Function to make HTTP request to the Go backend
local function make_request(endpoint, data)
	local url = string.format("http://%s:%d%s", config.backend_host, config.backend_port, endpoint)

	local cmd = {
		"curl",
		"-s",
		"-X", "POST",
		"-H", "Content-Type: application/json",
		"-d", vim.json.encode(data),
		"--max-time", tostring(config.timeout / 1000),
		url
	}

	local result = vim.system(cmd, { text = true }):wait()

	if result.code ~= 0 then
		vim.notify("Failed to connect to Flutter navigation backend", vim.log.levels.ERROR)
		return nil
	end

	local ok, response = pcall(vim.json.decode, result.stdout)
	if not ok then
		vim.notify("Failed to parse response from backend", vim.log.levels.ERROR)
		return nil
	end

	return response
end

function M.check_health()
	local cmd = {
		"curl",
		"-s",
		"--max-time", "3",
		string.format("http://%s:%d/health", config.backend_host, config.backend_port)
	}

	local result = vim.system(cmd, { text = true }):wait()

	if result.code ~= 0 then
		print("❌ Backend not reachable")
		return false
	end

	local ok, response = pcall(vim.json.decode, result.stdout)
	if ok and response.healthy then
		print("✅ Backend healthy, Connected: " .. (response.connected and "Yes" or "No"))
		return true
	else
		print("❌ Backend unhealthy")
		return false
	end
end

function M.navigate_to_selected_widget()
	local response = make_request("/navigate", { action = "get_location" })

	if not response then
		return
	end

	if not response.success then
		vim.notify("No Flutter widget selected: " .. (response.message or "Unknown error"), vim.log.levels.WARN)
		return
	end

	local location = response.location

	if not location or not location.file then
		vim.notify("Invalid location data from backend", vim.log.levels.ERROR)
		return
	end

	local file_path = location.file
	if string.match(file_path, "^file://") then
		file_path = file_path:gsub("^file://", "")
	elseif string.match(file_path, "^file:/") then
		file_path = file_path:gsub("^file:/", "/")
	end

	if vim.fn.filereadable(file_path) == 0 then
		vim.notify("File does not exist: " .. file_path, vim.log.levels.ERROR)
		return
	end

	local lib_pos = string.find(file_path, "/lib/", 1, true)
	local relative_path = string.sub(file_path, lib_pos + 1)

	local current_file_path = vim.fn.expand('%:.')

	if current_file_path ~= relative_path then
		-- Open the file and navigate to the line and column
		require('telescope.builtin').find_files({
			default_text = relative_path,
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = require('telescope.actions.state').get_selected_entry()
					vim.cmd('edit ' .. selection.path)
					vim.api.nvim_win_set_cursor(0, { location.line, location.column - 1 })
				end)
				return true
			end,
		})
		return
	end

	-- Navigate to selected widgets line and column
	vim.fn.cursor(location.line or 1, location.column or 1)
end

-- Helper to extract vm-service URL from profiler_url
local function extract_vm_service_url(profiler_url)
	-- profiler_url format: http://127.0.0.1:9100/?uri=<vm-service-url>
	local uri = profiler_url:match("[?&]uri=([^&]+)")
	return uri
end

-- Function to start the Go backend binary
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
	local binary = config.backend_binary or "flutter_navigation_backend"
	local cmd = { binary, "-vm-service", vm_service_url }
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
	vim.api.nvim_create_user_command("FlutterNavigate", M.navigate_to_selected_widget, {
		desc = "Navigate to selected Flutter widget"
	})

	vim.api.nvim_create_user_command("FlutterHealth", M.check_health, {
		desc = "Check Flutter navigation backend health"
	})

	vim.api.nvim_create_user_command("FlutterBackendStart", M.start_backend, {
		desc = "Start Flutter navigation Go backend"
	})
end

return M
