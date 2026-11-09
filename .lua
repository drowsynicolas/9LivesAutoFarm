repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Terrain = workspace.Terrain

local function blankName(length)
    return string.rep("\u{200B}", length or 20)
end
local guiName = blankName(20)
if CoreGui:FindFirstChild(guiName) then return end

do
    local old = workspace:FindFirstChild("antiFreeFall")
    if old then old:Destroy() end
    local part = Instance.new("Part")
    part.Name = "antiFreeFall"
    part.Size = Vector3.new(6, 1, 6)
    part.Position = Vector3.new(0, 995.85, 0)
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0.2
    part.Material = Enum.Material.Plastic
    part.Color = Color3.fromRGB(0, 0, 0)
    part.Parent = workspace
end

local BASE_DIR = "9lives_autofarm"
local SFX_DIR = BASE_DIR .. "/9lives_sfx"
local CONFIGS_DIR = BASE_DIR .. "/9lives_configs"
local STATE_DIR = BASE_DIR .. "/9lives_state"
local IMG_PATH = BASE_DIR .. "/img.png"
local CONFIGS_PATH = CONFIGS_DIR .. "/configs.json"
local STATE_PATH = STATE_DIR .. "/state.json"
local LEGACY_CONFIG_PATH = "haunteddnicolas_9lives_autofarm_config.json"

pcall(function()
    if not isfolder(BASE_DIR) then makefolder(BASE_DIR) end
    if not isfolder(SFX_DIR) then makefolder(SFX_DIR) end
    if not isfolder(CONFIGS_DIR) then makefolder(CONFIGS_DIR) end
    if not isfolder(STATE_DIR) then makefolder(STATE_DIR) end
end)

local config = {
    collapsed = false, farmEnabled = false, coinAura = false,
    avoidMurderer = false, safeMethod = false,
    speed = 20, delay = 0.5, coinAuraRadius = 5, avoidRadius = 30,
    safeTiltAngle = 90,
    optimizeGame = false, render3d = true, capFps = false, fpsValue = 240,
    antiAfk = false, antiFling = false, antiVoid = false,
    disableSfx = false, disableGuiAnimations = false,
    autoKillAll = false, autoShootMurd = false, autoHero = false,
    position = { XScale = 0.5, XOffset = 0, YScale = 0.5, YOffset = 0 }
}

local CONFIG_FIELDS = {
    "farmEnabled","coinAura","avoidMurderer","safeMethod","speed","delay",
    "coinAuraRadius","avoidRadius","safeTiltAngle","optimizeGame","render3d","capFps","fpsValue",
    "antiAfk","antiFling","antiVoid","disableSfx","disableGuiAnimations",
    "autoKillAll","autoShootMurd","autoHero",
}

local function saveConfigs()
    local data = {}
    for _, key in ipairs(CONFIG_FIELDS) do data[key] = config[key] end
    pcall(function() writefile(CONFIGS_PATH, HttpService:JSONEncode(data)) end)
end
local function saveState()
    pcall(function()
        writefile(STATE_PATH, HttpService:JSONEncode({collapsed = config.collapsed, position = config.position}))
    end)
end
local function loadConfig()
    local needMigrate = false
    if isfile and isfile(CONFIGS_PATH) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIGS_PATH)) end)
        if ok and data then
            for _, key in ipairs(CONFIG_FIELDS) do
                if data[key] ~= nil then config[key] = data[key] end
            end
        end
    elseif isfile and isfile(LEGACY_CONFIG_PATH) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(LEGACY_CONFIG_PATH)) end)
        if ok and data then
            for _, key in ipairs(CONFIG_FIELDS) do
                if data[key] ~= nil then config[key] = data[key] end
            end
            needMigrate = true
        end
    end
    if isfile and isfile(STATE_PATH) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(STATE_PATH)) end)
        if ok and data then
            config.collapsed = data.collapsed == true
            if data.position then config.position = data.position end
        end
    end
    if needMigrate then
        saveConfigs(); saveState()
        pcall(function() delfile(LEGACY_CONFIG_PATH) end)
    end
end
loadConfig()

local Connections = {}
local function track(conn) table.insert(Connections, conn) return conn end

local soundUrls = {
    meow1 = "https://raw.githubusercontent.com/drowsynicolas/9LivesGUIsfx/main/9lives%20catmeow1.mp3",
    meow2 = "https://raw.githubusercontent.com/drowsynicolas/9LivesGUIsfx/main/9lives%20catmeow2.mp3",
    meow3 = "https://raw.githubusercontent.com/drowsynicolas/9LivesGUIsfx/main/9lives%20catmeow3.mp3",
    meow4 = "https://raw.githubusercontent.com/drowsynicolas/9LivesGUIsfx/main/9lives%20catmeow4.mp3",
    meow5 = "https://raw.githubusercontent.com/drowsynicolas/9LivesGUIsfx/main/9lives%20catmeow5.mp3",
    hiss  = "https://raw.githubusercontent.com/drowsynicolas/9LivesGUIsfx/main/9lives%20cathiss.mp3",
    purr  = "https://raw.githubusercontent.com/drowsynicolas/9LivesGUIsfx/main/9lives%20catpurring.mp3",
    chirp = "https://raw.githubusercontent.com/drowsynicolas/9LivesGUIsfx/main/9lives%20catchirp.mp3",
}
local sounds = {}
local lastMeow = nil
local function stopAllScriptSounds()
    for _, child in ipairs(SoundService:GetChildren()) do
        if child:IsA("Sound") and child.Name:find("9lives_") then
            pcall(function() child:Stop() end)
        end
    end
end
local function playSfx(sound)
    if config.disableSfx or not sound then return end
    stopAllScriptSounds()
    pcall(function() sound.TimePosition = 0 sound:Play() end)
