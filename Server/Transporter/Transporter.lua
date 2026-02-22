--Transporter by Julianstap, 2023

local M = {}
-- M.COBALT_VERSION = "1.7.6"
-- utils.setLogType("CTF",93)

local floor = math.floor
local mod = math.fmod
local rand = math.random

local playersOutsideOfRound = {}
local gameState = {players = {}}
local vehicleIDs = {} --need this to couple vehid on spawn to player. gameState.players needs to be reset 
local vehVel = {}
local laststate = gameState
local levelName = ""
local area = ""
local areaNames = {}
local levels = {}
local requestedArea = ""
local flagPrefabCount = 1
local goalPrefabCount = 1
local timeSinceLastContact = 0
local requestedScoreLimit = 0
local teamSize = 1
local possibleTeams = {"Red", "LightBlue", "Green", "Yellow", "Purple"}
local chosenTeams = {}
local lastCollision = {"", ""}
local autoStartTimer = 0
local ghosts = true
local areas = {}
local availableFromAreas = {}
local TRANSPORTER_DATA_PATH = "Resources/Server/Transporter/Data/"

local areaCreation = {}

gameState.flagExists = false
gameState.gameRunning = false
gameState.gameEnding = false
gameState.currentArea = ""
gameState.flagCount = 1
gameState.goalCount = 1
gameState.allowFlagCarrierResets = false

local defaultRedFadeDistance = 100 -- the distance between a flag carrier and someone that doesn't have the flag, where the screen of the flag carrier will turn red
local defaultColorPulse = true -- if the car color should pulse between the car color and blue
local defaultFlagTint = true -- if the infecor should have a blue tint
local defaultDistancecolor = 0.3 -- max intensity of the red filter

local pickUniqueState = pickUniqueState or {}

local settings = {}
settings.autoStart = false
settings.autoStartWaitTime = 30
settings.ghosts = true
settings.roundLength = 300 -- length of a round in seconds
settings.teams = false
settings.allowCommands = true
settings.randomVehicles = true

-- local TransporterCommands = {
-- 	transporter = {originModule = "Transporter", level = 0, arguments = {"argument"}, sourceLimited = 1, description = "Enables the .zip with the filename specified."},
-- 	ctf = {originModule = "Transporter", level = 0, arguments = {"argument"}, sourceLimited = 1, description = "Alias for transporter."},
-- 	CTF = {originModule = "Transporter", level = 0, arguments = {"argument"}, sourceLimited = 1, description = "Alias for transporter."}
-- }

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

