--==================================================
-- 🍉 SolRNG Watermelon V8
-- by sarry_fixe
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- ⚙️ SETTINGS
--==================================================

local ESP_ENABLED = true
local DOT_ENABLED = true
local FPS_ENABLED = false

local AUTO_QUEST = false
local AUTO_WALK = false

local LIME_NAME = "Lime"

local WATERMELON_NAMES = {
    "watermelon",
    "melon",
    "dua",
    "duahau"
}

local QUEST_DISTANCE = 8
local WATERMELON_TOUCH_DISTANCE = 5

local SCAN_INTERVAL = 0.8
local REPATH_INTERVAL = 1.2
local QUEST_COOLDOWN = 3

--==================================================
-- 🧠 STATES
--==================================================

local STATE_IDLE = "IDLE"
local STATE_GET_QUEST = "GET QUEST"
local STATE_FIND_WATERMELON = "FIND WATERMELON"
local STATE_TOUCH_WATERMELON = "TOUCH WATERMELON"

local ControllerState = STATE_IDLE

local QuestReceived = false

local CurrentTarget = nil
local CurrentTargetPart = nil

local CurrentPath = nil
local CurrentWaypoints = {}
local WaypointIndex = 1

local LastPathTime = 0
local LastQuestTime = 0
local LastScanTime = 0

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
    CurrentWaypoints = {}
    WaypointIndex = 1
end

if Player.Character then
    SetupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(function(char)
    task.wait(1)
    SetupCharacter(char)
end)

local function IsAlive()

    return Character
        and Humanoid
        and RootPart
        and Humanoid.Health > 0
end

--==================================================
-- 🔎 OBJECT HELPERS
--==================================================

local function GetObjectPart(obj)

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

        return obj:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end

    return obj:FindFirstChildWhichIsA(
        "BasePart",
        true
    )
end

local function IsWatermelon(obj)

    if not obj then
        return false
    end

    local name = string.lower(obj.Name)

    for _, keyword in ipairs(WATERMELON_NAMES) do

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
-- 🍉 SCAN
--==================================================

local Watermelons = {}

local function ScanWatermelons()

    table.clear(Watermelons)

    for _, obj in ipairs(
        Workspace:GetDescendants()
    ) do

        if IsWatermelon(obj) then

            local part = GetObjectPart(obj)

            if part then

                table.insert(
                    Watermelons,
                    {
                        Object = obj,
                        Part = part
                    }
                )
            end
        end
    end
end

local function GetNearestWatermelon()

    if not IsAlive() then
        return nil, nil
    end

    local nearest
    local nearestPart
    local nearestDistance = math.huge

    for _, data in ipairs(Watermelons) do

        local obj = data.Object
        local part = data.Part

        if obj
            and obj.Parent
            and part
            and part.Parent
            and IsWatermelon(obj) then

            local distance =
                (RootPart.Position - part.Position).Magnitude

            if distance < nearestDistance then

                nearestDistance = distance
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

    for _, obj in ipairs(
        Workspace:GetDescendants()
    ) do

        if string.lower(obj.Name)
            == string.lower(LIME_NAME) then

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

    return lime, GetObjectPart(lime)
end

--==================================================
-- 🛣️ PATH
--==================================================

local function ClearPath()

    CurrentPath = nil
    CurrentWaypoints = {}
    WaypointIndex = 1
end

local function CreatePath(destination)

    if not IsAlive() or not destination then
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
            RootPart.Position,
            destination
        )
    end)

    if not success then
        return false
    end

    if path.Status ~= Enum.PathStatus.Success then
        return false
    end

    CurrentPath = path
    CurrentWaypoints = path:GetWaypoints()
    WaypointIndex = 1
    LastPathTime = tick()

    return #CurrentWaypoints > 0
end

local function MoveToPosition(destination)

    if not IsAlive() then
        return
    end

    if not destination then
        return
    end

    if not CurrentPath
        or tick() - LastPathTime >= REPATH_INTERVAL then

        CreatePath(destination)
    end

    if #CurrentWaypoints == 0 then

        Humanoid:MoveTo(destination)

        return
    end

    local waypoint =
        CurrentWaypoints[WaypointIndex]

    if not waypoint then

        ClearPath()

        return
    end

    if waypoint.Action
        == Enum.PathWaypointAction.Jump then

        Humanoid.Jump = true
    end

    Humanoid:MoveTo(waypoint.Position)

    if
        (RootPart.Position - waypoint.Position).Magnitude
        <= 4
    then

        WaypointIndex += 1
    end
end

--==================================================
-- 🍋 TALK LIME
--==================================================

