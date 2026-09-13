--==================================================
-- 🍉 SolRNG Watermelon V1
-- by sarry_fixe
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- ⚙️ SETTINGS
--==================================================

local ESP_ENABLED = true
local AUTO_MINIGAME = false

local SUB_SPEED = 35
local NORMAL_SPEED = 16

local TOUCH_DISTANCE = 5
local SCAN_DELAY = 0.5
local MOVE_DELAY = 0.18

local LIME_NAME = "Lime"

local WATERMELON_NAMES = {
    "watermelon",
    "melon",
    "dua",
    "duahau",
    "dưa",
    "dưahấu",
    "dưa hấu"
}

--==================================================
-- 🧠 STATE
--==================================================

local STATE = "IDLE"

local Character
local Humanoid
local Root

local CurrentWatermelon = nil
local Running = false

local BrightBaseline = nil
local WasDark = false

--==================================================
-- 👤 CHARACTER
--==================================================

local function SetupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    Root = char:WaitForChild("HumanoidRootPart")
end

if Player.Character then
    task.spawn(SetupCharacter, Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    SetupCharacter(char)
end)

--==================================================
-- 🔎 WATERMELON CHECK
--==================================================

local function IsWatermelon(obj)
    if not obj then
        return false
    end

    local name = string.lower(obj.Name)

    for _, keyword in ipairs(WATERMELON_NAMES) do
        if string.find(name, keyword, 1, true) then
            return true
        end
    end

    return false
end

--==================================================
-- 📦 GET PART
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

    local highlight = obj:FindFirstChild("WatermelonESP")
    if highlight then
        highlight:Destroy()
    end

    local dot = obj:FindFirstChild("WatermelonDot")
    if dot then
        dot:Destroy()
    end
end

local function AddESP(obj)
    if not ESP_ENABLED or not obj then
        return
    end

    local part = GetPart(obj)
    if not part then
        return
    end

    -- Highlight
    if not obj:FindFirstChild("WatermelonESP") then
        local h = Instance.new("Highlight")
        h.Name = "WatermelonESP"
        h.Adornee = obj
        h.FillTransparency = 0.65
        h.OutlineTransparency = 0
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = obj
    end

    -- 🔴 Red dot
    if not obj:FindFirstChild("WatermelonDot") then
        local gui = Instance.new("BillboardGui")
        gui.Name = "WatermelonDot"
        gui.Adornee = part
        gui.Size = UDim2.fromOffset(18, 18)
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
-- 🔍 SCAN WATERMELONS
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

    if IsWatermelon(obj) and ESP_ENABLED then
        AddESP(obj)
    end
end)

--==================================================
-- 🎯 NEAREST WATERMELON
--==================================================

local function GetNearestWatermelon()
    if not Root then
        return nil
    end

    local nearest = nil
    local nearestDistance = math.huge

    for _, obj in ipairs(ScanWatermelons()) do
        local part = GetPart(obj)

        if part and part:IsDescendantOf(Workspace) then
            local distance = (Root.Position - part.Position).Magnitude

            if distance < nearestDistance then
                nearestDistance = distance
                nearest = obj
            end
        end
    end

    return nearest
end

--==================================================
-- 🍋 FIND LIME
--==================================================

local function FindLime()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if string.lower(obj.Name) == string.lower(LIME_NAME) then
            if obj:IsA("Model") or obj:IsA("BasePart") then
                return obj
            end
        end
    end

    return nil
end

--==================================================
-- 📍 GET LIME POSITION
--==================================================

local function GetObjectPosition(obj)
    local part = GetPart(obj)

    if part then
        return part.Position
    end

    return nil
end

--==================================================
-- 🚶 SIMPLE MOVE
--==================================================

local function StopMove()
    if Humanoid and Root then
        Humanoid:Move(Vector3.zero)
        Humanoid.WalkSpeed = NORMAL_SPEED
    end
end

local function MoveToPosition(position, speed)
    if not Humanoid or not Root then
        return false
    end

    Humanoid.WalkSpeed = math.clamp(speed or SUB_SPEED, 1, 100)

    Humanoid:MoveTo(position)

    local start = tick()

    while Humanoid and Root and AUTO_MINIGAME do
        if (Root.Position - position).Magnitude <= TOUCH_DISTANCE then
            return true
        end

        if tick() - start > 15 then
            return false
        end

        task.wait(MOVE_DELAY)
        Humanoid:MoveTo(position)
    end

    return false
