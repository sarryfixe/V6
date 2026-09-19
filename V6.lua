--==================================================
-- 🍉 SARRY HUB V1
-- by sarry_fixe
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local AVATAR_ID = "rbxassetid://127272362394063"

local ESP_ENABLED = false
local AUTO_ENABLED = false
local SPEED_ENABLED = false
local DARK_ENABLED = false

local SUB_SPEED = 30
local DEFAULT_SPEED = 16

local TARGET = nil

local PATH = nil
local WAYPOINTS = {}
local WAYPOINT_INDEX = 1

local LAST_REPATH = 0
local REPATH_TIME = 0.35

local LAST_POSITION = nil
local STUCK_TIME = 0
local STUCK_LIMIT = 10

local DIRECT_DISTANCE = 6
local FINAL_DISTANCE = 2.5

--==================================================
-- SAVE LIGHTING
--==================================================

local OldLighting = {
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ExposureCompensation = Lighting.ExposureCompensation,
	FogColor = Lighting.FogColor,
	FogStart = Lighting.FogStart,
	FogEnd = Lighting.FogEnd
}

--==================================================
-- 🌑 BẬT / TẮT BÓNG TỐI
--==================================================

local ShadowsOff = false

local function UpdateShadows()

	if ShadowsOff then

		-- TẮT BÓNG
		Lighting.GlobalShadows = false
		Lighting.Brightness = 2
		Lighting.Ambient = Color3.fromRGB(200,200,200)
		Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)

		DarkButton.Text = "☀️ Bóng tối : OFF"

	else

		-- BẬT BÓNG
		Lighting.GlobalShadows = true
		Lighting.Brightness = OldLighting.Brightness
		Lighting.Ambient = OldLighting.Ambient
		Lighting.OutdoorAmbient = OldLighting.OutdoorAmbient
		Lighting.ExposureCompensation =
			OldLighting.ExposureCompensation

		DarkButton.Text = "🌑 Bóng tối : ON"

	end
end

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "SarryHub"
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

--==================================================
-- MENU
--==================================================

local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.Size = UDim2.fromOffset(340,500)
Menu.Position = UDim2.new(0.5,-170,0.5,-250)
Menu.BackgroundColor3 = Color3.fromRGB(24,24,29)
Menu.BorderSizePixel = 0
Menu.Parent = Gui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0,14)
MenuCorner.Parent = Menu

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Thickness = 2
MenuStroke.Color = Color3.fromRGB(75,75,85)
MenuStroke.Parent = Menu

--==================================================
-- DRAG
--==================================================

local function MakeDraggable(object)

	local dragging = false
	local dragStart
	local startPosition

	object.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPosition = object.Position

			input.Changed:Connect(function()

				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end

			end)

		end

	end)

	UIS.InputChanged:Connect(function(input)

		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			local delta = input.Position - dragStart

			object.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,

				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)

		end

	end)
end

MakeDraggable(Menu)

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,-65,0,45)
Title.Position = UDim2.fromOffset(15,5)
Title.BackgroundTransparency = 1
Title.Text = "🍉 SARRY HUB V1"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Menu

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1,-30,0,22)
Credit.Position = UDim2.fromOffset(15,45)
Credit.BackgroundTransparency = 1
Credit.Text = "by sarry_fixe"
Credit.TextColor3 = Color3.fromRGB(155,155,165)
Credit.TextSize = 13
Credit.Font = Enum.Font.Gotham
Credit.TextXAlignment = Enum.TextXAlignment.Left
Credit.Parent = Menu

--==================================================
-- HIDE
--==================================================

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.fromOffset(38,38)
HideButton.Position = UDim2.new(1,-48,0,10)
HideButton.BackgroundColor3 = Color3.fromRGB(45,45,52)
HideButton.Text = "—"
HideButton.TextColor3 = Color3.new(1,1,1)
HideButton.TextSize = 20
HideButton.Font = Enum.Font.GothamBold
HideButton.Parent = Menu

local HideCorner = Instance.new("UICorner")
HideCorner.CornerRadius = UDim.new(1,0)
HideCorner.Parent = HideButton

--==================================================
-- BUTTON CREATOR
--==================================================

local function CreateButton(text,y)

	local button = Instance.new("TextButton")

	button.Size = UDim2.new(1,-30,0,50)
	button.Position = UDim2.fromOffset(15,y)
	button.BackgroundColor3 = Color3.fromRGB(40,40,48)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.new(1,1,1)
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.Parent = Menu

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,10)
	corner.Parent = button

	return button
end

--==================================================
-- BUTTONS
--==================================================

local ESPButton =
	CreateButton("🍉 ESP Dưa hấu : OFF",85)

