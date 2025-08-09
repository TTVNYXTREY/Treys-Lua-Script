-- ROBLOX ESP Script: GhostWare Full Version

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')
local UserInputService = game:GetService('UserInputService')
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Load TokyoLib UI
local library = loadstring(
    game:HttpGet(
        'https://raw.githubusercontent.com/drillygzzly/Roblox-UI-Libs/main/1%20Tokyo%20Lib%20(FIXED)/Tokyo%20Lib%20Source.lua'
    )
)({
    cheatname = 'GhostWare',
    gamename = 'GhostWare',
})
library:init()

local Window = library.NewWindow({
    title = 'GhostWare',
    size = UDim2.new(0, 550, 0, 400),
})

local VisualsTab = Window:AddTab('Visuals')
local CombatTab = Window:AddTab('Combat')
local MiscTab = Window:AddTab('Misc')
local SettingsTab = library:CreateSettingsTab(Window)

-- Sections
local ESPSection = VisualsTab:AddSection('ESP Settings')
local CombatSection = CombatTab:AddSection('Combat Features')
local MiscSection = MiscTab:AddSection('Misc Features')
local SettingsSection = SettingsTab:AddSection('Settings')

-- State variables
local espEnabled = false
local distanceEnabled = false
local nameEnabled = false
local healthBarEnabled = false
local skeletonEnabled = false
local chamsEnabled = false
local teamCheckEnabled = false

local espBoxColor = Color3.fromRGB(255, 0, 0)
local distanceColor = Color3.fromRGB(255, 255, 255)
local nameColor = Color3.fromRGB(255, 255, 255)
local skeletonColor = Color3.fromRGB(0, 255, 255)
local chamsFillColor = Color3.fromRGB(0, 255, 0)
local chamsOutlineColor = Color3.fromRGB(255, 255, 255)

local silentAimEnabled = false
local silentAimBone = 'Head'

-- Fly variables
local flyEnabled = false
local flySpeed = 50
local bodyVelocity

-- Drawing helpers
local function createBox()
    local b = Drawing.new('Square')
    b.Visible = false
    b.Thickness = 1
    b.Filled = false
    b.Transparency = 1
    b.ZIndex = 2
    b.Color = espBoxColor
    return b
end

local function createText(size, z)
    local t = Drawing.new('Text')
    t.Visible = false
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.new(0, 0, 0)
    t.Font = 1
    t.Size = size
    t.ZIndex = z
    return t
end

local function createLine()
    local l = Drawing.new('Line')
    l.Visible = false
    l.Thickness = 1.5
    l.ZIndex = 2
    return l
end

-- Tables to store ESP objects
local espBoxes = {}
local distanceTexts = {}
local nameTexts = {}
local healthBars = {}
local skeletons = {}
local highlights = {}

-- Utility functions
local function getBoundingBox(character)
    local points = {}
    for _, part in pairs(character:GetChildren()) do
        if part:IsA('BasePart') and part.Transparency < 1 then
            local cf = part.CFrame
            local size = part.Size / 2
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        local point = cf
                            * Vector3.new(size.X * x, size.Y * y, size.Z * z)
                        local screenPos, onScreen = Camera:WorldToViewportPoint(
                            point
                        )
                        if onScreen then
                            table.insert(
                                points,
                                Vector2.new(screenPos.X, screenPos.Y)
                            )
                        end
                    end
                end
            end
        end
    end

    if #points < 2 then
        return nil
    end

    local minX, maxX = points[1].X, points[1].X
    local minY, maxY = points[1].Y, points[1].Y
    for _, p in pairs(points) do
        minX = math.min(minX, p.X)
        maxX = math.max(maxX, p.X)
        minY = math.min(minY, p.Y)
        maxY = math.max(maxY, p.Y)
    end

    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local function isEnemy(player)
    if not teamCheckEnabled then
        return true
    end
    local lpTeam = LocalPlayer.Team
    local targetTeam = player.Team
    return (lpTeam ~= targetTeam) or (lpTeam == nil)
