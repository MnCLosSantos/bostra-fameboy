local retroconsole = {
	consoleType = Config.RetroMachine,
	consoleGPU = Config.GPUList[1],
	consoleCPU = Config.CPUList[1],
}

local gamingconsole = {
	consoleType = Config.GamingMachine,
	consoleGPU = Config.GPUList[1],
	consoleCPU = Config.CPUList[1],
}

local superconsole = {
	consoleType = Config.SuperMachine,
	consoleGPU = Config.GPUList[1],
	consoleCPU = Config.CPUList[1],
}

-- ─────────────────────────────────────────────
--  Arcade payment handler
--  Charges the player for their chosen session
--  tier, then confirms or denies on the client.
-- ─────────────────────────────────────────────
RegisterNetEvent("bostra-fameboy:server:payArcade", function(price, duration)
	local src = source

	if Config.frameworkObj == "QB" then
		local QBCore = exports["qb-core"]:GetCoreObject()
		local Player = QBCore.Functions.GetPlayer(src)
		if not Player then return end

		local cash    = Player.Functions.GetMoney("cash")
		local bank    = Player.Functions.GetMoney("bank")

		if cash >= price then
			Player.Functions.RemoveMoney("cash", price, "arcade-session")
			TriggerClientEvent("bostra-fameboy:client:arcadePaySuccess", src, duration)
		elseif bank >= price then
			Player.Functions.RemoveMoney("bank", price, "arcade-session")
			TriggerClientEvent("bostra-fameboy:client:arcadePaySuccess", src, duration)
		else
			TriggerClientEvent("bostra-fameboy:client:arcadePayFail", src)
		end

	elseif Config.frameworkObj == "ESX" then
		local ESX = exports["es_extended"]:getSharedObject()
		local xPlayer = ESX.GetPlayerFromId(src)
		if not xPlayer then return end

		local money = xPlayer.getMoney()  -- cash wallet

		if money >= price then
			xPlayer.removeMoney(price)
			TriggerClientEvent("bostra-fameboy:client:arcadePaySuccess", src, duration)
		else
			-- Try bank account if cash is short
			local bankAccount = xPlayer.getAccount("bank")
			if bankAccount and bankAccount.money >= price then
				xPlayer.removeAccountMoney("bank", price)
				TriggerClientEvent("bostra-fameboy:client:arcadePaySuccess", src, duration)
			else
				TriggerClientEvent("bostra-fameboy:client:arcadePayFail", src)
			end
		end

	else
		-- No framework: let them play for free (same as items)
		TriggerClientEvent("bostra-fameboy:client:arcadePaySuccess", src, duration)
	end
end)

-- ─────────────────────────────────────────────
--  Framework setup & item / command registration
-- ─────────────────────────────────────────────
if Config.frameworkObj == "QB" then
	QBCore = exports["qb-core"]:GetCoreObject()

	-- /command to test all games as the fameboy advanced console
	QBCore.Commands.Add("testgames", "Test Fameboy", {}, false, function(source)
		local src = source
		TriggerClientEvent("bostra-fameboy:open:console", src, superconsole)
	end, "admin")

	-- Creates 3 types of fameboy consoles (items — free, no timer)
	QBCore.Functions.CreateUseableItem("retrofameboy", function(src, item)
		TriggerClientEvent("bostra-fameboy:open:console", src, retroconsole, "console")
	end)

	QBCore.Functions.CreateUseableItem("fameboy", function(src, item)
		TriggerClientEvent("bostra-fameboy:open:console", src, gamingconsole, "console")
	end)

	QBCore.Functions.CreateUseableItem("fameboyadvanced", function(src, item)
		TriggerClientEvent("bostra-fameboy:open:console", src, superconsole, "console")
	end)

elseif Config.frameworkObj == "ESX" then
	ESX = exports["es_extended"]:getSharedObject()

	RegisterCommand("fameboy", function(source)
		local src = source
		TriggerClientEvent("bostra-fameboy:open:console", src, superconsole)
	end, Config.AdminOnly)

	-- Creates 3 types of fameboy consoles (items — free, no timer)
	ESX.RegisterUsableItem("retrofameboy", function(source)
		TriggerClientEvent("bostra-fameboy:open:console", source, retroconsole, "console")
	end)

	ESX.RegisterUsableItem("fameboy", function(source)
		TriggerClientEvent("bostra-fameboy:open:console", source, gamingconsole, "console")
	end)

	ESX.RegisterUsableItem("fameboyadvanced", function(source)
		TriggerClientEvent("bostra-fameboy:open:console", source, superconsole, "console")
	end)

elseif Config.frameworkObj == "none" then
	RegisterCommand("fameboy", function(source)
		local src = source
		TriggerClientEvent("bostra-fameboy:open:console", src, superconsole, "console")
	end, Config.AdminOnly)
end