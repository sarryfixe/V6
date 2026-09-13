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

local ESP_ENABLED = true
local DOT_ENABLED = true
local AUTO_MODE = false

local LIME_NAME = "Lime"

local WATERMELON_NAMES = {
    "watermelon",
    "melon",
    "dua",
    "duahau",
    "dưa",
    "dưahấu"
}

local STATE = "IDLE"
local TARGET = nil

local MAX_TARGET_DISTANCE = 5000
local TOUCH_DISTANCE = 4
local LIME_DISTANCE = 8

--==================================================
-- CHARACTER
--==================================================

local Character
local Humanoid
local RootPart

local function SetupCharacter()
    Character = Player.Character or Player.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
end

SetupCharacter()

Player.CharacterAdded:Connect(function()
    task.wait(1)
    SetupCharacter()
end)

--==================================================
-- HELPERS
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

        local hrp = obj:FindFirstChild("HumanoidRootPart")
        if hrp and hrp:IsA("BasePart") then
            return hrp
        end

        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        return part
    end

    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function IsAlive()
    return Character
        and Humanoid
        and Humanoid.Health > 0
        and RootPart
end

--==================================================
-- WATERMELON
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

local function FindWatermelons()
    local result = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsWatermelon(obj) then
            local part = GetPart(obj)

            if part then
                table.insert(result, obj)
            end
        end
    end

    return result
end

local function GetNearestWatermelon()
    if not IsAlive() then
        return nil
    end

    local nearest = nil
    local nearestDistance = MAX_TARGET_DISTANCE

    for _, obj in ipairs(FindWatermelons()) do
        local part = GetPart(obj)

        if part then
            local distance = (RootPart.Position - part.Position).Magnitude

            if distance < nearestDistance then
                nearestDistance = distance
                nearest = obj
            end
        end
    end

    return nearest
end

--==================================================
-- ESP
--==================================================

local ESP_FOLDER = Instance.new("Folder")
ESP_FOLDER.Name = "SarryFixe_WatermelonESP"
ESP_FOLDER.Parent = PlayerGui

local function RemoveESP(obj)
    local gui = ESP_FOLDER:FindFirstChild(obj:GetDebugId())
    if gui then
        gui:Destroy()
    end
end

local function AddESP(obj)
    if not ESP_ENABLED then
        return
    end

    local part = GetPart(obj)
    if not part then
        return
    end

    local id = obj:GetDebugId()

    if ESP_FOLDER:FindFirstChild(id) then
        return
    end

    local holder = Instance.new("BillboardGui")
    holder.Name = id
    holder.Adornee = part
    holder.Size = UDim2.fromOffset(30, 30)
    holder.StudsOffset = Vector3.new(0, 2, 0)
    holder.AlwaysOnTop = true
    holder.Parent = ESP_FOLDER

    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.fromOffset(12, 12)
    dot.Position = UDim2.fromScale(0.5, 0.5)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
    dot.BorderSizePixel = 0
    dot.Visible = DOT_ENABLED
    dot.Parent = holder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
end

local function RefreshESP()
    ESP_FOLDER:ClearAllChildren()

    if not ESP_ENABLED then
        return
    end

    for _, obj in ipairs(FindWatermelons()) do
        AddESP(obj)
    end
end

task.spawn(function()
    while task.wait(1) do
        RefreshESP()
    end
end)

--==================================================
-- FIND LIME
--==================================================

local function GetLime()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == LIME_NAME then
            return obj
        end
    end

    return nil
end

--==================================================
-- MOVE
--==================================================

local function MoveToPosition(position)
    if not IsAlive() then
        return false
    end

    Humanoid:MoveTo(position)

    local started = tick()

    while IsAlive() and tick() - started < 8 do
        if (RootPart.Position - position).Magnitude <= TOUCH_DISTANCE then
            return true
        end

        task.wait(0.15)
    end

    return false
end

local function MoveToObject(obj, distance)
    local part = GetPart(obj)

    if not part or not IsAlive() then
        return false
    end

    distance = distance or TOUCH_DISTANCE

    local started = tick()

    while IsAlive() and obj.Parent and tick() - started < 10 do
        part = GetPart(obj)

        if not part then
            return true
        end

        local dist = (RootPart.Position - part.Position).Magnitude

        if dist <= distance then
            Humanoid:Move(Vector3.zero)
            return true
        end

        Humanoid:MoveTo(part.Position)

        task.wait(0.12)
    end

    return false
end

--==================================================
-- INTERACTION
--==================================================

local function ActivatePrompt(prompt)
    if not prompt then
        return false
    end

    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(function()
            fireproximityprompt(prompt)
        end)

        if ok then
            return true
        end
    end

    return false
end

local function ActivateClickDetector(detector)
    if not detector then
        return false
    end

    if typeof(fireclickdetector) == "function" then
        local ok = pcall(function()
            fireclickdetector(detector)
        end)

        if ok then
            return true
        end
    end

    return false