end

local function updateHighlight(player)
    if not chamsEnabled then
        if highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end
        return
    end

    if not highlights[player] then
        local highlight = Instance.new('Highlight')
        highlight.Adornee = player.Character
        highlight.FillColor = chamsFillColor
        highlight.OutlineColor = chamsOutlineColor
        highlight.FillTransparency = 0.3
        highlight.OutlineTransparency = 0
        highlight.Parent = Workspace
        highlights[player] = highlight
    else
        highlights[player].FillColor = chamsFillColor
        highlights[player].OutlineColor = chamsOutlineColor
        highlights[player].Adornee = player.Character
    end
end

-- UI elements
ESPSection:AddToggle({
    text = 'Enable ESP',
    flag = 'esp_toggle',
    state = espEnabled,
    callback = function(v)
        espEnabled = v
    end,
})

ESPSection:AddColor({
    text = 'ESP Box Color',
    color = espBoxColor,
    flag = 'esp_box_color',
    callback = function(c)
        espBoxColor = c
    end,
})

ESPSection:AddToggle({
    text = 'Show Distance',
    flag = 'distance_toggle',
    state = distanceEnabled,
    callback = function(v)
        distanceEnabled = v
    end,
})

ESPSection:AddColor({
    text = 'Distance Color',
    color = distanceColor,
    flag = 'distance_color',
    callback = function(c)
        distanceColor = c
    end,
})

ESPSection:AddToggle({
    text = 'Show Names',
    flag = 'name_toggle',
    state = nameEnabled,
    callback = function(v)
        nameEnabled = v
    end,
})

ESPSection:AddColor({
    text = 'Name Color',
    color = nameColor,
    flag = 'name_color',
    callback = function(c)
        nameColor = c
    end,
})

ESPSection:AddToggle({
    text = 'Show Health Bars',
    flag = 'health_toggle',
    state = healthBarEnabled,
    callback = function(v)
        healthBarEnabled = v
    end,
})

ESPSection:AddToggle({
    text = 'Show Skeleton',
    flag = 'skeleton_toggle',
    state = skeletonEnabled,
    callback = function(v)
        skeletonEnabled = v
    end,
})

ESPSection:AddColor({
    text = 'Skeleton Color',
    color = skeletonColor,
    flag = 'skeleton_color',
    callback = function(c)
        skeletonColor = c
    end,
})

ESPSection:AddToggle({
    text = 'Enable Chams',
    flag = 'chams_toggle',
    state = chamsEnabled,
    callback = function(v)
        chamsEnabled = v
    end,
})

ESPSection:AddColor({
    text = 'Cham Fill Color',
    color = chamsFillColor,
    flag = 'chams_fill',
    callback = function(c)
        chamsFillColor = c
    end,
})

ESPSection:AddColor({
    text = 'Cham Outline Color',
    color = chamsOutlineColor,
    flag = 'chams_outline',
    callback = function(c)
        chamsOutlineColor = c
    end,
})

ESPSection:AddToggle({
    text = 'Team Check (ESP)',
    flag = 'team_check_toggle',
    state = teamCheckEnabled,
    callback = function(v)
        teamCheckEnabled = v
    end,
})

-- Combat Tab (silent aim placeholder)
CombatSection:AddToggle({
    text = 'Silent Aim',
    flag = 'silent_aim_toggle',
    state = silentAimEnabled,
    callback = function(v)
        silentAimEnabled = v
    end,
})

CombatSection:AddList({
    text = 'Silent Aim Bone',
    flag = 'silent_aim_bone',
    values = { 'Head', 'UpperTorso', 'LowerTorso' },
    selected = silentAimBone,
    callback = function(v)
        silentAimBone = v
    end,
})

-- Misc Tab Fly toggle and speed slider
MiscSection:AddToggle({
    text = 'Fly',
    flag = 'fly_toggle',
    state = flyEnabled,
    callback = function(v)
        flyEnabled = v
        if
            not flyEnabled
            and LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild('Humanoid')
        then
            LocalPlayer.Character.Humanoid.PlatformStand = false
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
        end
    end,
})