local AutoButton =
	CreateButton("🤖 Auto tìm dưa : OFF",145)

local SpeedButton =
	CreateButton("🚀 Speed Boost : OFF",205)

local SubSpeedButton =
	CreateButton("🔢 SubSpeed : 30",265)

local DarkButton =
	CreateButton("🌑 Dark Map : OFF",325)

--==================================================
-- SUB SPEED
--==================================================

local MinusButton = Instance.new("TextButton")
MinusButton.Size = UDim2.fromOffset(55,42)
MinusButton.Position = UDim2.fromOffset(15,395)
MinusButton.BackgroundColor3 = Color3.fromRGB(48,48,57)
MinusButton.Text = "−"
MinusButton.TextColor3 = Color3.new(1,1,1)
MinusButton.TextSize = 24
MinusButton.Font = Enum.Font.GothamBold
MinusButton.Parent = Menu

local PlusButton = Instance.new("TextButton")
PlusButton.Size = UDim2.fromOffset(55,42)
PlusButton.Position = UDim2.new(1,-70,0,395)
PlusButton.BackgroundColor3 = Color3.fromRGB(48,48,57)
PlusButton.Text = "+"
PlusButton.TextColor3 = Color3.new(1,1,1)
PlusButton.TextSize = 24
PlusButton.Font = Enum.Font.GothamBold
PlusButton.Parent = Menu

for _,button in ipairs({MinusButton,PlusButton}) do

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0,10)
	corner.Parent = button

end

--==================================================
-- AVATAR
--==================================================

local Avatar = Instance.new("ImageButton")
Avatar.Name = "SarryAvatar"
Avatar.Size = UDim2.fromOffset(90,90)
Avatar.Position = UDim2.new(0,20,0.5,-45)
Avatar.BackgroundColor3 = Color3.fromRGB(25,25,30)
Avatar.Image = AVATAR_ID
Avatar.Visible = false
Avatar.Parent = Gui

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1,0)
AvatarCorner.Parent = Avatar

local AvatarStroke = Instance.new("UIStroke")
AvatarStroke.Thickness = 3
AvatarStroke.Color = Color3.new(1,1,1)
AvatarStroke.Parent = Avatar

MakeDraggable(Avatar)

HideButton.MouseButton1Click:Connect(function()

	Menu.Visible = false
	Avatar.Visible = true

end)

Avatar.MouseButton1Click:Connect(function()

	Menu.Visible = true
	Avatar.Visible = false

end)

--==================================================
-- CHARACTER
--==================================================

local function GetCharacter()
	return Player.Character
end

local function GetHumanoid()

	local character = GetCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot()

	local character = GetCharacter()

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

--==================================================
-- WATERMELON DETECTION
--==================================================

local function IsWatermelon(object)

	if not object:IsA("BasePart")
		and not object:IsA("Model") then
		return false
	end

	local name = string.lower(object.Name)

	return string.find(name,"watermelon",1,true) ~= nil
		or string.find(name,"melon",1,true) ~= nil
		or string.find(name,"duahau",1,true) ~= nil
		or string.find(name,"dua",1,true) ~= nil
end

local function GetWatermelonPart(object)

	if object:IsA("BasePart") then
		return object
	end

	if object:IsA("Model") then

		if object.PrimaryPart then
			return object.PrimaryPart
		end

		return object:FindFirstChildWhichIsA(
			"BasePart",
			true
		)
	end

	return nil
end

local function GetObjectPosition(object)

	local part = GetWatermelonPart(object)

	if part then
		return part.Position
	end

	return nil
end

--==================================================
-- 🔴 RED DOT LOCATOR
--==================================================

local LocatorFolder = Instance.new("Folder")
LocatorFolder.Name = "WatermelonLocator"
LocatorFolder.Parent = Gui

local function ClearLocator()

	for _,object in ipairs(LocatorFolder:GetChildren()) do

		object:Destroy()

	end

	-- Xóa attachment cũ nếu còn
	for _,object in ipairs(workspace:GetDescendants()) do

		if object:IsA("Attachment")
			and object.Name == "SarryRedDot" then

			object:Destroy()

		end

	end
end

local function CreateRedDot(object)

	local part = GetWatermelonPart(object)

	if not part then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "SarryRedDot"

	attachment.Position = Vector3.new(
		0,
		(part.Size.Y / 2) + 1.5,
		0
	)

	attachment.Parent = part

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RedDot"
	billboard.Adornee = attachment
	billboard.Size = UDim2.fromOffset(16,16)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 10000
	billboard.Parent = LocatorFolder

	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromScale(1,1)
	dot.BackgroundColor3 = Color3.fromRGB(255,0,0)
	dot.BorderSizePixel = 0
	dot.Parent = billboard

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1,0)
	dotCorner.Parent = dot

	local dotStroke = Instance.new("UIStroke")
	dotStroke.Thickness = 1
	dotStroke.Color = Color3.new(1,1,1)
	dotStroke.Parent = dot