end

--==================================================
-- TALK TO LIME
--==================================================

local function TalkToLime()
    local lime = GetLime()

    if not lime then
        return false
    end

    local part = GetPart(lime)

    if not part then
        return false
    end

    if (RootPart.Position - part.Position).Magnitude > LIME_DISTANCE then
        MoveToObject(lime, LIME_DISTANCE)
        return false
    end

    for _, obj in ipairs(lime:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            if ActivatePrompt(obj) then
                return true
            end
        end

        if obj:IsA("ClickDetector") then
            if ActivateClickDetector(obj) then
                return true
            end
        end
    end

    return false
end

--==================================================
-- CLICK GUI BY TEXT
--==================================================

local function TextMatches(text, words)
    text = string.lower(text or "")

    for _, word in ipairs(words) do
        if string.find(text, string.lower(word), 1, true) then
            return true
        end
    end

    return false
end

local function FindButton(words)
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then

            local text = ""

            if gui:IsA("TextButton") then
                text = gui.Text
            end

            if TextMatches(text, words) then
                return gui
            end
        end
    end

    return nil
end

local function ClickButton(button)
    if not button then
        return false
    end

    if typeof(firesignal) == "function" then
        local ok = pcall(function()
            firesignal(button.MouseButton1Click)
        end)

        if ok then
            return true
        end
    end

    if typeof(getconnections) == "function" then
        local ok = pcall(function()
            for _, connection in ipairs(getconnections(button.MouseButton1Click)) do
                if connection.Function then
                    connection.Function()
                end
            end
        end)

        if ok then
            return true
        end
    end

    return false
end

--==================================================
-- OPEN MINIGAME
--==================================================

local function OpenMinigame()
    local button = FindButton({
        "minigame",
        "mini game",
        "[minigame]"
    })

    if button then
        return ClickButton(button)
    end

    return false
end

--==================================================
-- PURPLE TICKET
--==================================================

local function FindPurpleTicket()
    for _, gui in ipairs(PlayerGui:GetDescendants()) do

        if gui:IsA("TextButton") or gui:IsA("ImageButton") then

            local text = ""

            if gui:IsA("TextButton") then
                text = gui.Text
            end

            local lower = string.lower(text)

            if string.find(lower, "ticket", 1, true)
                or string.find(lower, "1", 1, true)
                or string.find(lower, "vé", 1, true) then

                return gui
            end
        end
    end

    return nil
end

local function ClickPurpleTicket()
    local ticket = FindPurpleTicket()

    if ticket then
        return ClickButton(ticket)
    end

    return false
end

--==================================================
-- DETECT BLACK MAP / MINIGAME
--==================================================

local function IsMinigameActive()
    -- Dựa vào sự xuất hiện của watermelon trong map
    -- hoặc UI minigame.

    local count = 0

    for _, obj in ipairs(FindWatermelons()) do
        count += 1

        if count >= 1 then
            return true
        end
    end

    return false
end

--==================================================
-- STATE MACHINE
--==================================================

local function RunController()
    if not AUTO_MODE then
        STATE = "IDLE"
        TARGET = nil
        return
    end

    ------------------------------------------------
    -- 1. ĐI LIME
    ------------------------------------------------

    if STATE == "IDLE" then
        STATE = "LIME"
        return
    end

    ------------------------------------------------
    -- 2. TALK LIME
    ------------------------------------------------

    if STATE == "LIME" then

        local lime = GetLime()

        if not lime then
            return
        end

        local limePart = GetPart(lime)

        if not limePart then
            return
        end

        local distance =
            (RootPart.Position - limePart.Position).Magnitude

        if distance > LIME_DISTANCE then
            MoveToObject(lime, LIME_DISTANCE)
            return
        end

        -- Talk
        TalkToLime()

        task.wait(1)

        -- Mở minigame
        OpenMinigame()

        task.wait(1)

        -- Bấm vé tím
        ClickPurpleTicket()

        task.wait(2)

        STATE = "WATERMELON"

        return
    end

    ------------------------------------------------
    -- 3. TÌM DƯA
    ------------------------------------------------

    if STATE == "WATERMELON" then

        if not TARGET or not TARGET.Parent then
            TARGET = GetNearestWatermelon()
        end

        if TARGET then
            STATE = "GO_WATERMELON"
        else
            task.wait(0.5)
        end

        return
    end

    ------------------------------------------------
    -- 4. ĐI TỚI DƯA
    ------------------------------------------------

    if STATE == "GO_WATERMELON" then

        if not TARGET or not TARGET.Parent then
            TARGET = nil
            STATE = "WATERMELON"
            return
        end

        local part = GetPart(TARGET)

        if not part then
            TARGET = nil
            STATE = "WATERMELON"
            return
        end

        local distance =
            (RootPart.Position - part.Position).Magnitude

        if distance <= TOUCH_DISTANCE then
            Humanoid:Move(Vector3.zero)

            -- Chạm dưa = phá dưa
            task.wait(0.35)

            if not TARGET.Parent then
                TARGET = nil
                STATE = "WATERMELON"
            end

            return
        end

        Humanoid:MoveTo(part.Position)

        return
    end
end

--==================================================
-- CONTROLLER LOOP
--==================================================

task.spawn(function()
    while task.wait(0.15) do
        pcall(RunController)
    end
end)

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SarryFixe_Watermelon_V1"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(250, 230)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "🍉 SolRNG Watermelon V1"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(1, 0, 0, 20)
Credit.Position = UDim2.fromOffset(0, 38)
Credit.BackgroundTransparency = 1
Credit.Text = "by sarry_fixe"
Credit.TextColor3 = Color3.fromRGB(160, 160, 160)
Credit.TextSize = 12
Credit.Font = Enum.Font.Gotham
Credit.Parent = Main

--==================================================
-- DRAG
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

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- BUTTON
--==================================================

local function MakeButton(text, y)
    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = UDim2.fromOffset(10, y)

    button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    button.BorderSizePixel = 0

    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold

    button.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = button

    return button
end

--==================================================
-- ESP BUTTON
--==================================================

local ESPButton =
    MakeButton("🍉 Định vị dưa: ON", 65)

ESPButton.MouseButton1Click:Connect(function()

    ESP_ENABLED = not ESP_ENABLED

    ESPButton.Text =
        "🍉 Định vị dưa: "
        .. (ESP_ENABLED and "ON" or "OFF")

    RefreshESP()
end)

--==================================================
-- DOT BUTTON
--==================================================

local DotButton =
    MakeButton("🔴 Chấm dưa: ON", 105)

DotButton.MouseButton1Click:Connect(function()

    DOT_ENABLED = not DOT_ENABLED

    DotButton.Text =
        "🔴 Chấm dưa: "
        .. (DOT_ENABLED and "ON" or "OFF")

    for _, gui in ipairs(ESP_FOLDER:GetChildren()) do
        local dot = gui:FindFirstChild("Dot")

        if dot then
            dot.Visible = DOT_ENABLED
        end
    end
end)

--==================================================
-- AUTO BUTTON
--==================================================

local AutoButton =
    MakeButton("🍋 Auto Minigame: OFF", 145)

AutoButton.MouseButton1Click:Connect(function()

    AUTO_MODE = not AUTO_MODE

    if AUTO_MODE then
        STATE = "LIME"
        TARGET = nil

        AutoButton.Text = "🍋 Auto Minigame: ON"
    else
        STATE = "IDLE"
        TARGET = nil

        if IsAlive() then
            Humanoid:Move(Vector3.zero)
        end

        AutoButton.Text = "🍋 Auto Minigame: OFF"
    end
end)

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 30)
Status.Position = UDim2.fromOffset(10, 185)
Status.BackgroundTransparency = 1
Status.Text = "Status: IDLE"
Status.TextColor3 = Color3.fromRGB(180, 180, 180)
Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.Parent = Main