end
local function playMeow()
    local pool = {}
    for _, s in ipairs({sounds.meow1, sounds.meow2, sounds.meow3, sounds.meow4, sounds.meow5}) do
        if s and s ~= lastMeow then table.insert(pool, s) end
    end
    if #pool == 0 then return end
    local pick = pool[math.random(1, #pool)]
    lastMeow = pick
    playSfx(pick)
end
local function playHiss() playSfx(sounds.hiss) end
local function playPurr() playSfx(sounds.purr) end
local function playChirp() playSfx(sounds.chirp) end

local destroyed = false
local revealTweens = {}
local sectionHeaders = {}

local StuckTime = 0.5
local PreRoundPos = Vector3.new(0, 999, 0)
local FARM_DIRECTION = Vector3.new(0, 0, -1)
local RETARGET_MIN_DIST = 0
local MURDERER_AVOID_RADIUS_Y = 20
local SAFE_TILT = CFrame.Angles(-math.rad(config.safeTiltAngle), 0, 0)

local DefaultGravity = workspace.Gravity
local FarmPlatform = nil
local FarmLockPos = nil
local AlignConnection = nil
local BadCoins = {}
local PreRoundActive = false
local GravityApplied = false
local coinAreasStartTime = nil
local NeedsRetarget = false
local rolesCache = {}
local murdererPositions = {}
local barnStartTime = nil
local barnResetDone = false
local AnimKillConnection = nil
local coinAreasWasActive = false
local lastAvoidRetargetCheck = 0

local safeMethodActive = false
local safeMethodChar = nil
local safeCollisionsParts = {}

local totalEarned = 0
local sessionStart = config.farmEnabled and tick() or nil
local sessionStartEarned = 0

local function AddCoin(amount)
    amount = amount or 1
    local oldTotal = totalEarned
    totalEarned = totalEarned + amount
    if math.floor(totalEarned / 1000) > math.floor(oldTotal / 1000) then playChirp() end
end

local function GetCoinsPerHour()
    if not sessionStart then return 0 end
    local elapsed = tick() - sessionStart
    if elapsed < 10 then return 0 end
    local sessionEarned = totalEarned - sessionStartEarned
    return math.floor(sessionEarned / (elapsed / 3600))
end

local function ClearPlatform()
    FarmLockPos = nil
    if AlignConnection then AlignConnection:Disconnect() AlignConnection = nil end
    if FarmPlatform and FarmPlatform.Parent then FarmPlatform:Destroy() end
    FarmPlatform = nil
end

local function killAllAnimations(hum)
    if not hum or not hum.Parent then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then return end
    for _, trackAnim in ipairs(animator:GetPlayingAnimationTracks()) do
        trackAnim:Stop(0)
    end
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    if AnimKillConnection then AnimKillConnection:Disconnect() end
    AnimKillConnection = animator.AnimationPlayed:Connect(function(trackAnim)
        trackAnim:Stop(0)
    end)
end

local function applySafeState(hum)
    if not hum or not hum.Parent then return end
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, trackAnim in ipairs(animator:GetPlayingAnimationTracks()) do
            trackAnim:Stop(0)
        end
        if AnimKillConnection then AnimKillConnection:Disconnect() end
        AnimKillConnection = animator.AnimationPlayed:Connect(function(trackAnim)
            trackAnim:Stop(0)
        end)
    end
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
end

local function restoreStandardState(hum)
    if AnimKillConnection then AnimKillConnection:Disconnect() AnimKillConnection = nil end
    if not hum or not hum.Parent then return end
    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
end

local function refreshMurdererPositions()
    local fresh = {}
    for name, data in pairs(rolesCache) do
        if data.Role == "Murderer" and not data.Killed and not data.Dead then
            local p = Players:FindFirstChild(name)
            if p and p ~= LocalPlayer then
                local char = p.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then table.insert(fresh, hrp.Position) end
            end
        end
    end
    murdererPositions = fresh
end

local function isPosUnsafe(pos)
    if not config.avoidMurderer or #murdererPositions == 0 then return false end
    local xz2 = config.avoidRadius * config.avoidRadius
    local y2 = MURDERER_AVOID_RADIUS_Y * MURDERER_AVOID_RADIUS_Y
    for _, mp in ipairs(murdererPositions) do
        local dx, dy, dz = pos.X - mp.X, pos.Y - mp.Y, pos.Z - mp.Z
        if (dx*dx + dz*dz)/xz2 + (dy*dy)/y2 < 1 then return true end
    end
    return false
end
local function isCoinSafe(coinPos) return not isPosUnsafe(coinPos) end

local function IsCoinAvailable(coin)
    if not coin or not coin.Parent then return false end
    if not coin:IsA("BasePart") or coin.Name ~= "Coin_Server" then return false end
    if coin:GetAttribute("Collected") == true then return false end
    if not coin:FindFirstChild("TouchInterest") then return false end
    return true
end

local function GetDistOrigin(plat, hrp)
    if config.safeMethod then return (hrp and hrp.Position) or plat.Position end
    return plat.Position
end
local function GetYOffset() return config.safeMethod and -3.5 or 1.2 end

local function GetContainers()
    local out = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            local c = obj:FindFirstChild("CoinContainer")
            if c then table.insert(out, c) end
        end
    end
    return out
end

local function FindNearestCoin(pos)
    local best, bestDist = nil, math.huge
    for _, c in ipairs(GetContainers()) do
        for _, coin in ipairs(c:GetChildren()) do
            if IsCoinAvailable(coin) and not BadCoins[coin] then
                local cp = coin.Position
                if not isPosUnsafe(cp) then
                    local d = (pos - cp).Magnitude
                    if d < bestDist then best, bestDist = coin, d end
                end
            end
        end
    end
    return best, bestDist
end

local function FindRandomSafeCoin()
    local safe = {}
    for _, c in ipairs(GetContainers()) do
        for _, coin in ipairs(c:GetChildren()) do
            if IsCoinAvailable(coin) and not BadCoins[coin] and not isPosUnsafe(coin.Position) then
                table.insert(safe, coin)
            end
        end
    end
    return #safe > 0 and safe[math.random(1, #safe)] or nil
end

local function BuildPlatform(char, hrp, hum)
    local part = Instance.new("Part")
    part.Name = "drowsynicolas_platform"
    part.Size = Vector3.new(5, 0.65, 5)
    part.Anchored = false
    part.CanCollide = true
    part.Massless = true
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Transparency = 1
    part.CFrame = hrp.CFrame
    part.Parent = char
    FarmPlatform = part

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp; weld.Part1 = part; weld.Parent = part

    AlignConnection = RunService.Heartbeat:Connect(function()
        if not char.Parent or not hrp.Parent or not part.Parent then return end
        hum.AutoRotate = false
        local pos = FarmLockPos or hrp.Position
        local baseCF = CFrame.lookAt(pos, pos + FARM_DIRECTION)
        if config.safeMethod then baseCF = baseCF * SAFE_TILT end
        hrp.CFrame = baseCF
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    return part
end

local function MoveTo(part, char, initialTarget, onRetarget)
    part.Anchored = false
    local currentTarget = initialTarget
    local startPos = part.Position
    local dist = (currentTarget - startPos).Magnitude
    local duration = dist / config.speed
    local elapsed = 0
    while part.Parent and char.Parent and elapsed < duration do
        if onRetarget then
            local action, newTarget = onRetarget(currentTarget)
            if action == "abort" then return false end
            if action == "retarget" and newTarget then
                currentTarget = newTarget
                startPos = part.Position
                dist = (currentTarget - startPos).Magnitude
                duration = dist / config.speed
                elapsed = 0
            end
        end
        local dt = RunService.Heartbeat:Wait()
        elapsed += dt
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local pos = startPos:Lerp(currentTarget, alpha)
        local platCF = CFrame.new(pos)
        if config.safeMethod then
            platCF = CFrame.lookAt(pos, pos + FARM_DIRECTION) * SAFE_TILT
        end
        part.CFrame = platCF
    end
    if part.Parent and char.Parent then
        local finalCF = CFrame.new(currentTarget)
        if config.safeMethod then
            finalCF = CFrame.lookAt(currentTarget, currentTarget + FARM_DIRECTION) * SAFE_TILT
        end
        part.CFrame = finalCF
    end
    return true
end

local function FindCoinAreas()
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("CoinAreas") then return true end
    end
    return false
end
local function IsBarnActive()
    local barn = workspace:FindFirstChild("Barn")
    if not barn or not barn:IsA("Model") then return false end
    return barn:FindFirstChild("CoinAreas") ~= nil
end

local optimizeActive = false
local optimizeConnections = {}
local optimizedObjects = setmetatable({}, {__mode = "k"})
local optimizeRescanThread = nil
local RemoveDecals = true
local originalLighting = {
    GlobalShadows = Lighting.GlobalShadows, Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd, EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
}
local originalTerrain = {
    WaterWaveSize = Terrain.WaterWaveSize, WaterWaveSpeed = Terrain.WaterWaveSpeed,
    WaterReflectance = Terrain.WaterReflectance, WaterTransparency = Terrain.WaterTransparency,
}
local originalQualityLevel = nil
pcall(function() originalQualityLevel = settings().Rendering.QualityLevel end)

local function isProtected(obj)
    if not obj or not obj.Parent then return true end
    local n = obj.Name
    if type(n) == "string" and (n:find("9lives_") or n:find("drowsynicolas_")) then return true end
    return false
end

local function optimizeObject(obj)
    if not optimizeActive then return end
    if not obj or not obj.Parent then return end
    if isProtected(obj) or optimizedObjects[obj] then return end

    local saved = {}
    local function trySaveAndSet(key, value)
        local ok, old = pcall(function() return obj[key] end)
        if not ok then return end
        local ok2 = pcall(function() obj[key] = value end)
        if not ok2 then return end
        saved[key] = old
    end

    pcall(function()
        if obj:IsA("MeshPart") then
            trySaveAndSet("Material", Enum.Material.Plastic)
            trySaveAndSet("Reflectance", 0)
            trySaveAndSet("CastShadow", false)
            trySaveAndSet("TextureID", "")
            local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
            if sa then
                saved.SurfaceAppearance = sa
                saved.SurfaceAppearanceParent = obj
                pcall(function() sa.Parent = nil end)
            end
        elseif obj:IsA("BasePart") then
            trySaveAndSet("Material", Enum.Material.Plastic)
            trySaveAndSet("Reflectance", 0)
            trySaveAndSet("CastShadow", false)
        elseif RemoveDecals and (obj:IsA("Decal") or obj:IsA("Texture")) then
            if obj.Transparency < 1 then
                trySaveAndSet("Transparency", 1)
            end
        elseif obj:IsA("SurfaceAppearance") then
            saved.SurfaceAppearance = obj
            saved.SurfaceAppearanceParent = obj.Parent
            pcall(function() obj.Parent = nil end)
        elseif obj:IsA("ParticleEmitter") then
            if obj.Enabled then
                trySaveAndSet("Enabled", false)
                trySaveAndSet("Rate", 0)
                trySaveAndSet("Lifetime", NumberRange.new(0))
                trySaveAndSet("Speed", NumberRange.new(0))
            end
        elseif obj:IsA("Trail") then
            if obj.Enabled then
                trySaveAndSet("Enabled", false)
                trySaveAndSet("Lifetime", 0)
            end
        elseif obj:IsA("Beam") then
            if obj.Enabled then
                trySaveAndSet("Enabled", false)
            end
        elseif obj:IsA("Explosion") then
            trySaveAndSet("BlastPressure", 1)
            trySaveAndSet("BlastRadius", 1)
        elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")
            or obj:IsA("Highlight") or obj:IsA("PointLight")
            or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            if obj.Enabled then
                trySaveAndSet("Enabled", false)
            end
        elseif obj:IsA("PostEffect") then
            if obj.Enabled then
                trySaveAndSet("Enabled", false)
            end
        end
    end)

    if next(saved) ~= nil then
        optimizedObjects[obj] = saved
    end
end

local function restoreObject(obj, saved)
    if not obj then return end

    if saved.SurfaceAppearance then
        local sa = saved.SurfaceAppearance
        pcall(function()
            if sa and saved.SurfaceAppearanceParent and saved.SurfaceAppearanceParent.Parent then
                sa.Parent = saved.SurfaceAppearanceParent
            elseif sa and not sa.Parent then
                sa:Destroy()
            end
        end)
        if sa == obj then return end
    end

    if not obj.Parent then return end

    if saved.Material ~= nil then pcall(function() obj.Material = saved.Material end) end
    if saved.Reflectance ~= nil then pcall(function() obj.Reflectance = saved.Reflectance end) end
    if saved.CastShadow ~= nil then pcall(function() obj.CastShadow = saved.CastShadow end) end
    if saved.TextureID ~= nil then pcall(function() obj.TextureID = saved.TextureID end) end
    if saved.Transparency ~= nil then pcall(function() obj.Transparency = saved.Transparency end) end
    if saved.Enabled ~= nil then pcall(function() obj.Enabled = saved.Enabled end) end
    if saved.Rate ~= nil then pcall(function() obj.Rate = saved.Rate end) end
    if saved.Lifetime ~= nil then pcall(function() obj.Lifetime = saved.Lifetime end) end
    if saved.Speed ~= nil then pcall(function() obj.Speed = saved.Speed end) end
    if saved.BlastPressure ~= nil then pcall(function() obj.BlastPressure = saved.BlastPressure end) end
    if saved.BlastRadius ~= nil then pcall(function() obj.BlastRadius = saved.BlastRadius end) end
end

local function findAndDestroyRaggy()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d.Name == "Raggy" then d:Destroy() end
    end
end
local function findAndDestroyVisuals()
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    if not ps then return end
    for _, d in ipairs(ps:GetDescendants()) do
        if d.Name == "WeaponVisuals" and d.ClassName == "Folder" then d:Destroy() end
    end
end

local function startOptimizeGame()
    if optimizeActive then return end
    optimizeActive = true
    pcall(function()
        Terrain.WaterWaveSize = 0 Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0 Terrain.WaterTransparency = 0
    end)
    pcall(function()
        Lighting.GlobalShadows = false Lighting.Brightness = 0.8
        Lighting.FogEnd = 9e9
        Lighting.EnvironmentDiffuseScale = 0 Lighting.EnvironmentSpecularScale = 0
    end)
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    task.spawn(function()
        local all = game:GetDescendants()
        for i = 1, #all, 500 do
            if not optimizeActive then return end
            for j = i, math.min(i + 499, #all) do optimizeObject(all[j]) end
            task.wait()
        end
    end)
    table.insert(optimizeConnections, game.DescendantAdded:Connect(function(obj)
        if optimizeActive then task.defer(optimizeObject, obj) end
    end))
    findAndDestroyRaggy()
    table.insert(optimizeConnections, workspace.DescendantAdded:Connect(function(inst)
        if not optimizeActive then return end
        if inst:IsA("Model") and inst.Name == "Raggy" then inst:Destroy() end
    end))
    findAndDestroyVisuals()
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    if ps then
        table.insert(optimizeConnections, ps.DescendantAdded:Connect(function(inst)
            if not optimizeActive then return end
            if inst.Name == "WeaponVisuals" and inst.ClassName == "Folder" then inst:Destroy() end
        end))
    end
    if optimizeRescanThread then pcall(task.cancel, optimizeRescanThread) end
    optimizeRescanThread = task.spawn(function()
        while optimizeActive do
            task.wait(1)
            if not optimizeActive then break end
            findAndDestroyRaggy(); findAndDestroyVisuals()
        end
    end)
end

local function stopOptimizeGame()
    if not optimizeActive then return end
    optimizeActive = false
    if optimizeRescanThread then
        pcall(task.cancel, optimizeRescanThread)
        optimizeRescanThread = nil
    end

    for _, conn in ipairs(optimizeConnections) do pcall(function() conn:Disconnect() end) end
    table.clear(optimizeConnections)

    pcall(function() Terrain.WaterWaveSize = originalTerrain.WaterWaveSize end)
    pcall(function() Terrain.WaterWaveSpeed = originalTerrain.WaterWaveSpeed end)
    pcall(function() Terrain.WaterReflectance = originalTerrain.WaterReflectance end)
    pcall(function() Terrain.WaterTransparency = originalTerrain.WaterTransparency end)

    pcall(function() Lighting.GlobalShadows = originalLighting.GlobalShadows end)
    pcall(function() Lighting.Brightness = originalLighting.Brightness end)
    pcall(function() Lighting.FogEnd = originalLighting.FogEnd end)
    pcall(function() Lighting.EnvironmentDiffuseScale = originalLighting.EnvironmentDiffuseScale end)
    pcall(function() Lighting.EnvironmentSpecularScale = originalLighting.EnvironmentSpecularScale end)

    if originalQualityLevel then
        pcall(function() settings().Rendering.QualityLevel = originalQualityLevel end)
    end

    for obj, saved in pairs(optimizedObjects) do
        pcall(restoreObject, obj, saved)
    end
    table.clear(optimizedObjects)
end

local antiVoidPart = nil
local antiVoidConn = nil
local function startAntiVoid()
    if antiVoidPart then return end
    antiVoidPart = Instance.new("Part")
    antiVoidPart.Name = "9lives_antiVoidPart"
    antiVoidPart.Size = Vector3.new(10, 1, 10)
    antiVoidPart.Anchored = true
    antiVoidPart.CanCollide = true
    antiVoidPart.CanQuery = false
    antiVoidPart.CanTouch = false
    antiVoidPart.CastShadow = false
    antiVoidPart.Massless = true
    antiVoidPart.Transparency = 1
    antiVoidPart.Position = Vector3.new(0, -480, 0)
    antiVoidPart.Parent = workspace
    antiVoidConn = RunService.Heartbeat:Connect(function()
        if not antiVoidPart or not antiVoidPart.Parent then return end
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            antiVoidPart.Position = Vector3.new(root.Position.X, -480, root.Position.Z)
        end
    end)
end
local function stopAntiVoid()
    if antiVoidConn then antiVoidConn:Disconnect() antiVoidConn = nil end
    if antiVoidPart then antiVoidPart:Destroy() antiVoidPart = nil end
end

local antiFlingActive = false
local antiFlingConn = nil
local antiFlingPlayerAddedConn = nil
local antiFlingPlayerRemovingConn = nil
local antiFlingCharConns = {}
local antiFlingPlayerConns = {}
local antiFlingTrackedPlayers = {}
local antiFlingModifiedParts = {}

local function antiFlingDisableCanCollide(part)
    if part:IsA("BasePart") and part.CanCollide then
        part.CanCollide = false
        antiFlingModifiedParts[part] = true
    end
end
local function antiFlingTrackCharacter(character)
    for _, part in ipairs(character:GetChildren()) do antiFlingDisableCanCollide(part) end
    if antiFlingCharConns[character] then antiFlingCharConns[character]:Disconnect() end
    antiFlingCharConns[character] = character.ChildAdded:Connect(function(child)
        if antiFlingActive then antiFlingDisableCanCollide(child) end
    end)
end
local function antiFlingTrackPlayer(player)
    if player == LocalPlayer or antiFlingTrackedPlayers[player] then return end
    antiFlingTrackedPlayers[player] = true
    if player.Character then antiFlingTrackCharacter(player.Character) end
    if antiFlingPlayerConns[player] then antiFlingPlayerConns[player]:Disconnect() end
    antiFlingPlayerConns[player] = player.CharacterAdded:Connect(function(char)
        if antiFlingActive then antiFlingTrackCharacter(char) end
    end)
end
local function antiFlingUntrackPlayer(player)
    antiFlingTrackedPlayers[player] = nil
    if antiFlingPlayerConns[player] then antiFlingPlayerConns[player]:Disconnect() antiFlingPlayerConns[player] = nil end
    if player.Character and antiFlingCharConns[player.Character] then
        antiFlingCharConns[player.Character]:Disconnect() antiFlingCharConns[player.Character] = nil
    end
end
local function startAntiFling()
    if antiFlingActive then return end
    antiFlingActive = true
    for _, player in ipairs(Players:GetPlayers()) do antiFlingTrackPlayer(player) end
    antiFlingPlayerAddedConn = Players.PlayerAdded:Connect(antiFlingTrackPlayer)
    antiFlingPlayerRemovingConn = Players.PlayerRemoving:Connect(antiFlingUntrackPlayer)
    antiFlingConn = RunService.Heartbeat:Connect(function()
        if not antiFlingActive then return end
        for player in pairs(antiFlingTrackedPlayers) do
            local character = player.Character
            if character then
                for _, part in ipairs(character:GetChildren()) do antiFlingDisableCanCollide(part) end
            end
        end
    end)
end
local function stopAntiFling()
    if not antiFlingActive then return end
    antiFlingActive = false
    if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn = nil end
    if antiFlingPlayerAddedConn then antiFlingPlayerAddedConn:Disconnect() antiFlingPlayerAddedConn = nil end
    if antiFlingPlayerRemovingConn then antiFlingPlayerRemovingConn:Disconnect() antiFlingPlayerRemovingConn = nil end
    for player in pairs(antiFlingTrackedPlayers) do antiFlingUntrackPlayer(player) end
    for _, conn in pairs(antiFlingCharConns) do pcall(function() conn:Disconnect() end) end
    table.clear(antiFlingCharConns) table.clear(antiFlingPlayerConns) table.clear(antiFlingTrackedPlayers)
    for part in pairs(antiFlingModifiedParts) do
        if part and part.Parent then pcall(function() part.CanCollide = true end) end
    end
    table.clear(antiFlingModifiedParts)
end

local antiAfkActive = false
local antiAfkConns = {}
local antiAfkFallbackConn = nil
local function startAntiAfk()
    if antiAfkActive then return end
    antiAfkActive = true
    table.clear(antiAfkConns)
    if getconnections then
        local ok = pcall(function()
            for _, conn in ipairs(getconnections(LocalPlayer.Idled)) do
                if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
                table.insert(antiAfkConns, conn)
            end
        end)
        if not ok then
            antiAfkFallbackConn = LocalPlayer.Idled:Connect(function()
                pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
            end)
        end
    else
        antiAfkFallbackConn = LocalPlayer.Idled:Connect(function()
            pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
        end)
    end
end
local function stopAntiAfk()
    if not antiAfkActive then return end
    antiAfkActive = false
    for _, conn in ipairs(antiAfkConns) do pcall(function() if conn.Enable then conn:Enable() end end) end
    table.clear(antiAfkConns)
    if antiAfkFallbackConn then pcall(function() antiAfkFallbackConn:Disconnect() end) antiAfkFallbackConn = nil end
end

local function applyFpsCap()
    if not setfpscap then return end
    pcall(function() setfpscap(config.capFps and config.fpsValue or 240) end)
end
local render3dOverlay = nil
local function startRender3dDisabled()
    if render3dOverlay then return end
    local ok = pcall(function() RunService:Set3DRenderingEnabled(false) end)
    if not ok then return end
    render3dOverlay = Instance.new("ScreenGui")
    render3dOverlay.Name = "9lives_3dOverlay"
    render3dOverlay.IgnoreGuiInset = true
    render3dOverlay.ResetOnSpawn = false
    render3dOverlay.DisplayOrder = 999999
    render3dOverlay.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local f = Instance.new("Frame")
    f.Size = UDim2.fromScale(1, 1) f.BackgroundColor3 = Color3.new(0,0,0) f.BorderSizePixel = 0
    f.Parent = render3dOverlay
end
local function stopRender3dDisabled()
    pcall(function() RunService:Set3DRenderingEnabled(true) end)
    if render3dOverlay then render3dOverlay:Destroy() render3dOverlay = nil end
end
local function applyRender3d() if config.render3d then stopRender3dDisabled() else startRender3dDisabled() end end

local function getEquippedKnife()
    local char = LocalPlayer.Character
    if char then
        local k = char:FindFirstChild("Knife")
        if k and k:IsA("Tool") then return k end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local k = bp:FindFirstChild("Knife")
        if k and k:IsA("Tool") then return k end
    end
    return nil
end

local function hasKnifeOrMurderer()
    if getEquippedKnife() then return true end
    local data = rolesCache[LocalPlayer.Name]
    return data and data.Role == "Murderer" or false
end

local function killAllAlivePlayers()
    local knife = getEquippedKnife()
    if not knife then return end
    local handleTouched = (knife:FindFirstChild("Events") or knife):FindFirstChild("HandleTouched")
    if not handleTouched or not handleTouched:IsA("RemoteEvent") then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character
           and player:GetAttribute("Alive") == true then
            local targetChar = player.Character
            local hitPart = targetChar:FindFirstChild("HumanoidRootPart")
                or targetChar:FindFirstChild("Head")
                or targetChar:FindFirstChild("Torso")
                or targetChar:FindFirstChild("UpperTorso")
            if hitPart then
                pcall(function() handleTouched:FireServer(hitPart.Position) end)
                pcall(function() handleTouched:FireServer(hitPart) end)
            end
        end
    end
end

local function hasGun()
    local char = LocalPlayer.Character
    if char then
        local g = char:FindFirstChild("Gun")
        if g and g:IsA("Tool") then return true end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local g = bp:FindFirstChild("Gun")
        if g and g:IsA("Tool") then return true end
    end
    return false
end

local function getEquippedGun()
    local char = LocalPlayer.Character
    if char then
        local g = char:FindFirstChild("Gun")
        if g and g:IsA("Tool") then return g end
    end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local g = bp:FindFirstChild("Gun")
        if g and g:IsA("Tool") then return g end
    end
    return nil
end

local ShootPrediction = 0.165
local _shootVelCache = {}

local function shootPredict(part, leadTime)
    leadTime = leadTime or ShootPrediction
    if not part or not part.Parent then return nil end

    local now = tick()
    local c = _shootVelCache[part]
    local vel
    if c and (now - c.time) > 0 and (now - c.time) < 0.25 then
        vel = (part.Position - c.pos) / (now - c.time)
    else
        vel = part.AssemblyLinearVelocity
    end
    _shootVelCache[part] = { pos = part.Position, time = now }

    local horizVel = Vector3.new(vel.X, 0, vel.Z)

    local pingComp = 0
    pcall(function()
        pingComp = math.clamp(LocalPlayer:GetNetworkPing() * 0.5, 0, 0.06)
    end)

    local predicted = part.Position + horizVel * (leadTime + pingComp)

    local hum = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
    if hum then
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Jumping
            or state == Enum.HumanoidStateType.Freefall then
            predicted = predicted + Vector3.new(0, vel.Y * 0.08, 0)
        end
    end

    local maxLead = 20
    local d = (predicted - part.Position).Magnitude
    if d > maxLead then
        predicted = part.Position + (predicted - part.Position).Unit * maxLead
    end
    return predicted
end

local function isMurdererAlive(player)
    local data = rolesCache[player.Name]
    if not data or data.Role ~= "Murderer" then return false end
    if data.Killed or data.Dead then return false end
    return player:GetAttribute("Alive") == true
end

local function findMurdererHRPs()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and isMurdererAlive(player) then
                table.insert(list, hrp)
            end
        end
    end
    return list
end

local function shootMurderer()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    local gun = getEquippedGun()
    if not gun then return false end
    if gun.Parent ~= char then
        hum:EquipTool(gun)
        task.wait(0.05)
    end

    local remote = gun:FindFirstChild("Shoot")
    if not remote then return false end

    local hrps = findMurdererHRPs()
    if #hrps == 0 then return false end

    for _, hrp in ipairs(hrps) do
        local startCF = CFrame.new(hrp.Position)
        local predictedPos = shootPredict(hrp, ShootPrediction)
        if predictedPos then
            local endPos = predictedPos + Vector3.new(0.01, 0.01, 0.01)
            remote:FireServer(startCF, CFrame.new(endPos))
        end
    end
    return true
end

local function findGunDrop()
    return workspace:FindFirstChild("GunDrop", true)
end

local function grabGun(drop)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not (hrp and drop and drop.Parent) then return end
    pcall(function()
        firetouchinterest(hrp, drop, 0)
        task.wait()
        firetouchinterest(hrp, drop, 1)
    end)
    task.wait(0.05)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local gun = getEquippedGun()
        if gun and gun.Parent ~= char then
            pcall(function() hum:EquipTool(gun) end)
        end
    end
end

local gunListenerConn = nil
local gunListenerRescanThread = nil
local GUN_GRAB_RESCAN = 0.5

local function tryGrabGunDrop()
    if not config.autoHero then return end
    if LocalPlayer:GetAttribute("Alive") ~= true then return end
    if hasKnifeOrMurderer() then return end
    if hasGun() then return end
    local drop = findGunDrop()
    if drop then grabGun(drop) end
end

local function startGunListener()
    if gunListenerConn then return end
    gunListenerConn = workspace.DescendantAdded:Connect(function(obj)
        if not obj:IsA("BasePart") or obj.Name ~= "GunDrop" then return end
        if not config.autoHero then return end
        if LocalPlayer:GetAttribute("Alive") ~= true then return end
        if hasKnifeOrMurderer() then return end
        if hasGun() then return end
        task.wait(0.05)
        if obj and obj.Parent then
            grabGun(obj)
            task.delay(0.2, function()
                if obj and obj.Parent and not hasGun() then
                    grabGun(obj)
                end
            end)
        end
    end)
    if gunListenerRescanThread then pcall(task.cancel, gunListenerRescanThread) end
    gunListenerRescanThread = task.spawn(function()
        while gunListenerConn and not destroyed do
            tryGrabGunDrop()
            task.wait(GUN_GRAB_RESCAN)
        end
    end)
end

local function stopGunListener()
    if gunListenerConn then
        pcall(function() gunListenerConn:Disconnect() end)
        gunListenerConn = nil
    end
    if gunListenerRescanThread then
        pcall(task.cancel, gunListenerRescanThread)
        gunListenerRescanThread = nil
    end
end

local function isMurdererStillAlive()
    for _, data in pairs(rolesCache) do
        if data.Role == "Murderer" and not data.Killed and not data.Dead then
            return true
        end
    end
    return false
end

local killLoopActive = false
local killLoopThread = nil
local KILL_WARMUP = 0.2
local KILL_RETRY_INTERVAL = 0.1

local function isAnyoneElseAlive()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player:GetAttribute("Alive") == true then
            return true
        end
    end
    return false
end

local function stopKillLoop()
    killLoopActive = false
    if killLoopThread then
        pcall(task.cancel, killLoopThread)
        killLoopThread = nil
    end
end

local function startKillLoop()
    if killLoopActive then return end
    ClearPlatform()
    killLoopActive = true
    killLoopThread = task.spawn(function()
        local startedAt = tick()
        local lastAttempt = 0
        while killLoopActive and not destroyed do
            RunService.Heartbeat:Wait()

            if not config.autoKillAll or not config.farmEnabled
               or LocalPlayer:GetAttribute("Alive") ~= true
               or not isAnyoneElseAlive() then
                killLoopActive = false
                break
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.lookAt(PreRoundPos, PreRoundPos + FARM_DIRECTION)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end

            local now = tick()
            if now - startedAt < KILL_WARMUP then
                continue
            end

            if now - lastAttempt >= KILL_RETRY_INTERVAL then
                lastAttempt = now
                pcall(killAllAlivePlayers)
            end
        end
    end)
end

local shootLoopActive = false
local shootLoopMode = nil
local shootLoopThread = nil
local SHOOT_INTERVAL = 0.05

local function stopShootLoop()
    shootLoopActive = false
    shootLoopMode = nil
    if shootLoopThread then
        pcall(task.cancel, shootLoopThread)
        shootLoopThread = nil
    end
end

local function startShootLoop(mode)
    if shootLoopActive then return end
    ClearPlatform()
    shootLoopActive = true
    shootLoopMode = mode or "shoot"
    shootLoopThread = task.spawn(function()
        local loopStartedAt = tick()
        local lastShot = 0
        local lastGrabAttempt = 0
        while shootLoopActive and not destroyed do
            RunService.Heartbeat:Wait()

            local toggleOn
            if shootLoopMode == "hero" then
                toggleOn = config.autoHero
            else
                toggleOn = config.autoShootMurd
            end

            if not toggleOn or not config.farmEnabled
               or LocalPlayer:GetAttribute("Alive") ~= true
               or not isMurdererStillAlive() then
                shootLoopActive = false
                break
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.lookAt(PreRoundPos, PreRoundPos + FARM_DIRECTION)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end

            local now = tick()
            if now - loopStartedAt < 0.2 then
                continue
            end

            if hasGun() then
                if now - lastShot >= SHOOT_INTERVAL then
                    lastShot = now
                    pcall(shootMurderer)
                end
            elseif shootLoopMode == "hero" then
                if now - lastGrabAttempt >= 0.1 then
                    lastGrabAttempt = now
                    local drop = findGunDrop()
                    if drop then grabGun(drop) end
                end
            else
                shootLoopActive = false
                break
            end
        end
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = guiName
gui.Parent = CoreGui
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local viewportSize = workspace.CurrentCamera.ViewportSize
local baseScale = math.min(viewportSize.X / 800, viewportSize.Y / 600, 1.5)
local scale = (UserInputService.TouchEnabled and viewportSize.X < 768) and baseScale * 1.3 or (UserInputService.TouchEnabled and baseScale * 0.9 or baseScale * 1.1)

local HEADER_HEIGHT = 32 * scale
local panelOriginalHeight = 200
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 180 * scale, 0, panelOriginalHeight * scale)
panel.Position = UDim2.new(config.position.XScale, config.position.XOffset, config.position.YScale, config.position.YOffset)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12 * scale)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(0, 0, 0)
panelStroke.Transparency = 0.10
panelStroke.Thickness = 3 * scale

local currentParticles = nil
local function createParticles(parent, count)
    if currentParticles then
        currentParticles.running = false
        for _, p in ipairs(currentParticles.particles) do
            if p.object and p.object.Parent then p.object:Destroy() end
        end
    end
    local newBatch = {running = true, particles = {}}
    for i = 1, count do
        local ball = Instance.new("Frame")
        ball.Name = blankName(20)
        local size = math.random(2, 4)
        ball.Size = UDim2.new(0, size * scale, 0, size * scale)
        ball.Position = UDim2.new(math.random(5, 95) / 100, 0, math.random(5, 95) / 100, 0)
        ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ball.BackgroundTransparency = math.random(20, 60) / 100
        ball.BorderSizePixel = 0
        ball.ZIndex = 0
        ball.Parent = parent
        Instance.new("UICorner", ball).CornerRadius = UDim.new(1, 0)
        table.insert(newBatch.particles, {
            object = ball,
            verticalSpeed = math.random(8, 18) / 100,
            horizontalSpeed = math.random(1, 3) / 100,
        })
    end
    task.spawn(function()
        while newBatch.running and parent and parent.Parent do
            local delta = RunService.RenderStepped:Wait()
            for _, p in ipairs(newBatch.particles) do
                local obj = p.object
                if obj and obj.Parent then
                    local currentX, currentY = obj.Position.X.Scale, obj.Position.Y.Scale
                    local newX = currentX + p.horizontalSpeed * delta
                    local newY = currentY - p.verticalSpeed * delta
                    if newY < 0 then newY = 1 newX = math.random(5, 95) / 100 end
                    if newX > 0.98 then newX = 0.02 end
                    obj.Position = UDim2.new(newX, 0, newY, 0)
                end
            end
        end
    end)
    currentParticles = newBatch
end
createParticles(panel, 10)

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,HEADER_HEIGHT)
header.BackgroundTransparency = 1
header.Parent = panel

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -90*scale, 1, 0)
headerLabel.Position = UDim2.new(0, 30*scale, 0.5, 0)
headerLabel.AnchorPoint = Vector2.new(0, 0.5)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "9Lives - Auto Farm"
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextSize = 12*scale
headerLabel.TextColor3 = Color3.fromRGB(255,255,255)
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Parent = header

local middleImage = Instance.new("ImageLabel")
middleImage.Size = UDim2.new(0, 18*scale, 0, 18*scale)
middleImage.Position = UDim2.new(1, -47*scale, 0, 7*scale)
middleImage.BackgroundTransparency = 1
middleImage.Image = "rbxassetid://73598966558406"
middleImage.Parent = header
Instance.new("UICorner", middleImage).CornerRadius = UDim.new(1, 0)
local middleStroke = Instance.new("UIStroke", middleImage)
middleStroke.Color = Color3.fromRGB(0, 0, 0)
middleStroke.Transparency = 0.2

task.spawn(function()
    local ok, result = pcall(function()
        writefile(IMG_PATH, game:HttpGet("https://raw.githubusercontent.com/drowsynicolas/drowsynicolas-ODH-icon/refs/heads/main/image.png"))
        return getcustomasset(IMG_PATH)
    end)
    if ok and result and middleImage and middleImage.Parent then middleImage.Image = result end
end)

local collapseBtn = Instance.new("ImageButton")
collapseBtn.Size = UDim2.new(0,22*scale,0,22*scale)
collapseBtn.Position = UDim2.new(0,4*scale,0,4*scale)
collapseBtn.BackgroundTransparency = 1
collapseBtn.Image = "rbxassetid://137805819128674"
collapseBtn.AutoButtonColor = false
collapseBtn.Selectable = false
collapseBtn.Parent = header

local closeBtn = Instance.new("ImageButton")
closeBtn.Size = UDim2.new(0,22*scale,0,22*scale)
closeBtn.Position = UDim2.new(1,-26*scale,0,4*scale)
closeBtn.BackgroundTransparency = 1
closeBtn.Image = "rbxassetid://132261474823036"
closeBtn.AutoButtonColor = false
closeBtn.Selectable = false
closeBtn.Parent = header

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT)
scrollFrame.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 2*scale
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
scrollFrame.ScrollBarImageTransparency = 0.3
scrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ClipsDescendants = true
scrollFrame.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6*scale)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingLeft = UDim.new(0, 15*scale)
listPadding.PaddingRight = UDim.new(0, 11*scale)
listPadding.PaddingTop = UDim.new(0, 6*scale)
listPadding.PaddingBottom = UDim.new(0, 8*scale)
listPadding.Parent = scrollFrame

