--==================================================
-- 🍉 SolRNG Watermelon V1
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

local WATERMELON_KEYWORDS = {
	"watermelon",
	"melon",
	"dua",
	"duahau",
	"dưa",
	"dưa hấu",
	"dưahấu"
}

local NORMAL_SPEED = 16
local SUB_SPEED = 35

local TOUCH_DISTANCE = 4.5
local STUCK_TIME = 10

local ESP_ENABLED = true
local AUTO_WATERMELON = false
local SPEED_BOOST = false

--==================================================
-- CHARACTER
--==================================================

local Character
local Humanoid
local Root

local function SetupCharacter(char)
	Character = char

	Humanoid = char:WaitForChild(
		"Humanoid",
		10
	)

	Root = char:WaitForChild(
		"HumanoidRootPart",
		10
	)
end

if Player.Character then
	task.spawn(function()
		SetupCharacter(Player.Character)
	end)
end

Player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	SetupCharacter(char)

	CurrentWatermelon = nil
	CurrentPath = nil
	CurrentWaypoint = 1
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
-- WATERMELON CHECK
--==================================================

local function IsWatermelon(object)
	if not object then
		return false
	end

	local name = string.lower(object.Name)

	for _, keyword in ipairs(
		WATERMELON_KEYWORDS
	) do
		if string.find(
			name,
			keyword,
			1,
			true
		) then
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

	local highlight =
		object:FindFirstChild("WatermelonESP")

	if highlight then
		highlight:Destroy()
	end

	local dot =
		object:FindFirstChild("WatermelonDot")

	if dot then
		dot:Destroy()
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

	if not object:FindFirstChild(
		"WatermelonESP"
	) then

		local highlight =
			Instance.new("Highlight")

		highlight.Name =
			"WatermelonESP"

		highlight.Adornee =
			object

		highlight.FillTransparency =
			0.65

		highlight.OutlineTransparency =
			0

		highlight.FillColor =
			Color3.fromRGB(
				255,
				0,
				0
			)

		highlight.OutlineColor =
			Color3.fromRGB(
				255,
				255,
				255
			)

		highlight.DepthMode =
			Enum.HighlightDepthMode.AlwaysOnTop

		highlight.Parent =
			object
	end

	if not object:FindFirstChild(
		"WatermelonDot"
	) then

		local gui =
			Instance.new("BillboardGui")

		gui.Name =
			"WatermelonDot"

		gui.Adornee =
			part

		gui.Size =
			UDim2.fromOffset(
				16,
				16
			)

		gui.StudsOffset =
			Vector3.new(
				0,
				3,
				0
			)

		gui.AlwaysOnTop =
			true

		gui.Parent =
			object

		local dot =
			Instance.new("Frame")

		dot.Size =
			UDim2.fromScale(
				1,
				1
			)

		dot.BackgroundColor3 =
			Color3.fromRGB(
				255,
				0,
				0
			)

		dot.BorderSizePixel = 0
		dot.Parent = gui

		local corner =
			Instance.new("UICorner")

		corner.CornerRadius =
			UDim.new(
				1,
				0
			)

		corner.Parent = dot
	end
end

--==================================================
-- SCAN
--==================================================

local function ScanWatermelons()
	local list = {}

	for _, object in ipairs(
		Workspace:GetDescendants()
	) do

		if IsWatermelon(object) then
			local part = GetPart(object)

			if part then
				table.insert(
					list,
					object
				)

				AddESP(object)
			end
		end
	end

	return list
end

--==================================================
-- GET NEAREST
--==================================================

local function GetNearestWatermelon()
	if not Root then
		return nil
	end

	local nearest
	local nearestDistance = math.huge

	-- QUAN TRỌNG:
	-- mỗi lần tìm đều scan lại toàn bộ map
	local list =
		ScanWatermelons()

	for _, object in ipairs(list) do

		if object:IsDescendantOf(
			Workspace
		) then

			local part =
				GetPart(object)

			if part then

				local distance =
					(
						Root.Position -
						part.Position
					).Magnitude

				if distance <
					nearestDistance then

					nearestDistance =
						distance

					nearest =
						object
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
			math.clamp(
				SUB_SPEED,
				1,
				100
			)
	else
		Humanoid.WalkSpeed =
			NORMAL_SPEED
	end