MiscSection:AddSlider({
    text = 'Fly Speed',
    flag = 'fly_speed',
    min = 1,
    max = 1000,
    increment = 1,
    value = flySpeed,
    callback = function(v)
        flySpeed = v
    end,
})

-- Main loop for ESP and Fly
RunService.RenderStepped:Connect(function()
    if flyEnabled then
        local character = LocalPlayer.Character
        if
            character
            and character:FindFirstChild('HumanoidRootPart')
            and character:FindFirstChild('Humanoid')
        then
            local hrp = character.HumanoidRootPart
            local humanoid = character.Humanoid
            humanoid.PlatformStand = true

            if not bodyVelocity or not bodyVelocity.Parent then
                bodyVelocity = Instance.new('BodyVelocity')
                bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Parent = hrp
            end

            local moveVec = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveVec = moveVec + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVec = moveVec - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveVec = moveVec - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVec = moveVec + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVec = moveVec + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                moveVec = moveVec - Vector3.new(0, 1, 0)
            end

            if moveVec.Magnitude > 0 then
                moveVec = moveVec.Unit * flySpeed
            end

            bodyVelocity.Velocity = moveVec
        else
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
            if
                LocalPlayer.Character
                and LocalPlayer.Character:FindFirstChild('Humanoid')
            then
                LocalPlayer.Character.Humanoid.PlatformStand = false
            end
        end
    else
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        if
            LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild('Humanoid')
        then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end

    if not espEnabled then
        for _, tab in pairs({ espBoxes, distanceTexts, nameTexts, healthBars, skeletons }) do
            for _, obj in pairs(tab) do
                obj.Visible = false
            end
        end
        -- Remove highlights if ESP disabled
        for plr, highlight in pairs(highlights) do
            highlight:Destroy()
            highlights[plr] = nil
        end
        return
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if
            plr ~= LocalPlayer
            and plr.Character
            and plr.Character:FindFirstChild('HumanoidRootPart')
            and isEnemy(plr)
        then
            local pos, size = getBoundingBox(plr.Character)
            if pos and size then
                -- Box
                espBoxes[plr] = espBoxes[plr] or createBox()
                local box = espBoxes[plr]
                box.Visible = true
                box.Position = pos
                box.Size = Vector2.new(size.X * 0.85, size.Y)
                box.Color = espBoxColor

                -- Distance
                if distanceEnabled then
                    distanceTexts[plr] = distanceTexts[plr] or createText(12, 3)
                    local dist = (
                        LocalPlayer.Character.HumanoidRootPart.Position
                        - plr.Character.HumanoidRootPart.Position
                    ).Magnitude
                    local text = distanceTexts[plr]
                    text.Visible = true
                    text.Text = string.format('%.0f ft', dist * 3.28084)
                    text.Position = Vector2.new(
                        pos.X + (size.X * 0.425),
                        pos.Y + size.Y + 2
                    )
                    text.Color = distanceColor
                elseif distanceTexts[plr] then
                    distanceTexts[plr].Visible = false
                end

                -- Names
                if nameEnabled then
                    nameTexts[plr] = nameTexts[plr] or createText(12, 3)
                    local text = nameTexts[plr]
                    text.Visible = true
                    text.Text = plr.DisplayName
                    text.Position = Vector2.new(
                        pos.X + (size.X * 0.425),
                        pos.Y - 14
                    )
                    text.Color = nameColor
                elseif nameTexts[plr] then
                    nameTexts[plr].Visible = false
                end

                -- Health Bars
                if healthBarEnabled then
                    healthBars[plr] = healthBars[plr] or createBox()
                    local bar = healthBars[plr]
                    local hum = plr.Character:FindFirstChild('Humanoid')
                    local hp = hum and hum.Health or 0
                    local maxhp = hum and hum.MaxHealth or 100
                    local percent = math.clamp(hp / maxhp, 0, 1)
                    bar.Visible = true
                    bar.Filled = true
                    bar.Color = Color3.fromRGB(
                        255 - percent * 255,
                        percent * 255,
                        0
                    )
                    bar.Size = Vector2.new(3, size.Y * percent)
                    bar.Position = Vector2.new(
                        pos.X - 5,
                        pos.Y + size.Y * (1 - percent)
                    )
                elseif healthBars[plr] then
                    healthBars[plr].Visible = false
                end

                -- Skeleton
                if skeletonEnabled then
                    if not skeletons[plr] then
                        skeletons[plr] = {}
                    end
                    local bones = {
                        { 'Head', 'UpperTorso' },
                        { 'UpperTorso', 'LowerTorso' },
                        { 'UpperTorso', 'LeftUpperArm' },
                        { 'LeftUpperArm', 'LeftLowerArm' },
                        { 'LeftLowerArm', 'LeftHand' },
                        { 'UpperTorso', 'RightUpperArm' },
                        { 'RightUpperArm', 'RightLowerArm' },
                        { 'RightLowerArm', 'RightHand' },
                        { 'LowerTorso', 'LeftUpperLeg' },
                        { 'LeftUpperLeg', 'LeftLowerLeg' },
                        { 'LeftLowerLeg', 'LeftFoot' },
                        { 'LowerTorso', 'RightUpperLeg' },
                        { 'RightUpperLeg', 'RightLowerLeg' },
                        { 'RightLowerLeg', 'RightFoot' },
                    }
                    for i, bone in ipairs(bones) do
                        local a = plr.Character:FindFirstChild(bone[1])
                        local b = plr.Character:FindFirstChild(bone[2])
                        if a and b then
                            skeletons[plr][i] = skeletons[plr][i]
                                or createLine()
                            local line = skeletons[plr][i]
                            local aPos, aOnScreen = Camera:WorldToViewportPoint(
                                a.Position
                            )
                            local bPos, bOnScreen = Camera:WorldToViewportPoint(
                                b.Position
                            )
                            if aOnScreen and bOnScreen then
                                line.Visible = true
                                line.From = Vector2.new(aPos.X, aPos.Y)
                                line.To = Vector2.new(bPos.X, bPos.Y)
                                line.Color = skeletonColor
                            else
                                line.Visible = false
                            end
                        elseif skeletons[plr][i] then
                            skeletons[plr][i].Visible = false
                        end
                    end
                else
                    if skeletons[plr] then
                        for _, line in pairs(skeletons[plr]) do
                            line.Visible = false
                        end
                    end
                end

                -- Chams
                updateHighlight(plr)
            else
                -- Hide ESP if no bounding box
                if espBoxes[plr] then
                    espBoxes[plr].Visible = false
                end
                if distanceTexts[plr] then
                    distanceTexts[plr].Visible = false
                end
                if nameTexts[plr] then
                    nameTexts[plr].Visible = false
                end
                if healthBars[plr] then
                    healthBars[plr].Visible = false
                end
                if skeletons[plr] then
                    for _, line in pairs(skeletons[plr]) do
                        line.Visible = false
                    end
                end
                if highlights[plr] then
                    highlights[plr]:Destroy()
                    highlights[plr] = nil
                end
            end
        else
            -- Hide ESP for player if not valid
            if espBoxes[plr] then
                espBoxes[plr].Visible = false
            end
            if distanceTexts[plr] then
                distanceTexts[plr].Visible = false
            end
            if nameTexts[plr] then
                nameTexts[plr].Visible = false
            end
            if healthBars[plr] then
                healthBars[plr].Visible = false
            end
            if skeletons[plr] then
                for _, line in pairs(skeletons[plr]) do
                    line.Visible = false
                end
            end
            if highlights[plr] then
                highlights[plr]:Destroy()
                highlights[plr] = nil
            end
        end
    end
end)
