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

local ESP_ENABLED = true
local DOT_ENABLED = true

local AUTO_QUEST = false
local AUTO_WATERMELON = false

local LIME_NAME = "Lime"

local WATERMELON_NAMES = {
    "watermelon",
    "melon",
    "dua",
    "duahau",
    "dưa",
    "dưahấu"
}

local QUEST_DISTANCE = 8
local TARGET_DISTANCE = 5

local SCAN_INTERVAL = 1
local REPATH_DELAY = 1.5
local QUEST_COOLDOWN = 2

--==================================================
-- 🧠 STATE
--==================================================

local STATE_IDLE = "IDLE"
local STATE_LIME = "LIME"
local STATE_WATERMELON = "WATERMELON"

local State = STATE_IDLE

local QuestReceived = false

local CurrentTarget = nil
local CurrentTargetPart = nil

local LastScan = 0
local LastPath = 0
local LastQuest = 0

local CurrentPath = nil
local Waypoints = {}
local WaypointIndex = 1

--==================================================
-- 👤 CHARACTER
--==================================================

local Character
local Humanoid
local RootPart

local function SetupCharacter(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid", 10)
    RootPart = char:WaitForChild("HumanoidRootPart", 10)

    CurrentTarget = nil
    CurrentTargetPart = nil
    CurrentPath = nil
    Waypoints = {}
    WaypointIndex = 1
end

if Player.Character then
    SetupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    SetupCharacter(char)
end)

local function Alive()
    return Character
        and Humanoid
        and RootPart
        and Humanoid.Health > 0
end

--==================================================
-- 🔎 OBJECT
--==================================================

local function GetPart(obj)
    if not obj then
        return nil
    end

    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") and obj.PrimaryPart then
        return obj.PrimaryPart
    end

    return obj:FindFirstChildWhichIsA("BasePart", true)
end

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
-- 🍉 WATERMELON SCAN
--==================================================

local Watermelons = {}

local function ScanWatermelons()
    table.clear(Watermelons)

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if IsWatermelon(obj) then
            local part = GetPart(obj)

            if part then
                table.insert(Watermelons, {
                    Object = obj,
                    Part = part
                })
            end
        end
    end
end

local function GetNearestWatermelon()
    if not Alive() then
        return nil, nil
    end

    local nearest
    local nearestPart
    local distance = math.huge

    for _, data in ipairs(Watermelons) do
        local obj = data.Object
        local part = data.Part

        if obj
            and obj.Parent
            and part
            and part.Parent
            and IsWatermelon(obj) then

            local d =
                (RootPart.Position - part.Position).Magnitude

            if d < distance then
                distance = d
                nearest = obj
                nearestPart = part
            end
        end
    end

    return nearest, nearestPart
end

--==================================================
-- 🍋 LIME
--==================================================

local function GetLime()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if string.lower(obj.Name) == string.lower(LIME_NAME) then
            return obj
        end
    end

    return nil
end

local function GetLimePart()
    local lime = GetLime()

    if not lime then
        return nil, nil
    end

    return lime, GetPart(lime)
end

--==================================================
-- 🛣️ PATH
--==================================================

local function ClearPath()
    CurrentPath = nil
    Waypoints = {}
    WaypointIndex = 1
end

local function MakePath(destination)
    if not Alive() or not destination then
        return false
    end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 5
    })

    local ok = pcall(function()
        path:ComputeAsync(
            RootPart.Position,
            destination
        )
    end)

    if not ok then
        return false
    end

    if path.Status ~= Enum.PathStatus.Success then
        return false
    end

    CurrentPath = path
    Waypoints = path:GetWaypoints()
    WaypointIndex = 1
    LastPath = tick()

    return #Waypoints > 0
end

local function MoveTo(destination)
    if not Alive() or not destination then
        return
    end

    if not CurrentPath
        or tick() - LastPath >= REPATH_DELAY then

        MakePath(destination)
    end

    if #Waypoints == 0 then
        Humanoid:MoveTo(destination)
        return
    end

    local waypoint = Waypoints[WaypointIndex]

    if not waypoint then
        ClearPath()
        return
    end

    if waypoint.Action == Enum.PathWaypointAction.Jump then
        Humanoid.Jump = true
    end

    Humanoid:MoveTo(waypoint.Position)

    if (RootPart.Position - waypoint.Position).Magnitude <= 3 then
        WaypointIndex += 1
    end