local function TalkToLime()

    if not IsAlive() then
        return false
    end

    local lime, limePart =
        GetLimePart()

    if not limePart then
        return false
    end

    local distance =
        (RootPart.Position - limePart.Position).Magnitude

    if distance > QUEST_DISTANCE then

        MoveToPosition(
            limePart.Position
        )

        return false
    end

    for _, obj in ipairs(
        lime:GetDescendants()
    ) do

        if obj:IsA("ProximityPrompt") then

            if typeof(
                fireproximityprompt
            ) == "function" then

                local success =
                    pcall(function()

                        fireproximityprompt(obj)
                    end)

                if success then
                    return true
                end
            end
        end

        if obj:IsA("ClickDetector") then

            if typeof(
                fireclickdetector
            ) == "function" then

                local success =
                    pcall(function()

                        fireclickdetector(obj)
                    end)

                if success then
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

    if not CurrentTargetPart then

        CurrentTargetPart =
            GetObjectPart(CurrentTarget)
    end

    return CurrentTargetPart ~= nil
end

--==================================================
-- 🍉 AUTO TOUCH / BREAK
--==================================================

local function TouchWatermelon()

    if not IsAlive() then
        return
    end

    if not TargetValid() then

        ClearTarget()

        ControllerState =
            STATE_FIND_WATERMELON

        return
    end

    local distance =
        (RootPart.Position -
            CurrentTargetPart.Position).Magnitude

    -- Đã chạm / đủ gần quả
    if distance <= WATERMELON_TOUCH_DISTANCE then

        -- Dừng tại quả
        Humanoid:MoveTo(
            RootPart.Position
        )

        -- Chờ game xử lý việc chạm/đập
        task.wait(0.25)

        -- Nếu quả biến mất -> quả đã được xử lý
        if not TargetValid() then

            ClearTarget()

            ControllerState =
                STATE_FIND_WATERMELON

            return
        end

        -- Nếu quả vẫn còn, tiến sát thêm
        if distance > 2 then

            MoveToPosition(
                CurrentTargetPart.Position
            )
        end

        return
    end

    -- Chưa tới quả
    MoveToPosition(
        CurrentTargetPart.Position
    )
end

--==================================================
-- 🍉 FIND TARGET
--==================================================

local function FindWatermelon()

    if not IsAlive() then
        return
    end

    if TargetValid() then

        ControllerState =
            STATE_TOUCH_WATERMELON

        return
    end

    ClearTarget()

    if tick() - LastScanTime >= SCAN_INTERVAL then

        ScanWatermelons()

        LastScanTime = tick()
    end

    local target, part =
        GetNearestWatermelon()

    if target and part then

        CurrentTarget = target
        CurrentTargetPart = part

        ClearPath()

        ControllerState =
            STATE_TOUCH_WATERMELON

        return
    end

    -- Không còn dưa
    if AUTO_QUEST then

        QuestReceived = false

        ControllerState =
            STATE_GET_QUEST
    end
end

--==================================================
-- 🍋 QUEST
--==================================================

local function RunQuest()

    if not AUTO_QUEST then
        return
    end

    if not IsAlive() then
        return
    end

    if QuestReceived then

        AUTO_QUEST = false
        AUTO_WALK = true

        QuestReceived = true

        ClearTarget()
        ClearPath()

        ControllerState =
            STATE_FIND_WATERMELON

        return
    end

    if tick() - LastQuestTime
        < QUEST_COOLDOWN then

        return
    end

    local lime, limePart =
        GetLimePart()

    if not limePart then
        return
    end

    local distance =
        (RootPart.Position -
            limePart.Position).Magnitude

    if distance > QUEST_DISTANCE then

        MoveToPosition(
            limePart.Position
        )

        return
    end

    local success =
        TalkToLime()

    if success then

        QuestReceived = true
        LastQuestTime = tick()

        --==========================================
        -- ⭐ NHẬN QUEST XONG
        --==========================================

        AUTO_QUEST = false
        AUTO_WALK = true

        ClearTarget()
        ClearPath()

        ControllerState =
            STATE_FIND_WATERMELON
    end
end

--==================================================
-- 🧠 SINGLE CONTROLLER
--==================================================

