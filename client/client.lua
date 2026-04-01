ConsoleOpen = false
ArcadeSessionTimer = nil  -- holds the active arcade session thread

function DestroyProp(entity)
	if not entity or not DoesEntityExist(entity) then return end
	SetEntityAsMissionEntity(entity, true, true)
	Wait(5)
	DetachEntity(entity, true, true)
	Wait(5)
	DeleteEntity(entity)
	DeleteObject(entity)
	ExecuteCommand("propstuck")
end

function SafeDestroyFameboyProp()
	if FameboyProp then
		DestroyProp(FameboyProp)
		FameboyProp = nil
	end
end

function OpenConsoleMenu(listGames, console_)
	local FameBoy = {}
	local console = console_
	local index = 0
	for _, value in pairs(listGames) do
		index = index + 1
		FameBoy[#FameBoy + 1] = {
			title = value.name,
			event = "bostra-fameboy:client:startGame",
			icon = "gamepad",
			args = {
				game = value.link,
				gpu = console.consoleGPU,
				cpu = console.consoleCPU,
			},
		}
	end
	lib.registerContext({
		id = "arcade_menu",
		title = "Fame Boy:",
		icon = "gamepad",
		iconColor = "#ff0000",
		onExit = function()
			ClearPedTasks(PlayerPedId())
			SafeDestroyFameboyProp()
		end,
		options = FameBoy,
	})
	lib.showContext("arcade_menu")
end

-- Shows a pricing menu for arcade machines, then charges the player server-side
-- before opening the game list. Items bypass this entirely.
function OpenArcadePricingMenu(console)
	local options = {}
	for _, tier in ipairs(Config.ArcadePricing) do
		local capturedTier = tier  -- capture for closure
		options[#options + 1] = {
			title = capturedTier.label,
			icon = "coins",
			onSelect = function()
				-- Ask the server to charge the player; server responds with success/fail
				TriggerServerEvent(
					"bostra-fameboy:server:payArcade",
					capturedTier.price,
					capturedTier.duration
				)
			end,
		}
	end

	lib.registerContext({
		id = "arcade_pricing_menu",
		title = "🕹️ Arcade Machine",
		icon = "gamepad",
		iconColor = "#ffcc00",
		options = options,
	})
	lib.showContext("arcade_pricing_menu")

	-- Store console so the server callback can use it
	ArcadePendingConsole = console
end

-- Called by the server once payment succeeds; starts the session with a timer
RegisterNetEvent("bostra-fameboy:client:arcadePaySuccess", function(duration)
	if not ArcadePendingConsole then return end
	local console = ArcadePendingConsole
	ArcadePendingConsole = nil

	StartScene("arcade")
	OpenConsoleMenu(console.consoleType, console)

	-- Kill any existing session timer
	if ArcadeSessionTimer then
		ArcadeSessionTimer = nil
	end

	-- Countdown: close the arcade when time runs out
	ArcadeSessionTimer = true
	CreateThread(function()
		local endTime = GetGameTimer() + (duration * 1000)
		while ArcadeSessionTimer do
			Wait(1000)
			local remaining = math.floor((endTime - GetGameTimer()) / 1000)
			if remaining <= 0 then
				break
			end
			-- Show a warning 60 s and 30 s before time is up
			if remaining == 60 or remaining == 30 then
				lib.notify({
					title = "Arcade",
					description = remaining .. " seconds remaining on your session!",
					type = "warning",
					duration = 5000,
				})
			end
		end
		-- Time up — close the arcade
		if ArcadeSessionTimer then
			ArcadeSessionTimer = nil
			lib.notify({
				title = "Arcade",
				description = "Your arcade session has ended.",
				type = "inform",
				duration = 5000,
			})
			TriggerEvent("bostra-fameboy:close:console")
		end
	end)
end)

-- Called by the server when the player can't afford the session
RegisterNetEvent("bostra-fameboy:client:arcadePayFail", function()
	lib.notify({
		title = "Arcade",
		description = "You don't have enough money!",
		type = "error",
		duration = 4000,
	})
end)

function StartScene(type)
	if type == "console" then
		local model = "fameboy"
		lib.requestAnimDict("amb@code_human_wander_texting_fat@male@base")
		lib.requestModel(model)
		-- Destroy any existing prop before creating a new one
		SafeDestroyFameboyProp()
		FameboyProp = CreateObject(model, GetEntityCoords(PlayerPedId()), true, true, false)
		AttachEntityToEntity(FameboyProp,PlayerPedId(),90,-0.012811991906801,-0.0047054325280712,-0.062918639160292,0,0,0,true,true,false,true,1,true)
		TaskPlayAnim(PlayerPedId(),"amb@code_human_wander_texting_fat@male@base","static",8.0,8.0,-1,1,0,false,false,false)
		ConsoleOpen = true
	elseif type == "arcade" then
		lib.requestAnimDict("anim_casino_a@amb@casino@games@arcadecabinet@maleright")
		TaskPlayAnim(PlayerPedId(),"anim_casino_a@amb@casino@games@arcadecabinet@maleright","insert_coins",8.0,8.0,-1,1,0,false,false,false)
		Wait(2700)
		TaskPlayAnim(PlayerPedId(),"anim_casino_a@amb@casino@games@arcadecabinet@maleright","playidle_v2",8.0,8.0,-1,1,0,false,false,false)
		ConsoleOpen = true
	end
