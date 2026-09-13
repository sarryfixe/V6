-- 🍉 SolRNG ESP Watermelon V2
-- by sarry_fixe

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

local ESPEnabled = false
local DotEnabled = true
local FPSBoostEnabled = false
local AutoGoEnabled = false

local Keywords = {
    "watermelon",
    "melon",
    "dua",
    "duahau"
}

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "WatermelonESP"
ESPFolder.Parent = workspace

-- =========================
-- FIND WATERMELON
-- =========================

local function IsWatermelon(obj)
    local name = string.lower(obj.Name)

    for _, keyword in ipairs(Keywords) do
        if string.find(name, keyword, 1, true) then
            return true
        end
    end

    return false
end

local function GetPart(obj)
    if obj:IsA("BasePart") then
        return obj
    end

    if obj:IsA("Model") then
        if obj.PrimaryPart then
            return obj.PrimaryPart
        end

        return obj:FindFirstChildWhichIsA("BasePart", true)
    end

    return nil
end

local function GetNearestWatermelon()
    local character = Player.Character
    if not character then return nil end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest = nil
    local shortest = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if IsWatermelon(obj) then
            local part = GetPart(obj)

            if part then
                local distance = (root.Position - part.Position).Magnitude

                if distance < shortest then
                    shortest = distance
                    nearest = part
                end
            end
        end
    end

    return nearest, shortest
end

-- =========================
-- ESP
-- =========================

local function AddESP(obj)
    if not ESPEnabled then return end
    if not IsWatermelon(obj) then return end

    local part = GetPart(obj)
    if not part then return end

    if ESPFolder:FindFirstChild(obj:GetDebugId()) then
        return
    end

    local holder = Instance.new("Folder")
    holder.Name = obj:GetDebugId()
    holder.Parent = ESPFolder

    local highlight = Instance.new("Highlight")
    highlight.Adornee = obj:IsA("Model") and obj or part
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = holder

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 100, 0, 35)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = holder

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = "🍉 DƯA"
    text.TextScaled = true
    text.TextStrokeTransparency = 0
    text.Parent = billboard
end

local function ClearESP()
    for _, v in ipairs(ESPFolder:GetChildren()) do
        v:Destroy()
    end
end

local function ScanESP()
    ClearESP()

    if not ESPEnabled then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if IsWatermelon(obj) then
            AddESP(obj)
        end
    end
end

-- =========================
-- GUI
-- =========================

local Gui = Instance.new("ScreenGui")
Gui.Name = "SolRNGWatermelonV2"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 330)
Main.Position = UDim2.new(0.5, -140, 0.5, -165)
Main.BackgroundTransparency = 0.1
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

-- TITLE

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "🍉 SolRNG ESP Watermelon V2"
Title.TextScaled = true
Title.TextStrokeTransparency = 0
Title.Parent = Main

local Credit = Instance.new("TextLabel")
Credit.Position = UDim2.new(0, 0, 0, 42)
Credit.Size = UDim2.new(1, 0, 0, 25)
Credit.BackgroundTransparency = 1
Credit.Text = "by sarry_fixe"
Credit.TextScaled = true
Credit.Parent = Main

-- =========================
-- BUTTON FUNCTION
-- =========================

local function CreateButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 45)
    button.Position = UDim2.new(0, 10, 0, y)
    button.BackgroundTransparency = 0.15
    button.Text = text
    button.TextScaled = true
    button.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = button

    return button
end

local ESPButton = CreateButton("👁️ ESP dưa hấu: OFF", 75)
local DotButton = CreateButton("🎯 Center Dot: ON", 125)
local FPSButton = CreateButton("⚡ FPS Boost: OFF", 175)
local FinderButton = CreateButton("🔎 Finder V2", 225)
local AutoButton = CreateButton("🍉 Auto đi tới dưa: OFF", 275)

-- =========================
-- CENTER DOT
-- =========================

local Dot = Instance.new("Frame")
Dot.Size = UDim2.new(0, 6, 0, 6)
Dot.Position = UDim2.new(0.5, -3, 0.5, -3)
Dot.BackgroundTransparency = 0
Dot.Visible = true
Dot.Parent = Gui

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = Dot

