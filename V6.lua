--==================================================
-- 🍉🎣 SARRY HUB V1
-- by sarry_fixe
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local ESP_ENABLED = true
local AUTO_WATERMELON = false
local AUTO_FISHING = false
local SPEED_BOOST = false

local SUB_SPEED = 35
local NORMAL_SPEED = 16

local TOUCH_DISTANCE = 2.5
local DIRECT_DISTANCE = 6
local STUCK_TIME = 10

local WATERMELON_KEYWORDS = {
	"watermelon",
	"melon",
	"dua",
	"duahau",
	"dưa",
	"dưa hấu",
	"dưahấu"
}

--==================================================
-- CHARACTER
--==================================================

local Character
local Humanoid
local Root

local CurrentWatermelon
local CurrentPath
local CurrentWaypoint = 1

local LastPosition
local LastMovementTime = tick()

local function SetupCharacter(char)
	Character = char
	Humanoid = char:WaitForChild("Humanoid", 10)
	Root = char:WaitForChild("HumanoidRootPart", 10)

	CurrentWatermelon = nil
	CurrentPath = nil
	CurrentWaypoint = 1

	LastPosition = Root.Position
	LastMovementTime = tick()
end

if Player.Character then
	task.spawn(function()
		SetupCharacter(Player.Character)
	end)
end

Player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	SetupCharacter(char)
end)

--==================================================
-- GET PART
--==================================================

local function GetPart(object)
	if not object then
		return nil
	end

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

	return object:FindFirstChildWhichIsA(
		"BasePart",
		true
	)
end

--==================================================
-- WATERMELON
--==================================================

local function IsWatermelon(object)
	if not object then
		return false
	end

	local name = string.lower(object.Name)

	for _, keyword in ipairs(WATERMELON_KEYWORDS) do
		if string.find(name, keyword, 1, true) then
			return true
		end
	end

	return false
end

--==================================================
-- ESP
--==================================================

local function RemoveESP(object)
	if not object then
		return
	end

	local h = object:FindFirstChild("SarryWatermelonESP")
	if h then
		h:Destroy()
	end

	local d = object:FindFirstChild("SarryWatermelonDot")
	if d then
		d:Destroy()
	end
end

local function AddESP(object)
	if not ESP_ENABLED then
		return
	end

	local part = GetPart(object)
	if not part then
		return
	end

	if not object:FindFirstChild("SarryWatermelonESP") then
		local highlight = Instance.new("Highlight")

		highlight.Name = "SarryWatermelonESP"
		highlight.Adornee = object
		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0
		highlight.FillColor = Color3.fromRGB(255, 0, 0)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.DepthMode =
			Enum.HighlightDepthMode.AlwaysOnTop

		highlight.Parent = object
	end

	if not object:FindFirstChild("SarryWatermelonDot") then
		local gui = Instance.new("BillboardGui")

		gui.Name = "SarryWatermelonDot"
		gui.Adornee = part
		gui.Size = UDim2.fromOffset(16, 16)
		gui.StudsOffset = Vector3.new(0, 3, 0)
		gui.AlwaysOnTop = true
		gui.Parent = object

		local dot = Instance.new("Frame")

		dot.Size = UDim2.fromScale(1, 1)
		dot.BackgroundColor3 =
			Color3.fromRGB(255, 0, 0)
		dot.BorderSizePixel = 0
		dot.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot
	end
end

local function ScanWatermelons()
	local list = {}

	for _, object in ipairs(Workspace:GetDescendants()) do
		if IsWatermelon(object) then
			local part = GetPart(object)

			if part then
				table.insert(list, object)
				AddESP(object)
			end
		end
	end

	return list
end

local function GetNearestWatermelon()
	if not Root then
		return nil
	end

	local nearest
	local nearestDistance = math.huge

	for _, object in ipairs(ScanWatermelons()) do
		if object:IsDescendantOf(Workspace) then
			local part = GetPart(object)

			if part then
				local distance =
					(Root.Position - part.Position).Magnitude

				if distance < nearestDistance then
					nearestDistance = distance
					nearest = object
				end
			end
		end
	end

	return nearest
end

--==================================================
-- SPEED
--==================================================

local function ApplySpeed()
	if not Humanoid then
		return
	end

	if SPEED_BOOST then
		Humanoid.WalkSpeed =
			math.clamp(SUB_SPEED, 1, 100)
	else
		Humanoid.WalkSpeed = NORMAL_SPEED
	end
end

--==================================================
-- PATH
--==================================================

local function ClearPath()
	CurrentPath = nil
	CurrentWaypoint = 1
