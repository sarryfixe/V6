--==================================================
-- 🍉 SolRNG Watermelon V1
-- by sarry_fixe
--==================================================
-- Chức năng:
-- 🍉 Định vị dưa + chấm đỏ
-- 🤖 Auto tìm và đi tới dưa
-- 🚀 SubSpeed 1-100
-- 🍋 Tự đi tới Lime
-- 🗣️ Tự Talk với Lime
-- 🎮 Tự chọn Minigame
-- 🎟️ Minigame sẽ do hệ thống game xử lý Ticket
-- 🖱️ Menu kéo được
-- 👁️ Ẩn / hiện menu
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local LIME_NAME = "Lime"

local ESP_ENABLED = true
local AUTO_WATERMELON = false
local AUTO_LIME = false

local SUB_SPEED = 35
local NORMAL_SPEED = 16

local TOUCH_DISTANCE = 4.5
local MOVE_INTERVAL = 0.12
local SCAN_INTERVAL = 0.5

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

local function SetupCharacter(character)
	Character = character
	Humanoid = character:WaitForChild("Humanoid")
	Root = character:WaitForChild("HumanoidRootPart")
end

if Player.Character then
	task.spawn(SetupCharacter, Player.Character)
end

Player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	SetupCharacter(character)
end)

--==================================================
-- OBJECT PART
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
-- WATERMELON DETECTION
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

	local highlight = object:FindFirstChild(
		"WatermelonESP"
	)

	if highlight then
		highlight:Destroy()
	end

	local dot = object:FindFirstChild(
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

	if not object:IsDescendantOf(Workspace) then
		return
	end

	local part = GetPart(object)

	if not part then
		return
	end

	-- Highlight
	if not object:FindFirstChild("WatermelonESP") then

		local highlight = Instance.new("Highlight")

		highlight.Name = "WatermelonESP"
		highlight.Adornee = object

		highlight.FillTransparency = 0.65
		highlight.OutlineTransparency = 0

		highlight.FillColor =
			Color3.fromRGB(255, 0, 0)

		highlight.OutlineColor =
			Color3.fromRGB(255, 255, 255)

		highlight.DepthMode =
			Enum.HighlightDepthMode.AlwaysOnTop

		highlight.Parent = object
	end

	-- Red dot
	if not object:FindFirstChild("WatermelonDot") then

		local billboard = Instance.new(
			"BillboardGui"
		)

		billboard.Name = "WatermelonDot"
		billboard.Adornee = part

		billboard.Size =
			UDim2.fromOffset(16, 16)

		billboard.StudsOffset =
			Vector3.new(0, 3, 0)

		billboard.AlwaysOnTop = true
		billboard.Parent = object

		local dot = Instance.new("Frame")

		dot.Size = UDim2.fromScale(1, 1)

		dot.BackgroundColor3 =
			Color3.fromRGB(255, 0, 0)

		dot.BorderSizePixel = 0
		dot.Parent = billboard

		local corner = Instance.new("UICorner")

		corner.CornerRadius =
			UDim.new(1, 0)

		corner.Parent = dot
	end
end

--==================================================
-- SCAN WATERMELONS
--==================================================

local function GetWatermelons()
	local result = {}

	for _, object in ipairs(
		Workspace:GetDescendants()
	) do

		if IsWatermelon(object) then

			local part = GetPart(object)

			if part then
				table.insert(result, object)

				if ESP_ENABLED then
					AddESP(object)
				end
			end
		end
	end

	return result
end

Workspace.DescendantAdded:Connect(function(object)

	task.wait(0.05)

	if IsWatermelon(object)
	and ESP_ENABLED then

		AddESP(object)
	end
end)

--==================================================
-- NEAREST WATERMELON
--==================================================

local CurrentWatermelon = nil

local function GetNearestWatermelon()
	if not Root then
		return nil
	end

	local nearest = nil
	local nearestDistance = math.huge

	for _, object in ipairs(
		GetWatermelons()
	) do

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

local function SetNormalSpeed()
	if Humanoid then
		Humanoid.WalkSpeed = NORMAL_SPEED
	end
end

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

--==================================================
-- MOVE TO
--==================================================

local function MoveToPosition(
	position,
	speed
)
	if not Humanoid or not Root then
		return false
	end

	Humanoid.WalkSpeed = speed

	Humanoid:MoveTo(position)

	while Humanoid
	and Root
	and Humanoid.Health > 0 do

		local distance =
			(Root.Position - position).Magnitude

		if distance <= TOUCH_DISTANCE then
			return true
		end

		Humanoid:MoveTo(position)

		task.wait(MOVE_INTERVAL)
	end

	return false
end

--==================================================
-- AUTO WATERMELON
--==================================================

task.spawn(function()

	while true do

		if AUTO_WATERMELON
		and not AUTO_LIME
		and Humanoid
		and Root
		and Humanoid.Health > 0 then

			SetSubSpeed()

			if not CurrentWatermelon
			or not CurrentWatermelon:IsDescendantOf(
				Workspace
			) then

				CurrentWatermelon =
					GetNearestWatermelon()
			end

			if CurrentWatermelon then

				local part =
					GetPart(CurrentWatermelon)

				if part then

					local distance =
						(
							Root.Position -
							part.Position
						).Magnitude

					if distance <= TOUCH_DISTANCE then

						-- đứng sát dưa
						Humanoid:MoveTo(
							part.Position
						)

						task.wait(0.15)

						-- Nếu game phá dưa
						-- bằng Touch thì ở đây
						-- nhân vật đã chạm dưa.

						if not CurrentWatermelon
						:IsDescendantOf(Workspace) then

							CurrentWatermelon = nil

						else

							-- kiểm tra lại
							CurrentWatermelon =
								GetNearestWatermelon()
						end

					else

						Humanoid:MoveTo(
							part.Position
						)

					end

				else
					CurrentWatermelon = nil
				end

			else
				task.wait(SCAN_INTERVAL)
			end

		else
			task.wait(0.2)
		end

		task.wait(MOVE_INTERVAL)
	end
end)

--==================================================
-- FIND LIME
--==================================================

local function FindLime()

	for _, object in ipairs(
		Workspace:GetDescendants()
	) do

		if string.lower(object.Name)
			== string.lower(LIME_NAME) then

			if object:IsA("Model")
			or object:IsA("BasePart") then

				return object
			end
		end
	end

	return nil
end

--==================================================
-- FIND PROXIMITY PROMPT
--==================================================

local function FindPrompt(object)

	if not object then
		return nil
	end

	return object:FindFirstChildWhichIsA(
		"ProximityPrompt",
		true
	)
end

--==================================================
-- TALK TO LIME
--==================================================

local function TalkToLime()

	local lime = FindLime()

	if not lime then
		return false
	end

	local part = GetPart(lime)

	if not part then
		return false
	end

	SetNormalSpeed()

	local reached =
		MoveToPosition(
			part.Position,
			NORMAL_SPEED
		)

	if not reached then
		return false
	end

	task.wait(0.5)

	local prompt =
		FindPrompt(lime)

	if prompt then

		-- Khi prompt ở gần, Roblox sẽ
		-- cho phép người chơi kích hoạt
		-- bằng Input nếu Prompt được thiết kế
		-- trong game của bạn.

		if prompt.Enabled then

			prompt:InputHoldBegin()

			task.wait(
				math.max(
					prompt.HoldDuration,
					0.1
				)
			)

			prompt:InputHoldEnd()

			return true
		end
	end

	return false
end

--==================================================
-- FIND GUI BUTTON BY TEXT / NAME
--==================================================

local function FindButton(keywords)

	for _, object in ipairs(
		PlayerGui:GetDescendants()
	) do

		if object:IsA("TextButton")
		or object:IsA("ImageButton") then

			local name =
				string.lower(object.Name)

			local text = ""

			if object:IsA("TextButton") then
				text =
					string.lower(
						object.Text or ""
					)
			end

			for _, keyword in ipairs(
				keywords
			) do

				keyword =
					string.lower(keyword)

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
-- CLICK GUI BUTTON
--==================================================

local function ActivateButton(button)

	if not button then
		return false
	end

	if button:IsA("GuiButton") then

		button:Activate()

		return true
	end

	return false
end

--==================================================
-- MINIGAME BUTTON
--==================================================

local function ClickMinigame()

	-- ảnh của bạn cho thấy:
	-- [ Minigame ]

	local button =
		FindButton({
			"minigame",
			"mini game",
			"mini-game"
		})

	if button then

		ActivateButton(button)

		task.wait(1)

		return true
	end

	return false
end

--==================================================
-- AUTO LIME
--==================================================

local LimeBusy = false

local function RunLime()

	if LimeBusy then
		return
	end

	LimeBusy = true

	-- Dừng auto dưa
	CurrentWatermelon = nil

	-- Đi Lime + Talk
	local talked =
		TalkToLime()

	if talked then

		task.wait(0.8)

		-- Bấm Minigame
		ClickMinigame()

		task.wait(1)

	end

	LimeBusy = false
end

--==================================================
-- AUTO LIME LOOP
--==================================================

task.spawn(function()

	while true do

		if AUTO_LIME then

			RunLime()

		else

			task.wait(0.3)

		end

		task.wait(0.5)
	end
end)

--==================================================
-- GUI
--==================================================

local ScreenGui =
	Instance.new("ScreenGui")

ScreenGui.Name =
	"SolRNG_Watermelon_V1"

ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

--==================================================
-- MAIN
--==================================================

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
	UDim.new(0, 12)

MainCorner.Parent = Main

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
	UDim2.fromOffset(12, 2)

Title.BackgroundTransparency = 1

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

Title.Parent = Main

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
	UDim2.fromOffset(12, 35)

Credit.BackgroundTransparency = 1

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

Credit.Parent = Main

--==================================================
-- HIDE
--==================================================

local Hide =
	Instance.new("TextButton")

Hide.Size =
	UDim2.fromOffset(30, 30)

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

Hide.Text = "−"

Hide.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

Hide.TextSize = 20
Hide.Font =
	Enum.Font.GothamBold

Hide.Parent = Main

local function MakeCorner(object)
	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(0, 8)

	corner.Parent = object
end

MakeCorner(Hide)

--==================================================
-- BUTTON CREATOR
--==================================================

local function CreateButton(
	text,
	y
)

	local button =
		Instance.new("TextButton")

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

	button.Text = text

	button.Parent = Main

	MakeCorner(button)

	return button
end

--==================================================
-- ESP BUTTON
--==================================================

local ESPButton =
	CreateButton(
		"🍉 Định vị dưa: ON",
		65
	)

local function UpdateESPButton()

	ESPButton.Text =
		"🍉 Định vị dưa: " ..
		(
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

				if IsWatermelon(object) then
					RemoveESP(object)
				end
			end
		end

		UpdateESPButton()
	end
)

--==================================================
-- AUTO WATERMELON BUTTON
--==================================================

local AutoWatermelonButton =
	CreateButton(
		"🤖 Auto tìm dưa: OFF",
		113
	)

local function UpdateAutoWatermelon()

	AutoWatermelonButton.Text =
		"🤖 Auto tìm dưa: " ..
		(
			AUTO_WATERMELON
			and "ON"
			or "OFF"
		)
end

AutoWatermelonButton.MouseButton1Click:Connect(
	function()

		AUTO_WATERMELON =
			not AUTO_WATERMELON

		if AUTO_WATERMELON then
			AUTO_LIME = false
			CurrentWatermelon = nil
		else
			SetNormalSpeed()
		end

		UpdateAutoWatermelon()
		UpdateAutoLime()
	end
)

--==================================================
-- LIME BUTTON
--==================================================

local AutoLimeButton =
	CreateButton(
		"🍋 Đi tới Lime: OFF",
		161
	)

function UpdateAutoLime()

	AutoLimeButton.Text =
		"🍋 Đi tới Lime: " ..
		(
			AUTO_LIME
			and "ON"
			or "OFF"
		)
end

AutoLimeButton.MouseButton1Click:Connect(
	function()

		AUTO_LIME =
			not AUTO_LIME

		if AUTO_LIME then

			-- Không chạy dưa cùng lúc
			AUTO_WATERMELON = false
			CurrentWatermelon = nil

			SetNormalSpeed()

		else

			SetNormalSpeed()
		end

		UpdateAutoLime()
		UpdateAutoWatermelon()
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

SpeedLabel.BackgroundTransparency = 1

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

SpeedLabel.Parent = Main

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
	tostring(SUB_SPEED)

SpeedBox.PlaceholderText =
	"Nhập tốc độ 1 - 100"

SpeedBox.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

SpeedBox.TextSize = 14

SpeedBox.Font =
	Enum.Font.GothamBold

SpeedBox.ClearTextOnFocus = false

SpeedBox.Parent = Main

MakeCorner(SpeedBox)

SpeedBox.FocusLost:Connect(
	function()

		local value =
			tonumber(
				SpeedBox.Text
			)

		if not value then

			SpeedBox.Text =
				tostring(SUB_SPEED)

			return
		end

		value =
			math.clamp(
				math.floor(value),
				1,
				100
			)

		SUB_SPEED = value

		SpeedBox.Text =
			tostring(SUB_SPEED)

		if AUTO_WATERMELON then
			SetSubSpeed()
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

Status.Parent = Main

MakeCorner(Status)

--==================================================
-- SHOW BUTTON
--==================================================

local Show =
	Instance.new("TextButton")

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

Show.Text = "🍉"
Show.TextSize = 27

Show.Visible = false

Show.Parent = ScreenGui

local ShowCorner =
	Instance.new("UICorner")

ShowCorner.CornerRadius =
	UDim.new(1, 0)

ShowCorner.Parent = Show

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
-- DRAG MENU
--==================================================

local Dragging = false
local DragStart
local StartPosition

Title.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			Dragging = true
			DragStart = input.Position
			StartPosition =
				Main.Position
		end
	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if not Dragging then
			return
		end

		if input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			local delta =
				input.Position -
				DragStart

			Main.Position =
				UDim2.new(
					StartPosition.X.Scale,
					StartPosition.X.Offset +
						delta.X,

					StartPosition.Y.Scale,
					StartPosition.Y.Offset +
						delta.Y
				)
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			Dragging = false
		end
	end
)

--==================================================
-- STATUS LOOP
--==================================================

task.spawn(function()

	while ScreenGui.Parent do

		local target = "Không có"

		if CurrentWatermelon
		and CurrentWatermelon.Parent then

			target =
				CurrentWatermelon.Name
		end

		local state = "IDLE"

		if AUTO_LIME then
			state = "ĐANG TỚI LIME"
		elseif AUTO_WATERMELON then
			state = "ĐANG TÌM DƯA"
		end

		Status.Text =
			"Status: " ..
			state ..
			"\nDưa: " ..
			target ..
			" | Speed: " ..
			tostring(SUB_SPEED)

		task.wait(0.25)
	end
end)

--==================================================
-- ESP SCAN LOOP
--==================================================

task.spawn(function()

	while ScreenGui.Parent do

		if ESP_ENABLED then
			GetWatermelons()
		end

		task.wait(1)
	end
end)

--==================================================
-- CLEAN TARGET
--==================================================

Workspace.DescendantRemoving:Connect(
	function(object)

		if object ==
			CurrentWatermelon then

			CurrentWatermelon = nil
		end
	end
)

--==================================================
-- START
--==================================================

GetWatermelons()

print(
	"🍉 SolRNG Watermelon V1 loaded"
)

print(
	"by sarry_fixe"
)
