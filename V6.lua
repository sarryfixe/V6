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
-- ⚙️ SETTINGS
--==================================================

local LIME_NAME = "Lime"

local ESP_ENABLED = true
local AUTO_WATERMELON = false
local AUTO_LIME = false

local SUB_SPEED = 35
local NORMAL_SPEED = 16

local TOUCH_DISTANCE = 4.5

-- Nếu đứng yên quá lâu sẽ respawn
local STUCK_TIME = 10

-- Khoảng thời gian kiểm tra nhân vật có di chuyển
local STUCK_CHECK_INTERVAL = 0.5

-- Khoảng cách giữa các waypoint
local WAYPOINT_REACHED_DISTANCE = 4

-- Thời gian chờ sau respawn
local RESPAWN_WAIT = 2

--==================================================
-- 🍉 WATERMELON KEYWORDS
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

--==================================================
-- 👤 CHARACTER
--==================================================

local Character = nil
local Humanoid = nil
local Root = nil

local CharacterReady = false

local function SetupCharacter(character)

	Character = character
	CharacterReady = false

	Humanoid = character:WaitForChild(
		"Humanoid",
		10
	)

	Root = character:WaitForChild(
		"HumanoidRootPart",
		10
	)

	if Humanoid and Root then
		CharacterReady = true
	end
end

if Player.Character then
	task.spawn(function()
		SetupCharacter(Player.Character)
	end)
end

Player.CharacterAdded:Connect(function(character)

	SetupCharacter(character)

	task.wait(0.5)

	-- Nếu Auto dưa đang bật,
	-- bắt đầu lại từ nhân vật mới.
	if AUTO_WATERMELON then
		CurrentWatermelon = nil
		PathWaypoints = nil
		PathIndex = 1
	end
end)

--==================================================
-- 📦 GET PART
--==================================================

function GetPart(object)

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
-- 🍉 CHECK WATERMELON
--==================================================

local function IsWatermelon(object)

	if not object then
		return false
	end

	local name = string.lower(
		object.Name
	)

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
-- 🍉 ESP
--==================================================

local function RemoveESP(object)

	if not object then
		return
	end

	local highlight =
		object:FindFirstChild(
			"WatermelonESP"
		)

	if highlight then
		highlight:Destroy()
	end

	local dot =
		object:FindFirstChild(
			"WatermelonDot"
		)

	if dot then
		dot:Destroy()
	end
end

local function AddESP(object)

	if not ESP_ENABLED then
		return
	end

	if not object:IsDescendantOf(
		Workspace
	) then
		return
	end

	local part =
		GetPart(object)

	if not part then
		return
	end

	-- Highlight
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

	-- 🔴 Red dot
	if not object:FindFirstChild(
		"WatermelonDot"
	) then

		local billboard =
			Instance.new(
				"BillboardGui"
			)

		billboard.Name =
			"WatermelonDot"

		billboard.Adornee =
			part

		billboard.Size =
			UDim2.fromOffset(
				16,
				16
			)

		billboard.StudsOffset =
			Vector3.new(
				0,
				3,
				0
			)

		billboard.AlwaysOnTop =
			true

		billboard.Parent =
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

		dot.Parent =
			billboard

		local corner =
			Instance.new(
				"UICorner"
			)

		corner.CornerRadius =
			UDim.new(
				1,
				0
			)

		corner.Parent =
			dot
	end
end

--==================================================
-- 🔍 SCAN WATERMELONS
--==================================================

local function GetWatermelons()

	local result = {}

	for _, object in ipairs(
		Workspace:GetDescendants()
	) do

		if IsWatermelon(object) then

			local part =
				GetPart(object)

			if part then

				table.insert(
					result,
					object
				)

				if ESP_ENABLED then
					AddESP(object)
				end
			end
		end
	end

	return result
end

Workspace.DescendantAdded:Connect(
	function(object)

		task.wait(0.05)

		if IsWatermelon(object)
		and ESP_ENABLED then

			AddESP(object)
		end
	end
)

--==================================================
-- 🎯 NEAREST WATERMELON
--==================================================

CurrentWatermelon = nil

local function GetNearestWatermelon()

	if not Root then
		return nil
	end

	local nearest = nil
	local nearestDistance =
		math.huge

	for _, object in ipairs(
		GetWatermelons()
	) do

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
-- 🚀 SPEED
--==================================================

local function SetSubSpeed()

	if Humanoid then

		Humanoid.WalkSpeed =
			math.clamp(
				SUB_SPEED,
				1,
				100
			)
	end
end

local function SetNormalSpeed()

	if Humanoid then
		Humanoid.WalkSpeed =
			NORMAL_SPEED
	end