end

local function CreatePath(position)
	if not Root then
		return false
	end

	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 4
	})

	local success = pcall(function()
		path:ComputeAsync(
			Root.Position,
			position
		)
	end)

	if not success then
		return false
	end

	if path.Status ~= Enum.PathStatus.Success then
		return false
	end

	CurrentPath = path:GetWaypoints()
	CurrentWaypoint = 1

	return #CurrentPath > 0
end

--==================================================
-- STUCK
--==================================================

local function ResetStuck()
	if Root then
		LastPosition = Root.Position
	end

	LastMovementTime = tick()
end

local function IsStuck()
	if not Root then
		return false
	end

	if not LastPosition then
		ResetStuck()
		return false
	end

	local moved =
		(Root.Position - LastPosition).Magnitude

	if moved >= 0.5 then
		LastPosition = Root.Position
		LastMovementTime = tick()
		return false
	end

	return tick() - LastMovementTime >= STUCK_TIME
end

--==================================================
-- RESPAWN
--==================================================

local Respawning = false

local function RespawnBecauseStuck()
	if Respawning then
		return
	end

	Respawning = true

	CurrentWatermelon = nil
	ClearPath()

	local oldCharacter = Character

	if Humanoid and Humanoid.Health > 0 then
		Humanoid.Health = 0
	end

	local timeout = tick() + 15

	while tick() < timeout do
		if Player.Character
			and Player.Character ~= oldCharacter then
			break
		end

		task.wait(0.2)
	end

	if Player.Character
		and Player.Character ~= oldCharacter then
		SetupCharacter(Player.Character)
	end

	task.wait(1)

	CurrentWatermelon = nil
	ClearPath()
	ResetStuck()

	Respawning = false
end

--==================================================
-- SMOOTH WATERMELON MOVEMENT
--==================================================

local function MoveToWatermelon()
	if not CurrentWatermelon then
		return
	end

	if not Root or not Humanoid then
		return
	end

	local part = GetPart(CurrentWatermelon)

	if not part then
		CurrentWatermelon = nil
		ClearPath()
		return
	end

	ApplySpeed()

	local distance =
		(Root.Position - part.Position).Magnitude

	--==============================================
	-- 🛑 DỪNG GẦN DƯA
	--==============================================

	if distance <= TOUCH_DISTANCE then
		Humanoid:Move(Vector3.zero)

		CurrentWatermelon = nil
		ClearPath()
		ResetStuck()

		task.wait(0.15)
		return
	end

	--==============================================
	-- 🍉 ĐI THẲNG KHI GẦN
	--==============================================

	if distance <= DIRECT_DISTANCE then
		ClearPath()

		Humanoid:MoveTo(part.Position)

		return
	end

	--==============================================
	-- 🧭 PATHFINDING
	--==============================================

	if not CurrentPath then
		if not CreatePath(part.Position) then
			Humanoid:MoveTo(part.Position)
			return
		end
	end

	local waypoint =
		CurrentPath[CurrentWaypoint]

	if not waypoint then
		ClearPath()
		Humanoid:MoveTo(part.Position)
		return
	end

	if waypoint.Action ==
		Enum.PathWaypointAction.Jump then
		Humanoid.Jump = true
	end

	Humanoid:MoveTo(waypoint.Position)

	if (Root.Position - waypoint.Position).Magnitude <= 3 then
		CurrentWaypoint += 1
	end
end

--==================================================
-- AUTO WATERMELON
--==================================================

local AutoWatermelonRunning = false

local function StartAutoWatermelon()
	if AutoWatermelonRunning then
		return
	end

	AutoWatermelonRunning = true
	ResetStuck()

	while AUTO_WATERMELON do

		if Respawning then
			task.wait(0.4)
			continue
		end

		if not Humanoid
			or not Root
			or Humanoid.Health <= 0 then
			task.wait(0.4)
			continue
		end

		ApplySpeed()

		--==========================================
		-- 🔄 TARGET MỚI
		--==========================================

		if not CurrentWatermelon
			or not CurrentWatermelon:IsDescendantOf(
				Workspace
			) then

			CurrentWatermelon = nil
			ClearPath()

			CurrentWatermelon =
				GetNearestWatermelon()

			ResetStuck()
		end

		--==========================================
		-- KHÔNG CÓ DƯA
		--==========================================

		if not CurrentWatermelon then
			ClearPath()
			task.wait(0.35)
			continue
		end

		--==========================================
		-- ANTI-STUCK
		--==========================================

		if IsStuck() then
			RespawnBecauseStuck()

			CurrentWatermelon = nil
			ClearPath()

			continue
		end

		MoveToWatermelon()

		task.wait(0.08)
	end

	CurrentWatermelon = nil
	ClearPath()
	ApplySpeed()

	AutoWatermelonRunning = false