-- =========================
-- FINDER LABEL
-- =========================

local FinderLabel = Instance.new("TextLabel")
FinderLabel.Size = UDim2.new(0, 250, 0, 35)
FinderLabel.Position = UDim2.new(0.5, -125, 1, -55)
FinderLabel.BackgroundTransparency = 0.2
FinderLabel.Text = "🍉 Finder V2: --"
FinderLabel.TextScaled = true
FinderLabel.Visible = false
FinderLabel.Parent = Gui

local FinderCorner = Instance.new("UICorner")
FinderCorner.CornerRadius = UDim.new(0, 8)
FinderCorner.Parent = FinderLabel

-- =========================
-- ESP BUTTON
-- =========================

ESPButton.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled

    ESPButton.Text = "👁️ ESP dưa hấu: " ..
        (ESPEnabled and "ON" or "OFF")

    if ESPEnabled then
        ScanESP()
    else
        ClearESP()
    end
end)

-- =========================
-- DOT BUTTON
-- =========================

DotButton.MouseButton1Click:Connect(function()
    DotEnabled = not DotEnabled

    Dot.Visible = DotEnabled

    DotButton.Text = "🎯 Center Dot: " ..
        (DotEnabled and "ON" or "OFF")
end)

-- =========================
-- FPS BOOST
-- =========================

FPSButton.MouseButton1Click:Connect(function()
    FPSBoostEnabled = not FPSBoostEnabled

    FPSButton.Text = "⚡ FPS Boost: " ..
        (FPSBoostEnabled and "ON" or "OFF")

    if FPSBoostEnabled then
        Lighting.GlobalShadows = false

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("BloomEffect")
            or effect:IsA("BlurEffect")
            or effect:IsA("ColorCorrectionEffect")
            or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
    else
        Lighting.GlobalShadows = true

        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("BloomEffect")
            or effect:IsA("BlurEffect")
            or effect:IsA("ColorCorrectionEffect")
            or effect:IsA("SunRaysEffect") then
                effect.Enabled = true
            end
        end
    end
end)

-- =========================
-- FINDER V2
-- =========================

FinderButton.MouseButton1Click:Connect(function()
    FinderLabel.Visible = not FinderLabel.Visible
end)

RunService.RenderStepped:Connect(function()
    if not FinderLabel.Visible then
        return
    end

    local watermelon, distance = GetNearestWatermelon()

    if watermelon then
        FinderLabel.Text =
            "🍉 " .. watermelon.Name ..
            " | " .. math.floor(distance) .. " studs"
    else
        FinderLabel.Text = "🍉 Không tìm thấy dưa"
    end
end)

-- =========================
-- AUTO GO TO WATERMELON
-- =========================

AutoButton.MouseButton1Click:Connect(function()
    AutoGoEnabled = not AutoGoEnabled

    AutoButton.Text = "🍉 Auto đi tới dưa: " ..
        (AutoGoEnabled and "ON" or "OFF")
end)

task.spawn(function()
    while task.wait(0.25) do

        if AutoGoEnabled then

            local character = Player.Character

            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local root = character:FindFirstChild("HumanoidRootPart")

                if humanoid and root then

                    local watermelon = GetNearestWatermelon()

                    if watermelon then
                        humanoid:MoveTo(watermelon.Position)
                    end

                end
            end
        end
    end
end)

-- =========================
-- AUTO SCAN
-- =========================

task.spawn(function()
    while task.wait(2) do
        if ESPEnabled then
            ScanESP()
        end
    end
end)

workspace.DescendantAdded:Connect(function(obj)
    if ESPEnabled and IsWatermelon(obj) then
        task.wait(0.1)
        AddESP(obj)
    end
end)

-- =========================
-- DRAG MENU
-- =========================

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

UserInputService.InputChanged:Connect(function(input)

    if not dragging then return end

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

UserInputService.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

print("🍉 SolRNG ESP Watermelon V2 loaded!")