end

--==================================================
-- PATH
--==================================================

local CurrentPath
local CurrentWaypoint = 1

local function ClearPath()
	CurrentPath = nil
	CurrentWaypoint = 1
end

local function CreatePath(targetPosition)

	if not Root then
		return false
	end

	local path =
		PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			AgentCanClimb = true,
			WaypointSpacing = 4
		})

	local success =
		pcall(function()
			path:ComputeAsync(
				Root.Position,
				targetPosition
			)
		end)

	if not success then
		return false
	end

	if path.Status
		~= Enum.PathStatus.Success then

		return false
	end

	CurrentPath = path:GetWaypoints()
	CurrentWaypoint = 1

	return #CurrentPath > 0
end

--==================================================
-- MOVE
--==================================================

local function MoveToWatermelon()

	if not CurrentWatermelon then
		return
	end

	if not Root
	or not Humanoid then
		return
	end

	local part =
		GetPart(CurrentWatermelon)

	if not part then
		CurrentWatermelon = nil
		ClearPath()
		return
	end

	ApplySpeed()

	local distance =
		(
			Root.Position -
			part.Position
		).Magnitude

	--==============================================
	-- ĐÃ TỚI DƯA
	--==============================================

	if distance <= TOUCH_DISTANCE then

		Humanoid:MoveTo(
			part.Position
		)

		task.wait(0.3)

		-- Dưa đã biến mất
		if not CurrentWatermelon
			:IsDescendantOf(
				Workspace
			) then

			CurrentWatermelon = nil
			ClearPath()

		else
			-- Nếu game xử lý Touch chậm,
			-- kiểm tra lại rồi tìm quả khác.
			task.wait(0.3)

			if CurrentWatermelon
				and CurrentWatermelon
					:IsDescendantOf(
						Workspace
					) then

				CurrentWatermelon =
					GetNearestWatermelon()

				ClearPath()
			end
		end

		return
	end

	--==============================================
	-- TẠO PATH MỚI
	--==============================================

	if not CurrentPath then

		if not CreatePath(
			part.Position
		) then

			-- fallback
			Humanoid:MoveTo(
				part.Position
			)

			return
		end
	end

	--==============================================
	-- WAYPOINT
	--==============================================

	local waypoint =
		CurrentPath[
			CurrentWaypoint
		]

	if not waypoint then
		ClearPath()
		return
	end

	if waypoint.Action
		== Enum.PathWaypointAction.Jump then

		Humanoid.Jump = true
	end

	Humanoid:MoveTo(
		waypoint.Position
	)

	if (
		Root.Position -
		waypoint.Position
	).Magnitude <= 4 then

		CurrentWaypoint += 1
	end
end

--==================================================
-- ANTI STUCK
--==================================================

local LastPosition
local LastMovementTime = tick()

local function ResetStuck()
	if Root then
		LastPosition =
			Root.Position
	end

	LastMovementTime =
		tick()
end

local function IsStuck()

	if not Root then
		return false
	end

	if not LastPosition then
		ResetStuck()
		return false
	end

	local distance =
		(
			Root.Position -
			LastPosition
		).Magnitude

	if distance >= 0.5 then
		LastPosition =
			Root.Position

		LastMovementTime =
			tick()

		return false
	end

	return (
		tick() -
		LastMovementTime
	) >= STUCK_TIME
end

--==================================================
-- RESPAWN
--==================================================

local Respawning = false

local function RespawnPlayer()

	if Respawning then
		return
	end

	Respawning = true

	CurrentWatermelon = nil
	ClearPath()

	if Humanoid
		and Humanoid.Health > 0 then

		Humanoid.Health = 0
	end

	local oldCharacter =
		Character

	local timeout =
		tick() + 15

	while tick() < timeout do

		if Player.Character
			and Player.Character
				~= oldCharacter then

			break
		end

		task.wait(0.2)
	end

	if Player.Character
		and Player.Character
			~= oldCharacter then

		SetupCharacter(
			Player.Character
		)
	end

	task.wait(2)

	CurrentWatermelon = nil
	ClearPath()
	ResetStuck()

	Respawning = false
