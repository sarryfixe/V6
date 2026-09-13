--==================================================
-- 🍉 SolRNG ESP Watermelon V6
-- by sarry_fixe
--
-- FEATURES:
-- 👁️ ESP ON/OFF
-- 🎯 Center Dot
-- 🚀 FPS Boost
-- 🧭 Pathfinding
-- 🧱 Anti-Stuck
-- 🔄 Auto Target
--==================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SETTINGS
--==================================================

local ESP_ENABLED = false
local DOT_ENABLED = true
local FPS_ENABLED = false
local AUTO_WALK = false

local TARGET_REACHED_DISTANCE = 7
local REPATH_TIME = 0.35

-- Anti stuck
local STUCK_CHECK_TIME = 1.0
local STUCK_DISTANCE = 1.2

-- Path
local AGENT_RADIUS = 2
local AGENT_HEIGHT = 5
local WAYPOINT_SPACING = 3

--==================================================
-- WATERMELON KEYWORDS
--==================================================

local Keywords = {
    "watermelon",
    "melon",
    "dua",
    "duahau"
}

--==================================================
-- DATA
--==================================================

local Marked = {}

local FPSBackup = {
    GlobalShadows = nil,
    FogEnd = nil,
    Effects = {},
    Particles = {},
    Trails = {},
    Beams = {},
    TerrainDecoration = nil
}

--==================================================
-- WATERMELON CHECK
--==================================================

local function IsWatermelon(Object)

    if not Object then
        return false
    end

    local Name = string.lower(Object.Name)

    for _, Word in ipairs(Keywords) do

        if string.find(Name, Word, 1, true) then
            return true
        end

    end

    return false
end

--==================================================
-- GET PART
--==================================================

local function GetPart(Object)

    if not Object then
        return nil
    end

    if Object:IsA("BasePart") then
        return Object
    end

    if Object:IsA("Model") then

        if Object.PrimaryPart then
            return Object.PrimaryPart
        end

        return Object:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end

    return nil
end

--==================================================
-- ADD ESP
--==================================================

local function AddESP(Object)

    if Marked[Object] then
        return
    end

    local Part = GetPart(Object)

    if not Part then
        return
    end

    --==================================================
    -- HIGHLIGHT
    --==================================================

    local Highlight = Instance.new("Highlight")

    Highlight.Name = "WatermelonESP"
    Highlight.Adornee = Object

    Highlight.FillTransparency = 0.65
    Highlight.OutlineTransparency = 0

    -- Quan trọng: lấy đúng trạng thái hiện tại
    Highlight.Enabled = ESP_ENABLED

    Highlight.Parent = Object

    --==================================================
    -- CENTER DOT
    --==================================================

    local DotGui = Instance.new("BillboardGui")

    DotGui.Name = "WatermelonCenterDot"
    DotGui.Adornee = Part

    DotGui.Size =
        UDim2.fromOffset(12, 12)

    DotGui.AlwaysOnTop = true
    DotGui.LightInfluence = 0
    DotGui.Enabled = DOT_ENABLED

    DotGui.Parent = PlayerGui

    local Dot = Instance.new("Frame")

    Dot.Size = UDim2.fromScale(1, 1)

    Dot.BackgroundColor3 =
        Color3.fromRGB(255, 60, 60)

    Dot.BorderSizePixel = 0
    Dot.Parent = DotGui

    local Corner = Instance.new("UICorner")

    Corner.CornerRadius =
        UDim.new(1, 0)

    Corner.Parent = Dot

    --==================================================
    -- SAVE
    --==================================================

    Marked[Object] = {
        Highlight = Highlight,
        Dot = DotGui,
        Part = Part
    }
end

--==================================================
-- SCAN
--==================================================

local function ScanWatermelons()

    for _, Object in ipairs(
        Workspace:GetDescendants()
    ) do

        if IsWatermelon(Object) then
            AddESP(Object)
        end

    end
end

--==================================================
-- NEW OBJECT
--==================================================

Workspace.DescendantAdded:Connect(function(Object)

    task.wait(0.08)

    if IsWatermelon(Object) then
        AddESP(Object)
    end
end)

--==================================================
-- CLEAN
--==================================================

local function CleanMarked()

    for Object, Data in pairs(Marked) do

        if not Object
            or not Object.Parent
            or not Data
            or not Data.Part
            or not Data.Part.Parent then

            if Data then

                if Data.Highlight then
                    pcall(function()
                        Data.Highlight:Destroy()
                    end)
                end

                if Data.Dot then
                    pcall(function()
                        Data.Dot:Destroy()
                    end)
                end

            end

            Marked[Object] = nil
        end

    end