task.spawn(function()

    while task.wait(0.12) do

        if not IsAlive() then
            continue
        end

        -- Không có chức năng nào
        if not AUTO_QUEST
            and not AUTO_WALK then

            ControllerState =
                STATE_IDLE

            ClearPath()

            continue
        end

        --==========================================
        -- QUEST
        --==========================================

        if AUTO_QUEST then

            ControllerState =
                STATE_GET_QUEST

            RunQuest()

        --==========================================
        -- WATERMELON
        --==========================================

        elseif AUTO_WALK then

            if ControllerState
                == STATE_IDLE then

                ControllerState =
                    STATE_FIND_WATERMELON
            end

            if ControllerState
                == STATE_FIND_WATERMELON then

                FindWatermelon()

            elseif ControllerState
                == STATE_TOUCH_WATERMELON then

                TouchWatermelon()
            end
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
        obj:FindFirstChild(
            "WatermelonHighlight"
        )

    if highlight then
        highlight:Destroy()
    end

    local dot =
        obj:FindFirstChild(
            "WatermelonDot"
        )

    if dot then
        dot:Destroy()
    end
end

local function AddESP(obj)

    if not obj
        or not obj.Parent then

        return
    end

    local part =
        GetObjectPart(obj)

    if not part then
        return
    end

    if ESP_ENABLED then

        local highlight =
            obj:FindFirstChild(
                "WatermelonHighlight"
            )

        if not highlight then

            highlight =
                Instance.new("Highlight")

            highlight.Name =
                "WatermelonHighlight"

            highlight.Adornee = obj

            highlight.FillColor =
                Color3.fromRGB(
                    255, 0, 0
                )

            highlight.OutlineColor =
                Color3.fromRGB(
                    255, 255, 255
                )

            highlight.FillTransparency =
                0.45

            highlight.Parent = obj
        end

    else

        RemoveESP(obj)
    end

    if DOT_ENABLED then

        local dot =
            obj:FindFirstChild(
                "WatermelonDot"
            )

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
                Color3.fromRGB(
                    255, 0, 0
                )

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
            obj:FindFirstChild(
                "WatermelonDot"
            )

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
-- 🚀 FPS BOOST
--==================================================

local SavedLighting = {}

local function FPSBoost(enable)

    if enable then

        SavedLighting.GlobalShadows =
            Lighting.GlobalShadows

        SavedLighting.FogEnd =
            Lighting.FogEnd

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000

        for _, obj in ipairs(
            Workspace:GetDescendants()
        ) do

            if obj:IsA("ParticleEmitter")
                or obj:IsA("Trail")
                or obj:IsA("Beam") then

                obj.Enabled = false

            elseif obj:IsA("BasePart") then

                obj.CastShadow = false
            end
        end

    else

        if SavedLighting.GlobalShadows ~= nil then

            Lighting.GlobalShadows =
                SavedLighting.GlobalShadows
        end

        if SavedLighting.FogEnd ~= nil then

            Lighting.FogEnd =
                SavedLighting.FogEnd
        end
    end
end

--==================================================
-- 🖥️ GUI
--==================================================

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "SolRNG_V8"

ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main =
    Instance.new("Frame")

Main.Size =
    UDim2.fromOffset(280, 355)

Main.Position =
    UDim2.new(
        0.5,
        -140,
        0.5,
        -177
    )

Main.BackgroundColor3 =
    Color3.fromRGB(
        25, 25, 30
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
    UDim2.new(1, 0, 0, 45)

Title.BackgroundTransparency = 1

Title.Text =
    "🍉 SolRNG Watermelon V8"

Title.TextColor3 =
    Color3.fromRGB(
        255, 255, 255
    )

Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

--==================================================
-- DRAG
--==================================================

local dragging = false
local dragStart
local startPos

Title.InputBegan:Connect(function(input)

    if input.UserInputType
        == Enum.UserInputType.MouseButton1

        or input.UserInputType
        == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = Main.Position

        input.Changed:Connect(function()

            if input.UserInputState
                == Enum.UserInputState.End then

                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)

    if not dragging then
        return
    end

    if input.UserInputType
        == Enum.UserInputType.MouseMovement

        or input.UserInputType
        == Enum.UserInputType.Touch then

        local delta =
            input.Position - dragStart

        Main.Position =
            UDim2.new(
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

local function CreateButton(
    text,
    y
)

    local button =
        Instance.new("TextButton")

    button.Size =
        UDim2.new(
            1,
            -20,
            0,
            40
        )

    button.Position =
        UDim2.new(
            0,
            10,
            0,
            y
        )

    button.BackgroundColor3 =
        Color3.fromRGB(
            40, 40, 48
        )

    button.TextColor3 =
        Color3.fromRGB(
            255, 255, 255
        )

    button.TextSize = 14
    button.Font =
        Enum.Font.GothamBold

    button.Text = text
    button.Parent = Main

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 8)

    corner.Parent = button

    return button
end

--==================================================
-- BUTTONS
--==================================================

local ESPButton =
    CreateButton(
        "ESP: ON",
        50
    )

local DotButton =
    CreateButton(
        "Dot: ON",
        95
    )

local FPSButton =
    CreateButton(
        "FPS Boost: OFF",
        140
    )

local QuestButton =
    CreateButton(
        "🍋 Auto Quest Limee: OFF",
        185
    )

local WalkButton =
    CreateButton(
        "🍉 Auto Dưa Hấu: OFF",
        230
    )

--==================================================
-- STATUS
--==================================================

local Status =
    Instance.new("TextLabel")

Status.Size =
    UDim2.new(
        1,
        -20,
        0,
        65
    )

Status.Position =
    UDim2.new(
        0,
        10,
        0,
        280
    )

Status.BackgroundTransparency = 1

Status.TextColor3 =
    Color3.fromRGB(
        190, 190, 190
    )

Status.TextSize = 12
Status.Font = Enum.Font.Gotham
Status.TextWrapped = true
Status.Parent = Main

--==================================================
-- STATUS UPDATE
--==================================================

task.spawn(function()

    while task.wait(0.2) do

        local targetText = "None"

        if CurrentTarget then
            targetText =
                CurrentTarget.Name
        end

        Status.Text =
            "State: "
            .. ControllerState
            .. "\nTarget: "
            .. targetText
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
        "ESP: "
        .. (
            ESP_ENABLED
            and "ON"
            or "OFF"
        )

    UpdateESP()
end)

--==================================================
-- DOT BUTTON
--==================================================

DotButton.MouseButton1Click:Connect(function()

    DOT_ENABLED =
        not DOT_ENABLED

    DotButton.Text =
        "Dot: "
        .. (
            DOT_ENABLED
            and "ON"
            or "OFF"
        )

    UpdateESP()
end)

--==================================================
-- FPS BUTTON
--==================================================

FPSButton.MouseButton1Click:Connect(function()

    FPS_ENABLED =
        not FPS_ENABLED

    FPSButton.Text =
        "FPS Boost: "
        .. (
            FPS_ENABLED
            and "ON"
            or "OFF"
        )

    FPSBoost(FPS_ENABLED)
end)

--==================================================
-- 🍋 QUEST BUTTON
--==================================================

QuestButton.MouseButton1Click:Connect(function()

    AUTO_QUEST =
        not AUTO_QUEST

    if AUTO_QUEST then

        -- Không chạy 2 controller cùng lúc
        AUTO_WALK = false

        QuestReceived = false

        ClearTarget()
        ClearPath()

        ControllerState =
            STATE_GET_QUEST

        QuestButton.Text =
            "🍋 Auto Quest Limee: ON"

        WalkButton.Text =
            "🍉 Auto Dưa Hấu: OFF"

    else

        QuestButton.Text =
            "🍋 Auto Quest Limee: OFF"

        if not AUTO_WALK then

            ControllerState =
                STATE_IDLE

            ClearPath()
        end
    end
end)

--==================================================
-- 🍉 WATERMELON BUTTON
--==================================================

WalkButton.MouseButton1Click:Connect(function()

    AUTO_WALK =
        not AUTO_WALK

    if AUTO_WALK then

        AUTO_QUEST = false

        ClearTarget()
        ClearPath()

        ControllerState =
            STATE_FIND_WATERMELON

        QuestButton.Text =
            "🍋 Auto Quest Limee: OFF"

        WalkButton.Text =
            "🍉 Auto Dưa Hấu: ON"

    else

        WalkButton.Text =
            "🍉 Auto Dưa Hấu: OFF"

        ControllerState =
            STATE_IDLE

        ClearTarget()
        ClearPath()
    end
end)

--==================================================
-- 👻 MINIMIZE
--==================================================

local Mini =
    Instance.new("TextButton")

Mini.Size =
    UDim2.fromOffset(
        50,
        50
    )

Mini.Position =
    UDim2.new(
        0,
        15,
        0.5,
        -25
    )

Mini.BackgroundColor3 =
    Color3.fromRGB(
        25, 25, 30
    )

Mini.Text = "🍉"
Mini.TextSize = 25
Mini.Visible = false
Mini.Parent = ScreenGui

local MiniCorner =
    Instance.new("UICorner")

MiniCorner.CornerRadius =
    UDim.new(1, 0)

MiniCorner.Parent = Mini

local HideButton =
    Instance.new("TextButton")

HideButton.Size =
    UDim2.fromOffset(
        25,
        25
    )

HideButton.Position =
    UDim2.new(
        1,
        -32,
        0,
        10
    )

HideButton.BackgroundTransparency = 1
HideButton.Text = "×"
HideButton.TextColor3 =
    Color3.fromRGB(
        255, 255, 255
    )

HideButton.TextSize = 20
HideButton.Parent = Main

HideButton.MouseButton1Click:Connect(function()

    Main.Visible = false
    Mini.Visible = true
end)

Mini.MouseButton1Click:Connect(function()

    Main.Visible = true
    Mini.Visible = false
end)

--==================================================
-- 🔄 RESCAN
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
-- ✅ LOADED
--==================================================

print(
    "🍉 SolRNG Watermelon V8 Loaded"
)

print(
    "🍋 Limee Quest -> 🍉 Touch Watermelon"
)