end

--==================================================
-- AUTO LOOP
--==================================================

local AutoRunning = false

local function StartAuto()

	if AutoRunning then
		return
	end

	AutoRunning = true
	ResetStuck()

	while AUTO_WATERMELON do

		if Respawning then
			task.wait(0.5)
			continue
		end

		if not Humanoid
			or not Root
			or Humanoid.Health <= 0 then

			task.wait(0.5)
			continue
		end

		-- Luôn giữ tốc độ
		ApplySpeed()

		--==========================================
		-- 🔄 TARGET LOOP
		--==========================================

		if not CurrentWatermelon
			or not CurrentWatermelon
				:IsDescendantOf(
					Workspace
				) then

			-- QUAN TRỌNG:
			-- target cũ bị xóa hoàn toàn
			-- rồi scan lại từ đầu.
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
			task.wait(0.5)

			continue
		end

		--==========================================
		-- CHỐNG KẸT 10 GIÂY
		--==========================================

		if IsStuck() then

			RespawnPlayer()

			-- sau respawn:
			-- vòng while tiếp tục
			-- scan dưa mới.
			CurrentWatermelon = nil
			ClearPath()

			continue
		end

		--==========================================
		-- ĐI TỚI DƯA
		--==========================================

		MoveToWatermelon()

		task.wait(0.12)
	end

	CurrentWatermelon = nil
	ClearPath()

	ApplySpeed()

	AutoRunning = false
end

--==================================================
-- GUI
--==================================================

local ScreenGui =
	Instance.new("ScreenGui")

ScreenGui.Name =
	"SolRNG_Watermelon_V1"

ScreenGui.ResetOnSpawn =
	false

ScreenGui.Parent =
	PlayerGui

local Main =
	Instance.new("Frame")

Main.Size =
	UDim2.fromOffset(
		290,
		390
	)

Main.Position =
	UDim2.new(
		0.5,
		-145,
		0.5,
		-195
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		25,
		25,
		30
	)

Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner =
	Instance.new("UICorner")

MainCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

MainCorner.Parent =
	Main

--==================================================
-- TITLE
--==================================================

local Title =
	Instance.new("TextLabel")

Title.Size =
	UDim2.new(
		1,
		-50,
		0,
		38
	)

