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
-- SETTINGS
--==================================================

local ESP_ENABLED = true
local AUTO_MODE = false
local SPEED_ENABLED = true

local NORMAL_SPEED = 16
local FAST_SPEED = 50

local LIME_NAME = "Lime"

local TOUCH_DISTANCE = 4
local LIME_DISTANCE = 8

local WATERMELON_NAMES = {
    "watermelon",
    "melon",
    "dua",
    "duahau",
    "dưa",
    "dưahau",
    "dưahấu"
}

-- Thời gian chờ Lime
local TALK_DELAY = 1.0
local MINIGAME_DELAY = 1.5
local TICKET_DELAY = 1.0

local STATE = "IDLE"
local TARGET = nil

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

    if SPEED_ENABLED then
        Humanoid.WalkSpeed = FAST_SPEED
    else
        Humanoid.WalkSpeed = NORMAL_SPEED
    end
end

SetupCharacter()

Player.CharacterAdded:Connect(function()
    task.wait(1)
    SetupCharacter()
end)

--==================================================
-- HELPER
--==================================================

local function IsAlive()
    return Character
        and Humanoid
        and Humanoid.Health > 0
        and RootPart
end

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

        return obj:FindFirstChildWhichIsA("BasePart", true)
    end

    return obj:FindFirstChildWhichIsA("BasePart", true)
end

--==================================================
-- WATERMELON DETECTION
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

    local nearest
    local nearestDistance = math.huge

    for _, obj in ipairs(FindWatermelons()) do

        local part = GetPart(obj)

        if part then

            local distance =
                (RootPart.Position - part.Position).Magnitude

            if distance < nearestDistance then

                nearestDistance = distance
                nearest = obj

            end

        end

    end

    return nearest
end

--==================================================
-- ESP + RED DOT
--==================================================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "SarryFixe_WatermelonESP"
ESPFolder.Parent = PlayerGui

local function RefreshESP()

    ESPFolder:ClearAllChildren()

    if not ESP_ENABLED then
        return
    end

    for _, obj in ipairs(FindWatermelons()) do

        local part = GetPart(obj)

        if part then

            local Billboard = Instance.new("BillboardGui")

            Billboard.Name = obj:GetDebugId()
            Billboard.Adornee = part
            Billboard.Size = UDim2.fromOffset(35,35)
            Billboard.StudsOffset = Vector3.new(0,2,0)
            Billboard.AlwaysOnTop = true
            Billboard.Parent = ESPFolder

            local Dot = Instance.new("Frame")

            Dot.Size = UDim2.fromOffset(12,12)
            Dot.Position = UDim2.fromScale(0.5,0.5)
            Dot.AnchorPoint = Vector2.new(0.5,0.5)

            Dot.BackgroundColor3 =
                Color3.fromRGB(255,40,40)

            Dot.BorderSizePixel = 0
            Dot.Parent = Billboard

            local Corner = Instance.new("UICorner")

            Corner.CornerRadius = UDim.new(1,0)
            Corner.Parent = Dot

        end

    end
end

