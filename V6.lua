--==================================================
-- 🍉 SolRNG Watermelon V1
-- by sarry_fixe
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- ⚙️ SETTINGS
--==================================================

local ESP_ENABLED = true
local AUTO_WALK = false

local SUB_SPEED = 35
local NORMAL_SPEED = 16

local TOUCH_DISTANCE = 5
local MOVE_DELAY = 0.12
local SCAN_DELAY = 0.35

local WatermelonKeywords = {
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

local Character
local Humanoid
local Root

local function SetupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    Root = char:WaitForChild("HumanoidRootPart")
end

if Player.Character then
    task.spawn(SetupCharacter, Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    SetupCharacter(char)
end)

--==================================================
-- 🔎 CHECK WATERMELON
--==================================================

local function IsWatermelon(obj)
    if not obj then
        return false
    end

    local name = string.lower(obj.Name)

    for _, keyword in ipairs(WatermelonKeywords) do
        if string.find(name, keyword, 1, true) then
            return true
        end
    end

    return false
end

--==================================================
-- 📍 GET PART
--==================================================

local function GetPart(obj)
    if not obj then
        return nil
    end

    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart
        end

        return obj:FindFirstChildWhichIsA("BasePart", true)
    end

    return obj:FindFirstChildWhichIsA("BasePart", true)
end

--==================================================
-- 🍉 ESP
--==================================================

local function RemoveESP(obj)
    if not obj then
        return
    end

    local h = obj:FindFirstChild("WatermelonESP")
    if h then
        h:Destroy()
    end

    local d = obj:FindFirstChild("WatermelonDot")
    if d then
        d:Destroy()
    end
end

local function AddESP(obj)
    if not ESP_ENABLED then
        return
    end

    if not obj or not obj:IsDescendantOf(Workspace) then
        return
    end

    local part = GetPart(obj)

    if not part then
        return
    end

    -- Highlight
    if not obj:FindFirstChild("WatermelonESP") then
        local highlight = Instance.new("Highlight")

        highlight.Name = "WatermelonESP"
        highlight.Adornee = obj
        highlight.FillTransparency = 0.65
        highlight.OutlineTransparency = 0
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        highlight.Parent = obj
    end

    -- 🔴 Dot
    if not obj:FindFirstChild("WatermelonDot") then
        local gui = Instance.new("BillboardGui")

        gui.Name = "WatermelonDot"
        gui.Adornee = part
        gui.Size = UDim2.fromOffset(16, 16)
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.AlwaysOnTop = true

        gui.Parent = obj

        local dot = Instance.new("Frame")

        dot.Size = UDim2.fromScale(1, 1)
        dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        dot.BorderSizePixel = 0

        dot.Parent = gui

        local corner = Instance.new("UICorner")

        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = dot
    end
end

--==================================================
-- 🔍 SCAN
--==================================================

local function ScanWatermelons()
    local list = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsWatermelon(obj) then
            local part = GetPart(obj)

            if part then
                table.insert(list, obj)

                if ESP_ENABLED then
                    AddESP(obj)
                end
            end
        end
    end

    return list
end

Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.05)

    if IsWatermelon(obj) then
        if ESP_ENABLED then
            AddESP(obj)
        end
    end
end)

--==================================================
-- 🎯 NEAREST WATERMELON
--==================================================

local function GetNearestWatermelon()
    if not Root then
        return nil
    end

    local nearest
    local nearestDistance = math.huge

    for _, obj in ipairs(ScanWatermelons()) do
        if obj and obj:IsDescendantOf(Workspace) then

            local part = GetPart(obj)

            if part then
                local distance =
                    (Root.Position - part.Position).Magnitude

                if distance < nearestDistance then
                    nearestDistance = distance
                    nearest = obj
                end
            end
        end
    end

    return nearest
end

--==================================================
-- 🚀 SET SPEED
--==================================================

local function ApplySpeed()
    if not Humanoid then
        return
    end

    if AUTO_WALK then
        Humanoid.WalkSpeed = math.clamp(
            SUB_SPEED,
            1,
            100
        )
    else
        Humanoid.WalkSpeed = NORMAL_SPEED
    end
end

--==================================================
-- 🍉 AUTO WALK
--==================================================

local CurrentTarget = nil