Title.Position =
	UDim2.fromOffset(
		12,
		2
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"🍉 SolRNG Watermelon V1"

Title.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

Title.TextSize = 17
Title.Font =
	Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent =
	Main

local Credit =
	Instance.new("TextLabel")

Credit.Size =
	UDim2.new(
		1,
		-20,
		0,
		20
	)

Credit.Position =
	UDim2.fromOffset(
		12,
		35
	)

Credit.BackgroundTransparency =
	1

Credit.Text =
	"by sarry_fixe"

Credit.TextColor3 =
	Color3.fromRGB(
		160,
		160,
		160
	)

Credit.TextSize = 11
Credit.Font =
	Enum.Font.Gotham

Credit.TextXAlignment =
	Enum.TextXAlignment.Left

Credit.Parent =
	Main

--==================================================
-- BUTTON CREATOR
--==================================================

local function CreateButton(
	text,
	y
)

	local button =
		Instance.new(
			"TextButton"
		)

	button.Size =
		UDim2.new(
			1,
			-24,
			0,
			42
		)

	button.Position =
		UDim2.fromOffset(
			12,
			y
		)

	button.BackgroundColor3 =
		Color3.fromRGB(
			45,
			45,
			52
		)

	button.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	button.TextSize = 14
	button.Font =
		Enum.Font.GothamBold

	button.Text =
		text

	button.Parent =
		Main

	local corner =
		Instance.new(
			"UICorner"
		)

	corner.CornerRadius =
		UDim.new(
			0,
			8
		)

	corner.Parent =
		button

	return button
end

--==================================================
-- ESP
--==================================================

local ESPButton =
	CreateButton(
		"🍉 Định vị dưa: ON",
		65
	)

ESPButton.MouseButton1Click:Connect(
	function()

		ESP_ENABLED =
			not ESP_ENABLED

		ESPButton.Text =
			"🍉 Định vị dưa: "
			.. (
				ESP_ENABLED
				and "ON"
				or "OFF"
			)

		if ESP_ENABLED then

			ScanWatermelons()

		else

			for _, object in ipairs(
				Workspace:GetDescendants()
			) do

				if IsWatermelon(object) then
					RemoveESP(object)
				end
			end
		end
	end
)

--==================================================
-- AUTO
--==================================================

local AutoButton =
	CreateButton(
		"🤖 Auto tìm dưa: OFF",
		113
	)

AutoButton.MouseButton1Click:Connect(
	function()

		AUTO_WATERMELON =
			not AUTO_WATERMELON

		AutoButton.Text =
			"🤖 Auto tìm dưa: "
			.. (
				AUTO_WATERMELON
				and "ON"
				or "OFF"
			)

		if AUTO_WATERMELON then

			CurrentWatermelon = nil
			ClearPath()

			task.spawn(
				StartAuto
			)

		else

			CurrentWatermelon = nil
			ClearPath()

			if Humanoid then
				Humanoid:Move(
					Vector3.zero
				)
			end

			ApplySpeed()
		end
	end
)

--==================================================
-- SPEED BOOST
--==================================================

local SpeedButton =
	CreateButton(
		"🚀 Speed Boost: OFF",
		161
	)

SpeedButton.MouseButton1Click:Connect(
	function()

		SPEED_BOOST =
			not SPEED_BOOST

		SpeedButton.Text =
			"🚀 Speed Boost: "
			.. (
				SPEED_BOOST
				and "ON"
				or "OFF"
			)

		ApplySpeed()
	end
)

--==================================================
-- SPEED LABEL
--==================================================

local SpeedLabel =
	Instance.new("TextLabel")

SpeedLabel.Size =
	UDim2.new(
		1,
		-24,
		0,
		22
	)

SpeedLabel.Position =
	UDim2.fromOffset(
		12,
		210
	)

SpeedLabel.BackgroundTransparency =
	1

SpeedLabel.Text =
	"🔢 SubSpeed: 1 - 100"

SpeedLabel.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

SpeedLabel.TextSize = 13
SpeedLabel.Font =
	Enum.Font.GothamBold

SpeedLabel.TextXAlignment =
	Enum.TextXAlignment.Left

SpeedLabel.Parent =
	Main

--==================================================
-- SPEED BOX
--==================================================

local SpeedBox =
	Instance.new("TextBox")

SpeedBox.Size =
	UDim2.new(
		1,
		-24,
		0,
		40
	)

SpeedBox.Position =
	UDim2.fromOffset(
		12,
		235
	)

SpeedBox.BackgroundColor3 =
	Color3.fromRGB(
		40,
		40,
		48
	)

SpeedBox.Text =
	tostring(
		SUB_SPEED
	)

SpeedBox.PlaceholderText =
	"Nhập tốc độ 1 - 100"

SpeedBox.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

SpeedBox.TextSize = 14
SpeedBox.Font =
	Enum.Font.GothamBold

SpeedBox.ClearTextOnFocus =
	false

SpeedBox.Parent =
	Main

local SpeedCorner =
	Instance.new(
		"UICorner"
	)

SpeedCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

SpeedCorner.Parent =
	SpeedBox

SpeedBox.FocusLost:Connect(
	function()

		local value =
			tonumber(
				SpeedBox.Text
			)

		if not value then

			SpeedBox.Text =
				tostring(
					SUB_SPEED
				)

			return
		end

		SUB_SPEED =
			math.clamp(
				math.floor(
					value
				),
				1,
				100
			)

		SpeedBox.Text =
			tostring(
				SUB_SPEED
			)

		-- Chỉ áp dụng ngay
		-- khi Speed Boost đang bật.
		if SPEED_BOOST then
			ApplySpeed()
		end
	end
)

--==================================================
-- STATUS
--==================================================

local Status =
	Instance.new("TextLabel")

Status.Size =
	UDim2.new(
		1,
		-24,
		0,
		42
	)

Status.Position =
	UDim2.fromOffset(
		12,
		285
	)

Status.BackgroundColor3 =
	Color3.fromRGB(
		35,
		35,
		42
	)

Status.TextColor3 =
	Color3.fromRGB(
		220,
		220,
		220
	)

Status.TextSize = 12
Status.Font =
	Enum.Font.Gotham

Status.TextWrapped = true

Status.Text =
	"Status: IDLE"

Status.Parent =
	Main

local StatusCorner =
	Instance.new(
		"UICorner"
	)

StatusCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

StatusCorner.Parent =
	Status

--==================================================
-- HIDE BUTTON
--==================================================

local Hide =
	Instance.new(
		"TextButton"
	)

Hide.Size =
	UDim2.fromOffset(
		30,
		30
	)

Hide.Position =
	UDim2.new(
		1,
		-37,
		0,
		7
	)

Hide.BackgroundColor3 =
	Color3.fromRGB(
		45,
		45,
		52
	)

Hide.Text =
	"−"

Hide.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

Hide.TextSize = 20
Hide.Font =
	Enum.Font.GothamBold

Hide.Parent =
	Main

local HideCorner =
	Instance.new(
		"UICorner"
	)

HideCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

HideCorner.Parent =
	Hide

--==================================================
-- SHOW BUTTON
--==================================================

local Show =
	Instance.new(
		"TextButton"
	)

Show.Size =
	UDim2.fromOffset(
		55,
		55
	)

Show.Position =
	UDim2.new(
		0,
		15,
		0.5,
		-27
	)

Show.BackgroundColor3 =
	Color3.fromRGB(
		25,
		25,
		30
	)

Show.Text =
	"🍉"

Show.TextSize = 27
Show.Visible = false

Show.Parent =
	ScreenGui

local ShowCorner =
	Instance.new(
		"UICorner"
	)

ShowCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

ShowCorner.Parent =
	Show

Hide.MouseButton1Click:Connect(
	function()

		Main.Visible = false
		Show.Visible = true
	end
)

Show.MouseButton1Click:Connect(
	function()

		Main.Visible = true
		Show.Visible = false
	end
)

--==================================================
-- DRAG
--==================================================

local Dragging = false
local DragStart
local StartPosition

Title.InputBegan:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			Dragging = true
			DragStart =
				input.Position

			StartPosition =
				Main.Position
		end
	end
)