end

--==================================================
-- AUTO FISHING
--==================================================

local FishingBusy = false

local function GetGuiObjects()
	local result = {}

	for _, obj in ipairs(PlayerGui:GetDescendants()) do
		if obj:IsA("GuiObject") then
			table.insert(result, obj)
		end
	end

	return result
end

local function HasText(obj, words)
	if not (
		obj:IsA("TextLabel")
		or obj:IsA("TextButton")
		or obj:IsA("TextBox")
	) then
		return false
	end

	local text =
		string.lower(obj.Text or "")

	for _, word in ipairs(words) do
		if string.find(
			text,
			string.lower(word),
			1,
			true
		) then
			return true
		end
	end

	return false
end

local function FindFishButton()
	for _, obj in ipairs(GetGuiObjects()) do
		if obj:IsA("TextButton")
			and obj.Visible
			and HasText(obj, {
				"fish",
				"fishing",
				"câu"
			}) then

			return obj
		end
	end

	return nil
end

local function FindExitButton()
	for _, obj in ipairs(GetGuiObjects()) do
		if obj:IsA("TextButton")
			and obj.Visible
			and HasText(obj, {
				"exit",
				"close"
			}) then

			return obj
		end
	end

	return nil
end

local function FindRedIndicator()
	local best
	local bestArea = math.huge

	for _, obj in ipairs(GetGuiObjects()) do
		if obj.Visible then

			local size = obj.AbsoluteSize

			if size.Y >= 5
				and size.Y <= 80
				and size.X <= 30 then

				local c =
					obj.BackgroundColor3

				if c.R > 0.65
					and c.R > c.G * 1.5
					and c.R > c.B * 1.5 then

					local area =
						size.X * size.Y

					if area < bestArea then
						bestArea = area
						best = obj
					end
				end
			end
		end
	end

	return best
end

local function FindTrack()
	local red = FindRedIndicator()

	if not red then
		return nil
	end

	local redPos =
		red.AbsolutePosition

	local redSize =
		red.AbsoluteSize

	local redY =
		redPos.Y + redSize.Y / 2

	local best
	local bestDistance = math.huge

	for _, obj in ipairs(GetGuiObjects()) do
		if obj.Visible and obj ~= red then

			local pos =
				obj.AbsolutePosition

			local size =
				obj.AbsoluteSize

			local centerY =
				pos.Y + size.Y / 2

			local sameY =
				math.abs(centerY - redY)

			if size.X >= 150
				and sameY < 80 then

				if sameY < bestDistance then
					bestDistance = sameY
					best = obj
				end
			end
		end
	end

	return best
end

local function FishInput()
	-- Tìm button thao tác câu
	for _, obj in ipairs(GetGuiObjects()) do

		if obj:IsA("TextButton")
			and obj.Visible then

			local name =
				string.lower(obj.Name)

			if string.find(name, "fish", 1, true)
				or string.find(name, "catch", 1, true)
				or string.find(name, "click", 1, true)
				or string.find(name, "reel", 1, true) then

				obj:Activate()
				return true
			end
		end
	end

	return false
end

local function IsMinigameOpen()
	if FindRedIndicator() then
		return true
	end

	for _, obj in ipairs(GetGuiObjects()) do
		if obj.Visible
			and HasText(obj, {
				"ready",
				"fishing",
				"catch"
			}) then

			return true
		end
	end

	return false
end

local function IsFishingFinished()
	for _, obj in ipairs(GetGuiObjects()) do
		if obj.Visible
			and HasText(obj, {
				"fishing failed",
				"fish is gone",
				"success",
				"caught",
				"failed"
			}) then

			return true
		end
	end

	return false
end

local function ControlFishingMinigame()

	local startTime = tick()

	while AUTO_FISHING
		and tick() - startTime < 20 do

		local red =
			FindRedIndicator()

		local track =
			FindTrack()

		if red and track then

			local redCenter =
				red.AbsolutePosition.X
				+ red.AbsoluteSize.X / 2

			local trackLeft =
				track.AbsolutePosition.X + 8

			local trackRight =
				track.AbsolutePosition.X
				+ track.AbsoluteSize.X
				- 8

			--======================================
			-- 🎯 SẮP RA NGOÀI → CLICK
			--======================================

			if redCenter <= trackLeft
				or redCenter >= trackRight then

				FishInput()

				task.wait(0.08)
			end
		end

		task.wait(0.04)
	end