end

--==================================================
-- 🧭 PATH VARIABLES
--==================================================

local PathWaypoints = nil
local PathIndex = 1

local LastPathTarget = nil

--==================================================
-- 🧭 COMPUTE PATH
--==================================================

local function ComputePath(targetPosition)

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

	local waypoints =
		path:GetWaypoints()

	if #waypoints == 0 then
		return false
	end

	PathWaypoints =
		waypoints

	PathIndex = 1

	LastPathTarget =
		targetPosition

	return true
end

--==================================================
-- ♻️ RESET PATH
--==================================================

local function ResetPath()

	PathWaypoints = nil
	PathIndex = 1
	LastPathTarget = nil

end

--==================================================
-- 💀 RESPAWN / UNSTUCK
--==================================================

local Respawning = false

local function RespawnBecauseStuck()

	if Respawning then
		return
	end

	Respawning = true

	-- Xóa target/path cũ
	CurrentWatermelon = nil
	ResetPath()

	-- Dừng điều khiển cũ
	if Humanoid then
		Humanoid:Move(Vector3.zero)
	end

	--==================================================
	-- Roblox respawn thông thường:
	-- làm nhân vật chết để hệ thống SpawnLocation
	-- tạo nhân vật mới.
	--==================================================

	if Humanoid
	and Humanoid.Health > 0 then

		Humanoid.Health = 0
	end

	-- Chờ CharacterAdded
	local start =
		tick()

	while tick() - start
		< 15 do

		if Player.Character
		and Player.Character
			~= Character then

			break
		end

		task.wait(0.2)
	end

	-- Nếu Character mới đã có
	if Player.Character
	and Player.Character
		~= Character then

		SetupCharacter(
			Player.Character
		)
	end

	-- Chờ ổn định
	task.wait(
		RESPAWN_WAIT
	)

	-- Tính lại từ đầu
	CurrentWatermelon = nil
	ResetPath()

	Respawning = false
end

--==================================================
-- 🧍 STUCK DETECTOR
--==================================================

local LastPosition = nil
local LastMoveTime = tick()

local function ResetStuckDetector()

	if Root then
		LastPosition =
			Root.Position
	end

	LastMoveTime =
		tick()
end

local function CheckStuck()

	if not Root then
		return false
	end

	local currentPosition =
		Root.Position

	if not LastPosition then

		LastPosition =
			currentPosition

		LastMoveTime =
			tick()

		return false
	end

	local moved =
		(
			currentPosition -
			LastPosition
		).Magnitude

	-- Có di chuyển
	if moved >= 0.5 then

		LastPosition =
			currentPosition

		LastMoveTime =
			tick()

		return false
	end

	-- Không di chuyển quá 10 giây
	if tick() - LastMoveTime
		>= STUCK_TIME then

		return true
	end

	return false
end

--==================================================
-- 🚶 FOLLOW PATH
--==================================================

local function FollowPath()

	if not Root
	or not Humanoid then

		return false
	end

	if not CurrentWatermelon then
		return false
	end

	if not CurrentWatermelon
		:IsDescendantOf(
			Workspace
		) then

		CurrentWatermelon =
			nil

		ResetPath()

		return false
	end

	local part =
		GetPart(
			CurrentWatermelon
		)

	if not part then

		CurrentWatermelon =
			nil

		ResetPath()

		return false
	end

	--==================================================
	-- Nếu chưa có path → tính path
	--==================================================

	if not PathWaypoints then

		local success =
			ComputePath(
				part.Position
			)

		if not success then

			-- Pathfinding thất bại:
			-- thử MoveTo trực tiếp
			SetSubSpeed()

			Humanoid:MoveTo(
				part.Position
			)

			return true
		end
	end

	--==================================================
	-- Kiểm tra target có đổi vị trí nhiều không
	--==================================================

	if LastPathTarget then

		if (
			LastPathTarget -
			part.Position
		).Magnitude > 8 then

			ResetPath()

			ComputePath(
				part.Position
			)
		end
	end

	--==================================================
	-- Waypoint
	--==================================================

	local waypoint =
		PathWaypoints[
			PathIndex
		]

	if not waypoint then

		ResetPath()

		return true
	end

	SetSubSpeed()

	-- Jump waypoint
	if waypoint.Action
		== Enum.PathWaypointAction.Jump then

		Humanoid.Jump = true
	end

	Humanoid:MoveTo(
		waypoint.Position
	)

	local distance =
		(
			Root.Position -
			waypoint.Position
		).Magnitude

	if distance
		<= WAYPOINT_REACHED_DISTANCE then

		PathIndex += 1
	end

	return true