UIS.InputChanged:Connect(
	function(input)

		if not Dragging then
			return
		end

		if input.UserInputType
			== Enum.UserInputType.MouseMovement
			or input.UserInputType
			== Enum.UserInputType.Touch then

			local delta =
				input.Position -
				DragStart

			Main.Position =
				UDim2.new(
					StartPosition.X.Scale,
					StartPosition.X.Offset
						+ delta.X,

					StartPosition.Y.Scale,
					StartPosition.Y.Offset
						+ delta.Y
				)
		end
	end
)

UIS.InputEnded:Connect(
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			Dragging = false
		end
	end
)

--==================================================
-- STATUS LOOP
--==================================================
task.spawn(function()

	while ScreenGui.Parent do

		local targetName =
			"Không có"

		if CurrentWatermelon
			and CurrentWatermelon.Parent then

			targetName =
				CurrentWatermelon.Name
		end

		local state = "IDLE"

		if Respawning then
			state =
				"♻️ ĐANG RESPAWN"

		elseif AUTO_WATERMELON then
			state =
				"🍉 ĐANG TÌM DƯA"

		end

		Status.Text =
			"Status: "
			.. state
			.. "\nTarget: "
			.. targetName
			.. " | Speed: "
			.. tostring(SUB_SPEED)

		task.wait(0)
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

print(
	"🍉 SolRNG Watermelon V1 loaded"
)

print(
	"by sarry_fixe"
)
