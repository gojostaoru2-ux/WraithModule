--[[
    WRAITH | VISUAL ENGINE
    Version: 3.0 (Skeleton Remastered)
]]

local Wraith = {}

Wraith.Settings = {
    Enabled = true,
    Box = true,
    CornerBox = false,
    Skeleton = false,
    Tracer = false,
    
    BoxColor = Color3.fromRGB(0, 255, 120),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(0, 255, 120),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    
    Thickness = 1,
    TracerOrigin = "Bottom", 
    TeamCheck = false
}

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    Camera = workspace.CurrentCamera,
    UserInputService = game:GetService("UserInputService")
}
local LocalPlayer = Services.Players.LocalPlayer
local Cache = {}
local Connections = {}

local function CreateDrawing(Type, Props)
    local Obj = Drawing.new(Type)
    for K, V in pairs(Props) do Obj[K] = V end
    return Obj
end

-- // CLEANER SKELETON MAPS
local R15_Map = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}
}

local R6_Map = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

local function AddEsp(Player)
    if Cache[Player] then return end
    local Objects = {
        BoxOutline = CreateDrawing("Square", {Transparency=1, Thickness=3, Filled=false, ZIndex=1}),
        Box = CreateDrawing("Square", {Transparency=1, Thickness=1, Filled=false, ZIndex=2}),
        TracerOutline = CreateDrawing("Line", {Transparency=1, Thickness=3, ZIndex=1}),
        Tracer = CreateDrawing("Line", {Transparency=1, Thickness=1, ZIndex=2}),
        Skeleton = {}
    }
    for i = 1, 8 do
        Objects["CornerOutline"..i] = CreateDrawing("Line", {Transparency=1, Thickness=3, ZIndex=1, Visible=false})
        Objects["Corner"..i] = CreateDrawing("Line", {Transparency=1, Thickness=1, ZIndex=2, Visible=false})
    end
    -- Pre-create 16 bones
    for i = 1, 16 do
        table.insert(Objects.Skeleton, CreateDrawing("Line", {Transparency=1, Thickness=1, ZIndex=2, Visible=false}))
    end
    Cache[Player] = Objects
end

local function RemoveEsp(Player)
    if Cache[Player] then
        local Objs = Cache[Player]
        Objs.Box:Remove(); Objs.BoxOutline:Remove()
        Objs.Tracer:Remove(); Objs.TracerOutline:Remove()
        for i=1,8 do Objs["Corner"..i]:Remove(); Objs["CornerOutline"..i]:Remove() end
        for _, L in ipairs(Objs.Skeleton) do L:Remove() end
        Cache[Player] = nil
    end
end

