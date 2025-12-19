--[[
    WRAITH | ENGINE MODULE
    Version: 1.0.0
    Description: High-performance Drawing API wrapper
]]

local Wraith = {}

--// 1. EXPORTED SETTINGS (The UI modifies these)
Wraith.Settings = {
    Enabled = true,
    Box = true,
    CornerBox = false,
    Color = Color3.fromRGB(0, 255, 120),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    Thickness = 1,
    TeamCheck = false
}

--// 2. INTERNAL SERVICES
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Camera = workspace.CurrentCamera
}
local LocalPlayer = Services.Players.LocalPlayer
local Cache = {}
local Connections = {} -- To store connections for cleanup

--// 3. DRAWING API
local function CreateDrawing(Type, Props)
    local Obj = Drawing.new(Type)
    for K, V in pairs(Props) do Obj[K] = V end
    return Obj
end

local function AddEsp(Player)
    if Cache[Player] then return end
    
    local Objects = {
        -- Standard Box
        BoxOutline = CreateDrawing("Square", { Transparency = 1, Thickness = 3, Filled = false, ZIndex = 1 }),
        Box = CreateDrawing("Square", { Transparency = 1, Thickness = 1, Filled = false, ZIndex = 2 }),
    }

    -- Corner Box Lines (8 Outline, 8 Main)
    for i = 1, 8 do
        Objects["CornerOutline"..i] = CreateDrawing("Line", { Transparency = 1, Thickness = 3, ZIndex = 1, Visible = false })
        Objects["Corner"..i] = CreateDrawing("Line", { Transparency = 1, Thickness = 1, ZIndex = 2, Visible = false })
    end
    
    Cache[Player] = Objects
end

local function RemoveEsp(Player)
    if Cache[Player] then
        for _, Obj in pairs(Cache[Player]) do Obj:Remove() end
        Cache[Player] = nil
    end
end

--// 4. RENDER LOOP
local function Update()
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if not Cache[Player] then AddEsp(Player) end
            
            local Objects = Cache[Player]
            local Char = Player.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char and Char:FindFirstChild("Humanoid")
            
            local S = Wraith.Settings -- Shorthand
            local IsTeammate = (S.TeamCheck and Player.Team == LocalPlayer.Team)
            local IsAlive = (Char and Root and Hum and Hum.Health > 0)
            local ShouldDraw = (S.Enabled and IsAlive and not IsTeammate)
            
            if ShouldDraw then
                local RootPos, OnScreen = Services.Camera:WorldToViewportPoint(Root.Position)
                
                if OnScreen then
                    -- Math
                    local HeadPos = Services.Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 2, 0))
                    local LegPos = Services.Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                    local Height = math.abs(HeadPos.Y - LegPos.Y)
                    local Width = Height * 0.55 
                    local Size = Vector2.new(math.floor(Width), math.floor(Height))
                    local Position = Vector2.new(math.floor(RootPos.X - Width / 2), math.floor(HeadPos.Y))
                    
                    if S.Box then
                        -- Disable Corners
                        for i = 1, 8 do Objects["Corner"..i].Visible = false; Objects["CornerOutline"..i].Visible = false end
                        
                        -- Enable Box
                        Objects.BoxOutline.Visible = true
                        Objects.BoxOutline.Size = Size
                        Objects.BoxOutline.Position = Position
                        Objects.BoxOutline.Color = S.OutlineColor
                        
                        Objects.Box.Visible = true
                        Objects.Box.Size = Size
                        Objects.Box.Position = Position
                        Objects.Box.Color = S.Color
                        Objects.Box.Thickness = S.Thickness

                    elseif S.CornerBox then
                        -- Disable Box
                        Objects.Box.Visible = false
                        Objects.BoxOutline.Visible = false

                        -- Enable Corners
                        local LineLen = math.ceil(Size.X / 3)
                        local X, Y, W, H = Position.X, Position.Y, Size.X, Size.Y
                        local Points = {
                            {X, Y, X + LineLen, Y}, {X, Y, X, Y + LineLen}, -- TL
                            {X + W, Y, X + W - LineLen, Y}, {X + W, Y, X + W, Y + LineLen}, -- TR
                            {X, Y + H, X + LineLen, Y + H}, {X, Y + H, X, Y + H - LineLen}, -- BL
                            {X + W, Y + H, X + W - LineLen, Y + H}, {X + W, Y + H, X + W, Y + H - LineLen} -- BR
                        }

                        for i = 1, 8 do
                            local P = Points[i]
                            local Outline = Objects["CornerOutline"..i]
                            local Main = Objects["Corner"..i]
                            
                            Outline.Visible = true; Outline.From = Vector2.new(P[1], P[2]); Outline.To = Vector2.new(P[3], P[4]); Outline.Color = S.OutlineColor
                            Main.Visible = true; Main.From = Vector2.new(P[1], P[2]); Main.To = Vector2.new(P[3], P[4]); Main.Color = S.Color; Main.Thickness = S.Thickness
                        end
                    else
                        -- Both Off
                        Objects.Box.Visible = false; Objects.BoxOutline.Visible = false
                        for i = 1, 8 do Objects["Corner"..i].Visible = false; Objects["CornerOutline"..i].Visible = false end
                    end
                else
                    -- Offscreen
                    Objects.Box.Visible = false; Objects.BoxOutline.Visible = false
                    for i = 1, 8 do Objects["Corner"..i].Visible = false; Objects["CornerOutline"..i].Visible = false end
                end
            else
                -- Invalid Target
                if Objects.Box then Objects.Box.Visible = false; Objects.BoxOutline.Visible = false end
                for i = 1, 8 do if Objects["Corner"..i] then Objects["Corner"..i].Visible = false; Objects["CornerOutline"..i].Visible = false end end
            end
        end
    end
end

--// 5. INITIALIZATION
function Wraith:Load()
    Connections.Render = Services.RunService.RenderStepped:Connect(Update)
    Connections.PlayerRemoving = Services.Players.PlayerRemoving:Connect(RemoveEsp)
    print("Wraith Engine Loaded")
end

function Wraith:Unload()
    if Connections.Render then Connections.Render:Disconnect() end
    if Connections.PlayerRemoving then Connections.PlayerRemoving:Disconnect() end
    for _, CacheItem in pairs(Cache) do
        for _, Obj in pairs(CacheItem) do Obj:Remove() end
    end
    table.clear(Cache)
    print("Wraith Engine Unloaded")
end

return Wraith