local timerSection = Instance.new("Frame")
timerSection.Size = UDim2.new(1, 0, 0, 0)
timerSection.AutomaticSize = Enum.AutomaticSize.Y
timerSection.BackgroundTransparency = 1
timerSection.BorderSizePixel = 0
timerSection.LayoutOrder = 2
timerSection.Parent = scrollFrame

local timerLayout = Instance.new("UIListLayout")
timerLayout.Padding = UDim.new(0, 1*scale)
timerLayout.SortOrder = Enum.SortOrder.LayoutOrder
timerLayout.Parent = timerSection

local function makeTimerLabel(text, size, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, size*scale)
    l.BackgroundTransparency = 1
    l.Text = text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 11*scale
    l.TextColor3 = Color3.fromRGB(255,255,255)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order
    l.Parent = timerSection
    return l
end

local timeLabel = makeTimerLabel("Time Elapsed", 20, 1)
timeLabel.Font = Enum.Font.GothamBold
timeLabel.TextSize = 14*scale
local dayLabel = makeTimerLabel("Days: 0", 14, 2)
local hourLabel = makeTimerLabel("Hours: 0", 14, 3)
local minuteLabel = makeTimerLabel("Minutes: 0", 14, 4)
local secondLabel = makeTimerLabel("Seconds: 0", 14, 5)