task.spawn(function()
    while task.wait(0.2) do

        local targetName = "None"

        if TARGET then
            targetName = TARGET.Name
        end

        Status.Text =
            "State: "
            .. STATE
            .. " | Target: "
            .. targetName
    end
end)

--==================================================
-- HIDE / SHOW
--==================================================

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.fromOffset(32, 32)
HideButton.Position = UDim2.new(1, -37, 0, 8)
HideButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
HideButton.BorderSizePixel = 0
HideButton.Text = "−"
HideButton.TextColor3 = Color3.new(1, 1, 1)
HideButton.TextSize = 20
HideButton.Font = Enum.Font.GothamBold
HideButton.Parent = Main

local HideCorner = Instance.new("UICorner")
HideCorner.CornerRadius = UDim.new(0, 8)
HideCorner.Parent = HideButton

local ShowButton = Instance.new("TextButton")
ShowButton.Size = UDim2.fromOffset(48, 48)
ShowButton.Position = UDim2.fromOffset(20, 200)
ShowButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ShowButton.BorderSizePixel = 0
ShowButton.Text = "🍉"
ShowButton.TextSize = 22
ShowButton.Visible = false
ShowButton.Parent = ScreenGui


local ShowCorner = Instance.new("UICorner")
ShowCorner.CornerRadius = UDim.new(1, 0)
ShowCorner.Parent = ShowButton

HideButton.MouseButton1Click:Connect(function()
    Main.Visible = false
    ShowButton.Visible = true
end)

ShowButton.MouseButton1Click:Connect(function()
    Main.Visible = true
    ShowButton.Visible = false
end)

--==================================================
-- START
--==================================================

RefreshESP()

print("🍉 SolRNG Watermelon V1 loaded")
print("by sarry_fixe")
