--[[
    WRAITH | AIM ENGINE
    Version: 2.5 (Type Safe)
]]

local WraithAim = {}

WraithAim.Settings = {
    Enabled = false,
    TeamCheck = false,
    Smoothing = 0,
    TargetPart = "Head",
    Method = "Cursor", 
    FOV = 100,
    ShowFOV = false,
    FOVColor = Color3.fromRGB(255, 255, 255),
    TriggerKey = Enum.UserInputType.MouseButton2
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

-- // HELPER: Fixes Rayfield returning tables {"Head"} instead of "Head"
local function Sanitize(Val)
    if type(Val) == "table" then return Val[1] end
    return Val
end

local function GetTarget()
    local BestTarget = nil
    local BestDist = math.huge
    local MousePos = Services.UserInputService:GetMouseLocation()
    
    -- Sanitize Settings on the fly
    local TgtPartName = Sanitize(WraithAim.Settings.TargetPart)
    local MethodName = Sanitize(WraithAim.Settings.Method)
    
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if WraithAim.Settings.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            
            local Char = Player.Character
            local Part = Char and Char:FindFirstChild(TgtPartName)
            local Hum = Char and Char:FindFirstChild("Humanoid")
            
            if Part and Hum and Hum.Health > 0 then
                local ScreenPos, OnScreen = Services.Camera:WorldToViewportPoint(Part.Position)
                
                if OnScreen then
                    local Dist
                    if MethodName == "Cursor" then
                        Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    else
                        Dist = (LocalPlayer.Character.HumanoidRootPart.Position - Part.Position).Magnitude
                    end
                    
                    if MethodName == "Cursor" and Dist > WraithAim.Settings.FOV then continue end

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

local function IsKeyDown()
    local Key = WraithAim.Settings.TriggerKey
    if typeof(Key) == "EnumItem" then
        if Key.EnumType == Enum.KeyCode then
            return Services.UserInputService:IsKeyDown(Key)
        elseif Key.EnumType == Enum.UserInputType then
            return Services.UserInputService:IsMouseButtonPressed(Key)
        end
    end
    return false
end

local function Update()
    FOVCircle.Visible = (WraithAim.Settings.ShowFOV and WraithAim.Settings.Enabled)
    FOVCircle.Radius = WraithAim.Settings.FOV
    FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    FOVCircle.Color = WraithAim.Settings.FOVColor
    FOVCircle.Transparency = 1
    FOVCircle.Thickness = 1

    if not WraithAim.Settings.Enabled then return end
    
    if IsKeyDown() then
        local Target = GetTarget()
        if Target then
            if Target.Parent and Target.Parent:FindFirstChild("Humanoid") and Target.Parent.Humanoid.Health > 0 then
                local CurrentCFrame = Services.Camera.CFrame
                local TargetCFrame = CFrame.new(Services.Camera.CFrame.Position, Target.Position)
                
                if WraithAim.Settings.Smoothing > 0 then
                    Services.Camera.CFrame = CurrentCFrame:Lerp(TargetCFrame, (1 - WraithAim.Settings.Smoothing))
                else
                    Services.Camera.CFrame = TargetCFrame
                end
            end
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