local earnedSpacer = Instance.new("Frame")
earnedSpacer.Size = UDim2.new(1, 0, 0, 4*scale)
earnedSpacer.BackgroundTransparency = 1
earnedSpacer.BorderSizePixel = 0
earnedSpacer.LayoutOrder = 6
earnedSpacer.Parent = timerSection

local totalEarnedLabel = Instance.new("TextLabel")
totalEarnedLabel.Size = UDim2.new(1, 0, 0, 16*scale)
totalEarnedLabel.BackgroundTransparency = 1
totalEarnedLabel.Text = "Total Earned: 0"
totalEarnedLabel.Font = Enum.Font.GothamBold
totalEarnedLabel.TextSize = 12*scale
totalEarnedLabel.TextColor3 = Color3.fromRGB(255,255,255)
totalEarnedLabel.TextXAlignment = Enum.TextXAlignment.Left
totalEarnedLabel.LayoutOrder = 7
totalEarnedLabel.Parent = timerSection

local avgPerHourLabel = Instance.new("TextLabel")
avgPerHourLabel.Size = UDim2.new(1, 0, 0, 16*scale)
avgPerHourLabel.BackgroundTransparency = 1
avgPerHourLabel.Text = "Avg Per Hour: 0"
avgPerHourLabel.Font = Enum.Font.GothamBold
avgPerHourLabel.TextSize = 12*scale
avgPerHourLabel.TextColor3 = Color3.fromRGB(255,255,255)
avgPerHourLabel.TextXAlignment = Enum.TextXAlignment.Left
avgPerHourLabel.LayoutOrder = 8
avgPerHourLabel.Parent = timerSection