end

--==================================================
-- 🧭 PATH MOVE
--==================================================

local function PathMoveTo(position, speed)
    if not Root or not Humanoid then
        return false
    end

    local path

    pcall(function()
        path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 4
        })

        path:ComputeAsync(Root.Position, position)
    end)

    if not path or path.Status ~= Enum.PathStatus.Success then
        return MoveToPosition(position, speed)
    end

    local waypoints = path:GetWaypoints()

    for _, waypoint in ipairs(waypoints) do
        if not AUTO_MINIGAME then
            return false
        end

        if waypoint.Action == Enum.PathWaypointAction.Jump then
            Humanoid.Jump = true
        end

        MoveToPosition(waypoint.Position, speed)
    end

    return true
end

--==================================================
-- 🖱️ CLICK HELPERS
--==================================================

local function TryFirePrompt(obj)
    if not obj then
        return false
    end

    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)

    if prompt and typeof(fireproximityprompt) == "function" then
        pcall(function()
            fireproximityprompt(prompt)
        end)

        return true
    end

    return false
end

local function TryFireClick(obj)
    if not obj then
        return false
    end

    local detector = obj:FindFirstChildWhichIsA("ClickDetector", true)

    if detector and typeof(fireclickdetector) == "function" then
        pcall(function()
            fireclickdetector(detector)
        end)

        return true
    end

    return false
end

--==================================================
-- 🍋 TALK TO LIME
--==================================================

local function TalkToLime()
    local lime = FindLime()

    if not lime then
        return false
    end

    local pos = GetObjectPosition(lime)

    if not pos then
        return false
    end

    -- Lime dùng tốc độ bình thường
    if Humanoid then
        Humanoid.WalkSpeed = NORMAL_SPEED
    end

    PathMoveTo(pos, NORMAL_SPEED)

    task.wait(0.7)

    if TryFirePrompt(lime) then
        task.wait(1)
        return true
    end

    if TryFireClick(lime) then
        task.wait(1)
        return true
    end

    return false
end

--==================================================
-- 🔘 FIND GUI BUTTON
--==================================================