end

--==================================================
-- 🍉 AUTO WATERMELON CONTROLLER
--==================================================

local AutoRunning = false

local function StartAutoWatermelon()

	if AutoRunning then
		return
	end

	AutoRunning = true

	ResetStuckDetector()

	while AUTO_WATERMELON do

		--==================================================
		-- Character check
		--==================================================

		if not CharacterReady
		or not Character
		or not Humanoid
		or not Root
		or Humanoid.Health <= 0 then

			task.wait(0.5)
			continue
		end

		--==================================================
		-- Giữ Speed
		--==================================================

		SetSubSpeed()

		--==================================================
		-- Target check
		--==================================================

		if not CurrentWatermelon
		or not CurrentWatermelon
			:IsDescendantOf(
				Workspace
			) then

			CurrentWatermelon =
				GetNearestWatermelon()

			ResetPath()
			ResetStuckDetector()
		end

		--==================================================
		-- Không có dưa
		--==================================================

		if not CurrentWatermelon then

			ResetPath()

			task.wait(
				0.5
			)

			continue
		end

		--==================================================
		-- Target part
		--==================================================

		local part =
			GetPart(
				CurrentWatermelon
			)

		if not part then

			CurrentWatermelon =
				nil

			ResetPath()

			continue
		end

		--==================================================
		-- Khoảng cách
		--==================================================

		local distance =
			(
				Root.Position -
				part.Position
			).Magnitude

		--==================================================
		-- Đã tới dưa
		--==================================================

		if distance
			<= TOUCH_DISTANCE then

			Humanoid:MoveTo(
				part.Position
			)

			task.wait(0.2)

			-- Nếu dưa biến mất
			if not CurrentWatermelon
				:IsDescendantOf(
					Workspace
				) then

				CurrentWatermelon =
					nil

				ResetPath()

			else

				-- Có thể game cần thêm
				-- một chút thời gian để
				-- xử lý Touch.
				task.wait(0.2)

				if CurrentWatermelon
					and CurrentWatermelon
						:IsDescendantOf(
							Workspace
						) then

					CurrentWatermelon =
						GetNearestWatermelon()

					ResetPath()
				end
			end

			ResetStuckDetector()

			continue
		end

		--==================================================
		-- 🚨 CHECK KẸT
		--==================================================

		if CheckStuck() then

			-- Tự respawn
			RespawnBecauseStuck()

			-- Sau respawn:
			-- tìm dưa + path mới
			CurrentWatermelon =
				nil

			ResetPath()
			ResetStuckDetector()

			continue
		end

		--==================================================
		-- 🧭 ĐI THEO PATH
		--==================================================

		FollowPath()

		task.wait(
			0.12
		)
	end

	--==================================================
	-- STOP
	--==================================================

	CurrentWatermelon = nil
	ResetPath()
	AutoRunning = false

	SetNormalSpeed()
end

--==================================================
-- 🍋 FIND LIME
--==================================================

local function FindLime()

	for _, object in ipairs(
		Workspace:GetDescendants()
	) do

		if string.lower(
			object.Name
		) == string.lower(
			LIME_NAME
		) then

			if object:IsA("Model")
			or object:IsA("BasePart") then

				return object
			end
		end
	end

	return nil
end

--==================================================
-- 🗣️ FIND LIME PROMPT
--==================================================

local function FindLimePrompt(lime)

	if not lime then
		return nil
	end

	return lime:FindFirstChildWhichIsA(
		"ProximityPrompt",
		true
	)
end

--==================================================
-- 🍋 MOVE TO LIME
--==================================================

local function MoveToLime()

	local lime =
		FindLime()

	if not lime then
		return false
	end

	local part =
		GetPart(lime)

	if not part then
		return false
	end

	SetNormalSpeed()

	-- Dùng pathfinding cho Lime
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
				part.Position
			)

		end)

	if success
	and path.Status
		== Enum.PathStatus.Success then

		for _, waypoint in ipairs(
			path:GetWaypoints()
		) do

			if not AUTO_LIME then
				return false
			end

			if waypoint.Action
				== Enum.PathWaypointAction.Jump then

				Humanoid.Jump = true
			end

			Humanoid:MoveTo(
				waypoint.Position
			)

			local start =
				tick()

			while AUTO_LIME
			and Humanoid
			and Root do

				if (
					Root.Position -
					waypoint.Position
				).Magnitude
					<= WAYPOINT_REACHED_DISTANCE then

					break
				end

				if tick() - start > 8 then
					break
				end

				task.wait(0.15)
			end
		end

	else

		Humanoid:MoveTo(
			part.Position
		)

		task.wait(1)
	end

	return true