end

--==================================================
-- CHARACTER
--==================================================

local function GetCharacter()

    local Character = Player.Character

    if not Character then
        return nil, nil, nil
    end

    local Humanoid =
        Character:FindFirstChildOfClass(
            "Humanoid"
        )

    local Root =
        Character:FindFirstChild(
            "HumanoidRootPart"
        )

    return Character, Humanoid, Root
end

--==================================================
-- NEAREST WATERMELON
--==================================================

local function GetNearestWatermelon()

    local _, _, Root =
        GetCharacter()

    if not Root then
        return nil, nil
    end

    local Nearest = nil
    local NearestDistance = math.huge

    for Object, Data in pairs(Marked) do

        if Object
            and Object.Parent
            and Data
            and Data.Part
            and Data.Part.Parent then

            local Distance =
                (
                    Root.Position -
                    Data.Part.Position
                ).Magnitude

            if Distance < NearestDistance then

                NearestDistance = Distance
                Nearest = Object

            end
        end

    end

    return Nearest, NearestDistance
end

--==================================================
-- STOP
--==================================================

local function StopMovement()

    local _, Humanoid, Root =
        GetCharacter()

    if Humanoid and Root then

        Humanoid:Move(Vector3.zero)

        Humanoid:MoveTo(
            Root.Position
        )

    end
end

--==================================================
-- CREATE PATH
--==================================================

local function CreatePath(TargetPart)

    local _, _, Root =
        GetCharacter()

    if not Root then
        return nil
    end

    if not TargetPart
        or not TargetPart.Parent then

        return nil
    end

    local Path

    local Success = pcall(function()

        Path =
            PathfindingService:CreatePath({
                AgentRadius = AGENT_RADIUS,
                AgentHeight = AGENT_HEIGHT,
                AgentCanJump = true,
                AgentCanClimb = true,
                WaypointSpacing = WAYPOINT_SPACING
            })

        Path:ComputeAsync(
            Root.Position,
            TargetPart.Position
        )

    end)

    if not Success then
        return nil
    end

    if not Path then
        return nil
    end

    if Path.Status
        ~= Enum.PathStatus.Success then

        return nil
    end

    return Path
end

--==================================================
-- FOLLOW PATH
--==================================================

local function FollowPath(TargetPart)

    if not AUTO_WALK then
        return false
    end

    if not TargetPart
        or not TargetPart.Parent then

        return false
    end

    local Path =
        CreatePath(TargetPart)

    if not Path then
        return false
    end

    local Waypoints =
        Path:GetWaypoints()

    if #Waypoints == 0 then
        return false
    end

    --==================================================
    -- PATH BLOCKED
    --==================================================

    local PathBlocked = false

    local BlockConnection =
        Path.Blocked:Connect(function()
            PathBlocked = true
        end)

    --==================================================
    -- WAYPOINTS
    --==================================================

    for _, Waypoint in ipairs(Waypoints) do

        if not AUTO_WALK then
            break
        end

        if PathBlocked then
            break
        end

        if not TargetPart.Parent then
            break
        end

        local _, Humanoid, Root =
            GetCharacter()

        if not Humanoid
            or not Root then

            break
        end

        --==================================================
        -- CHECK TARGET DISTANCE
        --==================================================

        local TargetDistance =
            (
                Root.Position -
                TargetPart.Position
            ).Magnitude

        if TargetDistance
            <= TARGET_REACHED_DISTANCE then

            StopMovement()
            break
        end

        --==================================================
        -- JUMP
        --==================================================

        if Waypoint.Action
            == Enum.PathWaypointAction.Jump then

            Humanoid.Jump = true
        end

        Humanoid:MoveTo(
            Waypoint.Position
        )

        --==================================================
        -- WAIT
        --==================================================

        local LastPosition =
            Root.Position

        local LastCheck =
            tick()

        local Reached = false

        local StartTime =
            tick()

        while AUTO_WALK
            and not PathBlocked
            and TargetPart.Parent do

            task.wait(0.08)

            local _, CurrentHumanoid, CurrentRoot =
                GetCharacter()

            if not CurrentHumanoid
                or not CurrentRoot then

                break
            end

            --==================================================
            -- TARGET DISAPPEARED
            --==================================================

            if not TargetPart.Parent then
                break
            end

            --==================================================
            -- CLOSE TO TARGET
            --==================================================

            local CurrentTargetDistance =
                (
                    CurrentRoot.Position -
                    TargetPart.Position
                ).Magnitude

            if CurrentTargetDistance
                <= TARGET_REACHED_DISTANCE then

                Reached = true
                break
            end

            --==================================================
            -- WAYPOINT REACHED
            --==================================================

            local WaypointDistance =
                (
                    CurrentRoot.Position -
                    Waypoint.Position
                ).Magnitude

            if WaypointDistance <= 4 then

                Reached = true
                break
            end

            --==================================================
            -- ANTI-STUCK
            --==================================================

            if tick() - LastCheck
                >= STUCK_CHECK_TIME then

                local Moved =
                    (
                        CurrentRoot.Position -
                        LastPosition
                    ).Magnitude

                if Moved < STUCK_DISTANCE then

                    -- Bị kẹt
                    Reached = false
                    PathBlocked = true
                    break
                end

                LastPosition =
                    CurrentRoot.Position

                LastCheck =
                    tick()
            end

            --==================================================
            -- WAYPOINT TIMEOUT
            --==================================================

            if tick() - StartTime > 4 then

                Reached = false
                PathBlocked = true
                break
            end
        end

        if not Reached then
            break
        end
    end

    if BlockConnection then
        BlockConnection:Disconnect()
    end

    return not PathBlocked