local function ButtonMatches(obj, keywords)
    if not (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
        return false
    end

    local text = ""

    pcall(function()
        text = string.lower(obj.Text or "")
    end)

    local name = string.lower(obj.Name)

    for _, key in ipairs(keywords) do
        key = string.lower(key)

        if string.find(name, key, 1, true)
        or string.find(text, key, 1, true) then
            return true
        end
    end

    return false
end

local function FindGUIButton(keywords)
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if ButtonMatches(gui, keywords) then
            return gui
        end
    end

    return nil
end

--==================================================
-- 🖱️ FIRE GUI BUTTON
--==================================================

local function FireGUIButton(button)
    if not button then
        return false
    end

    -- firesignal
    if typeof(firesignal) == "function" then
        pcall(function()
            firesignal(button.MouseButton1Click)
        end)

        return true
    end

    -- getconnections
    if typeof(getconnections) == "function" then
        local success = pcall(function()
            for _, connection in ipairs(getconnections(button.MouseButton1Click)) do
                if connection.Function then
                    connection.Function()
                end
            end
        end)

        if success then
            return true
        end
    end

    -- Activate
    pcall(function()
        button:Activate()
    end)

    return true
end

--==================================================
-- 🎮 CLICK MINIGAME
--==================================================

local function ClickMinigame()
    task.wait(0.8)

    local button = FindGUIButton({
        "minigame",
        "mini game",
        "mini-game"
    })

    if button then
        FireGUIButton(button)
        return true
    end

    return false
end

--==================================================
-- 🎟️ FIND TICKET
--==================================================

local function FindTicket()
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local name = string.lower(obj.Name)

            local text = ""

            pcall(function()
                text = string.lower(obj.Text or "")
            end)

            if string.find(name, "ticket", 1, true)
            or string.find(name, "ticketbutton", 1, true)
            or string.find(name, "ve", 1, true)
            or string.find(text, "ticket", 1, true)
            or string.find(text, "vé", 1, true) then
                return obj
            end
        end
    end

    return nil
end

--==================================================
-- 🎟️ CLICK TICKET
--==================================================

local function ClickTicket()
    for i = 1, 20 do
        if not AUTO_MINIGAME then
            return false
        end

        local ticket = FindTicket()

        if ticket then
            FireGUIButton(ticket)
            return true
        end

        task.wait(0.25)
    end

    return false
end

--==================================================
-- 🌑 LIGHTING
--==================================================

local function GetLightScore()
    local ambient = Lighting.Ambient
    local outdoor = Lighting.OutdoorAmbient
    local brightness = Lighting.Brightness

    local a = (ambient.R + ambient.G + ambient.B) / 3
    local o = (outdoor.R + outdoor.G + outdoor.B) / 3

    return ((a + o) / 2) + (brightness / 10)
end

local function SaveBrightBaseline()
    BrightBaseline = GetLightScore()
end

local function IsDarkMap()
    local score = GetLightScore()

    if BrightBaseline then
        return score < BrightBaseline * 0.55
    end

    return score < 0.22
end

--==================================================
-- ⏳ WAIT DARK MAP
--==================================================

local function WaitForDarkMap()
    for i = 1, 100 do
        if not AUTO_MINIGAME then
            return false
        end

        if IsDarkMap() then
            WasDark = true
            return true
        end

        task.wait(0.2)
    end

    return false
end

--==================================================
-- 🍉 BREAK WATERMELON
--==================================================

local function BreakWatermelon(obj)
    if not obj or not obj:IsDescendantOf(Workspace) then
        return false
    end

    local part = GetPart(obj)

    if not part then
        return false
    end

    CurrentWatermelon = obj

    PathMoveTo(part.Position, SUB_SPEED)

    task.wait(0.25)

    -- Nếu game xử lý bằng touch bình thường,
    -- đứng gần/đụng vào dưa sẽ tự break.
    for i = 1, 15 do
        if not AUTO_MINIGAME then
            return false
        end

        if not obj:IsDescendantOf(Workspace) then
            CurrentWatermelon = nil
            return true
        end

        local p = GetPart(obj)

        if not p then
            CurrentWatermelon = nil
            return true
        end

        if Root then
            Humanoid:MoveTo(p.Position)

            if (Root.Position - p.Position).Magnitude <= TOUCH_DISTANCE then
                Humanoid:Move(Vector3.zero)
            end
        end

        task.wait(0.15)
    end

    return false
end

--==================================================
-- 🍉 WATERMELON LOOP
--==================================================

local function RunWatermelon()
    STATE = "WATERMELON"

    if Humanoid then
        Humanoid.WalkSpeed = SUB_SPEED
    end

    while AUTO_MINIGAME and IsDarkMap() do
        local target = GetNearestWatermelon()

        if target then
            BreakWatermelon(target)
        else
            task.wait(SCAN_DELAY)
        end
    end

    CurrentWatermelon = nil
end

--==================================================
-- 🔁 MAIN CONTROLLER
--==================================================

local function Controller()
    if Running then
        return
    end

    Running = true

    while AUTO_MINIGAME do

        --==========================================
        -- 🍋 1. LIME
        --==========================================

        STATE = "LIME"

        SaveBrightBaseline()

        if Humanoid then
            Humanoid.WalkSpeed = NORMAL_SPEED
        end

        local limeOK = TalkToLime()

        if not AUTO_MINIGAME then
            break
        end

        if not limeOK then
            task.wait(1)
            continue
        end

        --==========================================
        -- 🎮 2. MINIGAME BUTTON
        --==========================================

        STATE = "MINIGAME"

        task.wait(0.8)

        ClickMinigame()

        task.wait(0.8)

        --==========================================
        -- 🎟️ 3. TICKET
        --==========================================

        STATE = "TICKET"

        ClickTicket()

        --==========================================
        -- 🌑 4. WAIT MAP DARK
        --==========================================

        STATE = "WAIT_DARK"

        WaitForDarkMap()

        if not AUTO_MINIGAME then
            break
        end

        --==========================================
        -- 🍉 5. FARM WATERMELON
        --==========================================

        if IsDarkMap() then
            RunWatermelon()
        end

        --==========================================
        -- ☀️ 6. WAIT MAP BRIGHT
        --==========================================

        STATE = "WAIT_COMPLETE"

        local startWait = tick()

        while AUTO_MINIGAME do
            if not IsDarkMap() then
                break
            end

            -- timeout chống kẹt
            if tick() - startWait > 180 then
                break
            end

            task.wait(0.4)
        end

        --==========================================
        -- 🔄 7. REPEAT
        --==========================================

        if AUTO_MINIGAME then
            CurrentWatermelon = nil
            task.wait(1)
        end
    end

    StopMove()

    STATE = "IDLE"
    Running = false
end

--==================================================
-- 🎨 GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SolRNG_Watermelon_V1"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

--==================================================
-- 📦 MAIN
--==================================================

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(285, 330)
Main.Position = UDim2.new(0.5, -142, 0.5, -165)
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
Title.Size = UDim2.new(1, -40, 0, 42)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "🍉 SolRNG Watermelon V1"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1, -20, 0, 20)
Credit.Position = UDim2.fromOffset(12, 35)
Credit.BackgroundTransparency = 1
Credit.Text = "by sarry_fixe"
Credit.TextColor3 = Color3.fromRGB(170, 170, 170)
Credit.TextSize = 11
Credit.Font = Enum.Font.Gotham
Credit.TextXAlignment = Enum.TextXAlignment.Left
Credit.Parent = Main