end

local function UpdateLocator()

	ClearLocator()

	if not ESP_ENABLED then
		return
	end

	for _,object in ipairs(workspace:GetDescendants()) do

		if IsWatermelon(object) then
			CreateRedDot(object)
		end

	end
end

ESPButton.MouseButton1Click:Connect(function()

	ESP_ENABLED = not ESP_ENABLED

	if ESP_ENABLED then

		ESPButton.Text =
			"🍉 ESP Dưa hấu : ON"

		UpdateLocator()

	else

		ESPButton.Text =
			"🍉 ESP Dưa hấu : OFF"

		ClearLocator()

	end

end)

--==================================================
-- FIND NEAREST WATERMELON
--==================================================

local function FindNearestWatermelon()

	local root = GetRoot()

	if not root then
		return nil
	end

	local closest = nil
	local closestDistance = math.huge

	for _,object in ipairs(workspace:GetDescendants()) do

		if IsWatermelon(object) then

			local position =
				GetObjectPosition(object)

			if position then

				local distance =
					(position-root.Position).Magnitude

				if distance < closestDistance then

					closestDistance = distance
					closest = object

				end
			end
		end
	end

	return closest
end

--==================================================
-- PATH RESET
--==================================================

local function ClearPath()

	PATH = nil
	WAYPOINTS = {}
	WAYPOINT_INDEX = 1

end

--==================================================
-- CREATE PATH
--==================================================

local function CreatePath(target)

	local root = GetRoot()
	local targetPosition =
		GetObjectPosition(target)

	if not root or not targetPosition then
		return false
	end

	local path =
		PathfindingService:CreatePath({

			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			AgentCanClimb = true,
			WaypointSpacing = 3

		})

	local success = pcall(function()

		path:ComputeAsync(
			root.Position,
			targetPosition
		)

	end)

	if not success then
		return false
	end

	if path.Status ~= Enum.PathStatus.Success then
		return false
	end

	PATH = path
	WAYPOINTS = path:GetWaypoints()
	WAYPOINT_INDEX = 1

	return #WAYPOINTS > 0
end

--==================================================
-- MOVE PATH
--==================================================

local function MoveToWaypoint()

	local humanoid = GetHumanoid()
	local root = GetRoot()

	if not humanoid or not root then
		return
	end

	local waypoint =
		WAYPOINTS[WAYPOINT_INDEX]

	if not waypoint then
		return
	end

	if waypoint.Action ==
		Enum.PathWaypointAction.Jump then

		humanoid.Jump = true

	end

	humanoid:MoveTo(
		waypoint.Position
	)

	if
		(root.Position-waypoint.Position).Magnitude
		<= 3
	then

		WAYPOINT_INDEX += 1

	end
end

--==================================================
-- STUCK CHECK
--==================================================

local function CheckStuck()

	local root = GetRoot()

	if not root then
		return
	end

	if not LAST_POSITION then

		LAST_POSITION = root.Position
		STUCK_TIME = 0

		return
	end

	local moved =
		(root.Position-LAST_POSITION).Magnitude

	if moved < 1.2 then

		STUCK_TIME += 0.25

	else

		STUCK_TIME = 0

	end

	LAST_POSITION = root.Position

	if STUCK_TIME >= STUCK_LIMIT then

		STUCK_TIME = 0
		LAST_POSITION = nil

		TARGET = nil
		ClearPath()

		local humanoid = GetHumanoid()

		if humanoid then
			humanoid.Health = 0
		end

	end
end

--==================================================
-- AUTO MOVE
--==================================================

local function AutoMove()

	if not AUTO_ENABLED then
		return
	end

	local humanoid = GetHumanoid()
	local root = GetRoot()

	if not humanoid or not root then
		return
	end

	if not TARGET
		or not TARGET.Parent
		or not IsWatermelon(TARGET) then

		TARGET = FindNearestWatermelon()
		ClearPath()

	end

	if not TARGET then
		return
	end

	local targetPosition =
		GetObjectPosition(TARGET)

	if not targetPosition then

		TARGET = nil
		ClearPath()

		return
	end

	local distance =
		(root.Position-targetPosition).Magnitude

	if distance <= FINAL_DISTANCE then

		TARGET = nil
		ClearPath()

		return
	end

	if distance <= DIRECT_DISTANCE then

		humanoid:MoveTo(targetPosition)

		return
	end

	if os.clock()-LAST_REPATH >= REPATH_TIME then

		LAST_REPATH = os.clock()

		if not PATH
			or WAYPOINT_INDEX > #WAYPOINTS then

			CreatePath(TARGET)

		end
	end

	if #WAYPOINTS > 0
		and WAYPOINT_INDEX <= #WAYPOINTS then

		MoveToWaypoint()

	else

		humanoid:MoveTo(targetPosition)

	end