end

--==================================================
-- AUTO WALK ENGINE
--==================================================

task.spawn(function()

    while true do

        task.wait(REPATH_TIME)

        if not AUTO_WALK then
            continue
        end

        CleanMarked()
        ScanWatermelons()

        local Character,
            Humanoid,
            Root =
            GetCharacter()

        if not Character
            or not Humanoid
            or not Root then

            continue
        end

        if Humanoid.Health <= 0 then
            continue
        end

        --==================================================
        -- FIND TARGET
        --==================================================

        local Target,
            Distance =
            GetNearestWatermelon()

        if not Target then

            Status.Text =
                "❌ Không tìm thấy dưa"

            StopMovement()

            task.wait(0.5)

            continue
        end

        local Data =
            Marked[Target]

        if not Data
            or not Data.Part
            or not Data.Part.Parent then

            continue
        end

        --==================================================
        -- STATUS
        --==================================================

        Status.Text =
            string.format(
                "🍉 %s | %.0f studs",
                Target.Name,
                Distance
            )

        --==================================================
        -- ALREADY NEAR
        --==================================================

        if Distance
            <= TARGET_REACHED_DISTANCE then

            StopMovement()

            task.wait(0.25)

            continue
        end

        --==================================================
        -- FOLLOW
        --==================================================

        local Success =
            FollowPath(Data.Part)

        --==================================================
        -- PATH FAILED / STUCK
        --==================================================

        if not Success
            and AUTO_WALK then

            Status.Text =
                "🔄 Bị kẹt — đổi đường..."

            StopMovement()

            task.wait(0.15)
        end
    end
end)

--==================================================
-- FPS BOOST
--==================================================

local function EnableFPSBoost()

    -- Backup Lighting
    FPSBackup.GlobalShadows =
        Lighting.GlobalShadows

    FPSBackup.FogEnd =
        Lighting.FogEnd

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000

    -- Backup & disable PostEffects
    for _, Object in ipairs(
        Lighting:GetChildren()
    ) do

        if Object:IsA("PostEffect") then

            if FPSBackup.Effects[Object] == nil then

                FPSBackup.Effects[Object] =
                    Object.Enabled
            end

            Object.Enabled = false
        end
    end

    -- Terrain
    local Terrain =
        Workspace:FindFirstChildOfClass(
            "Terrain"
        )

    if Terrain then

        FPSBackup.TerrainDecoration =
            Terrain.Decoration

        Terrain.Decoration = false
    end

    -- Particles / Trails / Beams
    for _, Object in ipairs(
        Workspace:GetDescendants()
    ) do

        if Object:IsA("ParticleEmitter") then

            if FPSBackup.Particles[Object] == nil then

                FPSBackup.Particles[Object] =
                    Object.Enabled
            end

            Object.Enabled = false

        elseif Object:IsA("Trail") then

            if FPSBackup.Trails[Object] == nil then

                FPSBackup.Trails[Object] =
                    Object.Enabled
            end

            Object.Enabled = false

        elseif Object:IsA("Beam") then

            if FPSBackup.Beams[Object] == nil then

                FPSBackup.Beams[Object] =
                    Object.Enabled
            end

            Object.Enabled = false
        end
    end