local rolesSpacer = Instance.new("Frame")
rolesSpacer.Size = UDim2.new(1, 0, 0, 6*scale)
rolesSpacer.BackgroundTransparency = 1
rolesSpacer.BorderSizePixel = 0
rolesSpacer.LayoutOrder = 9
rolesSpacer.Parent = timerSection

local murdererLabel = makeTimerLabel("Murderer: ", 16, 10)
local gunLabel = makeTimerLabel("Sheriff: ", 16, 11)
murdererLabel.TextSize = 10*scale
murdererLabel.TextColor3 = Color3.fromRGB(120,120,120)
gunLabel.TextSize = 10*scale
gunLabel.TextColor3 = Color3.fromRGB(120,120,120)

local function resetTimerLabels()
    if dayLabel.Parent then dayLabel.Text = "Days: 0" end
    if hourLabel.Parent then hourLabel.Text = "Hours: 0" end
    if minuteLabel.Parent then minuteLabel.Text = "Minutes: 0" end
    if secondLabel.Parent then secondLabel.Text = "Seconds: 0" end
end

task.spawn(function()
    while dayLabel.Parent do
        if config.farmEnabled and sessionStart then
            local elapsed = math.floor(tick() - sessionStart)
            local d = math.floor(elapsed / 86400)
            local h = math.floor((elapsed % 86400) / 3600)
            local m = math.floor((elapsed % 3600) / 60)
            local s = elapsed % 60
            if dayLabel.Parent then dayLabel.Text = "Days: " .. d end
            if hourLabel.Parent then hourLabel.Text = "Hours: " .. h end
            if minuteLabel.Parent then minuteLabel.Text = "Minutes: " .. m end
            if secondLabel.Parent then secondLabel.Text = "Seconds: " .. s end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while totalEarnedLabel.Parent do
        local avg = GetCoinsPerHour()
        if totalEarnedLabel.Parent then totalEarnedLabel.Text = string.format("Total Earned: %d", totalEarned) end
        if avgPerHourLabel.Parent then avgPerHourLabel.Text = string.format("Avg Per Hour: %d", avg) end
        task.wait(2)
    end
end)

task.spawn(function()
    while murdererLabel.Parent and not destroyed do
        local murdererName = ""
        local sheriffName = nil
        local sheriffAlive = false

        for name, data in pairs(rolesCache) do
            if data.Role == "Murderer" and not data.Killed and not data.Dead then
                murdererName = name
            elseif data.Role == "Sheriff" then
                sheriffName = name
                sheriffAlive = not (data.Killed or data.Dead)
            end
        end

        local gunText = "Sheriff: "

        if sheriffName and sheriffAlive then
            gunText = "Sheriff: " .. sheriffName
        else
            local gunHolder = nil
            for _, player in ipairs(Players:GetPlayers()) do
                if player:GetAttribute("Alive") == true then
                    local char = player.Character
                    local bp = player:FindFirstChildOfClass("Backpack")
                    if (char and char:FindFirstChild("Gun"))
                       or (bp and bp:FindFirstChild("Gun")) then
                        gunHolder = player.Name
                        break
                    end
                end
            end
            if gunHolder then
                gunText = "Hero: " .. gunHolder
            elseif findGunDrop() then
                gunText = "Gun dropped!"
            end
        end

        if murdererLabel.Parent then murdererLabel.Text = "Murderer: " .. murdererName end
        if gunLabel.Parent then gunLabel.Text = gunText end

        task.wait(0.5)
    end
end)

local function remeasureSectionHeaders()
    for _, data in ipairs(sectionHeaders) do
        if not data.header.Parent then continue end
        local labelWidth = data.label.AbsoluteSize.X
        local totalWidth = data.header.AbsoluteSize.X
        if labelWidth > 0 and totalWidth > 0 then
            local gap = 6 * scale
            local lineWidth = (totalWidth - labelWidth) / 2 - gap
            if lineWidth > 0 then
                data.left.Size = UDim2.new(0, lineWidth, 0, 1*scale)
                data.right.Size = UDim2.new(0, lineWidth, 0, 1*scale)
            end
        end
    end
end

local function createSectionHeader(text, layoutOrder)
    local sectionHeader = Instance.new("Frame")
    sectionHeader.Size = UDim2.new(1, 0, 0, 18*scale)
    sectionHeader.BackgroundTransparency = 1
    sectionHeader.BorderSizePixel = 0
    sectionHeader.LayoutOrder = layoutOrder
    sectionHeader.Parent = scrollFrame

    local leftLine = Instance.new("Frame")
    leftLine.Size = UDim2.new(0, 0, 0, 1*scale)
    leftLine.Position = UDim2.new(0, 0, 0.5, 0)
    leftLine.AnchorPoint = Vector2.new(0, 0.5)
    leftLine.BackgroundColor3 = Color3.fromRGB(255,255,255)
    leftLine.BackgroundTransparency = 0.7
    leftLine.BorderSizePixel = 0
    leftLine.Parent = sectionHeader

    local rightLine = Instance.new("Frame")
    rightLine.Size = UDim2.new(0, 0, 0, 1*scale)
    rightLine.Position = UDim2.new(1, 0, 0.5, 0)
    rightLine.AnchorPoint = Vector2.new(1, 0.5)
    rightLine.BackgroundColor3 = Color3.fromRGB(255,255,255)
    rightLine.BackgroundTransparency = 0.7
    rightLine.BorderSizePixel = 0
    rightLine.Parent = sectionHeader

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 0, 1, 0)
    label.Position = UDim2.new(0.5, 0, 0.5, 0)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = (#text > 14) and (10*scale) or (11*scale)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = sectionHeader

    table.insert(sectionHeaders, {header = sectionHeader, label = label, left = leftLine, right = rightLine})
    return sectionHeader
end

local function createToggle(name, layoutOrder, initialValue, callback, onText, offText, opts)
    onText = onText or "[ ON ]" offText = offText or "[ OFF ]"
    opts = opts or {}
    local cooldown = opts.cooldown or 1
    local lastClickAt = 0
    local maxChars = math.max(#onText, #offText)
    local btnWidth = math.max(60, maxChars * 5.5 + 8) * scale
    local btnTextSize = (maxChars > 6) and (10*scale) or (12*scale)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22*scale)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = scrollFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -btnWidth - 4*scale, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local sc = Instance.new("UITextSizeConstraint")
    sc.MaxTextSize = math.floor(12*scale) sc.MinTextSize = 7 sc.Parent = label

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, btnWidth, 1, 0)
    btn.Position = UDim2.new(1, 0, 0, 0)
    btn.AnchorPoint = Vector2.new(1, 0)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = initialValue and onText or offText
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextSize = btnTextSize
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Selectable = false
    btn.Parent = row

    local state = initialValue
    btn.MouseButton1Click:Connect(function()
        local now = tick()
        if cooldown > 0 and now - lastClickAt < cooldown then return end
        lastClickAt = now
        state = not state
        btn.Text = state and onText or offText
        if callback then callback(state) end
        playMeow()
    end)
    return row, btn