end

--==================================================
-- 🗣️ TALK LIME
--==================================================

local function TalkToLime()

	if not Humanoid
	or not Root then
		return false
	end

	local lime =
		FindLime()

	if not lime then
		return false
	end

	local part =
		GetPart(lime)

	if not part then
		return false
	end

	local distance =
		(
			Root.Position -
			part.Position
		).Magnitude

	if distance > 8 then

		MoveToLime()

		task.wait(0.5)
	end

	local prompt =
		FindLimePrompt(
			lime
		)

	if not prompt then
		return false
	end

	if not prompt.Enabled then
		return false
	end

	--==================================================
	-- Prompt chuẩn Roblox
	--==================================================

	if prompt.HoldDuration > 0 then

		prompt:InputHoldBegin()

		task.wait(
			prompt.HoldDuration
			+ 0.1
		)

		prompt:InputHoldEnd()

	else

		prompt:InputHoldBegin()

		task.wait(0.1)

		prompt:InputHoldEnd()
	end

	return true
end

--==================================================
-- 🔘 FIND GUI BUTTON
--==================================================

local function FindButton(keywords)

	for _, object in ipairs(
		PlayerGui:GetDescendants()
	) do

		if object:IsA("TextButton")
		or object:IsA("ImageButton") then

			local name =
				string.lower(
					object.Name
				)

			local text = ""

			if object:IsA(
				"TextButton"
			) then

				text =
					string.lower(
						object.Text or ""
					)
			end

			for _, keyword in ipairs(
				keywords
			) do

				keyword =
					string.lower(
						keyword
					)

				if string.find(
					name,
					keyword,
					1,
					true
				)
				or string.find(
					text,
					keyword,
					1,
					true
				) then

					return object
				end
			end
		end
	end

	return nil
end

--==================================================
-- 🎮 CLICK MINIGAME
--==================================================

local function ClickMinigame()

	local button =
		FindButton({

			"minigame",
			"mini game",
			"mini-game"
		})

	if not button then
		return false
	end

	if button:IsA(
		"GuiButton"
	) then

		button:Activate()

		task.wait(1)

		return true
	end

	return false
end

--==================================================
-- 🍋 AUTO LIME LOOP
--==================================================

local LimeRunning = false

local function StartAutoLime()

	if LimeRunning then
		return
	end

	LimeRunning = true

	while AUTO_LIME do

		if not CharacterReady
		or not Humanoid
		or not Root then

			task.wait(0.5)
			continue
		end

		SetNormalSpeed()

		local lime =
			FindLime()

		if not lime then

			task.wait(1)

			continue
		end

		MoveToLime()

		if not AUTO_LIME then
			break
		end

		task.wait(0.5)

		TalkToLime()

		task.wait(0.8)

		if AUTO_LIME then
			ClickMinigame()
		end

		-- Không spam click Lime.
		task.wait(2)
	end

	LimeRunning = false
end

--==================================================
-- 🎨 GUI
--==================================================

local ScreenGui =
	Instance.new("ScreenGui")

ScreenGui.Name =
	"SolRNG_Watermelon_V1"

ScreenGui.ResetOnSpawn =
	false

ScreenGui.Parent =
	PlayerGui

--==================================================
-- MAIN
--==================================================

local Main =
	Instance.new("Frame")

Main.Size =
	UDim2.fromOffset(
		290,
		360
	)