task.spawn(function()

    while task.wait(1) do

        pcall(RefreshESP)

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

local function MoveToObject(obj, distance)

    if not IsAlive() then
        return false
    end

    local part = GetPart(obj)

    if not part then
        return false
    end

    distance = distance or TOUCH_DISTANCE

    local startTime = tick()

    while IsAlive()
        and obj
        and obj.Parent
        and tick() - startTime < 12 do

        part = GetPart(obj)

        if not part then
            return true
        end

        local dist =
            (RootPart.Position - part.Position).Magnitude

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
-- PROMPT / CLICK
--==================================================

local function ActivatePrompt(prompt)

    if typeof(fireproximityprompt) ~= "function" then
        return false
    end

    local ok = pcall(function()
        fireproximityprompt(prompt)
    end)

    return ok
end

local function ActivateClickDetector(detector)

    if typeof(fireclickdetector) ~= "function" then
        return false
    end

    local ok = pcall(function()
        fireclickdetector(detector)
    end)

    return ok
end

--==================================================
-- TALK LIME
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

    -- Tắt speed trong lúc tới Lime
    if Humanoid then
        Humanoid.WalkSpeed = NORMAL_SPEED
    end

    if (RootPart.Position - part.Position).Magnitude
        > LIME_DISTANCE then

        MoveToObject(lime, LIME_DISTANCE)

        return false
    end

    -- Đứng ổn định trước Lime
    Humanoid:Move(Vector3.zero)

    task.wait(TALK_DELAY)

    for _, obj in ipairs(lime:GetDescendants()) do

        if obj:IsA("ProximityPrompt") then

            if ActivatePrompt(obj) then
                return true
            end

        elseif obj:IsA("ClickDetector") then

            if ActivateClickDetector(obj) then
                return true
            end

        end

    end

    return false
end

--==================================================
-- FIND GUI BUTTON
--==================================================

local function FindButton(words)

    for _, gui in ipairs(PlayerGui:GetDescendants()) do

        if gui:IsA("TextButton") then

            local text =
                string.lower(gui.Text or "")

            for _, word in ipairs(words) do

                if string.find(
                    text,
                    string.lower(word),
                    1,
                    true
                ) then

                    return gui
                end

            end

        end

    end

    return nil
end

--==================================================
-- CLICK GUI BUTTON
--==================================================

local function ClickButton(button)

    if not button then
        return false
    end

    if typeof(firesignal) == "function" then

        local ok = pcall(function()

            firesignal(
                button.MouseButton1Click
            )

        end)

        if ok then
            return true
        end

    end

    if typeof(getconnections) == "function" then

        local ok = pcall(function()

            for _, connection in ipairs(
                getconnections(
                    button.MouseButton1Click
                )
            ) do

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
-- MINIGAME BUTTON
--==================================================

local function OpenMinigame()

    local button = FindButton({
        "minigame",
        "mini game",
        "mini-game"
    })

    if not button then
        return false
    end

    return ClickButton(button)
end

--==================================================
-- PURPLE TICKET
--==================================================

local function FindTicket()

    for _, gui in ipairs(PlayerGui:GetDescendants()) do

        if gui:IsA("TextButton") then

            local text =
                string.lower(gui.Text or "")

            if string.find(text,"ticket",1,true)
                or string.find(text,"vé",1,true) then

                return gui
            end

        end

    end

    return nil
end

local function ClickTicket()

    local ticket = FindTicket()

    if not ticket then
        return false
    end

    return ClickButton(ticket)
end

--==================================================
-- START MINIGAME
--==================================================

local function StartMinigame()

    -- Talk xong
    task.wait(MINIGAME_DELAY)

    -- Bấm Minigame
    OpenMinigame()

    -- Đợi UI vé hiện
    task.wait(TICKET_DELAY)

    -- Bấm vé
    ClickTicket()

    -- Chờ map chuyển sang minigame
    task.wait(2)

    -- Bật speed sau khi vào màn
    if Humanoid and SPEED_ENABLED then
        Humanoid.WalkSpeed = FAST_SPEED
    end
end

--==================================================
-- AUTO CONTROLLER
--==================================================

local function Controller()

    if not AUTO_MODE then
        STATE = "IDLE"
        TARGET = nil
        return
    end

    --==============================================
    -- LIME
    --==============================================

    if STATE == "LIME" then

        if not GetLime() then
            return
        end

        local talked = TalkToLime()

        if talked then

            task.wait(0.5)

            StartMinigame()

            TARGET = nil
            STATE = "WATERMELON"

        end

        return
    end

    --==============================================
    -- FIND WATERMELON
    --==============================================

    if STATE == "WATERMELON" then

        if not TARGET
            or not TARGET.Parent then

            TARGET = GetNearestWatermelon()

        end

        if TARGET then
            STATE = "GO_WATERMELON"
        end

        return
    end

    --==============================================
    -- GO WATERMELON
    --==============================================

    if STATE == "GO_WATERMELON" then

        if not TARGET
            or not TARGET.Parent then

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

            task.wait(0.4)

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

        pcall(Controller)

    end

end)

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name =
    "SarryFixe_Watermelon_V1"

ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")

Main.Size = UDim2.fromOffset(250,230)
Main.Position = UDim2.fromScale(0.5,0.5)
Main.AnchorPoint = Vector2.new(0.5,0.5)

Main.BackgroundColor3 =
    Color3.fromRGB(20,20,25)

Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")

MainCorner.CornerRadius =
    UDim.new(0,12)

MainCorner.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")

Title.Size =
    UDim2.new(1,-50,0,38)

Title.Position =
    UDim2.fromOffset(10,5)

Title.BackgroundTransparency = 1

Title.Text =
    "🍉 SolRNG Watermelon V1"

Title.TextColor3 =
    Color3.new(1,1,1)

Title.TextSize = 17
Title.Font = Enum.Font.GothamBold

Title.Parent = Main

local Credit = Instance.new("TextLabel")

Credit.Size =
    UDim2.new(1,0,0,20)

Credit.Position =
    UDim2.fromOffset(0,38)

Credit.BackgroundTransparency = 1

Credit.Text =
    "by sarry_fixe"

Credit.TextColor3 =
    Color3.fromRGB(160,160,160)

Credit.TextSize = 12
Credit.Font = Enum.Font.Gotham

Credit.Parent = Main

--==================================================
-- BUTTON MAKER
--==================================================

local function MakeButton(text,y)

    local button = Instance.new("TextButton")

    button.Size =
        UDim2.new(1,-20,0,38)

    button.Position =
        UDim2.fromOffset(10,y)

    button.BackgroundColor3 =
        Color3.fromRGB(35,35,42)

    button.BorderSizePixel = 0

    button.Text = text

    button.TextColor3 =
        Color3.new(1,1,1)

    button.TextSize = 14
    button.Font = Enum.Font.GothamBold

    button.Parent = Main

    local c = Instance.new("UICorner")

    c.CornerRadius =
        UDim.new(0,8)

    c.Parent = button

    return button
end

--==================================================
-- ESP BUTTON
--==================================================

local ESPButton =
    MakeButton(
        "🍉 ESP Dưa: ON",
        65
    )

ESPButton.MouseButton1Click:Connect(function()

    ESP_ENABLED = not ESP_ENABLED

    ESPButton.Text =
        "🍉 ESP Dưa: "
        .. (ESP_ENABLED and "ON" or "OFF")

    RefreshESP()

end)

--==================================================
-- AUTO BUTTON
--==================================================

local AutoButton =
    MakeButton(
        "🍋 Auto Minigame: OFF",
        108
    )

AutoButton.MouseButton1Click:Connect(function()

    AUTO_MODE = not AUTO_MODE

    if AUTO_MODE then

        STATE = "LIME"
        TARGET = nil

        AutoButton.Text =
            "🍋 Auto Minigame: ON"

    else

        STATE = "IDLE"
        TARGET = nil

        if IsAlive() then
            Humanoid:Move(Vector3.zero)
        end

        AutoButton.Text =
            "🍋 Auto Minigame: OFF"

    end

end)

--==================================================
-- SPEED BUTTON
--==================================================

local SpeedButton =
    MakeButton(
        "🚀 Speed: ON",
        151
    )

SpeedButton.MouseButton1Click:Connect(function()

    SPEED_ENABLED = not SPEED_ENABLED

    if SPEED_ENABLED then

        SpeedButton.Text =
            "🚀 Speed: ON"

        if IsAlive() then
            Humanoid.WalkSpeed = FAST_SPEED
        end

    else

        SpeedButton.Text =
            "🚀 Speed: OFF"

        if IsAlive() then
            Humanoid.WalkSpeed = NORMAL_SPEED
        end

    end

end)

--==================================================
-- STATUS
--==================================================

local Status = Instance.new("TextLabel")

Status.Size =
    UDim2.new(1,-20,0,30)

Status.Position =
    UDim2.fromOffset(10,194)

Status.BackgroundTransparency = 1

Status.Text =
    "Status: IDLE"

Status.TextColor3 =
    Color3.fromRGB(180,180,180)

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
            .. " | "
            .. targetName

    end

end)