--==================================================
-- ❌ CLOSE / HIDE
--==================================================

local Hide = Instance.new("TextButton")
Hide.Size = UDim2.fromOffset(30, 30)
Hide.Position = UDim2.new(1, -35, 0, 7)
Hide.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
Hide.Text = "−"
Hide.TextColor3 = Color3.fromRGB(255, 255 ,255)
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

local function UpdateESPButton()
    ESPButton.Text = "🍉 Định vị dưa: " .. (ESP_ENABLED and "ON" or "OFF")
end

UpdateESPButton()

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

    UpdateESPButton()
end)

--==================================================
-- 🎮 AUTO MINIGAME BUTTON
--==================================================

local AutoButton = Instance.new("TextButton")
AutoButton.Size = UDim2.new(1, -24, 0, 42)
AutoButton.Position = UDim2.fromOffset(12, 113)
AutoButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
AutoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoButton.TextSize = 14
AutoButton.Font = Enum.Font.GothamBold
AutoButton.Parent = Main

local function UpdateAutoButton()
    AutoButton.Text = "🍋 Auto Minigame: " ..
        (AUTO_MINIGAME and "ON" or "OFF")
end

UpdateAutoButton()

AutoButton.MouseButton1Click:Connect(function()
    AUTO_MINIGAME = not AUTO_MINIGAME

    UpdateAutoButton()

    if AUTO_MINIGAME then
        task.spawn(Controller)
    else
        STATE = "IDLE"
        CurrentWatermelon = nil
        StopMove()
    end
end)

--==================================================
-- 🚀 SPEED LABEL
--==================================================

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -24, 0, 25)
SpeedLabel.Position = UDim2.fromOffset(12, 165)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "🚀 SubSpeed (1 - 100)"
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextSize = 13
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = Main

--==================================================
-- 🔢 SPEED BOX
--==================================================

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(1, -24, 0, 40)
SpeedBox.Position = UDim2.fromOffset(12, 192)
SpeedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
SpeedBox.Text = tostring(SUB_SPEED)
SpeedBox.PlaceholderText = "Nhập tốc độ 1 - 100"
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
    value = math.clamp(value, 1, 100)

    SUB_SPEED = value
    SpeedBox.Text = tostring(SUB_SPEED)

    if AUTO_MINIGAME and STATE == "WATERMELON" and Humanoid then
        Humanoid.WalkSpeed = SUB_SPEED
    end
end)

--==================================================
-- 📊 STATUS
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -24, 0, 35)
Status.Position = UDim2.fromOffset(12, 242)
Status.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
Status.TextColor3 = Color3.fromRGB(220, 220, 220)
Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.Text = "Status: IDLE"
Status.TextWrapped = true
Status.Parent = Main

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = Status

--==================================================
-- 👁️ FLOATING SHOW BUTTON
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

local dragging = false
local dragStart
local startPos

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

--==================================================
-- 📊 STATUS LOOP
--==================================================

task.spawn(function()
    while ScreenGui.Parent do
        local targetName = "None"

        if CurrentWatermelon and CurrentWatermelon.Parent then
            targetName = CurrentWatermelon.Name
        end

        Status.Text =
            "Status: " .. STATE ..
            "\nTarget: " .. targetName ..
            " | Speed: " .. tostring(SUB_SPEED)

        task.wait(0.3)
    end
end)

--==================================================
-- 🚀 INITIAL SCAN
--==================================================

task.spawn(function()
    while ScreenGui.Parent do
        if ESP_ENABLED then
            ScanWatermelons()
        end

        task.wait(2)
    end
end)

print("🍉 SolRNG Watermelon V1 loaded")
print("by sarry_fixe")
