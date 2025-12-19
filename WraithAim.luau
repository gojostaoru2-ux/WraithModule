--[[
    WRAITH | AIM ENGINE
    Version: 1.0
]]

local WraithAim = {}

WraithAim.Settings = {
    Enabled = false,
    TeamCheck = false,
    Smoothing = 0,         -- 0 = Instant, 1 = Very Slow
    TargetPart = "Head",   -- Head, HumanoidRootPart, etc.
    Method = "Cursor",     -- "Cursor", "Distance"
    FOV = 100,             -- Radius
    ShowFOV = false,
    FOVColor = Color3.fromRGB(255, 255, 255)
}

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Camera = workspace.CurrentCamera,
    UserInputService = game:GetService("UserInputService")
}
local LocalPlayer = Services.Players.LocalPlayer
local Connection = nil
local FOVCircle = Drawing.new("Circle")

-- // HELPER: Get Closest Player
local function GetTarget()
    local BestTarget = nil
    local BestDist = math.huge
    local MousePos = Services.UserInputService:GetMouseLocation()
    
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if WraithAim.Settings.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            
            local Char = Player.Character
            local Part = Char and Char:FindFirstChild(WraithAim.Settings.TargetPart)
            local Hum = Char and Char:FindFirstChild("Humanoid")
            
            if Part and Hum and Hum.Health > 0 then
                local ScreenPos, OnScreen = Services.Camera:WorldToViewportPoint(Part.Position)
                
                if OnScreen then
                    local Dist = 0
                    if WraithAim.Settings.Method == "Cursor" then
                        Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    else -- Distance (3D)
                        Dist = (LocalPlayer.Character.HumanoidRootPart.Position - Part.Position).Magnitude
                    end
                    
                    -- Check FOV (Only for Cursor method mostly, but applies to all for safety)
                    if WraithAim.Settings.Method == "Cursor" and Dist > WraithAim.Settings.FOV then continue end

                    if Dist < BestDist then
                        BestDist = Dist
                        BestTarget = Part
                    end
                end
            end
        end
    end
    return BestTarget
end

-- // RENDER LOOP
local function Update()
    -- Update FOV Circle
    FOVCircle.Visible = (WraithAim.Settings.ShowFOV and WraithAim.Settings.Enabled)
    FOVCircle.Radius = WraithAim.Settings.FOV
    FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    FOVCircle.Color = WraithAim.Settings.FOVColor
    FOVCircle.Transparency = 1
    FOVCircle.Thickness = 1

    if not WraithAim.Settings.Enabled then return end
    if not Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end -- Right Click to Aim

    local Target = GetTarget()
    if Target then
        local CurrentCFrame = Services.Camera.CFrame
        local TargetCFrame = CFrame.new(Services.Camera.CFrame.Position, Target.Position)
        
        if WraithAim.Settings.Smoothing > 0 then
            -- Smooth Aim
            Services.Camera.CFrame = CurrentCFrame:Lerp(TargetCFrame, (1 - WraithAim.Settings.Smoothing))
        else
            -- Snap Aim
            Services.Camera.CFrame = TargetCFrame
        end
    end
end

function WraithAim:Load()
    Connection = Services.RunService.RenderStepped:Connect(Update)
end

function WraithAim:Unload()
    if Connection then Connection:Disconnect() end
    FOVCircle:Remove()
end

return WraithAim