--==================================================
-- DRAG MENU
--==================================================

local dragging = false
local dragStart
local startPosition

Title.InputBegan:Connect(function(input)

    if input.UserInputType ==
        Enum.UserInputType.MouseButton1

        or input.UserInputType ==
        Enum.UserInputType.Touch then

        dragging = true

        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()

            if input.UserInputState ==
                Enum.UserInputState.End then

                dragging = false

            end

        end)

    end

end)

UIS.InputChanged:Connect(function(input)

    if not dragging then
        return
    end

    local delta =
        input.Position - dragStart

    Main.Position =
        UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,

            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )

end)

--==================================================
-- HIDE / SHOW
--==================================================

local HideButton = Instance.new("TextButton")

HideButton.Size =
    UDim2.fromOffset(32,32)

HideButton.Position =
    UDim2.new(1,-37,0,8)

HideButton.BackgroundColor3 =
    Color3.fromRGB(45,45,52)

HideButton.BorderSizePixel = 0

HideButton.Text = "−"

HideButton.TextColor3 =
    Color3.new(1,1,1)

HideButton.TextSize = 20
HideButton.Font = Enum.Font.GothamBold

HideButton.Parent = Main

local HideCorner = Instance.new("UICorner")

HideCorner.CornerRadius =
    UDim.new(0,8)

HideCorner.Parent = HideButton

local ShowButton = Instance.new("TextButton")

ShowButton.Size =
    UDim2.fromOffset(48,48)

ShowButton.Position =
    UDim2.fromOffset(20,200)

ShowButton.BackgroundColor3 =
    Color3.fromRGB(25,25,30)

ShowButton.BorderSizePixel = 0

ShowButton.Text = "🍉"

ShowButton.TextSize = 22

ShowButton.Visible = false

ShowButton.Parent = ScreenGui

local ShowCorner = Instance.new("UICorner")

ShowCorner.CornerRadius =
    UDim.new(1,0)

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
-- LOAD
--==================================================

RefreshESP()

print("🍉 SolRNG Watermelon V1 loaded")
print("by sarry_fixe")
