--==================================================
-- 🍉 SARRY HUB V1
-- by sarry_fixe
-- ONE SCRIPT - ROBLOX STUDIO
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local AVATAR_ID = "rbxassetid://127272362394063"

local ESP_ENABLED = false
local AUTO_ENABLED = false
local SPEED_ENABLED = false

local SUB_SPEED = 30
local BOOST_SPEED = 50
local DEFAULT_SPEED = 16

local TARGET = nil
local WAYPOINTS = {}
local WAYPOINT_INDEX = 1

local PATH = nil
local PATH_BUSY = false

local STUCK_TIME = 0
local LAST_POSITION = nil
local STUCK_LIMIT = 10

local TARGET_REACHED_DISTANCE = 6
local DIRECT_DISTANCE = 6
local FINAL_DISTANCE = 2.5

local REPATH_TIME = 0.35
local LAST_REPATH = 0

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "SarryHub"
Gui.ResetOnSpawn = false
Gui.Parent = PlayerGui

local Menu = Instance.new("Frame")
Menu.Name = "Menu"
Menu.Size = UDim2.fromOffset(340, 430)
Menu.Position = UDim2.new(0.5, -170, 0.5, -215)
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

local function MakeDraggable(Object)

	local dragging = false
	local dragStart
	local startPos

	Object.InputBegan:Connect(function(input)

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPos = Object.Position

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

			Object.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,

				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
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
-- HIDE BUTTON
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
	CreateButton("🔢 SubSpeed : "..SUB_SPEED,265)

--==================================================
-- SPEED +/- 
--==================================================

local MinusButton = Instance.new("TextButton")
MinusButton.Size = UDim2.fromOffset(55,42)
MinusButton.Position = UDim2.fromOffset(15,330)
MinusButton.BackgroundColor3 = Color3.fromRGB(48,48,57)
MinusButton.Text = "−"
MinusButton.TextColor3 = Color3.new(1,1,1)
MinusButton.TextSize = 24
MinusButton.Font = Enum.Font.GothamBold
MinusButton.Parent = Menu

local PlusButton = Instance.new("TextButton")
PlusButton.Size = UDim2.fromOffset(55,42)
PlusButton.Position = UDim2.new(1,-70,0,330)
PlusButton.BackgroundColor3 = Color3.fromRGB(48,48,57)
PlusButton.Text = "+"
PlusButton.TextColor3 = Color3.new(1,1,1)
PlusButton.TextSize = 24
PlusButton.Font = Enum.Font.GothamBold
PlusButton.Parent = Menu

for _,button in ipairs({MinusButton,PlusButton}) do

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0,10)
	c.Parent = button

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

--==================================================
-- HIDE / SHOW
--==================================================

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
-- WATERMELON CHECK
--==================================================

local function IsWatermelon(object)

	if not object:IsA("BasePart") then
		return false
	end

	local name = string.lower(object.Name)

	if string.find(name,"watermelon") then
		return true
	end

	if string.find(name,"melon") then
		return true
	end

	if string.find(name,"duahau") then
		return true
	end

	if string.find(name,"dua") then
		return true
	end

	return false
end

--==================================================
-- ESP
--==================================================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "SarryESP"
ESPFolder.Parent = Gui

local function ClearESP()

	for _,object in ipairs(ESPFolder:GetChildren()) do
		object:Destroy()
	end

end

local function AddESP(object)

	if not IsWatermelon(object) then
		return
	end

	local highlight = Instance.new("Highlight")

	highlight.Name = "WatermelonESP"
	highlight.Adornee = object
	highlight.FillTransparency = 0.45
	highlight.OutlineTransparency = 0

	highlight.Parent = ESPFolder

end

local function UpdateESP()

	ClearESP()

	if not ESP_ENABLED then
		return
	end

	for _,object in ipairs(workspace:GetDescendants()) do

		if IsWatermelon(object) then
			AddESP(object)
		end

	end
end

ESPButton.MouseButton1Click:Connect(function()

	ESP_ENABLED = not ESP_ENABLED

	if ESP_ENABLED then
		ESPButton.Text = "🍉 ESP Dưa hấu : ON"
		UpdateESP()
	else
		ESPButton.Text = "🍉 ESP Dưa hấu : OFF"
		ClearESP()
	end

end)