end

--==================================================
-- 🍋 TALK TO LIME
--==================================================

local function TalkToLime()
    if not Alive() then
        return false
    end

    local lime, limePart = GetLimePart()

    if not limePart then
        return false
    end

    local distance =
        (RootPart.Position - limePart.Position).Magnitude

    if distance > QUEST_DISTANCE then
        MoveTo(limePart.Position)
        return false
    end

    for _, obj in ipairs(lime:GetDescendants()) do

        if obj:IsA("ProximityPrompt") then
            if typeof(fireproximityprompt) == "function" then
                local ok = pcall(function()
                    fireproximityprompt(obj)
                end)

                if ok then
                    return true
                end
            end
        end

        if obj:IsA("ClickDetector") then
            if typeof(fireclickdetector) == "function" then
                local ok = pcall(function()
                    fireclickdetector(obj)
                end)

                if ok then
                    return true
                end
            end
        end
    end

    return false
end

--==================================================
-- 🎯 TARGET
--==================================================

local function ClearTarget()
    CurrentTarget = nil
    CurrentTargetPart = nil
    ClearPath()
end

local function TargetValid()
    if not CurrentTarget then
        return false
    end

    if not CurrentTarget.Parent then
        return false
    end

    if not IsWatermelon(CurrentTarget) then
        return false
    end

    if not CurrentTargetPart
        or not CurrentTargetPart.Parent then

        CurrentTargetPart = GetPart(CurrentTarget)
    end

    return CurrentTargetPart ~= nil
end

--==================================================
-- 🍋 QUEST CONTROLLER
--==================================================

local function RunQuest()

    if not AUTO_QUEST then
        return
    end

    if not Alive() then
        return
    end

    if QuestReceived then
        AUTO_QUEST = false
        AUTO_WATERMELON = true

        State = STATE_WATERMELON

        ClearTarget()
        ClearPath()

        return
    end

    if tick() - LastQuest < QUEST_COOLDOWN then
        return
    end

    local lime, limePart = GetLimePart()

    if not limePart then
        return
    end

    local distance =
        (RootPart.Position - limePart.Position).Magnitude

    if distance > QUEST_DISTANCE then
        MoveTo(limePart.Position)
        return
    end

    local success = TalkToLime()

    if success then
        QuestReceived = true
        LastQuest = tick()

        -- Tắt Lime ngay sau khi nhận quest
        AUTO_QUEST = false

        -- Bật đi dưa
        AUTO_WATERMELON = true

        State = STATE_WATERMELON

        ClearTarget()
        ClearPath()
    end
end

--==================================================
-- 🍉 WATERMELON CONTROLLER
--==================================================

local function RunWatermelon()

    if not AUTO_WATERMELON then
        return
    end

    if not Alive() then
        return
    end

    if not TargetValid() then

        ClearTarget()

        if tick() - LastScan >= SCAN_INTERVAL then
            ScanWatermelons()
            LastScan = tick()
        end

        local target, part =
            GetNearestWatermelon()

        if target and part then
            CurrentTarget = target
            CurrentTargetPart = part

            ClearPath()
        else
            -- Không còn dưa:
            -- quay lại Lime để nhận quest mới
            AUTO_WATERMELON = false
            AUTO_QUEST = true
            QuestReceived = false

            State = STATE_LIME

            ClearTarget()
            ClearPath()

            return
        end
    end

    if not TargetValid() then
        return
    end

    local distance =
        (RootPart.Position - CurrentTargetPart.Position).Magnitude

    if distance <= TARGET_DISTANCE then
        -- Chỉ dừng khi đã tới quả dưa.
        -- Không giả định cơ chế phá của game.
        Humanoid:MoveTo(RootPart.Position)
        return
    end

    MoveTo(CurrentTargetPart.Position)
end

--==================================================
-- 🧠 SINGLE CONTROLLER
--==================================================

task.spawn(function()

    while task.wait(0.12) do

        if not Alive() then
            continue
        end

        if AUTO_QUEST then
            State = STATE_LIME
            RunQuest()

        elseif AUTO_WATERMELON then
            State = STATE_WATERMELON
            RunWatermelon()

        else
            State = STATE_IDLE
            ClearPath()
        end
    end
end)