function pickUnique(allOptions, availableOptions)
    local function isEmpty(t)
        return next(t) == nil
    end
    
    local function getRandomKey(t)
        local keys = {}
        for k in pairs(t) do
            table.insert(keys, k)
        end
    		if (#keys == 0) then return nil end
        return keys[math.random(1, #keys)]
    end
    
    -- Use the availableOptions table as a key to track its last picked item
    local stateKey = availableOptions
    local lastPicked = pickUniqueState[stateKey]
    
    if isEmpty(availableOptions) then
        -- Refill availableOptions from allOptions
        for k in pairs(allOptions) do
            availableOptions[k] = true
        end
        
        -- Remove the last picked item to avoid immediate repetition
        if lastPicked then
            availableOptions[lastPicked] = nil
        end
    end
    
    -- print("pickUnique called")  
    -- print("num available: " .. (function()
    --     local count = 0
    --     for k in pairs(availableOptions) do
    --         count = count + 1
    --     end
    --     return count
    -- end)())
    
    local pickedKey = getRandomKey(availableOptions)
  	if (pickedKey == nil) then return nil end
    
    -- Save the picked key globally
  	pickUniqueState[stateKey] = pickedKey
    availableOptions[pickedKey] = nil
    
    return pickedKey
end

function seconds_to_days_hours_minutes_seconds(total_seconds) --modified code from https://stackoverflow.com/questions/45364628/lua-4-script-to-convert-seconds-elapsed-to-days-hours-minutes-seconds
    local time_days     = floor(total_seconds / 86400)
    local time_hours    = floor(mod(total_seconds, 86400) / 3600)
    local time_minutes  = floor(mod(total_seconds, 3600) / 60)
    local time_seconds  = floor(mod(total_seconds, 60))

	if time_days == 0 then
		time_days = nil
	end
    if time_hours == 0 then
        time_hours = nil
    end
	if time_minutes == 0 then
		time_minutes = nil
	end
	if time_seconds == 0 then
		time_seconds = nil
	end
    return time_days ,time_hours , time_minutes , time_seconds
end

function gameStarting()
	local days, hours , minutes , seconds = seconds_to_days_hours_minutes_seconds(settings.roundLength)
	local amount = 0
	if days then
		amount = amount + 1
	end
	if hours then
		amount = amount + 1
	end
	if minutes then
		amount = amount + 1
	end
	if seconds then
		amount = amount + 1
	end
	if days then
		amount = amount - 1
		if days == 1 then
			if amount > 1 then
				days = ""..days.." day, "
			elseif amount == 1 then
				days = ""..days.." day and "
			elseif amount == 0 then
				days = ""..days.." day "
			end
		else
			if amount > 1 then
				days = ""..days.." days, "
			elseif amount == 1 then
				days = ""..days.." days and "
			elseif amount == 0 then
				days = ""..days.." days "
			end
		end
	end
	if hours then
		amount = amount - 1
		if hours == 1 then
			if amount > 1 then
				hours = ""..hours.." hour, "
			elseif amount == 1 then
				hours = ""..hours.." hour and "
			elseif amount == 0 then
				hours = ""..hours.." hour "
			end
		else
			if amount > 1 then
				hours = ""..hours.." hours, "
			elseif amount == 1 then
				hours = ""..hours.." hours and "
			elseif amount == 0 then
				hours = ""..hours.." hours "
			end
		end
	end
	if minutes then
		amount = amount - 1
		if minutes == 1 then
			if amount > 1 then
				minutes = ""..minutes.." minute, "
			elseif amount == 1 then
				minutes = ""..minutes.." minute and "
			elseif amount == 0 then
				minutes = ""..minutes.." minute "
			end
		else
			if amount > 1 then
				minutes = ""..minutes.." minutes, "
			elseif amount == 1 then
				minutes = ""..minutes.." minutes and "
			elseif amount == 0 then
				minutes = ""..minutes.." minutes "
			end
		end
	end
	if seconds then
		if seconds == 1 then
			seconds = ""..seconds.." second "
		else
			seconds = ""..seconds.." seconds "
		end
	end

	MP.SendChatMessage(-1,"Transporter game started, you have to survive for "..(days or "")..""..(hours or "")..""..(minutes or "")..""..(seconds or "").."")
end

function compareTable(gameState,tempTable,laststate)
	for variableName,variable in pairs(gameState) do
		if type(variable) == "table" then
			if not laststate[variableName] then
				laststate[variableName] = {}
			end
			if not tempTable[variableName] then
				tempTable[variableName] = {}
			end
			compareTable(gameState[variableName],tempTable[variableName],laststate[variableName])
			if type(tempTable[variableName]) == "table" and next(tempTable[variableName]) == nil then
				tempTable[variableName] = nil
			end
		elseif variable == "remove" then
			tempTable[variableName] = gameState[variableName]
			laststate[variableName] = nil
			gameState[variableName] = nil
		elseif laststate[variableName] ~= variable then
			tempTable[variableName] = gameState[variableName]
			laststate[variableName] = gameState[variableName]
		end
	end
end

function updateClients()
	local tempTable = {}
	compareTable(gameState,tempTable,laststate)
	-- print("updateClients: " .. dump(tempTable))

	if tempTable and next(tempTable) ~= nil then
		MP.TriggerClientEventJson(-1, "updateTransporterGameState", tempTable)
	end
end

local function loadAreas()
	levelName = MP.Get(MP.Settings.Map):match("/levels/(.+)/info.json") -- gets levelname out of /levels/levelname/info.json
	local file = io.open(TRANSPORTER_DATA_PATH .. "areas.json", "r") 
  if file then
    local content = file:read("*all")
    file:close()
	  areas = Util.JsonDecode(content)[levelName]
	  areaNames = {}
	  if not areas then
			print("Level doesn't have areas: " .. levelName)
			return
	  end
	  for name,_ in pairs(areas) do
			table.insert(areaNames, name)
	  end
	else
		print("Couldn't open Transporter/Data/areas.json")
	end
end

function spawnFlag()
	if not availableFromAreas[area] then
		availableFromAreas[area] = {}
	end
	if not availableFromAreas[area]["flags"] then
		availableFromAreas[area]["flags"] = {}
	end
  local flagName = pickUnique(areas[area]["flags"], availableFromAreas[area]["flags"])
  if not flagName then print("Failed to spawn flag") return end
	print("Chosen flag: " .. dump(flagName))
	-- print(dump(areas))
	local toSend = {}
	table.insert(toSend, flagName)
	table.insert(toSend, areas[area]["flags"][flagName]["position"])
	table.insert(toSend, areas[area]["flags"][flagName]["rotation"])
	MP.TriggerClientEvent(-1, "spawnFlag", Util.JsonEncode(toSend)) --flagPrefabTable[rand(1, flagPrefabTable.size())]
end

function spawnGoal()
	if not availableFromAreas[area] then
		availableFromAreas[area] = {}
	end
	if not availableFromAreas[area]["goals"] then
		availableFromAreas[area]["goals"] = {}
	end
	local goalName = pickUnique(areas[area]["goals"], availableFromAreas[area]["goals"])
	if not goalName then print("Failed to spawn goal") return end
	print("Chosen goal: " .. goalName)
	-- print(dump(areas))
	local toSend = {}
	table.insert(toSend, goalName)
	table.insert(toSend, areas[area]["goals"][goalName]["position"])
	table.insert(toSend, areas[area]["goals"][goalName]["rotation"])
	MP.TriggerClientEvent(-1, "spawnGoal", Util.JsonEncode(toSend)) --flagPrefabTable[rand(1, flagPrefabTable.size())]
end
 
function teleportPlayerToSpawn(ID)
	-- print(dump(areas))
	-- print("---------------------------------------------------------------")
	-- print(dump(availableFromAreas))
	-- print("---------------------------------------------------------------")
	-- print(dump(area))
	if not availableFromAreas[area] then
		availableFromAreas[area] = {}
	end
	if not availableFromAreas[area]["spawns"] then
		availableFromAreas[area]["spawns"] = {}
	end
	local spawnName = pickUnique(areas[area]["spawns"], availableFromAreas[area]["spawns"])
	if not spawnName then print("Couldn't find a spawn to teleport to") return end
	print("Chosen spawn: " .. spawnName)
	print(dump(areas))
	MP.TriggerClientEvent(ID, "teleportPlayerToSpawn", spawnName)
end

function spawnFlagAndGoal()
	spawnFlag()
	spawnGoal()
end

function applyStuff(targetDatabase, tables)
	local appliedTables = {}
	for tableName, table in pairs(tables) do
		if targetDatabase[tableName]:exists() == false then
			for key, value in pairs(table) do
				targetDatabase[tableName][key] = value
			end
			appliedTables[tableName] = tableName
		end
	end
	return appliedTables
end

function onAreaChange()	
	loadAreas() --Just to be sure
	local foundArea = false
	if not areas then print("There are no areas on this level...") return end
	for areaName,_ in pairs(areas) do
		if areaName == requestedArea then
			area = areaName
			foundArea = true
		end
	end
	if area == "" or not foundArea then
		for areaName,_ in pairs(areas) do
			area = areaName
			-- MP.SendChatMessage(-1, "The requested area for the transporter gamemode was not on this map, so it will default to the area " .. area)
			print("The requested area for the transporter gamemode was not on this map, so it will default to the area " .. area)
			break
		end
	end
	MP.TriggerClientEvent(-1, "setCurrentArea", area)
	MP.TriggerClientEvent(-1, "requestFlagCount", "nil")
	MP.TriggerClientEvent(-1, "requestGoalCount", "nil")
end

function teamAlreadyChosen(team)
	return chosenTeams[team].chosen
end

local function loadSettings()
	local file = io.open(TRANSPORTER_DATA_PATH .. "settings.json", "r") 
  if file then
    local content = file:read("*all")
    file:close()
	  settings = Util.JsonDecode(content)
	else
		print("Couldn't open Transporter/Data/settings.json")
	end
	print("Settings are now: " .. dump(settings))
end

function gameSetup()
	loadSettings()
	MP.TriggerClientEvent(-1, "requestVehicleID", "nil")
	math.randomseed(os.time())
	onAreaChange()
	for k,v in pairs(possibleTeams) do
		chosenTeams[v] = {}
		chosenTeams[v].chosen = false
		chosenTeams[v].score = 0  
	end
	gameState = {}
	gameState.players = {}
	gameState.settings = {
		redFadeDistance = defaultRedFadeDistance,
		ColorPulse = defaultColorPulse,
		flagTint = defaultFlagTint,
		distancecolor = defaultDistancecolor
		}
	local playerCount = 0
	for ID,Player in pairs(MP.GetPlayers()) do
		if MP.IsPlayerConnected(ID) and MP.GetPlayerVehicles(ID) then
			playerCount = playerCount + 1
		end
	end
	teamSize = math.floor(playerCount / #possibleTeams)
	local chosenTeam = possibleTeams[rand(1,#possibleTeams)]
	local teamCount = 0
	for ID,Player in pairs(MP.GetPlayers()) do
		if teamCount == teamSize then
			chosenTeam = possibleTeams[rand(1,#possibleTeams)]
			while teamAlreadyChosen(chosenTeam) do --possibility for endless loop, maybe need some better way for this
				chosenTeam = possibleTeams[rand(1,#possibleTeams)]
			end
			chosenTeams[chosenTeam].chosen = true
			teamCount = 0
		end
		if MP.IsPlayerConnected(ID) and MP.GetPlayerVehicles(ID) then
			local player = {}
			player.ID = ID
			player.localContact = false
			player.remoteContact = false
			player.hasFlag = false
			player.score = 0
			player.team = chosenTeam
			-- player.allowedResets = true
			-- player.resetTimer = 3
			-- player.resetTimerActive = false
			player.fadeEndTime = 0
			player.fade = false
			gameState.players[Player] = player
			teamCount = teamCount + 1
		end
	end

	if playerCount == 0 then
		MP.SendChatMessage(-1,"Failed to start, found no vehicles")
		return
	end

	gameState.playerCount = playerCount
	gameState.time = -5
	
	gameState.roundLength = settings.roundLength
	gameState.endtime = -1
	gameState.gameRunning = true
	gameState.gameEnding = false
	gameState.gameEnded = false
	gameState.teams = settings.teams
	gameState.currentArea = ""
	gameState.flagCount = 1
	gameState.goalCount = 1
	gameState.scoreLimit = requestedScoreLimit

	updateClients()

	MP.TriggerClientEventJson(-1, "receiveTransporterGameState", gameState)
end

function transporterGameEnd(reason)
    MP.TriggerClientEvent(-1, "removePrefabs", "all")
	gameState.gameEnding = true
	if reason == nil or reason == "nil" then
		MP.SendChatMessage(-1,"Game stopped for uknown reason")
	else
		if reason == "time" then
			MP.SendChatMessage(-1,"Game over, time limit was reached")
			gameState.endtime = gameState.time + 10
		elseif reason == "manual" then
			MP.SendChatMessage(-1,"Game stopped, Everyone Looses")
			gameState.endtime = gameState.time + 10
		elseif reason == "score" then
			MP.SendChatMessage(-1,"Game over, score limit was reached")
			gameState.endtime = gameState.time + 10
		end
	end

	MP.SendChatMessage(-1,"The scores this round are: ")
	local highestScore = 0
	local winningTeam = ""
	if settings.teams and chosenTeams then
		for teamName, teamData in pairs(chosenTeams) do
			if chosenTeams[teamName].chosen then
				-- print(dump(chosenTeams))
				chosenTeams[teamName].score = 0
				for playername,player in pairs(gameState.players) do
					if teamName == player.team then
						chosenTeams[teamName].totalScore = chosenTeams[teamName].totalScore + player.score
					end
				end
				if chosenTeams[teamName].score > highestScore then
					highestScore = chosenTeams[teamName].score
					winningTeam = teamName
				end
				MP.SendChatMessage(-1, "" .. teamName .. ": " .. chosenTeams[teamName].score)
			end
		end
	else
		for playername,player in pairs(gameState.players) do
			
			if player.score > highestScore then
				highestScore = player.score
			end
			MP.SendChatMessage(-1, "" .. playername .. ": " .. player.score)
		end
	end
	if settings.teams and chosenTeams then
		MP.SendChatMessage(-1, "Team " .. winningTeam .. " Won!")
		for playername,player in pairs(gameState.players) do
			if player.team == winningTeam then
				MP.TriggerClientEvent(player.ID, "onWin", "nil")
				playersOutsideOfRound[playername].totalScore = playersOutsideOfRound[playername].totalScore + 1--player.score
			else
				MP.TriggerClientEvent(player.ID, "onLose", "nil")
			end
		end
	else
		for playername,player in pairs(gameState.players) do
			if player.score == highestScore then
				MP.SendChatMessage(-1, "" .. playername .. " Won!")
				print("" .. dump(player))
				MP.TriggerClientEvent(player.ID, "onWin", "nil")
				playersOutsideOfRound[playername].totalScore = playersOutsideOfRound[playername].totalScore + 1--player.score
			else
				MP.TriggerClientEvent(player.ID, "onLose", "nil")
			end
		end
	end
	MP.SendChatMessage("Amount of rounds won:")
	for playername, player in pairs(playersOutsideOfRound) do
		MP.SendChatMessage(player.ID, "" .. playername .. ": " .. playersOutsideOfRound[playername].totalScore)
	end

	if settings.ghosts then
		for playerName,player in pairs(gameState.players) do
			gameState.players[playerName].fade = false
			-- print("Triggering unfadePerson " .. vehicleIDs[playerName].vehID)
			MP.TriggerClientEvent(-1, "unfadePerson", vehicleIDs[playerName].vehID)
		end	
	end
end

function showPrefabs(player) --shows the prefabs belonging to this map and this area
	for name,data in pairs(areas[area]["flags"]) do
		local toSend = {}
		table.insert(toSend, name)
		table.insert(toSend, data["position"])
		table.insert(toSend, data["rotation"])
		MP.TriggerClientEvent(player.playerID, "spawnFlag", Util.JsonEncode(toSend)) 
	end
	for name,data in pairs(areas[area]["goals"]) do
		local toSend = {}
		table.insert(toSend, name)
		table.insert(toSend, data["position"])
		table.insert(toSend, data["rotation"])
		MP.TriggerClientEvent(player.playerID, "spawnGoal", Util.JsonEncode(toSend)) 
	end
	for name, data in pairs(areas[area]["spawns"]) do
		local toSend = {}
		table.insert(toSend, name)
		table.insert(toSend, data["position"])
		table.insert(toSend, data["rotation"])
		MP.TriggerClientEvent(player.playerID, "spawnSpawnTrigger", Util.JsonEncode(toSend))
	end
	MP.TriggerClientEvent(player.playerID, "spawnObstacles", Util.JsonEncode(areas[area]["obstacles"]))
end

function onSaveArea(player, data)
	--print("onSaveArea called by player: " .. dump(player) .. " and data: " .. dump(data))
	local existingData = {}
	local file = io.open(TRANSPORTER_DATA_PATH .. "areas.json", "r")
	if file then
		local content = file:read("*all")
		file:close()
		existingData = Util.JsonDecode(content) or {}
	end
	
	levelName = MP.Get(MP.Settings.Map):match("/levels/(.+)/info.json")
	if not levelName then
		print("Couldn't determine level name")
		return false
	end
	
	if not existingData[levelName] then
		existingData[levelName] = {}
	end

	data = Util.JsonDecode(data)
	for areaName, areaData in pairs(data) do
		existingData[levelName][areaName] = areaData
		print("Saved area '" .. areaName .. "' for level '" .. levelName .. "'")
	end
	
	file = io.open(TRANSPORTER_DATA_PATH .. "areas.json", "w")
	if file then
		local jsonString = Util.JsonPrettify(Util.JsonEncode(existingData))
		file:write(jsonString)
		file:close()
		return true
	else
		print("Couldn't write to Transporter/Data/areas.json")
		return false
	end
	loadAreas()
end

function createFlag(player)
	MP.TriggerClientEvent(player.playerID, "onCreateFlag", "nil")
end

function createGoal(player)
	MP.TriggerClientEvent(player.playerID, "onCreateGoal", "nil")
end

function createSpawn(player)
	print("creating spawn...")
	MP.TriggerClientEvent(player.playerID, "onCreateSpawn", "nil")
end

function transporter(player, argument)
	if argument == "help" then
		MP.SendChatMessage(player.playerID, "Anything between double qoutes; \"\" is a command. \n Anything between single quotes; \'\' is an argument, \n if there is a slash it means those are the argument options for that command.")
		MP.SendChatMessage(player.playerID, "\"/transporter start\" to start a transporter game.")
		MP.SendChatMessage(player.playerID, "\"/transporter stop\" to stop a transporter game.")
		MP.SendChatMessage(player.playerID, "\"/transporter area \'chosenArea\' \" to choose an area to play transporter on.")
		MP.SendChatMessage(player.playerID, "\"/transporter list \'areas/levels\' \" to list the possible areas or levels to play transporter on.")
		MP.SendChatMessage(player.playerID, "\"/transporter show\" to show all flags and goals in the current area.")
		MP.SendChatMessage(player.playerID, "\"/transporter hide\" to hide all flags and goals in the current area.")
		MP.SendChatMessage(player.playerID, "\"/transporter start \'minutes\' \" to start a transporter game with a duration of the specified minutes.")
		MP.SendChatMessage(player.playerID, "\"/transporter time limit \'minutes\' \" to set the duration of a transporter game to the specified minutes.")
		MP.SendChatMessage(player.playerID, "\"/transporter score limit \'points\' \" to set the score limit of a transporter game to the specified score.")
		MP.SendChatMessage(player.playerID, "\"/transporter teams \'true/false\' \" to specify if the transporter games uses teams.")
		MP.SendChatMessage(player.playerID, "\"/transporter allow resets \'true/false\' \" to specify if the flag carrier can reset without losing the flag.")
		MP.SendChatMessage(player.playerID, "\"/transporter create \'flag/goal/spawn\' \" to create a goal, spawn, or flag, so you can make your own areas! \n Consult the tutorial on GitHub to learn how to do this.")
		MP.SendChatMessage(player.playerID, "\"/transporter ghosts \'true/false\' \" to specify if people should be ghosts on reset and when getting the flag.")
		MP.SendChatMessage(player.playerID, "\"/transporter save \'name\' \" to save the created area with the name (overwrites the area with name and saves all goals, flags, spawns, and obstacles created with /ctf create goal/flag/spawn or obstacles renamed with world editor.).")
		MP.SendChatMessage(player.playerID, "\"/transporter auto \'true/false\' \" turns auto mode on or off")
		MP.SendChatMessage(player.playerID, "\"/transporter auto wait time \'seconds\' \" the amount of seconds to wait between automatic rounds")
	elseif argument == "show" then
		onAreaChange()
		showPrefabs(player)
	elseif argument == "hide" then
		MP.TriggerClientEvent(player.playerID, "removePrefabs", "all")
	elseif argument == "start" or string.find(argument, "start %d") then
		local number = 5
		if string.find(argument, "start %d") then
			number = tonumber(string.sub(argument,7,10000))
			settings.roundLength = number * 60
			print("Transporter game starting with duration: " .. number)
		end
		if not gameState.gameRunning then
			if gameState.scoreLimit and gameState.scoreLimit > 0 then
				MP.SendChatMessage(-1, "Bring home " .. gameState.scoreLimit .. " to win!")
			end
			gameSetup()
			MP.SendChatMessage(-1, "Transporter started, GO GO GO!")
		else
			MP.SendChatMessage(-1, "A transporter game has already started.")
		end
	elseif string.find(argument, "time limit %d") then
		local number = tonumber(string.sub(argument,11,10000))
		settings.roundLength = number * 60
		print("Transporter game time limit is now: " .. settings.roundLength)
	elseif string.find(argument, "score limit %d") then
		local number = tonumber(string.sub(argument,12,10000))
		requestedScoreLimit = number
		print("Transporter game score limit is now: " .. number)
	elseif string.find(argument, "teams %S") then
		local teamsString = string.sub(argument,7,10000)
		if teamsString == "true" then
			settings.teams = true
		elseif teamsString == "false" then
			settings.teams = false
		end
		MP.SendChatMessage(-1, "Playing with teams: " .. dump(settings.teams) .. " (available options are true or false)")
	elseif string.find(argument, "save %S") then
			local tmpAreaName = string.sub(argument, 6, 10000)
		  MP.TriggerClientEvent(player.playerID, "saveArea", tmpAreaName)
	elseif string.find(argument, "allow resets %S") then
		local allowedString = string.sub(argument,14,10000)
		if allowedString == "true" then
			gameState.allowFlagCarrierResets = true
		elseif allowedString == "false" then
			gameState.allowFlagCarrierResets = false
		end
		MP.SendChatMessage(-1, "Resets allowed when carrying flag: " .. dump(gameState.allowFlagCarrierResets) .. " (available options are true or false)")
	elseif string.find(argument, "ghosts %S") then
		local allowedString = string.sub(argument,8,10000)
		if allowedString == "true" then
			settings.ghosts = true
		elseif allowedString == "false" then
			settings.ghosts = false
		end
		MP.SendChatMessage(-1, "Ghosting enabled: " .. dump(settings.ghosts) .. " (available options are true or false)")
	elseif string.match(argument, "^auto %S") then
    local value = string.match(argument, "^auto (%S+)")
    if value == "true" or value == "false" then
      settings.autoStart = (value == "true")
    end
	elseif string.match(argument, "^auto wait time %S") then
    local value = string.match(argument, "^auto wait time (%S+)")
    autoWaitTime = tonumber(value)
	elseif string.match(argument, "^random vehicles %S") then
    local value = string.match(argument, "^auto (%S+)")
    if value == "true" or value == "false" then
      settings.autoStart = (value == "true")
    end
	elseif string.find(argument, "create %S") then
		local createString = string.sub(argument,8,10000) 
		if createString == "flag" then
			createFlag(player)
		elseif createString == "goal" then
			createGoal(player)
		elseif createString == "spawn" then
			createSpawn(player)
		end
	elseif string.find(argument, "list %S") then
		local subArgument = string.sub(argument,6,10000)
		loadAreas()
		if subArgument == "areas" then
			if areaNames == {} then
				MP.SendChatMessage(player.playerID, "There are no areas made for this map, a server restart might fix it or try a different map.")
			else
				MP.SendChatMessage(player.playerID, "Possible areas to play on this map: " .. dump(areaNames))
			end
		elseif subArgument == "levels" then
			if levels == {} then
				MP.SendChatMessage(player.playerID, "There are no levels available for transporter, obviously something is very wrong.")
			else
				MP.SendChatMessage(player.playerID, "Possible levels to play transporter on: " .. dump(levels))
			end
		else
			MP.SendChatMessage(player.playerID, "I can't " .. argument .. ", try something else (like list areas or list levels).")
		end
	elseif string.find(argument, "area %S") then
		requestedArea = string.sub(argument,6,10000)
		onAreaChange()
		MP.SendChatMessage(-1, "Requested area: " .. requestedArea)
	elseif argument == "stop" then
		transporterGameEnd("manual")
		MP.SendChatMessage(-1, "Transporter stopping...")
	end	
end

function ctf(player, argument) --alias for transporter
	transporter(player, argument)
end

function CTF(player, argument) --alias for transporter
	transporter(player, argument)
end

function gameRunningLoop()
	if gameState.time < 0 then
		MP.SendChatMessage(-1,"Transporter game starting in "..math.abs(gameState.time).." second")
	end
	if gameState.time == 0 then
		gameStarting()
		for ID,Player in pairs(MP.GetPlayers()) do
			teleportPlayerToSpawn(ID)
		end
		spawnFlagAndGoal()
	end
	if gameState.time == -3 then
		for name, spawnData in pairs(areas[area]["spawns"]) do
			local toSend = {}
			table.insert(toSend, name)
			table.insert(toSend, spawnData["position"])
			table.insert(toSend, spawnData["rotation"])
			MP.TriggerClientEvent(-1, "spawnSpawnTrigger", Util.JsonEncode(toSend))
		end
		-- MP.TriggerClientEvent(-1, "spawnObstacles", "levels/" .. levelName .. "/multiplayer/" .. area .. "/obstacles.prefab.json")	
		MP.TriggerClientEvent(-1, "spawnObstacles", Util.JsonEncode(areas[area]["obstacles"]))
	end
	MP.TriggerClientEvent(-1, "requestVelocity", "nil")

	if not gameState.gameEnding and gameState.playerCount == 0 then
		gameState.gameEnding = true
		gameState.endtime = gameState.time + 2
	end

	local players = gameState.players

	if not gameState.gameEnding and gameState.time > 0 then
		local playercount = 0
		for playername,player in pairs(players) do
			if player.localContact and player.remoteContact then
				MP.SendChatMessage(-1,""..playername.." has captured the flag!")
			end		
			if settings.ghosts and not settings.teams and player.fade and gameState.time >= player.fadeEndTime then
				gameState.players[MP.GetPlayerName(player.ID)].fade = false
				MP.TriggerClientEvent(-1, "unfadePerson", vehicleIDs[MP.GetPlayerName(player.ID)].vehID)
				-- print("Triggering unfadePerson " .. vehicleIDs[MP.GetPlayerName(player.ID)].vehID)
				-- MP.TriggerClientEvent(player.ID, "allowResets", "nil")
			end
			if settings.ghosts and not settings.teams and not player.hasFlag and vehVel[MP.GetPlayerName(player.ID)] and (vehVel[MP.GetPlayerName(player.ID)].vel < 10) then --less than 10 km/h 
				gameState.players[MP.GetPlayerName(player.ID)].fade = true
				MP.TriggerClientEvent(-1, "fadePerson", vehicleIDs[MP.GetPlayerName(player.ID)].vehID)
				gameState.players[MP.GetPlayerName(player.ID)].fadeEndTime = gameState.time + 2
				-- print("A player should have faded cuz he slow af")
			end
			if not player.hasFlag and vehVel[MP.GetPlayerName(player.ID)] and (vehVel[MP.GetPlayerName(player.ID)].vel < 30) then
				MP.TriggerClientEvent(player.ID, "allowResets", "nil")
				--TODO: refactor reset system to check all the rules in a single place, do the same for fading. So do all checks where needed and expose bools so rules can be changed easily
			else
				MP.TriggerClientEvent(player.ID, "disallowResets", "nil") 
			end
			playercount = playercount + 1
		end
		gameState.playerCount = playercount
	end

	if not gameState.gameEnding and gameState.time == gameState.roundLength then
		transporterGameEnd("time")
		gameState.endtime = gameState.time + 10
	elseif gameState.gameEnding and gameState.time == gameState.endtime then
		gameState = {}
		gameState.players = {}
		gameState.gameRunning = false
		gameState.gameEnding = false
		gameState.gameEnded = true
		MP.TriggerClientEvent(-1, "onGameEnd", "nil")
		if settings.ghosts then
			for playerName,player in pairs(gameState.players) do
				gameState.players[playerName].fade = false
				-- print("Triggering unfadePerson " .. vehicleIDs[playerName].vehID)
				MP.TriggerClientEvent(-1, "unfadePerson", vehicleIDs[playerName].vehID)
			end	
		end
	elseif not gameState.gameEnding and gameState.scoreLimit and gameState.scoreLimit ~= 0 then
		for playerName,player in pairs(gameState.players) do
			if player.score >= gameState.scoreLimit then
				transporterGameEnd("score")
				MP.SendChatMessage(-1, "Score limit was reached, " .. playerName .. " is the winner")
			end
		end
	end
	if gameState.gameRunning then
		timeSinceLastContact = timeSinceLastContact + 1
		gameState.time = gameState.time + 1
	else
		for playername,player in pairs(players) do
			if settings.ghosts then
				-- gameState.players[MP.GetPlayerName(player.ID)].fade = false
				print("Triggering unfadePerson " .. vehicleIDs[MP.GetPlayerName(player.ID)].vehID)
				MP.TriggerClientEvent(-1, "unfadePerson", vehicleIDs[MP.GetPlayerName(player.ID)].vehID)
			end
		end
	end

	updateClients()
end

--resets flagcarrier and spawns a new flag
function resetFlagCarrier(localPlayerID, player) 
	-- print("resetFlagCarrier: " .. dump(player) .. " " .. localPlayerID)
	player = Util.JsonDecode(player)
	-- print("resetFlagCarrier: " .. dump(player) .. " Gamestate: " .. dump(gameState))
	if gameState.gameRunning and not gameState.gameEnding then
		if player.hasFlag == true then
			gameState.players[MP.GetPlayerName(localPlayerID)].hasFlag = false
			if not gameState.allowFlagCarrierResets then --whenever the flag switches places the previous flag carrier should be able to reset again
				MP.TriggerClientEvent(player.ID, "allowResets", "nil")
			end
			spawnFlag()
			MP.TriggerClientEvent(-1, "onFlagReset", "nil")
			print("Called onFlagReset")
			return
		end
	end
end

function transporterTimer()
	if gameState.gameRunning then
		gameRunningLoop()
	elseif settings.autoStart and MP.GetPlayerCount() > -1 then
		autoStartTimer = autoStartTimer + 1
		if autoStartTimer >= settings.autoStartWaitTime then
			autoStartTimer = 0
			gameSetup()
		end
	end
end

--called whenever the extension is loaded
function onInit()
    MP.RegisterEvent("requestTransporterGameState","requestTransporterGameState")
    MP.RegisterEvent("transporter","transporter")
    MP.RegisterEvent("ctf","ctf")
    MP.RegisterEvent("CTF","CTF")
    MP.TriggerClientEventJson(-1, "receiveTransporterGameState", gameState)
	
	MP.CancelEventTimer("counter")
	MP.CancelEventTimer("transporterSecond")
	MP.CreateEventTimer("transporterSecond",1000)
	MP.RegisterEvent("transporterSecond", "transporterTimer")

	MP.RegisterEvent("onTransporterContact", "onTransporterContact")
	MP.RegisterEvent("setLevelName", "setLevelName")
	MP.RegisterEvent("setFlagCarrier", "setFlagCarrier")
	MP.RegisterEvent("onGoal", "onGoal")
	MP.RegisterEvent("setLevels", "setLevels")
	MP.RegisterEvent("setFlagCount", "setFlagCount")
	MP.RegisterEvent("setGoalCount", "setGoalCount")
	MP.RegisterEvent("resetFlagCarrier", "resetFlagCarrier")
	MP.RegisterEvent("onTransporterContactreceive","onTransporterContact")
	MP.RegisterEvent("setVehicleID","setVehicleID")
	MP.RegisterEvent("setVehVel","setVehVel")
	MP.RegisterEvent("onChatMessage","onChatMessage")
	
	MP.RegisterEvent("onPlayerFirstAuth","onPlayerFirstAuth")
	MP.RegisterEvent("onPlayerAuth","onPlayerAuth")
	-- MP.RegisterEvent("onPlayerConnecting","onPlayerConnecting")
	MP.RegisterEvent("onPlayerJoining","onPlayerJoining")
	MP.RegisterEvent("onPlayerJoin","onPlayerJoin")
	MP.RegisterEvent("onPlayerDisconnect","onPlayerDisconnect")
	MP.RegisterEvent("onVehicleSpawn","onVehicleSpawn")
	MP.RegisterEvent("onVehicleEdited","onVehicleEdited")
	MP.RegisterEvent("onVehicleReset","onVehicleReset")
	MP.RegisterEvent("onVehicleDeleted","onVehicleDeleted")
	MP.RegisterEvent("onSaveArea","onSaveArea")

	loadAreas() --this uses the Map in ServerConfig.toml to parse only areas on this level
	loadSettings()
	-- applyStuff(commands, TransporterCommands)
	print("--------------------Transporter loaded----------------")
end


function onUnload()

end

--called whenever a player is authenticated by the server for the first time.
function onPlayerFirstAuth(player)

end

--called whenever the player is authenticated by the server.
function onPlayerAuth(player)

end

-- --called whenever someone begins connecting to the server
-- function onPlayerConnecting(playerID)
-- 	MP.TriggerClientEventJson(playerID, "receiveTransporterGameState", gameState)
-- end

--called when a player begins loading
function onPlayerJoining(player)

end

--called whenever a player has fully joined the session
function onPlayerJoin(playerID)
	playersOutsideOfRound[MP.GetPlayerName(playerID)] = {}
	playersOutsideOfRound[MP.GetPlayerName(playerID)].totalScore = 0
	-- MP.TriggerClientEvent(-1, "requestLevelName", "nil") --TODO: fix this when changing levels somehow
	-- MP.TriggerClientEvent(-1, "requestAreaNames", "nil")
	-- MP.TriggerClientEvent(-1, "requestLevels", "nil")
end

--called whenever a player disconnects from the server
function onPlayerDisconnect(playerID)
	gameState.players[MP.GetPlayerName(playerID)] = nil
	playersOutsideOfRound[MP.GetPlayerName(playerID)] = nil
	vehicleIDs[MP.GetPlayerName(playerID)] = nil
end

--called whenever a player sends a chat message
function onChatMessage(playerID, player_name, chatMessage)
	local player = {}
	player.playerID = playerID
	-- print("onChatMessage( " .. dump(player) .. ", " .. chatMessage .. ")")
	if string.find(chatMessage, "/ctf") then
		chatMessage = string.gsub(chatMessage, "/ctf ", "")
		transporter(player, chatMessage)
	end
	if string.find(chatMessage, "/CTF") then
		chatMessage = string.gsub(chatMessage, "/CTF ", "")
		transporter(player, chatMessage)
	end
	if string.find(chatMessage, "/transporter") then
		chatMessage = string.gsub(chatMessage, "/transporter ", "")
		transporter(player, chatMessage)
	end
end

--called whenever a player spawns a vehicle.
function onVehicleSpawn(player, vehID,  data)

end

--called whenever a player applies their vehicle edits.
function onVehicleEdited(player, vehID,  data)

end

--called whenever a player resets their vehicle, holding insert spams this function.
function onVehicleReset(playerID, vehID, data)
	if not gameState or not playerID or not gameState.players or not gameState.gameRunning or not gameState.players[MP.GetPlayerName(playerID)] or gameState.allowFlagCarrierResets then return end
	resetFlagCarrier(nil, Util.JsonEncode(gameState.players[MP.GetPlayerName(playerID)]))
	if settings.ghosts then
		MP.TriggerClientEvent(-1, "fadePerson", "" .. vehicleIDs[MP.GetPlayerName(playerID)].vehID)
		gameState.players[MP.GetPlayerName(playerID)].fade = true
		gameState.players[MP.GetPlayerName(playerID)].fadeEndTime = gameState.time + 2
	end
end

--called whenever a vehicle is deleted
function onVehicleDeleted(player, vehID,  source)


end

--whenever a message is sent to the Rcon
function onRconCommand(player, message, password, prefix)

end

--whenever a new client interacts with the RCON
function onNewRconClient(client)

end

--called when the server is stopped through the stopServer() function
function onStopServer()

end

function requestTransporterGameState(localPlayerID)
	--if levelName == "" then MP.TriggerClientEvent(localPlayerID, "requestLevelName", "nil") end
	-- if areaNames == {} then MP.TriggerClientEvent(localPlayerID, "requestAreaNames", "nil") end
	-- if levels == {} then MP.TriggerClientEvent(localPlayerID, "requestLevels", "nil") end
	-- if area == "" then onAreaChange() end
	MP.TriggerClientEventJson(localPlayerID, "receiveTransporterGameState", gameState)
end

function onTransporterContact(localPlayerID, data)
	local remotePlayerName = MP.GetPlayerName(tonumber(data))
	local localPlayerName = MP.GetPlayerName(localPlayerID)
	if timeSinceLastContact < 0.5 or (timeSinceLastContact <= 1.5 and ((lastCollision[1] == remotePlayerName and lastCollision[2] == localPlayerName) or (lastCollision[1] == localPlayerName and lastCollision[2] == remotePlayerName))) then return end
	lastCollision[1] = localPlayerName
	lastCollision[2] = remotePlayerName
	if gameState.gameRunning and not gameState.gameEnding then
		local localPlayer = gameState.players[localPlayerName]
		local remotePlayer = gameState.players[remotePlayerName]
		if localPlayer and remotePlayer then
			if gameState.teams then
				if localPlayer.team == remotePlayer.team then return end
			end
			local remotePlayerID = tonumber(data)
			if localPlayer.hasFlag == true and remotePlayer.hasFlag == false then
				gameState.players[localPlayerName].hasFlag = false
				gameState.players[remotePlayerName].hasFlag = true
				MP.TriggerClientEvent(localPlayerID, "allowResets", "nil") --lost flag
				MP.TriggerClientEvent(localPlayerID, "onLostFlag", "nil")
				MP.TriggerClientEvent(remotePlayerID, "disallowResets", "nil") --got flag
				MP.TriggerClientEvent(remotePlayerID, "onGotFlag", "nil")
				if settings.ghosts then
					MP.TriggerClientEvent(-1, "fadePerson", "" .. vehicleIDs[remotePlayerName].vehID)
					gameState.players[remotePlayerName].fade = true
					gameState.players[remotePlayerName].fadeEndTime = gameState.time + 2
				end
				
				gameState.players[remotePlayerName].remoteContact = false
				MP.SendChatMessage(-1, "".. remotePlayerName .." has captured the flag!")
			elseif remotePlayer.hasFlag == true and localPlayer.hasFlag == false then
				gameState.players[localPlayerName].hasFlag = true
				gameState.players[remotePlayerName].hasFlag = false
				MP.TriggerClientEvent(localPlayerID, "disallowResets", "nil") --got flag
				MP.TriggerClientEvent(localPlayerID, "onGotFlag", "nil")
				MP.TriggerClientEvent(remotePlayerID, "allowResets", "nil") --lost flag
				MP.TriggerClientEvent(remotePlayerID, "onLostFlag", "nil")
				gameState.players[localPlayerName].localContact = false
				if settings.ghosts then
					MP.TriggerClientEvent(-1, "fadePerson", "" .. vehicleIDs[localPlayerName].vehID)
					gameState.players[localPlayerName].fade = true
					gameState.players[localPlayerName].fadeEndTime = gameState.time + 2
				end
				MP.SendChatMessage(-1, "".. localPlayerName .." has captured the flag!")
			end
			timeSinceLastContact = 0
		end
	end
end

function setFlagCarrier(playerID)
	if gameState.players[MP.GetPlayerName(playerID)].hasFlag == false then 
		for playername,player in pairs(gameState.players) do
			gameState.players[playername].hasFlag = false
		end
		gameState.players[MP.GetPlayerName(playerID)].hasFlag = true
		MP.TriggerClientEvent(-1, "removePrefabs", "flag")
		-- print("" .. dump(gameState) .. " " .. vehicleIDs[MP.GetPlayerName(playerID)].vehID)
		-- if ghosts then --uncomment to enable ghost when going through the flag marker
		-- 	MP.TriggerClientEvent(-1, "fadePerson", "" .. vehicleIDs[MP.GetPlayerName(playerID)].vehID)
		-- 	gameState.players[MP.GetPlayerName(playerID)].fade = true
		-- 	gameState.players[MP.GetPlayerName(playerID)].fadeEndTime = gameState.time + 2
		-- end
		MP.SendChatMessage(-1,"".. MP.GetPlayerName(playerID) .." has the flag!")
	end
	updateClients()
end

function onGoal(playerID)
	if gameState.players[MP.GetPlayerName(playerID)].hasFlag == true then 
		gameState.players[MP.GetPlayerName(playerID)].score = gameState.players[MP.GetPlayerName(playerID)].score + 1
		gameState.players[MP.GetPlayerName(playerID)].hasFlag = false
		MP.TriggerClientEvent(-1, "removePrefabs", "goal")
		MP.TriggerClientEvent(playerID, "onScore", "nil")
		updateClients()
		MP.SendChatMessage(-1,"".. MP.GetPlayerName(playerID) .." Scored a point!")
		spawnFlagAndGoal()
	end
end

function setVehVel(playerID, vel)
	vehVel[MP.GetPlayerName(playerID)] = {}
	vehVel[MP.GetPlayerName(playerID)].vel = tonumber(vel)
	-- print("Set the velocity: " .. vel)
end

function setLevels(playerID, data)
	levels = {}
	for name in data:gmatch("%S+") do 
		table.insert(levels, name) 
	end
end

function setFlagCount(playerID, data)
	flagPrefabCount = tonumber(data)
end

function setGoalCount(playerID, data)
	goalPrefabCount = tonumber(data)
end

function setVehicleID(playerID, vehID)
	-- print("setVehicleID " .. MP.GetPlayerName(playerID))
	vehicleIDs[MP.GetPlayerName(playerID)] = {}
	vehicleIDs[MP.GetPlayerName(playerID)].vehID = vehID
end

M.onInit = onInit
M.onUnload = onUnload

M.onPlayerFirstAuth = onPlayerFirstAuth

M.onPlayerAuth = onPlayerAuth
-- M.onPlayerConnecting = onPlayerConnecting
M.onPlayerJoining = onPlayerJoining
M.onPlayerJoin = onPlayerJoin
M.onPlayerDisconnect = onPlayerDisconnect

M.onChatMessage = onChatMessage

M.onVehicleSpawn = onVehicleSpawn
M.onVehicleEdited = onVehicleEdited
M.onVehicleReset = onVehicleReset
M.onVehicleDeleted = onVehicleDeleted

M.onRconCommand = onRconCommand
M.onNewRconClient = onNewRconClient

M.onStopServer = onStopServer

M.requestTransporterGameState = requestTransporterGameState

M.onTransporterContact = onTransporterContact

M.setFlagCarrier = setFlagCarrier
M.onGoal = onGoal
M.setLevels = setLevels
M.setFlagCount = setFlagCount
M.setGoalCount = setGoalCount
M.resetFlagCarrier = resetFlagCarrier

M.setLevelName = setLevelName
M.setVehicleID = setVehicleID
M.setVehVel = setVehVel

M.transporter = transporter
M.ctf = ctf
M.CTF = CTF

M.loadAreas = loadAreas
M.onSaveArea = onSaveArea

return M