end

local function StartFishing()
	if FishingBusy then
		return
	end

	FishingBusy = true

	local fishButton =
		FindFishButton()

	if fishButton
		and fishButton.Visible then

		fishButton:Activate()

		task.wait(0.5)
	end

	FishingBusy = false
end

local AutoFishingRunning = false

local function StartAutoFishing()
	if AutoFishingRunning then
		return
	end

	AutoFishingRunning = true

	while AUTO_FISHING do

		if IsMinigameOpen() then

			ControlFishingMinigame()

			task.wait(0.2)

			if IsFishingFinished() then

				local exit =
					FindExitButton()

				if exit
					and exit.Visible then

					exit:Activate()
				end

				task.wait(0.6)
			end

		else

			StartFishing()

			task.wait(0.5)
		end

		task.wait(0.1)
	end

	AutoFishingRunning = false
end

--==================================================
-- GUI
--==================================================

local ScreenGui =
	Instance.new("ScreenGui")

ScreenGui.Name = "SarryHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main =
	Instance.new("Frame")

Main.Size =
	UDim2.fromOffset(290, 360)

Main.Position =
	UDim2.new(
		0.5,
		-145,
		0.5,
		-180
	)

Main.BackgroundColor3 =
	Color3.fromRGB(25, 25, 30)

Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner =
	Instance.new("UICorner")

MainCorner.CornerRadius =
	UDim.new(0, 12)

MainCorner.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title =
	Instance.new("TextLabel")

Title.Size =
	UDim2.new(1, -50, 0, 38)

Title.Position =
	UDim2.fromOffset(12, 3)

Title.BackgroundTransparency = 1

Title.Text =
	"🍉🎣 Sarry Hub"

Title.TextColor3 =
	Color3.new(1, 1, 1)

Title.TextSize = 18
Title.Font =
	Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent = Main

local Credit =
	Instance.new("TextLabel")

Credit.Size =
	UDim2.new(1, -20, 0, 18)

Credit.Position =
	UDim2.fromOffset(12, 36)

Credit.BackgroundTransparency = 1

Credit.Text =
	"by sarry_fixe"

Credit.TextColor3 =
	Color3.fromRGB(160, 160, 160)

Credit.TextSize = 11
Credit.Font =
	Enum.Font.Gotham

Credit.TextXAlignment =
	Enum.TextXAlignment.Left

Credit.Parent = Main

--==================================================
-- BUTTON
--==================================================

local function CreateButton(text, y)
	local button =
		Instance.new("TextButton")

	button.Size =
		UDim2.new(1, -24, 0, 42)

	button.Position =
		UDim2.fromOffset(12, y)

	button.BackgroundColor3 =
		Color3.fromRGB(45, 45, 52)

	button.Text =
		text

	button.TextColor3 =
		Color3.new(1, 1, 1)

	button.TextSize = 14
	button.Font =
		Enum.Font.GothamBold

	button.Parent = Main

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(0, 8)

	corner.Parent = button

	return button
end

--==================================================
-- 1 ESP
--==================================================

local ESPButton =
	CreateButton(
		"🍉 Định vị dưa: ON",
		62
	)

ESPButton.MouseButton1Click:Connect(function()

	ESP_ENABLED =
		not ESP_ENABLED

	ESPButton.Text =
		"🍉 Định vị dưa: "
		.. (ESP_ENABLED and "ON" or "OFF")

	if ESP_ENABLED then
		ScanWatermelons()
	else
		for _, obj in ipairs(
			Workspace:GetDescendants()
		) do
			if IsWatermelon(obj) then
				RemoveESP(obj)
			end
		end
	end
end)

--==================================================
-- 2 AUTO WATERMELON
--==================================================

local AutoWatermelonButton =
	CreateButton(
		"🤖 Auto tìm dưa: OFF",
		110
	)

AutoWatermelonButton.MouseButton1Click:Connect(function()

	AUTO_WATERMELON =
		not AUTO_WATERMELON

	AutoWatermelonButton.Text =
		"🤖 Auto tìm dưa: "
		.. (AUTO_WATERMELON and "ON" or "OFF")

	if AUTO_WATERMELON then
		CurrentWatermelon = nil
		ClearPath()

		task.spawn(
			StartAutoWatermelon
		)
	else
		CurrentWatermelon = nil
		ClearPath()

		if Humanoid then
			Humanoid:Move(Vector3.zero)
		end

		ApplySpeed()
	end
end)