--==================================================
-- 🎨 ESP
--==================================================

local function RemoveESP(obj)
    if not obj then
        return
    end

    local highlight =
        obj:FindFirstChild("WatermelonHighlight")

    if highlight then
        highlight:Destroy()
    end

    local dot =
        obj:FindFirstChild("WatermelonDot")

    if dot then
        dot:Destroy()
    end
end

local function AddESP(obj)

    if not obj or not obj.Parent then
        return
    end

    local part = GetPart(obj)

    if not part then
        return
    end

    if ESP_ENABLED then

        local highlight =
            obj:FindFirstChild("WatermelonHighlight")

        if not highlight then

            highlight = Instance.new("Highlight")

            highlight.Name =
                "WatermelonHighlight"

            highlight.Adornee = obj

            highlight.FillColor =
                Color3.fromRGB(255, 0, 0)

            highlight.OutlineColor =
                Color3.fromRGB(255, 255, 255)

            highlight.FillTransparency = 0.45

            highlight.Parent = obj
        end

    else
        local highlight =
            obj:FindFirstChild("WatermelonHighlight")

        if highlight then
            highlight:Destroy()
        end
    end

    if DOT_ENABLED then

        local dot =
            obj:FindFirstChild("WatermelonDot")

        if not dot then

            local billboard =
                Instance.new("BillboardGui")

            billboard.Name =
                "WatermelonDot"

            billboard.Adornee = part

            billboard.Size =
                UDim2.fromOffset(18, 18)

            billboard.StudsOffset =
                Vector3.new(0, 3, 0)

            billboard.AlwaysOnTop = true

            billboard.Parent = obj

            local frame =
                Instance.new("Frame")

            frame.Size =
                UDim2.fromScale(1, 1)

            frame.BackgroundColor3 =
                Color3.fromRGB(255, 0, 0)

            frame.BorderSizePixel = 0

            frame.Parent = billboard

            local corner =
                Instance.new("UICorner")

            corner.CornerRadius =
                UDim.new(1, 0)

            corner.Parent = frame
        end

    else

        local dot =
            obj:FindFirstChild("WatermelonDot")

        if dot then
            dot:Destroy()
        end
    end
end

local function UpdateESP()

    for _, obj in ipairs(
        Workspace:GetDescendants()
    ) do

        if IsWatermelon(obj) then
            AddESP(obj)
        end
    end
end

Workspace.DescendantAdded:Connect(function(obj)

    if IsWatermelon(obj) then
        task.wait(0.1)
        AddESP(obj)
    end
end)

--==================================================
-- 🖥️ GUI
--==================================================

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "SolRNG_Watermelon_V1"

ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main =
    Instance.new("Frame")

Main.Size =
    UDim2.fromOffset(280, 310)

Main.Position =
    UDim2.new(
        0.5,
        -140,
        0.5,
        -155
    )

Main.BackgroundColor3 =
    Color3.fromRGB(25, 25, 30)

Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner =
    Instance.new("UICorner")

Corner.CornerRadius =
    UDim.new(0, 12)

Corner.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title =
    Instance.new("TextLabel")

Title.Size =
    UDim2.new(1, 0, 0, 42)

Title.BackgroundTransparency = 1

Title.Text =
    "🍉 SolRNG Watermelon V1"

Title.TextColor3 =
    Color3.fromRGB(255, 255, 255)

Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local Credit =
    Instance.new("TextLabel")

Credit.Size =
    UDim2.new(1, 0, 0, 22)

Credit.Position =
    UDim2.new(0, 0, 0, 35)

Credit.BackgroundTransparency = 1

Credit.Text =
    "by sarry_fixe"

Credit.TextColor3 =
    Color3.fromRGB(170, 170, 170)

Credit.TextSize = 11
Credit.Font = Enum.Font.Gotham
Credit.Parent = Main

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

        input.Changed:Connect(function()

            if input.UserInputState ==
                Enum.UserInputState.End then

                Dragging = false
            end
        end)
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

        local Delta =
            input.Position - DragStart

        Main.Position =
            UDim2.new(
                StartPosition.X.Scale,
                StartPosition.X.Offset + Delta.X,

                StartPosition.Y.Scale,
                StartPosition.Y.Offset + Delta.Y
            )
    end