local function Update()
    for _, Player in ipairs(Services.Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if not Cache[Player] then AddEsp(Player) end
            
            local Objects = Cache[Player]
            local Char = Player.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char and Char:FindFirstChild("Humanoid")
            local S = Wraith.Settings
            
            local IsTeammate = (S.TeamCheck and Player.Team == LocalPlayer.Team)
            local IsAlive = (Char and Root and Hum and Hum.Health > 0)
            local ShouldDraw = (S.Enabled and IsAlive and not IsTeammate)
            
            -- Hide Everything Frame Start
            Objects.Box.Visible = false; Objects.BoxOutline.Visible = false
            Objects.Tracer.Visible = false; Objects.TracerOutline.Visible = false
            for i=1,8 do Objects["Corner"..i].Visible = false; Objects["CornerOutline"..i].Visible = false end
            for _, L in ipairs(Objects.Skeleton) do L.Visible = false end

            if ShouldDraw then
                local RootPos, OnScreen = Services.Camera:WorldToViewportPoint(Root.Position)
                
                -- Optimization: Only calculate ESP geometry if root is somewhat visible
                if OnScreen then
                    -- Box Math
                    local HeadPos = Services.Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, 2, 0))
                    local LegPos = Services.Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))
                    local Height = math.abs(HeadPos.Y - LegPos.Y)
                    local Width = Height * 0.55
                    local Size = Vector2.new(math.floor(Width), math.floor(Height))
                    local Position = Vector2.new(math.floor(RootPos.X - Width / 2), math.floor(HeadPos.Y))
                    
                    -- [BOX]
                    if S.Box then
                        Objects.BoxOutline.Visible = true; Objects.BoxOutline.Size = Size; Objects.BoxOutline.Position = Position; Objects.BoxOutline.Color = S.OutlineColor
                        Objects.Box.Visible = true; Objects.Box.Size = Size; Objects.Box.Position = Position; Objects.Box.Color = S.BoxColor; Objects.Box.Thickness = S.Thickness
                    elseif S.CornerBox then
                        local LineLen = math.ceil(Size.X / 3)
                        local X, Y, W, H = Position.X, Position.Y, Size.X, Size.Y
                        local Points = {{X,Y,X+LineLen,Y},{X,Y,X,Y+LineLen},{X+W,Y,X+W-LineLen,Y},{X+W,Y,X+W,Y+LineLen},{X,Y+H,X+LineLen,Y+H},{X,Y+H,X,Y+H-LineLen},{X+W,Y+H,X+W-LineLen,Y+H},{X+W,Y+H,X+W,Y+H-LineLen}}
                        for i = 1, 8 do
                            local P = Points[i]
                            Objects["CornerOutline"..i].Visible = true; Objects["CornerOutline"..i].From = Vector2.new(P[1], P[2]); Objects["CornerOutline"..i].To = Vector2.new(P[3], P[4]); Objects["CornerOutline"..i].Color = S.OutlineColor
                            Objects["Corner"..i].Visible = true; Objects["Corner"..i].From = Vector2.new(P[1], P[2]); Objects["Corner"..i].To = Vector2.new(P[3], P[4]); Objects["Corner"..i].Color = S.BoxColor; Objects["Corner"..i].Thickness = S.Thickness
                        end
                    end

                    -- [TRACER]
                    if S.Tracer then
                        local Origin
                        if S.TracerOrigin == "Top" then Origin = Vector2.new(Services.Camera.ViewportSize.X/2, 0)
                        elseif S.TracerOrigin == "Mouse" then Origin = Services.UserInputService:GetMouseLocation()
                        else Origin = Vector2.new(Services.Camera.ViewportSize.X/2, Services.Camera.ViewportSize.Y) end
                        
                        local To = Vector2.new(RootPos.X, RootPos.Y)
                        if S.Box or S.CornerBox then To = Vector2.new(RootPos.X, Position.Y + Size.Y) end

                        Objects.TracerOutline.Visible = true; Objects.TracerOutline.From = Origin; Objects.TracerOutline.To = To; Objects.TracerOutline.Color = S.OutlineColor
                        Objects.Tracer.Visible = true; Objects.Tracer.From = Origin; Objects.Tracer.To = To; Objects.Tracer.Color = S.TracerColor; Objects.Tracer.Thickness = S.Thickness
                    end
                end

                -- [SKELETON]
                -- We run this partially outside the root check to allow limbs to be seen even if torso is barely offscreen
                if S.Skeleton then
                    local Map = (Hum.RigType == Enum.HumanoidRigType.R15) and R15_Map or R6_Map
                    
                    for Index, Pair in ipairs(Map) do
                        local P1 = Char:FindFirstChild(Pair[1])
                        local P2 = Char:FindFirstChild(Pair[2])
                        
                        if P1 and P2 then
                            local V1, O1 = Services.Camera:WorldToViewportPoint(P1.Position)
                            local V2, O2 = Services.Camera:WorldToViewportPoint(P2.Position)
                            
                            -- CRITICAL FIX: Both joints must be visible to draw the bone
                            -- This prevents lines stretching across the screen when one joint is behind camera
                            if O1 and O2 then
                                local Bone = Objects.Skeleton[Index]
                                if Bone then
                                    Bone.Visible = true
                                    Bone.From = Vector2.new(V1.X, V1.Y)
                                    Bone.To = Vector2.new(V2.X, V2.Y)
                                    Bone.Color = S.SkeletonColor
                                    Bone.Thickness = S.Thickness
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function Wraith:Load()
    Connections.Render = Services.RunService.RenderStepped:Connect(Update)
    Connections.PlayerRemoving = Services.Players.PlayerRemoving:Connect(RemoveEsp)
end

function Wraith:Unload()
    if Connections.Render then Connections.Render:Disconnect() end
    if Connections.PlayerRemoving then Connections.PlayerRemoving:Disconnect() end
    for _, CacheItem in pairs(Cache) do
        if CacheItem.Box then CacheItem.Box:Remove() CacheItem.BoxOutline:Remove() end
        if CacheItem.Tracer then CacheItem.Tracer:Remove() CacheItem.TracerOutline:Remove() end
        for i=1,8 do if CacheItem["Corner"..i] then CacheItem["Corner"..i]:Remove() end end
        for _, L in ipairs(CacheItem.Skeleton) do L:Remove() end
    end
    table.clear(Cache)
end

return Wraith