end

local function createNumberInput(name, layoutOrder, initialValue, min, max, callback, opts)
    opts = opts or {}
    local suffix = opts.suffix
    local inputWidth = 60*scale

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22*scale)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = layoutOrder
    row.Parent = scrollFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -inputWidth - 4*scale, 1, 0)
    label.BackgroundTransparency = 1
    if suffix and #suffix > 0 then
        label.RichText = true
        local tinySize = math.floor(8 * scale)
        label.Text = name .. '  <font size="' .. tinySize .. '" color="#969696">' .. suffix .. '</font>'
        label.TextXAlignment = Enum.TextXAlignment.Center
    else
        label.Text = name
        label.TextXAlignment = Enum.TextXAlignment.Left
    end
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Parent = row
    local sc = Instance.new("UITextSizeConstraint")
    sc.MaxTextSize = math.floor(12*scale) sc.MinTextSize = 7 sc.Parent = label

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, inputWidth, 1, 0)
    box.Position = UDim2.new(1, 0, 0, 0)
    box.AnchorPoint = Vector2.new(1, 0)
    box.BackgroundColor3 = Color3.fromRGB(20,20,20)
    box.BackgroundTransparency = 0.2
    box.TextColor3 = Color3.fromRGB(255,255,255)
    box.Text = tostring(initialValue)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12*scale
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.Selectable = false
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6*scale)

    local lastValid = initialValue
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num == nil then box.Text = tostring(lastValid) return end
        num = math.clamp(num, min, max)
        lastValid = num
        box.Text = tostring(num)
        if callback then callback(num) end
    end)
    return row, box
end

createSectionHeader("Tracking", 1)
createSectionHeader("Main", 3)

createToggle("Auto Farm", 4, config.farmEnabled, function(state)
    config.farmEnabled = state
    if state then
        sessionStart = tick()
        sessionStartEarned = totalEarned
    else
        local wasMidSafeFarm = config.safeMethod and FarmPlatform ~= nil and FarmPlatform.Parent ~= nil
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        sessionStart = nil
        ClearPlatform()
        PreRoundActive = false
        do
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end
        if GravityApplied then
            workspace.Gravity = DefaultGravity
            GravityApplied = false
        end
        resetTimerLabels()

        if wasMidSafeFarm and hrp and hrp.Parent then
            task.delay(0.1, function()
                if hrp and hrp.Parent then
                    hrp.CFrame = hrp.CFrame + Vector3.new(0, 4, 0)
                end
            end)
        end
    end
    saveConfigs()
end)

createToggle("Coin Aura", 5, config.coinAura, function(state)
    config.coinAura = state
    saveConfigs()
end)

createSectionHeader("Configuration", 6)

createToggle("Farm Method", 7, config.safeMethod, function(state)
    config.safeMethod = state
    saveConfigs()
end, "[ SAFE ]", "[ STANDARD ]")

createToggle("Avoid Murderer", 8, config.avoidMurderer, function(state)
    config.avoidMurderer = state
    if not state then murdererPositions = {} end
    saveConfigs()
end)

createNumberInput("↑ Avoid Radius", 9, config.avoidRadius, 10, 50, function(v) config.avoidRadius = v saveConfigs() end)
createNumberInput("Speed", 10, config.speed, 10, 50, function(v) config.speed = v saveConfigs() end)
createNumberInput("Delay", 11, config.delay, 0, 5, function(v) config.delay = v saveConfigs() end)
createNumberInput("Coin Aura Radius", 12, config.coinAuraRadius, 0, 8, function(v) config.coinAuraRadius = v saveConfigs() end)

createNumberInput("Tilt", 12.2, config.safeTiltAngle, 0, 180, function(v)
    config.safeTiltAngle = v
    SAFE_TILT = CFrame.Angles(-math.rad(v), 0, 0)
    saveConfigs()
end)

createSectionHeader("Combat", 12.5)

createToggle("Auto Kill All", 12.6, config.autoKillAll, function(state)
    config.autoKillAll = state
    saveConfigs()
    if not state then stopKillLoop() end
end)

createToggle("Auto Shoot Murd", 12.7, config.autoShootMurd, function(state)
    config.autoShootMurd = state
    saveConfigs()
    if not state then stopShootLoop() end
end)

createToggle("Auto Hero", 12.8, config.autoHero, function(state)
    config.autoHero = state
    saveConfigs()
    if state then
        startGunListener()
    else
        stopGunListener()
        stopShootLoop()
    end
end)

createSectionHeader("Optimization", 13)

createToggle("Optimize Game", 14, config.optimizeGame, function(state)
    config.optimizeGame = state
    saveConfigs()
    if state then startOptimizeGame() else stopOptimizeGame() end
end)

createToggle("3D Rendering", 15, config.render3d, function(state)
    config.render3d = state
    saveConfigs()
    applyRender3d()
end)

local fpsValueBox = nil
local function setFpsValueEnabled(enabled)
    if not fpsValueBox then return end
    fpsValueBox.Active = enabled
    fpsValueBox.Selectable = enabled
    fpsValueBox.TextColor3 = enabled and Color3.fromRGB(255,255,255) or Color3.fromRGB(120,120,120)
    fpsValueBox.BackgroundTransparency = enabled and 0.2 or 0.45
    if not enabled then
        local focused = UserInputService:GetFocusedTextBox()
        if focused == fpsValueBox then focused:ReleaseFocus() end
    end
end

createToggle("Cap FPS", 16, config.capFps, function(state)
    config.capFps = state
    saveConfigs()
    setFpsValueEnabled(state)
    applyFpsCap()
end)

local _, fpsValueInput = createNumberInput("FPS Value", 17, config.fpsValue, 10, 240, function(v)
    config.fpsValue = v
    saveConfigs()
    if config.capFps then applyFpsCap() end
end)
fpsValueBox = fpsValueInput
setFpsValueEnabled(config.capFps)

createSectionHeader("Protection", 18)

createToggle("Anti AFK", 19, config.antiAfk, function(state)
    config.antiAfk = state
    saveConfigs()
    if state then startAntiAfk() else stopAntiAfk() end
end)

createToggle("Anti Fling", 20, config.antiFling, function(state)
    config.antiFling = state
    saveConfigs()
    if state then startAntiFling() else stopAntiFling() end
end)

createToggle("Anti Void", 21, config.antiVoid, function(state)
    config.antiVoid = state
    saveConfigs()
    if state then startAntiVoid() else stopAntiVoid() end
end)

createSectionHeader("Sounds & Visuals", 22)

createToggle("Disable SFX", 23, config.disableSfx, function(state) config.disableSfx = state saveConfigs() end)
createToggle("Disable GUI Animations", 24, config.disableGuiAnimations, function(state) config.disableGuiAnimations = state saveConfigs() end)

task.defer(remeasureSectionHeaders)

if config.antiAfk then startAntiAfk() end
if config.antiFling then startAntiFling() end
if config.antiVoid then startAntiVoid() end
if config.optimizeGame then startOptimizeGame() end
applyFpsCap()
applyRender3d()
if config.autoHero then startGunListener() end

local gameplayRemotes = ReplicatedStorage:FindFirstChild("Remotes")
local gameplayEvents = gameplayRemotes and gameplayRemotes:FindFirstChild("Gameplay")
local CoinCollectedRemote = gameplayEvents and gameplayEvents:FindFirstChild("CoinCollected")
local VictoryScreenRemote = gameplayEvents and gameplayEvents:FindFirstChild("VictoryScreen")
local RoundStartRemote = gameplayEvents and gameplayEvents:FindFirstChild("RoundStart")

if CoinCollectedRemote then
    track(CoinCollectedRemote.OnClientEvent:Connect(function(coinType, current, max, info)
        if config.farmEnabled then
            AddCoin(info and info.Value or 1)
        end

        if config.farmEnabled
           and current and max and current >= max
           and LocalPlayer:GetAttribute("Alive") == true then

            local didCombat = false
            local amKnifeHolder = hasKnifeOrMurderer()

            if config.autoKillAll and amKnifeHolder then
                startKillLoop()
                didCombat = true
            elseif not amKnifeHolder then
                if config.autoShootMurd and hasGun() and isMurdererStillAlive() then
                    startShootLoop("shoot")
                    didCombat = true
                elseif config.autoHero and isMurdererStillAlive() then
                    startShootLoop("hero")
                    didCombat = true
                end
            end

            if not didCombat then
                local char = LocalPlayer.Character
                if char then
                    pcall(function() char:BreakJoints() end)
                    task.wait(2)
                end
            end
        end
    end))
end

if VictoryScreenRemote then
    track(VictoryScreenRemote.OnClientEvent:Connect(function(won, role, reason, player, num)
        if won and LocalPlayer:GetAttribute("Alive") == true then
            local char = LocalPlayer.Character
            if char then
                pcall(function() char:BreakJoints() end)
                task.wait(1)
            end
        end
    end))
end

if RoundStartRemote then
    track(RoundStartRemote.OnClientEvent:Connect(function(roundTime, rolesTable)
        BadCoins = {}
        coinAreasStartTime = nil
        barnStartTime = nil
        barnResetDone = false
        NeedsRetarget = false
        if type(rolesTable) == "table" then
            rolesCache = rolesTable
        end
    end))
end

task.spawn(function()
    while LocalPlayer.Parent and not destroyed do
        local ok, data = pcall(function()
            return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
        end)
        if ok and data then rolesCache = data end
        task.wait(1.4)
    end
end)

task.spawn(function()
    while LocalPlayer.Parent and not destroyed do
        RunService.Heartbeat:Wait()
        if config.avoidMurderer then refreshMurdererPositions()
        elseif #murdererPositions > 0 then murdererPositions = {} end
    end
end)