end)

--==================================================
-- BUTTON
--==================================================

local function CreateButton(text, y)

    local Button =
        Instance.new("TextButton")

    Button.Size =
        UDim2.new(1, -20, 0, 42)

    Button.Position =
        UDim2.new(0, 10, 0, y)

    Button.BackgroundColor3 =
        Color3.fromRGB(40, 40, 48)

    Button.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    Button.TextSize = 14
    Button.Font = Enum.Font.GothamBold

    Button.Text = text
    Button.Parent = Main

    local ButtonCorner =
        Instance.new("UICorner")

    ButtonCorner.CornerRadius =
        UDim.new(0, 8)

    ButtonCorner.Parent = Button

    return Button
end

--==================================================
-- BUTTONS
--==================================================

local ESPButton =
    CreateButton(
        "🍉 Định vị dưa: ON",
        65
    )

local QuestButton =
    CreateButton(
        "🍋 Auto Quest Limee: OFF",
        112
    )

local WatermelonButton =
    CreateButton(
        "🚶 Auto tới dưa: OFF",
        159
    )

--==================================================
-- STATUS
--==================================================

local Status =
    Instance.new("TextLabel")

Status.Size =
    UDim2.new(1, -20, 0, 70)

Status.Position =
    UDim2.new(0, 10, 0, 215)

Status.BackgroundTransparency = 1

Status.TextColor3 =
    Color3.fromRGB(190, 190, 190)

Status.TextSize = 12
Status.Font = Enum.Font.Gotham

Status.TextWrapped = true
Status.Parent = Main

task.spawn(function()

    while task.wait(0.2) do

        local TargetName = "None"

        if CurrentTarget then
            TargetName =
                CurrentTarget.Name
        end

        Status.Text =
            "State: "
            .. State
            .. "\nTarget: "
            .. TargetName
            .. "\nQuest: "
            .. (
                QuestReceived
                and "ACTIVE"
                or "NONE"
            )
    end
end)

--==================================================
-- ESP BUTTON
--==================================================

ESPButton.MouseButton1Click:Connect(function()

    ESP_ENABLED =
        not ESP_ENABLED

    ESPButton.Text =
        "🍉 Định vị dưa: "
        .. (
            ESP_ENABLED
            and "ON"
            or "OFF"
        )

    UpdateESP()
end)

--==================================================
-- QUEST BUTTON
--==================================================

QuestButton.MouseButton1Click:Connect(function()

    AUTO_QUEST =
        not AUTO_QUEST

    if AUTO_QUEST then

        AUTO_WATERMELON = false
        QuestReceived = false

        ClearTarget()
        ClearPath()

        State = STATE_LIME

        QuestButton.Text =
            "🍋 Auto Quest Limee: ON"

        WatermelonButton.Text =
            "🚶 Auto tới dưa: OFF"

    else

        QuestButton.Text =
            "🍋 Auto Quest Limee: OFF"

        if not AUTO_WATERMELON then
            State = STATE_IDLE
            ClearPath()
        end
    end
end)

--==================================================
-- WATERMELON BUTTON
--==================================================

WatermelonButton.MouseButton1Click:Connect(function()

    AUTO_WATERMELON =
        not AUTO_WATERMELON

    if AUTO_WATERMELON then

        AUTO_QUEST = false

        ClearTarget()
        ClearPath()

        State = STATE_WATERMELON

        QuestButton.Text =
            "🍋 Auto Quest Limee: OFF"

        WatermelonButton.Text =
            "🚶 Auto tới dưa: ON"

    else

        WatermelonButton.Text =
            "🚶 Auto tới dưa: OFF"

        State = STATE_IDLE

        ClearTarget()
        ClearPath()
    end
end)

--==================================================
-- 🔄 AUTO SCAN
--==================================================

task.spawn(function()

    task.wait(1)

    ScanWatermelons()
    UpdateESP()

    while task.wait(2) do

        ScanWatermelons()

        if ESP_ENABLED
            or DOT_ENABLED then

            UpdateESP()
        end
    end
end)

--==================================================
-- 🍉 LOADED
--==================================================

print("================================")
print("🍉 SolRNG Watermelon V1")
print("by sarry_fixe")
print("🍋 Limee Quest")
print("🍉 Watermelon Locator")
print("================================")