Main.Position =
	UDim2.new(
		0.5,
		-145,
		0.5,
		-180
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
	Color3.fromRGB(
		255,
		255,
		255
	)

Title.TextSize = 17

Title.Font =
	Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent =
	Main

--==================================================
-- CREDIT
--==================================================

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
-- BUTTON HELPER
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
		Color3.fromRGB(
			255,
			255,
			255
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
-- 🍉 ESP BUTTON
--==================================================

local ESPButton =
	CreateButton(
		"🍉 Định vị dưa: ON",
		65
	)

local function UpdateESP()

	ESPButton.Text =
		"🍉 Định vị dưa: "
		.. (
			ESP_ENABLED
			and "ON"
			or "OFF"
		)
end

ESPButton.MouseButton1Click:Connect(
	function()

		ESP_ENABLED =
			not ESP_ENABLED

		if ESP_ENABLED then

			GetWatermelons()

		else

			for _, object in ipairs(
				Workspace:GetDescendants()
			) do

				if IsWatermelon(
					object
				) then

					RemoveESP(
						object
					)
				end
			end
		end

		UpdateESP()
	end
)

--==================================================
-- 🤖 AUTO WATERMELON
--==================================================

local AutoButton =
	CreateButton(
		"🤖 Auto tìm dưa: OFF",
		113
	)

local function UpdateAuto()

	AutoButton.Text =
		"🤖 Auto tìm dưa: "
		.. (
			AUTO_WATERMELON
			and "ON"
			or "OFF"
		)
end

AutoButton.MouseButton1Click:Connect(
	function()

		AUTO_WATERMELON =
			not AUTO_WATERMELON

		if AUTO_WATERMELON then

			-- Auto dưa không chạy
			-- cùng lúc với Lime.
			AUTO_LIME = false

			CurrentWatermelon =
				nil

			ResetPath()

			task.spawn(
				StartAutoWatermelon
			)

		else

			CurrentWatermelon =
				nil

			ResetPath()

			SetNormalSpeed()
		end

		UpdateAuto()
		UpdateLime()
	end
)

--==================================================
-- 🍋 LIME
--==================================================

local LimeButton =
	CreateButton(
		"🍋 Đi tới Lime: OFF",
		161
	)

function UpdateLime()

	LimeButton.Text =
		"🍋 Đi tới Lime: "
		.. (
			AUTO_LIME
			and "ON"
			or "OFF"
		)
end

LimeButton.MouseButton1Click:Connect(
	function()

		AUTO_LIME =
			not AUTO_LIME

		if AUTO_LIME then

			AUTO_WATERMELON =
				false

			CurrentWatermelon =
				nil

			ResetPath()

			SetNormalSpeed()

			task.spawn(
				StartAutoLime
			)

		else

			SetNormalSpeed()
		end

		UpdateLime()
		UpdateAuto()
	end
)

--==================================================
-- 🚀 SPEED LABEL
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
	"🚀 SubSpeed — 1 đến 100"

SpeedLabel.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

SpeedLabel.TextSize = 13

SpeedLabel.Font =
	Enum.Font.GothamBold

SpeedLabel.TextXAlignment =
	Enum.TextXAlignment.Left

SpeedLabel.Parent =
	Main

--==================================================
-- 🔢 SPEED BOX
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
	"Nhập 1 - 100"

SpeedBox.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
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

		value =
			math.clamp(
				math.floor(
					value
				),
				1,
				100
			)

		SUB_SPEED =
			value

		SpeedBox.Text =
			tostring(
				SUB_SPEED
			)

		if AUTO_WATERMELON then
			SetSubSpeed()
		end
	end
)

--==================================================
-- 📊 STATUS
--==================================================

local Status =
	Instance.new(
		"TextLabel"
	)

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

Status.TextWrapped =
	true

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
-- ➖ HIDE
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
	Color3.fromRGB(
		255,
		255,
		255
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
-- 👁️ SHOW
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

Show.Visible =
	false

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

		Main.Visible =
			false

		Show.Visible =
			true
	end
)

Show.MouseButton1Click:Connect(
	function()

		Main.Visible =
			true

		Show.Visible =
			false
	end
)

--==================================================
-- 🖱️ DRAG MENU
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

			Dragging =
				true

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

			Dragging =
				false
		end
	end
)

--==================================================
-- 📊 STATUS LOOP
--==================================================

task.spawn(function()

	while ScreenGui.Parent do

		local target =
			"Không có"

		if CurrentWatermelon
		and CurrentWatermelon.Parent then

			target =
				CurrentWatermelon.Name
		end

		local state =
			"IDLE"

		if Respawning then

			state =
				"RESPAWN / CHỐNG KẸT"

		elseif AUTO_LIME then

			state =
				"ĐANG TỚI LIME"

		elseif AUTO_WATERMELON then

			state =
				"ĐANG TÌM DƯA"
		end

		Status.Text =
			"Status: "
			.. state
			.. "\nDưa: "
			.. target
			.. " | Speed: "
			.. tostring(
				SUB_SPEED
			)

		task.wait(
			0.25
		)
	end
end)

--==================================================
-- 🔄 ESP LOOP
--==================================================

task.spawn(function()

	while ScreenGui.Parent do

		if ESP_ENABLED then
			GetWatermelons()
		end

		task.wait(
			1
		)
	end
end)

--==================================================
-- 🧹 TARGET CLEANUP
--==================================================

Workspace.DescendantRemoving:Connect(
	function(object)

		if object ==
			CurrentWatermelon then

			CurrentWatermelon =
				nil

			ResetPath()
		end
	end
)

--==================================================
-- 🚀 INITIAL
--==================================================

GetWatermelons()

print(
	"🍉 SolRNG Watermelon V1 loaded"
)

print(
	"by sarry_fixe"
)