task.spawn(function()
    while LocalPlayer.Parent and not destroyed do
        RunService.Heartbeat:Wait()
        local wasPreRoundActive = PreRoundActive
        local newPreRoundActive = false

        if IsBarnActive() then
            coinAreasWasActive = false
            if not barnStartTime then barnStartTime = tick() barnResetDone = false end
            if not barnResetDone and tick() - barnStartTime >= 15 then
                barnResetDone = true
                local char = LocalPlayer.Character
                if char then pcall(function() char:BreakJoints() end) end
            end
            coinAreasStartTime = nil
        else
            barnStartTime = nil
            barnResetDone = false
            if FindCoinAreas() then
                coinAreasWasActive = true
                if not coinAreasStartTime then coinAreasStartTime = tick() end
                local thresholdReached = (tick() - coinAreasStartTime) >= 10
                if config.farmEnabled and thresholdReached then
                    newPreRoundActive = true
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hrp then
                        if hum then hum.AutoRotate = false end
                        hrp.CFrame = CFrame.lookAt(PreRoundPos, PreRoundPos + FARM_DIRECTION)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            else
                if coinAreasWasActive then
                    coinAreasWasActive = false
                    if config.safeMethod then
                        local char = LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        killAllAnimations(hum)
                    end
                end
                coinAreasStartTime = nil
            end
        end

        PreRoundActive = newPreRoundActive

        if wasPreRoundActive and not PreRoundActive then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true end
        end
    end
end)

task.spawn(function()
    while LocalPlayer.Parent and not destroyed do
        RunService.Heartbeat:Wait()
        local farming = config.farmEnabled and LocalPlayer:GetAttribute("Alive") == true
        if farming then
            if not GravityApplied then
                workspace.Gravity = 0
                GravityApplied = true
            end
            if config.safeMethod and not PreRoundActive then
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                            safeCollisionsParts[part] = true
                        end
                    end
                end
            end
        else
            if GravityApplied then
                workspace.Gravity = DefaultGravity
                GravityApplied = false
            end
            for part in pairs(safeCollisionsParts) do
                if part and part.Parent then part.CanCollide = true end
            end
            table.clear(safeCollisionsParts)
        end
    end
end)

task.spawn(function()
    while LocalPlayer.Parent and not destroyed do
        RunService.Heartbeat:Wait()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local activelyFarming = config.farmEnabled and config.safeMethod
            and FarmPlatform and FarmPlatform.Parent
        if activelyFarming then
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if not safeMethodActive or safeMethodChar ~= char then
                safeMethodActive = true
                safeMethodChar = char
                applySafeState(hum)
            elseif animator and AnimKillConnection == nil then
                applySafeState(hum)
            end
        elseif safeMethodActive then
            safeMethodActive = false
            safeMethodChar = nil
            restoreStandardState(hum)
        end
    end
end)

task.spawn(function()
    while LocalPlayer.Parent and not destroyed do
        task.wait(0.05)
        if config.coinAura and LocalPlayer:GetAttribute("Alive") == true and not PreRoundActive then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local r = config.coinAuraRadius
                for _, c in ipairs(GetContainers()) do
                    for _, coin in ipairs(c:GetChildren()) do
                        if IsCoinAvailable(coin) then
                            local diff = hrp.Position - coin.Position
                            if math.abs(diff.X) <= r and math.abs(diff.Y) <= r and math.abs(diff.Z) <= r then
                                task.spawn(function()
                                    pcall(function()
                                        firetouchinterest(hrp, coin, 0)
                                        task.wait()
                                        firetouchinterest(hrp, coin, 1)
                                    end)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while LocalPlayer.Parent and not destroyed do
        task.wait(0.5)
        if config.farmEnabled and LocalPlayer:GetAttribute("Alive") == true and not PreRoundActive and not shootLoopActive and not killLoopActive then
            if not FarmPlatform or not FarmPlatform.Parent then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and hrp and hum then
                    local probeCoin = FindNearestCoin(hrp.Position)
                    if not probeCoin then
                        continue
                    end
                    hum.AutoRotate = false
                    local plat = BuildPlatform(char, hrp, hum)
                    lastAvoidRetargetCheck = 0
                    task.spawn(function()
                        while plat.Parent and char.Parent and not destroyed do
                            if not config.farmEnabled or not LocalPlayer:GetAttribute("Alive") or PreRoundActive or shootLoopActive or killLoopActive then
                                ClearPlatform()
                                break
                            end
                            NeedsRetarget = false
                            local coin, dist = FindNearestCoin(GetDistOrigin(plat, hrp))
                            if not coin then
                                FarmLockPos = plat.Position
                                task.wait(0.5)
                                continue
                            end
                            FarmLockPos = nil
                            local cp = coin.Position
                            local dest = Vector3.new(cp.X, cp.Y + GetYOffset(), cp.Z)
                            if dist and dist >= 150 then
                                local randomCoin = FindRandomSafeCoin()
                                if randomCoin then
                                    coin = randomCoin
                                    local rcp = randomCoin.Position
                                    dest = Vector3.new(rcp.X, rcp.Y + GetYOffset(), rcp.Z)
                                    local teleportY = config.safeMethod and (rcp.Y - 7.5) or (rcp.Y + 6.5)
                                    FarmLockPos = Vector3.new(rcp.X, teleportY, rcp.Z)
                                    if hrp.Parent then
                                        local baseCF = CFrame.lookAt(FarmLockPos, FarmLockPos + FARM_DIRECTION)
                                        if config.safeMethod then baseCF = baseCF * SAFE_TILT end
                                        hrp.CFrame = baseCF
                                    end
                                    task.wait(1)
                                    FarmLockPos = nil
                                end
                            end
                            MoveTo(plat, char, dest, function(_cur)
                                if not IsCoinAvailable(coin) or PreRoundActive then
                                    return "abort"
                                end
                                if not isCoinSafe(coin.Position) then
                                    local origin = GetDistOrigin(plat, hrp)
                                    local newCoin = FindNearestCoin(origin)
                                    if newCoin and newCoin ~= coin then
                                        coin = newCoin
                                        local ncp = newCoin.Position
                                        return "retarget", Vector3.new(ncp.X, ncp.Y + GetYOffset(), ncp.Z)
                                    end
                                    return "abort"
                                end
                                if NeedsRetarget then
                                    NeedsRetarget = false
                                    local origin = GetDistOrigin(plat, hrp)
                                    local liveDist = (origin - coin.Position).Magnitude
                                    local newCoin, newDist = FindNearestCoin(origin)
                                    if newCoin and newCoin ~= coin and newDist and newDist < liveDist and liveDist > RETARGET_MIN_DIST then
                                        coin = newCoin
                                        local ncp = newCoin.Position
                                        return "retarget", Vector3.new(ncp.X, ncp.Y + GetYOffset(), ncp.Z)
                                    end
                                end
                                if config.avoidMurderer then
                                    local now = tick()
                                    if now - lastAvoidRetargetCheck > 0.3 then
                                        lastAvoidRetargetCheck = now
                                        local origin = GetDistOrigin(plat, hrp)
                                        local liveDist = (origin - coin.Position).Magnitude
                                        local newCoin, newDist = FindNearestCoin(origin)
                                        if newCoin and newCoin ~= coin and newDist and (newDist + 0.5) < liveDist then
                                            coin = newCoin
                                            local ncp = newCoin.Position
                                            return "retarget", Vector3.new(ncp.X, ncp.Y + GetYOffset(), ncp.Z)
                                        end
                                    end
                                end
                            end)
                            if not plat.Parent or not char.Parent then break end
                            if IsCoinAvailable(coin) then
                                FarmLockPos = plat.Position
                                local stuckStart = tick()
                                while plat.Parent and char.Parent do
                                    RunService.Heartbeat:Wait()
                                    if PreRoundActive then break end
                                    if not IsCoinAvailable(coin) then break end
                                    if tick() - stuckStart >= StuckTime then
                                        BadCoins[coin] = true
                                        break
                                    end
                                end
                            end
                            if plat.Parent and char.Parent and not BadCoins[coin] then
                                FarmLockPos = plat.Position
                                task.wait(config.delay * 0.5)
                            end
                        end
                    end)
                end
            end
        else
            ClearPlatform()
        end
    end
end)

track(workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
        if obj:FindFirstChild("TouchInterest") then NeedsRetarget = true end
        obj:GetAttributeChangedSignal("Collected"):Connect(function()
            if obj:GetAttribute("Collected") == true then NeedsRetarget = true end
        end)
    elseif obj.Name == "TouchInterest" then
        local parent = obj.Parent
        if parent and parent:IsA("BasePart") and parent.Name == "Coin_Server" then
            NeedsRetarget = true
        end
    end
end))

track(LocalPlayer.CharacterAdded:Connect(function()
    stopKillLoop()
    stopShootLoop()
    ClearPlatform()
    BadCoins = {}
    safeMethodActive = false
    safeMethodChar = nil
    if AnimKillConnection then AnimKillConnection:Disconnect() AnimKillConnection = nil end
    table.clear(safeCollisionsParts)
    do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end
end))

local function setZIndexRecursive(obj, zIndex)
    if obj:IsA("GuiObject") and not obj.Name:find("FloatingParticle") then obj.ZIndex = zIndex end
    for _, child in ipairs(obj:GetChildren()) do setZIndexRecursive(child, zIndex) end
end
setZIndexRecursive(panel, 5)
if currentParticles and currentParticles.particles then
    for _, p in ipairs(currentParticles.particles) do if p.object then p.object.ZIndex = 0 end end
end

local dragStartPos = nil
local startFramePos = nil
local activeDragTouch = nil
local dragThresholdPixels = 5
local collapseAnimEnd = 0

panel.InputBegan:Connect(function(input)
    local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if not isMouse and not isTouch then return end
    if config.collapsed then return end
    if tick() < collapseAnimEnd then return end
    local touchY = input.Position.Y - panel.AbsolutePosition.Y
    if touchY > HEADER_HEIGHT then return end
    if isMouse then
        dragStartPos = input.Position
        startFramePos = panel.Position
    elseif isTouch then
        if activeDragTouch and activeDragTouch.UserInputState ~= Enum.UserInputState.End then return end
        dragStartPos = input.Position
        startFramePos = panel.Position
        activeDragTouch = input
    end
end)

panel.InputEnded:Connect(function(input)
    local isActiveMouse = input.UserInputType == Enum.UserInputType.MouseButton1
    local isActiveTouch = input.UserInputType == Enum.UserInputType.Touch and input == activeDragTouch
    if not isActiveMouse and not isActiveTouch then return end

    if isActiveTouch then
        activeDragTouch = nil
    end

    if dragStartPos and startFramePos then
        local currentPos = panel.Position
        local deltaX = currentPos.X.Offset - startFramePos.X.Offset
        local deltaY = currentPos.Y.Offset - startFramePos.Y.Offset
        if math.sqrt(deltaX^2 + deltaY^2) >= dragThresholdPixels and tick() >= collapseAnimEnd then
            local saveYOffset = currentPos.Y.Offset
            if collapsed then
                local expandedH = panelOriginalHeight * scale
                saveYOffset = saveYOffset + (expandedH - HEADER_HEIGHT) / 2
            end
            config.position = {XScale = currentPos.X.Scale, XOffset = currentPos.X.Offset,
                               YScale = currentPos.Y.Scale, YOffset = saveYOffset}
            saveState()
        end
    end
    dragStartPos = nil
    startFramePos = nil
end)