end

--==================================================
-- AUTO BUTTON
--==================================================

AutoButton.MouseButton1Click:Connect(function()

	AUTO_ENABLED = not AUTO_ENABLED

	TARGET = nil
	ClearPath()

	STUCK_TIME = 0
	LAST_POSITION = nil

	if AUTO_ENABLED then

		AutoButton.Text =
			"🤖 Auto tìm dưa : ON"

	else

		AutoButton.Text =
			"🤖 Auto tìm dưa : OFF"

	end
end)

--==================================================
-- SPEED
--==================================================

local function ApplySpeed()

	local humanoid = GetHumanoid()

	if not humanoid then
		return
	end

	if SPEED_ENABLED then

		humanoid.WalkSpeed = SUB_SPEED

	else

		humanoid.WalkSpeed = DEFAULT_SPEED

	end
end

SpeedButton.MouseButton1Click:Connect(function()

	SPEED_ENABLED = not SPEED_ENABLED

	if SPEED_ENABLED then

		SpeedButton.Text =
			"🚀 Speed Boost : ON"

	else

		SpeedButton.Text =
			"🚀 Speed Boost : OFF"

	end

	ApplySpeed()

end)

--==================================================
-- SUB SPEED
--==================================================

local function UpdateSubSpeed()

	SUB_SPEED =
		math.clamp(
			SUB_SPEED,
			1,
			100
		)

	SubSpeedButton.Text =
		"🔢 SubSpeed : "..SUB_SPEED

	ApplySpeed()

end

MinusButton.MouseButton1Click:Connect(function()

	SUB_SPEED =
		math.clamp(
			SUB_SPEED-1,
			1,
			100
		)

	UpdateSubSpeed()

end)

PlusButton.MouseButton1Click:Connect(function()

	SUB_SPEED =
		math.clamp(
			SUB_SPEED+1,
			1,
			100
		)

	UpdateSubSpeed()

end)

SubSpeedButton.MouseButton1Click:Connect(function()

	SUB_SPEED =
		math.clamp(
			SUB_SPEED+5,
			1,
			100
		)

	UpdateSubSpeed()

end)

--==================================================
-- 🌑 DARK MAP BUTTON
--==================================================

DarkButton.MouseButton1Click:Connect(function()

	DARK_ENABLED = not DARK_ENABLED

	SetDarkMap(DARK_ENABLED)

	if DARK_ENABLED then

		DarkButton.Text =
			"🌑 Dark Map : ON"

	else

		DarkButton.Text =
			"🌑 Dark Map : OFF"

	end

end)

--==================================================
-- RESPAWN
--==================================================

Player.CharacterAdded:Connect(function(character)

	TARGET = nil
	ClearPath()

	STUCK_TIME = 0
	LAST_POSITION = nil

	local humanoid =
		character:WaitForChild("Humanoid")

	task.wait(0.5)

	if SPEED_ENABLED then

		humanoid.WalkSpeed =
			SUB_SPEED

	else

		humanoid.WalkSpeed =
			DEFAULT_SPEED

	end

	-- Giữ Dark Map sau respawn
	if DARK_ENABLED then
		SetDarkMap(true)
	end

end)

--==================================================
-- MAIN LOOP
--==================================================

local elapsed = 0

RunService.Heartbeat:Connect(function(delta)

	if AUTO_ENABLED then

		AutoMove()

		elapsed += delta

		if elapsed >= 0.25 then

			elapsed = 0
			CheckStuck()

		end

	end

end)

--==================================================
-- RED DOT REFRESH
--==================================================

task.spawn(function()

	while Gui.Parent do

		task.wait(1)

		if ESP_ENABLED then
			UpdateLocator()
		end

	end

end)

--==================================================
-- TARGET REMOVED
--==================================================

workspace.DescendantRemoving:Connect(function(object)

	if object == TARGET then

		TARGET = nil
		ClearPath()

	end

end)

--==================================================
-- CLEANUP
--==================================================

Gui.AncestryChanged:Connect(function(_,parent)

	if not parent then

		ClearLocator()

		-- Trả Lighting về ban đầu
		SetDarkMap(false)

	end

end)

print("🍉 SARRY HUB V1 loaded")
print("by sarry_fixe")