local function AutoWalkLoop()
    while AUTO_WALK do

        if not Character
        or not Humanoid
        or not Root
        or Humanoid.Health <= 0 then

            task.wait(0.5)
            continue
        end

        -- Luôn giữ speed người dùng chọn
        Humanoid.WalkSpeed = math.clamp(
            SUB_SPEED,
            1,
            100
        )

        -- Nếu target cũ không còn tồn tại
        if not CurrentTarget
        or not CurrentTarget:IsDescendantOf(Workspace) then

            CurrentTarget = GetNearestWatermelon()
        end

        if CurrentTarget then

            local part = GetPart(CurrentTarget)

            if part then

                local distance =
                    (Root.Position - part.Position).Magnitude

                -- Đã tới dưa
                if distance <= TOUCH_DISTANCE then

                    -- Đứng sát để game nhận touch
                    Humanoid:MoveTo(part.Position)

                    task.wait(0.2)

                    -- Nếu dưa vẫn còn thì bỏ target
                    if CurrentTarget
                    and CurrentTarget:IsDescendantOf(Workspace) then

                        CurrentTarget = nil
                    end

                else

                    -- Đi thẳng tới dưa
                    Humanoid:MoveTo(part.Position)
                end

            else
                CurrentTarget = nil
            end

        else
            task.wait(SCAN_DELAY)
        end

        task.wait(MOVE_DELAY)
    end

    CurrentTarget = nil

    if Humanoid then
        Humanoid.WalkSpeed = NORMAL_SPEED
    end
end

--==================================================
-- 🎨 GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "SolRNG_Watermelon_V1"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

--==================================================
-- 📦 MAIN MENU
--==================================================

local Main = Instance.new("Frame")

Main.Size = UDim2.fromOffset(285, 315)
Main.Position = UDim2.new(0.5, -142, 0.5, -157)

Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0

Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")

MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

--==================================================
-- 🏷️ TITLE
--==================================================

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1, -45, 0, 38)
Title.Position = UDim2.fromOffset(12, 2)

Title.BackgroundTransparency = 1

Title.Text = "🍉 SolRNG Watermelon V1"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold

Title.TextXAlignment = Enum.TextXAlignment.Left

Title.Parent = Main

--==================================================
-- 💳 CREDIT
--==================================================

local Credit = Instance.new("TextLabel")

Credit.Size = UDim2.new(1, -20, 0, 20)
Credit.Position = UDim2.fromOffset(12, 35)

Credit.BackgroundTransparency = 1

Credit.Text = "by sarry_fixe"
Credit.TextColor3 = Color3.fromRGB(160, 160, 160)
Credit.TextSize = 11
Credit.Font = Enum.Font.Gotham

Credit.TextXAlignment = Enum.TextXAlignment.Left

Credit.Parent = Main

--==================================================
-- ➖ HIDE
--==================================================

local Hide = Instance.new("TextButton")

Hide.Size = UDim2.fromOffset(30, 30)
Hide.Position = UDim2.new(1, -37, 0, 7)

Hide.BackgroundColor3 = Color3.fromRGB(45, 45, 52)

Hide.Text = "−"
Hide.TextColor3 = Color3.fromRGB(255, 255, 255)
Hide.TextSize = 20
Hide.Font = Enum.Font.GothamBold

Hide.Parent = Main

local HideCorner = Instance.new("UICorner")

HideCorner.CornerRadius = UDim.new(0, 8)
HideCorner.Parent = Hide

--==================================================
-- 🍉 ESP BUTTON
--==================================================

local ESPButton = Instance.new("TextButton")

ESPButton.Size = UDim2.new(1, -24, 0, 42)
ESPButton.Position = UDim2.fromOffset(12, 65)

ESPButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)

ESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPButton.TextSize = 14
ESPButton.Font = Enum.Font.GothamBold

ESPButton.Parent = Main

local ESPCorner = Instance.new("UICorner")

ESPCorner.CornerRadius = UDim.new(0, 8)
ESPCorner.Parent = ESPButton

local function UpdateESP()
    ESPButton.Text =
        "🍉 Định vị dưa: " ..
        (ESP_ENABLED and "ON" or "OFF")
end

UpdateESP()

ESPButton.MouseButton1Click:Connect(function()

    ESP_ENABLED = not ESP_ENABLED

    if ESP_ENABLED then
        ScanWatermelons()
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if IsWatermelon(obj) then
                RemoveESP(obj)
            end
        end
    end

    UpdateESP()
end)

--==================================================
-- 🤖 AUTO BUTTON
--==================================================

local AutoButton = Instance.new("TextButton")

AutoButton.Size = UDim2.new(1, -24, 0, 42)
AutoButton.Position = UDim2.fromOffset(12, 113)

AutoButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)

AutoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoButton.TextSize = 14
AutoButton.Font = Enum.Font.GothamBold

AutoButton.Parent = Main

local AutoCorner = Instance.new("UICorner")

AutoCorner.CornerRadius = UDim.new(0, 8)
AutoCorner.Parent = AutoButton

local function UpdateAuto()
    AutoButton.Text =
        "🤖 Auto tìm dưa: " ..
        (AUTO_WALK and "ON" or "OFF")