track(UserInputService.InputChanged:Connect(function(input)
    if not dragStartPos or not startFramePos then return end
    local isMouseMove = input.UserInputType == Enum.UserInputType.MouseMovement
    local isActiveTouch = input == activeDragTouch
    if isMouseMove or isActiveTouch then
        local delta = input.Position - dragStartPos
        panel.Position = UDim2.new(
            startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
            startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
    end
end))

local collapsed = false
local collapseTweenToken = 0
collapseBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    dragStartPos = nil
    startFramePos = nil
    activeDragTouch = nil
    collapseAnimEnd = tick() + 0.5
    collapseBtn.Image = collapsed and "rbxassetid://92023845052369" or "rbxassetid://137805819128674"

    local expandedH = panelOriginalHeight * scale
    local collapsedH = HEADER_HEIGHT
    local targetHeight = collapsed and collapsedH or expandedH
    local targetYOffset = collapsed and (config.position.YOffset - (expandedH - collapsedH) / 2) or config.position.YOffset

    local newSize = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, targetHeight)
    local newPos = UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset, panel.Position.Y.Scale, targetYOffset)

    collapseTweenToken = collapseTweenToken + 1
    local myToken = collapseTweenToken

    if not collapsed then
        for _, child in pairs(panel:GetChildren()) do
            if child ~= header and not child.Name:find("FloatingParticle") and child:IsA("GuiObject") then
                child.Visible = true
                child.Active = true
            end
        end
    else
        for _, child in pairs(panel:GetChildren()) do
            if child ~= header and not child.Name:find("FloatingParticle") and child:IsA("GuiObject") then
                child.Active = false
            end
        end
    end

    local function hideChildren()
        for _, child in pairs(panel:GetChildren()) do
            if child ~= header and not child.Name:find("FloatingParticle") and child:IsA("GuiObject") then
                child.Visible = false
            end
        end
    end

    if config.disableGuiAnimations then
        panel.Size = newSize
        panel.Position = newPos
        if collapsed then hideChildren() end
    else
        local tween = TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = newSize, Position = newPos})
        tween:Play()
        if collapsed then
            tween.Completed:Connect(function()
                if destroyed or myToken ~= collapseTweenToken or not collapsed then return end
                hideChildren()
            end)
        end
    end

    if collapsed then createParticles(panel, 5) else createParticles(panel, 10) end
    if currentParticles and currentParticles.particles then
        for _, p in ipairs(currentParticles.particles) do if p.object then p.object.ZIndex = 0 end end
    end
    config.collapsed = collapsed
    saveState()
end)

if config.collapsed then
    collapsed = true
    collapseBtn.Image = "rbxassetid://92023845052369"
    local deltaY = (HEADER_HEIGHT - panel.Size.Y.Offset) / 2
    panel.Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, HEADER_HEIGHT)
    panel.Position = UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset, panel.Position.Y.Scale, panel.Position.Y.Offset + deltaY)
    for _, child in pairs(panel:GetChildren()) do
        if child ~= header and not child.Name:find("FloatingParticle") and child:IsA("GuiObject") then
            child.Visible = false child.Active = false
        end
    end
    createParticles(panel, 5)
    if currentParticles and currentParticles.particles then
        for _, p in ipairs(currentParticles.particles) do if p.object then p.object.ZIndex = 0 end end
    end
end

local function playRevealAnimation()
    if destroyed then return end
    if config.disableGuiAnimations then remeasureSectionHeaders() return end
    local finalWidth, finalHeight = panel.Size.X.Offset, panel.Size.Y.Offset
    local restoreTweens = {}
    local function collectReveal(obj)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local t1, t2, t3 = obj.TextTransparency, obj.BackgroundTransparency, obj.TextStrokeTransparency
            obj.TextTransparency, obj.BackgroundTransparency, obj.TextStrokeTransparency = 1, 1, 1
            table.insert(restoreTweens, TweenService:Create(obj, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency=t1, BackgroundTransparency=t2, TextStrokeTransparency=t3}))
        elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            local t1, t2 = obj.ImageTransparency, obj.BackgroundTransparency
            obj.ImageTransparency, obj.BackgroundTransparency = 1, 1
            table.insert(restoreTweens, TweenService:Create(obj, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {ImageTransparency=t1, BackgroundTransparency=t2}))
        elseif obj:IsA("Frame") then
            local t = obj.BackgroundTransparency
            obj.BackgroundTransparency = 1
            table.insert(restoreTweens, TweenService:Create(obj, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency=t}))
        elseif obj:IsA("UIStroke") then
            local t = obj.Transparency
            obj.Transparency = 1
            table.insert(restoreTweens, TweenService:Create(obj, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency=t}))
        end
        for _, child in ipairs(obj:GetChildren()) do collectReveal(child) end
    end
    panel.ClipsDescendants = true
    panel.Size = UDim2.new(0, 0, 0, 0)
    collectReveal(panel)
    local growHeight = TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,0,0,finalHeight)})
    table.insert(revealTweens, growHeight) growHeight:Play()
    growHeight.Completed:Connect(function()
        if destroyed then return end
        local growWidth = TweenService:Create(panel, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0,finalWidth,0,finalHeight)})
        table.insert(revealTweens, growWidth) growWidth:Play()
        growWidth.Completed:Connect(function()
            if destroyed then return end
            panel.ClipsDescendants = false
            remeasureSectionHeaders()
        end)
    end)
    for _, t in ipairs(restoreTweens) do table.insert(revealTweens, t) t:Play() end
end
task.spawn(playRevealAnimation)

task.spawn(function()
    local purrPath = SFX_DIR .. "/purr.mp3"
    local ok, result = pcall(function()
        writefile(purrPath, game:HttpGet(soundUrls.purr))
        return getcustomasset(purrPath)
    end)
    if ok and result then
        local s = Instance.new("Sound")
        s.Name = "9lives_purr" s.SoundId = result s.Volume = 1 s.Parent = SoundService
        sounds.purr = s
        playPurr()
    end
    for name, url in pairs(soundUrls) do
        if name == "purr" then continue end
        local fpath = SFX_DIR .. "/" .. name .. ".mp3"
        local ok2, result2 = pcall(function()
            writefile(fpath, game:HttpGet(url))
            return getcustomasset(fpath)
        end)
        if ok2 and result2 then
            local s = Instance.new("Sound")
            s.Name = "9lives_" .. name s.SoundId = result2 s.Volume = 0.5 s.Parent = SoundService
            sounds[name] = s
        end
    end
end)

local function collectFadeTweens(root, tweenInfo)
    local tweens = {}
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            table.insert(tweens, TweenService:Create(obj, tweenInfo, {TextTransparency=1, BackgroundTransparency=1, TextStrokeTransparency=1}))
        elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            table.insert(tweens, TweenService:Create(obj, tweenInfo, {ImageTransparency=1, BackgroundTransparency=1}))
        elseif obj:IsA("Frame") then
            table.insert(tweens, TweenService:Create(obj, tweenInfo, {BackgroundTransparency=1}))
        elseif obj:IsA("UIStroke") then
            table.insert(tweens, TweenService:Create(obj, tweenInfo, {Transparency=1}))
        end
    end
    return tweens
end

local function shutdown()
    if destroyed then return end
    destroyed = true
    saveState()
    playHiss()

    config.farmEnabled = false
    config.coinAura = false
    ClearPlatform()
    do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end

    safeMethodActive = false
    safeMethodChar = nil
    if AnimKillConnection then AnimKillConnection:Disconnect() AnimKillConnection = nil end
    do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then restoreStandardState(hum) end
    end
    for part in pairs(safeCollisionsParts) do
        if part and part.Parent then part.CanCollide = true end
    end
    table.clear(safeCollisionsParts)

    if GravityApplied then workspace.Gravity = DefaultGravity GravityApplied = false end

    if render3dOverlay then render3dOverlay:Destroy() render3dOverlay = nil
        pcall(function() RunService:Set3DRenderingEnabled(true) end) end
    if gunListenerConn then stopGunListener() end
    if killLoopActive then stopKillLoop() end
    if shootLoopActive then stopShootLoop() end
    if optimizeActive then stopOptimizeGame() end
    if antiVoidPart then stopAntiVoid() end
    if antiFlingActive then stopAntiFling() end
    if antiAfkActive then stopAntiAfk() end

    for _, t in ipairs(revealTweens) do pcall(function() t:Cancel() end) end
    table.clear(revealTweens)
    if currentParticles then currentParticles.running = false end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)

    panel.Active = false
    panel.ClipsDescendants = true
    dragStartPos = nil startFramePos = nil activeDragTouch = nil

    if config.disableGuiAnimations then
        if gui then gui:Destroy() end
        return
    end
    local fadeInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    for _, t in ipairs(collectFadeTweens(gui, fadeInfo)) do t:Play() end
    local squeeze = TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, panel.Size.Y.Offset)})
    squeeze:Play() squeeze.Completed:Wait()
    local vanish = TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
    vanish:Play() vanish.Completed:Wait()
    if gui then gui:Destroy() end
end

closeBtn.MouseButton1Click:Connect(shutdown)

track(gui.Destroying:Connect(function()
    destroyed = true
    config.farmEnabled = false
    config.coinAura = false
    ClearPlatform()
    do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end

    safeMethodActive = false
    safeMethodChar = nil
    if AnimKillConnection then AnimKillConnection:Disconnect() AnimKillConnection = nil end
    do
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then restoreStandardState(hum) end
    end
    for part in pairs(safeCollisionsParts) do
        if part and part.Parent then part.CanCollide = true end
    end
    table.clear(safeCollisionsParts)

    if GravityApplied then workspace.Gravity = DefaultGravity GravityApplied = false end

    if gunListenerConn then stopGunListener() end
    if killLoopActive then stopKillLoop() end
    if shootLoopActive then stopShootLoop() end
    if antiVoidPart then stopAntiVoid() end
    if antiFlingActive then stopAntiFling() end
    if antiAfkActive then stopAntiAfk() end
    if optimizeActive then stopOptimizeGame() end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
    for _, t in ipairs(revealTweens) do pcall(function() t:Cancel() end) end
    table.clear(revealTweens)
    for _, s in pairs(sounds) do pcall(function() s:Destroy() end) end
    table.clear(sounds)
    if currentParticles then currentParticles.running = false end
end))

local function makeBlankNames(obj)
    obj.Name = blankName(20)
    for _, child in ipairs(obj:GetChildren()) do makeBlankNames(child) end
end
makeBlankNames(gui)