--==================================================
-- FIND TARGET
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

			local distance =
				(object.Position-root.Position).Magnitude

			if distance < closestDistance then

				closestDistance = distance
				closest = object

			end

		end

	end

	return closest
end

--==================================================
-- CLEAR PATH
--==================================================

local function ClearPath()

	PATH = nil
	WAYPOINTS = {}
	WAYPOINT_INDEX = 1
	PATH_BUSY = false

end

--==================================================
-- CREATE PATH
--==================================================

local function CreatePath(target)

	local root = GetRoot()

	if not root or not target then
		return false
	end

	local path = PathfindingService:CreatePath({

		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 3

	})

	local success = pcall(function()

		path:ComputeAsync(
			root.Position,
			target.Position
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
-- NEXT WAYPOINT
--==================================================

local function MoveToNextWaypoint()

	local humanoid = GetHumanoid()
	local root = GetRoot()

	if not humanoid or not root then
		return
	end

	local waypoint = WAYPOINTS[WAYPOINT_INDEX]

	if not waypoint then
		return
	end

	if waypoint.Action == Enum.PathWaypointAction.Jump then
		humanoid.Jump = true
	end

	humanoid:MoveTo(waypoint.Position)

	if (root.Position-waypoint.Position).Magnitude <= 3 then
		WAYPOINT_INDEX += 1
	end

end

--==================================================
-- TARGET REACHED
--==================================================

local function CheckTargetReached()

	local root = GetRoot()

	if not root or not TARGET then
		return false
	end

	if not TARGET.Parent then
		return true
	end

	local distance =
		(root.Position-TARGET.Position).Magnitude

	if distance <= FINAL_DISTANCE then
		return true
	end

	return false
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

		ClearPath()

		-- Respawn khi bị kẹt quá lâu
		local humanoid = GetHumanoid()

		if humanoid then
			humanoid.Health = 0
		end

	end
end

--==================================================
-- AUTO MOVEMENT
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

	-- Target mất / bị xoá
	if not TARGET
		or not TARGET.Parent
		or not IsWatermelon(TARGET) then

		TARGET = FindNearestWatermelon()

		ClearPath()
	end

	if not TARGET then
		return
	end

	local distance =
		(TARGET.Position-root.Position).Magnitude

	-- Đã tới
	if distance <= FINAL_DISTANCE then

		TARGET = nil
		ClearPath()

		return
	end

	-- Gần thì đi thẳng
	if distance <= DIRECT_DISTANCE then

		humanoid:MoveTo(TARGET.Position)

		return
	end

	-- Repath
	if os.clock()-LAST_REPATH >= REPATH_TIME then

		LAST_REPATH = os.clock()

		if not PATH or WAYPOINT_INDEX > #WAYPOINTS then

			CreatePath(TARGET)

		end

	end

	-- Pathfinding
	if #WAYPOINTS > 0
		and WAYPOINT_INDEX <= #WAYPOINTS then

		MoveToNextWaypoint()

	else

		-- fallback
		humanoid:MoveTo(TARGET.Position)

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

		AutoButton.Text = "🤖 Auto tìm dưa : ON"

	else

		AutoButton.Text = "🤖 Auto tìm dưa : OFF"

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

		SpeedButton.Text = "🚀 Speed Boost : ON"

	else

		SpeedButton.Text = "🚀 Speed Boost : OFF"

	end

	ApplySpeed()

end)

--==================================================
-- SUB SPEED
--==================================================

local function UpdateSubSpeed()

	SUB_SPEED = math.clamp(
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
		humanoid.WalkSpeed = SUB_SPEED
	else
		humanoid.WalkSpeed = DEFAULT_SPEED
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
-- ESP REFRESH
--==================================================

task.spawn(function()

	while Gui.Parent do

		task.wait(1)

		if ESP_ENABLED then
			UpdateESP()
		end

	end

end)

--==================================================
-- CLEAN TARGET WHEN OBJECT DISAPPEARS
--==================================================

workspace.DescendantRemoving:Connect(function(object)

	if object == TARGET then

		TARGET = nil
		ClearPath()

	end

end)

--==================================================
-- INITIAL
--==================================================

print("🍉 Sarry Hub V1 loaded")
print("by sarry_fixe")