end

RegisterNetEvent("bostra-fameboy:client:startGame", function(data)
	ConsoleOpen = true
	SendNUIMessage({
		type = "on",
		game = data.game,
		gpu = data.gpu,
		cpu = data.cpu,
	})
	SetNuiFocus(true, true)
end)

-- Items open directly (free, no timer)
RegisterNetEvent("bostra-fameboy:open:console", function(console, type)
	StartScene(type)  -- FIX: removed duplicate StartScene call that leaked a second prop
	OpenConsoleMenu(console.consoleType, console)
end)

-- Arcade machines show the pricing menu first
RegisterNetEvent("bostra-fameboy:open:arcade", function(console)
	OpenArcadePricingMenu(console)
end)

RegisterNetEvent("bostra-fameboy:close:console", function()
	-- Cancel any running session timer
	ArcadeSessionTimer = nil

	SendNUIMessage({
		type = "off",
		game = "",
	})
	SetNuiFocus(false, false)
	local ped = PlayerPedId()
	EnableAllControlActions(0)
	EnableAllControlActions(1)
	EnableAllControlActions(2)
	ClearPedTasks(ped)
	-- FIX: single safe call replaces the double/conditional DestroyProp pattern
	SafeDestroyFameboyProp()
	ConsoleOpen = false
end)

RegisterNUICallback("exit", function()
	-- FIX: close:console handles everything including prop cleanup; no extra call needed
	TriggerEvent("bostra-fameboy:close:console")
end)

local retroconsole = {
	consoleType = Config.RetroMachine,
	consoleGPU = Config.GPUList[1],
	consoleCPU = Config.CPUList[1],
}

if Config.useArcades then
	for _, arcadeData in ipairs(Config.arcadeModelHashes) do
		local modelHash = arcadeData.hash
		local coords = arcadeData.coords
		local heading = arcadeData.heading
		if Config.Target == "qb" then
			if arcadeData.coords ~= nil then
				exports["qb-target"]:AddBoxZone("arcade_" .. modelHash, coords, 1.5, 1.6, {
					name = "arcade_" .. modelHash,
					heading = heading,
					debugPoly = Config.Debug,
					minZ = coords.z - 1.0,
					maxZ = coords.z + 1.0,
				}, {
					options = {
						{
							num = 1,
							icon = "fas fa-gamepad",
							label = "Play The Arcade Games",
							targeticon = "fas fa-gamepad",
							action = function(entity)
								if IsPedAPlayer(entity) then
									return false
								end
								-- Use pricing flow for arcade machines
								TriggerEvent("bostra-fameboy:open:arcade", retroconsole)
							end,
						},
					},
					distance = 2.5,
				})
			else
				exports["qb-target"]:AddTargetModel(modelHash, {
					options = {
						{
							num = 1,
							icon = "fas fa-gamepad",
							label = "Play The Arcade Games",
							targeticon = "fas fa-gamepad",
							action = function(entity)
								if IsPedAPlayer(entity) then
									return false
								end
								-- Use pricing flow for arcade machines
								TriggerEvent("bostra-fameboy:open:arcade", retroconsole)
							end,
						},
					},
					distance = 2.5,
				})
			end
		elseif Config.Target == "ox" then
			if arcadeData.coords ~= nil then
				local params = {
					coords = coords,
					size = { 1.0, 1.0, 4.0 },
					rotation = heading,
					debug = Config.Debug,
					drawSprite = false,
					options = {
						label = "Play The Arcade Games",
						name = "arcade_" .. modelHash,
						icon = "fas fa-gamepad",
						distance = 2.5,
						onExit = function()
							ClearPedTasks(PlayerPedId())
						end,
						onSelect = function()
							-- Use pricing flow for arcade machines
							TriggerEvent("bostra-fameboy:open:arcade", retroconsole)
						end,
					},
				}
				exports.ox_target:addBoxZone(params)
			else
				local options = {
					{
						label = "Play The Arcade Games",
						name = "arcade_" .. modelHash,
						icon = "fas fa-gamepad",
						iconColor = "#DA9110",
						distance = 2.5,
						onExit = function()
							ClearPedTasks(PlayerPedId())
						end,
						onSelect = function()
							-- Use pricing flow for arcade machines
							TriggerEvent("bostra-fameboy:open:arcade", retroconsole)
						end,
					},
				}
				exports.ox_target:addModel(modelHash, options)
			end
		end
	end
end

AddEventHandler("onResourceStop", function(resource)
	if resource == GetCurrentResourceName() then
		ArcadeSessionTimer = nil
		TriggerEvent("bostra-fameboy:close:console")
	end
end)