--==================================================
-- 3 AUTO FISHING
--==================================================

local AutoFishingButton =
	CreateButton(
		"🎣 Auto Fishing: OFF",
		158
	)

AutoFishingButton.MouseButton1Click:Connect(function()

	AUTO_FISHING =
		not AUTO_FISHING

	AutoFishingButton.Text =
		"🎣 Auto Fishing: "
		.. (AUTO_FISHING and "ON" or "OFF")

	if AUTO_FISHING then
		task.spawn(
			StartAutoFishing
		)
	end
end)

--==================================================
-- 4 SPEED
--==================================================

local SpeedButton =
	CreateButton(
		"🚀 Speed Boost: OFF",
		206
	)

SpeedButton.MouseButton1Click:Connect(function()

	SPEED_BOOST =
		not SPEED_BOOST

	SpeedButton.Text =
		"🚀 Speed Boost: "
		.. (SPEED_BOOST and "ON" or "OFF")

	ApplySpeed()
end)

--==================================================
-- 5 SUB SPEED
--==================================================

local SpeedBox =
	Instance.new("TextBox")

SpeedBox.Size =
	UDim2.new(1, -24, 0, 40)

SpeedBox.Position =
	UDim2.fromOffset(12, 254)

SpeedBox.BackgroundColor3 =
	Color3.fromRGB(40, 40, 48)

SpeedBox.Text =
	tostring(SUB_SPEED)

SpeedBox.PlaceholderText =
	"SubSpeed 1 - 100"

SpeedBox.TextColor3 =
	Color3.new(1, 1, 1)

SpeedBox.TextSize = 14
SpeedBox.Font =
	Enum.Font.GothamBold

SpeedBox.ClearTextOnFocus = false
SpeedBox.Parent = Main

local SpeedCorner =
	Instance.new("UICorner")

SpeedCorner.CornerRadius =
	UDim.new(0, 8)

SpeedCorner.Parent = SpeedBox

SpeedBox.FocusLost:Connect(function()

	local value =
		tonumber(SpeedBox.Text)

	if not value then
		SpeedBox.Text =
			tostring(SUB_SPEED)
		return
	end

	SUB_SPEED =
		math.clamp(
			math.floor(value),
			1,
			100
		)

	SpeedBox.Text =
		tostring(SUB_SPEED)

	if SPEED_BOOST then
		ApplySpeed()
	end
end)

--==================================================
-- STATUS
--==================================================

local Status =
	Instance.new("TextLabel")

Status.Size =
	UDim2.new(1, -24, 0, 40)

Status.Position =
	UDim2.fromOffset(12, 302)

Status.BackgroundTransparency = 1

Status.Text =
	"Status: IDLE"

Status.TextColor3 =
	Color3.fromRGB(190, 190, 190)

Status.TextSize = 11
Status.Font =
	Enum.Font.Gotham

Status.TextWrapped = true
Status.Parent = Main

--==================================================
-- DRAG
--==================================================

local Dragging = false
local DragStart
local StartPosition

Title.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		Dragging = true
		DragStart = input.Position
		StartPosition = Main.Position
	end
end)

UIS.InputChanged:Connect(function(input)

	if not Dragging then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		local delta =
			input.Position - DragStart

		Main.Position =
			UDim2.new(
				StartPosition.X.Scale,
				StartPosition.X.Offset + delta.X,
				StartPosition.Y.Scale,
				StartPosition.Y.Offset + delta.Y
			)
	end
end)

UIS.InputEnded:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		Dragging = false
	end
end)

--==================================================
-- STATUS LOOP
--==================================================

task.spawn(function()

	while ScreenGui.Parent do

		local state = "IDLE"

		if Respawning then
			state = "♻️ Respawning"

		elseif AUTO_FISHING then
			state = "🎣 Auto Fishing"

		elseif AUTO_WATERMELON then
			state = "🍉 Auto Watermelon"

		end

		Status.Text =
			"Status: "
			.. state
			.. "\nSpeed: "
			.. tostring(
				SPEED_BOOST
				and SUB_SPEED
				or NORMAL_SPEED
			)

		task.wait(0.15)
	end
end)

--==================================================
-- ESP LOOP
--==================================================

task.spawn(function()

	while ScreenGui.Parent do

		if ESP_ENABLED then
			ScanWatermelons()
		end

		task.wait(1)
	end
end)

--==================================================
-- START
--==================================================

ScanWatermelons()
ApplySpeed()

print("🍉🎣 Sarry Hub V1 loaded")
print("by sarry_fixe")