end

--==================================================
-- FPS RESTORE
--==================================================

local function DisableFPSBoost()

    if FPSBackup.GlobalShadows ~= nil then

        Lighting.GlobalShadows =
            FPSBackup.GlobalShadows
    end

    if FPSBackup.FogEnd ~= nil then

        Lighting.FogEnd =
            FPSBackup.FogEnd
    end

    -- Restore Effects
    for Object, Enabled in pairs(
        FPSBackup.Effects
    ) do

        if Object and Object.Parent then
            Object.Enabled = Enabled
        end
    end

    -- Restore Particles
    for Object, Enabled in pairs(
        FPSBackup.Particles
    ) do

        if Object and Object.Parent then
            Object.Enabled = Enabled
        end
    end

    -- Restore Trails
    for Object, Enabled in pairs(
        FPSBackup.Trails
    ) do

        if Object and Object.Parent then
            Object.Enabled = Enabled
        end
    end

    -- Restore Beams
    for Object, Enabled in pairs(
        FPSBackup.Beams
    ) do

        if Object and Object.Parent then
            Object.Enabled = Enabled
        end
    end

    -- Restore Terrain
    local Terrain =
        Workspace:FindFirstChildOfClass(
            "Terrain"
        )

    if Terrain
        and FPSBackup.TerrainDecoration ~= nil then

        Terrain.Decoration =
            FPSBackup.TerrainDecoration
    end
end

--==================================================
-- GUI
--==================================================

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "SolRNG_Watermelon_V6"

ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

--==================================================
-- MAIN
--==================================================

local Main =
    Instance.new("Frame")

Main.Size =
    UDim2.fromOffset(280, 285)

Main.Position =
    UDim2.new(
        0.5,
        -140,
        0.5,
        -142
    )

Main.BackgroundColor3 =
    Color3.fromRGB(20, 20, 25)

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
    UDim2.new(1, 0, 0, 32)

Title.Position =
    UDim2.fromOffset(0, 5)

Title.BackgroundTransparency = 1

Title.Text =
    "🍉 SolRNG ESP Watermelon V6"

Title.TextColor3 =
 Color3.new(1, 1, 1)

Title.TextSize = 16

Title.Font =
    Enum.Font.GothamBold

Title.Parent = Main

local Credit =
    Instance.new("TextLabel")

Credit.Size =
    UDim2.new(1, 0, 0, 18)

Credit.Position =
    UDim2.fromOffset(0, 34)

Credit.BackgroundTransparency = 1

Credit.Text =
    "by sarry_fixe"

Credit.TextColor3 =
    Color3.fromRGB(170, 170, 170)

Credit.TextSize = 11

Credit.Font =
    Enum.Font.Gotham

Credit.Parent = Main

--==================================================
-- DRAG
--==================================================

local Dragging = false
local DragStart
local StartPosition

Title.InputBegan:Connect(function(Input)

    if Input.UserInputType
        == Enum.UserInputType.MouseButton1

        or Input.UserInputType
        == Enum.UserInputType.Touch then

        Dragging = true

        DragStart =
            Input.Position

        StartPosition =
            Main.Position
    end
end)

UIS.InputChanged:Connect(function(Input)

    if not Dragging then
        return
    end

    if Input.UserInputType
        == Enum.UserInputType.MouseMovement

        or Input.UserInputType
        == Enum.UserInputType.Touch then

        local Delta =
            Input.Position -
            DragStart

        Main.Position =
            UDim2.new(
                StartPosition.X.Scale,
                StartPosition.X.Offset + Delta.X,

                StartPosition.Y.Scale,
                StartPosition.Y.Offset + Delta.Y
            )
    end
end)

UIS.InputEnded:Connect(function(Input)

    if Input.UserInputType
        == Enum.UserInputType.MouseButton1

        or Input.UserInputType
        == Enum.UserInputType.Touch then

        Dragging = false
    end
end)

--==================================================
-- BUTTON
--==================================================

local function CreateButton(Text, Y)

    local Button =
        Instance.new("TextButton")

    Button.Size =
        UDim2.new(1, -30, 0, 38)

    Button.Position =
        UDim2.fromOffset(15, Y)

    Button.BackgroundColor3 =
        Color3.fromRGB(35, 35, 45)

    Button.BorderSizePixel = 0

    Button.Text = Text

    Button.TextColor3 =
        Color3.new(1, 1, 1)

    Button.TextSize = 14

    Button.Font =
        Enum.Font.GothamMedium

    Button.Parent = Main

    local Corner =
        Instance.new("UICorner")

    Corner.CornerRadius =
        UDim.new(0, 8)

    Corner.Parent = Button

    return Button