end

UpdateAuto()

AutoButton.MouseButton1Click:Connect(function()

    AUTO_WALK = not AUTO_WALK

    UpdateAuto()
    ApplySpeed()

    if AUTO_WALK then
        task.spawn(AutoWalkLoop)
    end
end)

--==================================================
-- 🚀 SPEED
--==================================================

local SpeedLabel = Instance.new("TextLabel")

SpeedLabel.Size = UDim2.new(1, -24, 0, 25)
SpeedLabel.Position = UDim2.fromOffset(12, 165)

SpeedLabel.BackgroundTransparency = 1

SpeedLabel.Text = "🚀 SubSpeed — 1 đến 100"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextSize = 13
SpeedLabel.Font = Enum.Font.GothamBold

SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

SpeedLabel.Parent = Main

--==================================================
-- 🔢 SPEED BOX
--==================================================

local SpeedBox = Instance.new("TextBox")

SpeedBox.Size = UDim2.new(1, -24, 0, 42)
SpeedBox.Position = UDim2.fromOffset(12, 192)

SpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)

SpeedBox.Text = tostring(SUB_SPEED)
SpeedBox.PlaceholderText = "Nhập 1 - 100"

SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)

SpeedBox.TextSize = 14
SpeedBox.Font = Enum.Font.GothamBold

SpeedBox.ClearTextOnFocus = false

SpeedBox.Parent = Main

local SpeedCorner = Instance.new("UICorner")

SpeedCorner.CornerRadius = UDim.new(0, 8)
SpeedCorner.Parent = SpeedBox

SpeedBox.FocusLost:Connect(function()

    local value = tonumber(SpeedBox.Text)

    if not value then
        SpeedBox.Text = tostring(SUB_SPEED)
        return
    end

    value = math.floor(value)

    value = math.clamp(
        value,
        1,
        100
    )

    SUB_SPEED = value

    SpeedBox.Text = tostring(SUB_SPEED)

    if AUTO_WALK and Humanoid then
        Humanoid.WalkSpeed = SUB_SPEED
    end
end)

--==================================================
-- 📊 STATUS
--==================================================

local Status = Instance.new("TextLabel")

Status.Size = UDim2.new(1, -24, 0, 45)
Status.Position = UDim2.fromOffset(12, 244)

Status.BackgroundColor3 = Color3.fromRGB(35, 35, 42)

Status.TextColor3 = Color3.fromRGB(220, 220, 220)

Status.TextSize = 12
Status.Font = Enum.Font.Gotham

Status.TextWrapped = true
Status.Text = "Status: IDLE"

Status.Parent = Main

local StatusCorner = Instance.new("UICorner")

StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = Status

--==================================================
-- 👁️ SHOW BUTTON
--==================================================

local Show = Instance.new("TextButton")

Show.Size = UDim2.fromOffset(55, 55)
Show.Position = UDim2.new(0, 15, 0.5, -27)

Show.BackgroundColor3 = Color3.fromRGB(25, 25, 30)

Show.Text = "🍉"
Show.TextSize = 27

Show.Visible = false

Show.Parent = ScreenGui

local ShowCorner = Instance.new("UICorner")

ShowCorner.CornerRadius = UDim.new(1, 0)
ShowCorner.Parent = Show

Hide.MouseButton1Click:Connect(function()
    Main.Visible = false
    Show.Visible = true
end)

Show.MouseButton1Click:Connect(function()
    Main.Visible = true
    Show.Visible = false
end)

--==================================================
-- 🖱️ DRAG MENU
--==================================================

local Dragging = false
local DragStart
local StartPosition

Title.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = true

        DragStart = input.Position
        StartPosition = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)

    if not Dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then

        local Delta =
            input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,

            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        Dragging = false
    end
end)

--==================================================
-- 📊 STATUS LOOP
--==================================================

task.spawn(function()

    while ScreenGui.Parent do

        local target = "Không có"

        if CurrentTarget
        and CurrentTarget.Parent then

            target = CurrentTarget.Name
        end

        Status.Text =
            "Status: " ..
            (AUTO_WALK and "AUTO" or "IDLE") ..
            "\nDưa: " ..
            target ..
            " | Speed: " ..
            tostring(SUB_SPEED)

        task.wait(0.25)
    end
end)

--==================================================
-- 🔄 ESP SCAN LOOP
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
-- 🧹 CLEANUP TARGET
--==================================================

Workspace.DescendantRemoving:Connect(function(obj)

    if obj == CurrentTarget then
        CurrentTarget = nil
    end
end)

--==================================================
-- 🚀 START
--==================================================

ScanWatermelons()

print("🍉 SolRNG Watermelon V1 loaded")
print("by sarry_fixe")