end

--==================================================
-- BUTTONS
--==================================================

local ESPButton =
    CreateButton(
        "👁️ ESP Dưa hấu : OFF",
        58
    )

local DotButton =
    CreateButton(
        "🎯 Dấu chấm giữa : ON",
        103
    )

local FPSButton =
    CreateButton(
        "🚀 FPS Boost : OFF",
        148
    )

local AutoButton =
    CreateButton(
        "🍉 Auto đi tới dưa : OFF",
        193
    )

local Status =
    Instance.new("TextLabel")

Status.Size =
    UDim2.new(1, -30, 0, 35)

Status.Position =
    UDim2.fromOffset(15, 238)

Status.BackgroundTransparency = 1

Status.Text =
    "Chưa quét"

Status.TextColor3 =
    Color3.fromRGB(200, 200, 200)

Status.TextSize = 12

Status.Font =
    Enum.Font.Gotham

Status.Parent = Main

--==================================================
-- ESP ON/OFF - FIXED
--==================================================

local function UpdateAllESP()

    for Object, Data in pairs(Marked) do

        if Data
            and Data.Highlight
            and Data.Highlight.Parent then

            Data.Highlight.Enabled =
                ESP_ENABLED
        end
    end
end

ESPButton.Activated:Connect(function()

    ESP_ENABLED =
        not ESP_ENABLED

    if ESP_ENABLED then

        ESPButton.Text =
            "👁️ ESP Dưa hấu : ON"

    else

        ESPButton.Text =
            "👁️ ESP Dưa hấu : OFF"
    end

    UpdateAllESP()
end)

--==================================================
-- DOT ON/OFF
--==================================================

DotButton.Activated:Connect(function()

    DOT_ENABLED =
        not DOT_ENABLED

    if DOT_ENABLED then

        DotButton.Text =
            "🎯 Dấu chấm giữa : ON"

    else

        DotButton.Text =
            "🎯 Dấu chấm giữa : OFF"
    end

    for _, Data in pairs(Marked) do

        if Data
            and Data.Dot
            and Data.Dot.Parent then

            Data.Dot.Enabled =
                DOT_ENABLED
        end
    end
end)

--==================================================
-- FPS BUTTON
--==================================================

FPSButton.Activated:Connect(function()

    FPS_ENABLED =
        not FPS_ENABLED

    if FPS_ENABLED then

        FPSButton.Text =
            "🚀 FPS Boost : ON"

        EnableFPSBoost()

    else

        FPSButton.Text =
            "🚀 FPS Boost : OFF"

        DisableFPSBoost()
    end
end)

--==================================================
-- AUTO WALK BUTTON
--==================================================

AutoButton.Activated:Connect(function()

    AUTO_WALK =
        not AUTO_WALK

    if AUTO_WALK then

        AutoButton.Text =
            "🍉 Auto đi tới dưa : ON"

        ScanWatermelons()

        Status.Text =
            "🧭 Đang tìm đường..."

    else

        AutoButton.Text =
            "🍉 Auto đi tới dưa : OFF"

        StopMovement()

        Status.Text =
            "⏹️ Đã dừng Auto"
    end
end)

--==================================================
-- HIDE / SHOW
--==================================================

local ToggleButton =
    Instance.new("TextButton")

ToggleButton.Size =
    UDim2.fromOffset(52, 52)

ToggleButton.Position =
    UDim2.new(
        0,
        15,
        0.5,
        -25
    )

ToggleButton.BackgroundColor3 =
    Color3.fromRGB(25, 25, 30)

ToggleButton.BackgroundTransparency =
    0.15

ToggleButton.Text =
    "🍉"

ToggleButton.TextSize = 24

ToggleButton.TextColor3 =
    Color3.new(1, 1, 1)

ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = ScreenGui

local ToggleCorner =
    Instance.new("UICorner")

ToggleCorner.CornerRadius =
    UDim.new(1, 0)

ToggleCorner.Parent =
    ToggleButton

ToggleButton.Activated:Connect(function()

    Main.Visible =
        not Main.Visible

    ToggleButton.Text =
        Main.Visible
        and "✕"
        or "🍉"
end)

--==================================================
-- START
--==================================================

ScanWatermelons()
