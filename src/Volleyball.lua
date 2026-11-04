local HttpService = game:GetService("HttpService")

local function PostLoad(file)
  local ok, res = pcall(function()
    return request({
      Url = "https://blazewave.pages.dev/load",
      Method = "POST",
      Headers = { ["Content-Type"] = "application/json" },
      Body = HttpService:JSONEncode({ auth_key = "", file = file })
    })
  end)
  if ok and res and res.Success then return res end
end

local lib = PostLoad("src/Library.lua")
local Library = loadstring(lib.Body)()

local gl = PostLoad("gamelist.lua")
local GameList = loadstring(gl.Body)()

local scriptFile = GameList[game.GameId]
if scriptFile then
  local sr = PostLoad(scriptFile)
  if sr then
    loadstring(sr.Body)()
  end
end

local function Notify(options)
  Library:Notification(options.Title or "", options.Content, options.Duration or 3)
end


local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local _AC = require(game:GetService("ReplicatedFirst").Controllers.AnimationController)

local MARK = string.char(math.random(97, 122), math.random(97, 122), math.random(97, 122)) .. tostring(math.random(100000, 999999))
local MARK2 = string.char(math.random(97, 122), math.random(97, 122), math.random(97, 122)) .. tostring(math.random(100000, 999999))

local BallService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService
local Serve = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RF.Serve
local EffectsRemote = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService.RE.Effects
local doMove = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService.RE.DoMove
local StopAllEmotes = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.AnimationService.RE.StopAllEmotes
local GameEffectRemote = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.GameService.RE.Effect

local Hitbox = (function()
  local Config = {
    Enabled = true,
    SizeMultiplier = 5,
    Color = Color3.fromRGB(0, 0, 255),
    Transparency = 0.3,
    Material = Enum.Material.ForceField,
    CanCollide = false,
    CanQuery = true,
    CanTouch = true,
    CastShadow = true,
  }

  local M = {}

  local originalSizes = {}
  local updateConn = nil

  local function getTargetModel()
    for _, model in ipairs(Workspace:GetChildren()) do
      if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
        return model
      end
    end
    return nil
  end

  local function storeOriginal(model)
    if originalSizes[model] then return end

    originalSizes[model] = {}

    for _, part in ipairs(model:GetDescendants()) do
      if part:IsA("BasePart") then
        originalSizes[model][part] = {
          Size = part.Size,
          Color = part.Color,
          Transparency = part.Transparency,
          Material = part.Material,
          CanCollide = part.CanCollide,
          CanQuery = part.CanQuery,
          CanTouch = part.CanTouch,
          CastShadow = part.CastShadow,
        }
      end
    end
  end

  local function applyBigger(model)
    if not model then return end

    storeOriginal(model)

    for part, original in pairs(originalSizes[model]) do
      if part and part.Parent then
        local newSize = original.Size * Config.SizeMultiplier
        if part.Size ~= newSize then part.Size = newSize end
        if part.Color ~= Config.Color then part.Color = Config.Color end
        if part.Transparency ~= Config.Transparency then part.Transparency = Config.Transparency end
        if part.Material ~= Config.Material then part.Material = Config.Material end
        if part.CanCollide ~= Config.CanCollide then part.CanCollide = Config.CanCollide end
        if part.CanQuery ~= Config.CanQuery then part.CanQuery = Config.CanQuery end
        if part.CanTouch ~= Config.CanTouch then part.CanTouch = Config.CanTouch end
        if part.CastShadow ~= Config.CastShadow then part.CastShadow = Config.CastShadow end
      end
    end
  end

  local function restoreOriginal(model)
    if not model or not originalSizes[model] then return end

    for part, original in pairs(originalSizes[model]) do
      if part and part.Parent then
        part.Size = original.Size
        part.Color = original.Color
        part.Transparency = original.Transparency
        part.Material = original.Material
        part.CanCollide = original.CanCollide
        part.CanQuery = original.CanQuery
        part.CanTouch = original.CanTouch
        part.CastShadow = original.CastShadow
      end
    end

    originalSizes[model] = nil
  end

  local lastUpdate = 0

  local function update()
    local now = os.clock()
    if now - lastUpdate < 0.1 then return end
    lastUpdate = now

    local model = getTargetModel()

    if not model then return end

    if not Config.Enabled then
      restoreOriginal(model)
      return
    end

    applyBigger(model)
  end

  function M.enable()
    if updateConn then return end
    updateConn = RunService.Heartbeat:Connect(update)
  end

  function M.disable()
    if updateConn then
      updateConn:Disconnect()
      updateConn = nil
    end

    for model in pairs(originalSizes) do
      restoreOriginal(model)
    end

    originalSizes = {}
  end

  function M.setSize(mult)
    for model in pairs(originalSizes) do
      restoreOriginal(model)
    end
    Config.SizeMultiplier = mult
    originalSizes = {}
  end

  function M.setColor(color)
    Config.Color = color
  end

  function M.setTransparency(transparency)
    Config.Transparency = transparency
  end

  function M.setCanCollide(value)
    Config.CanCollide = value
  end

  function M.setCanTouch(value)
    Config.CanTouch = value
  end

  function M.setCastShadow(value)
    Config.CastShadow = value
  end

  return M
end)()

local hitboxEnabled = false
local hitboxScale = 5.0
local hitboxColor = Color3.fromRGB(255, 80, 80)
local hitboxTransparency = 0.3

local function enableHitbox() hitboxEnabled = true Hitbox.enable() end
local function disableHitbox() hitboxEnabled = false Hitbox.disable() end
local function setHitboxScale(scale) hitboxScale = scale or 5 Hitbox.setSize(hitboxScale) end
local function setHitboxColor(color) hitboxColor = color or Color3.fromRGB(255, 80, 80) Hitbox.setColor(hitboxColor) end
local function setHitboxTransparency(t) hitboxTransparency = t or 0.3 Hitbox.setTransparency(hitboxTransparency) end

local function getBallId()
  for _, model in ipairs(Workspace:GetChildren()) do
    if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
      local id = model.Name:match("%d+")
      if id then return tonumber(id) end
    end
  end
  return nil
end

local function getNearestBall()
  local nearestBall, nearestDistance = nil, math.huge
  local character = LocalPlayer.Character
  if not character then return nil end
  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return nil end
  for _, model in ipairs(Workspace:GetChildren()) do
    if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
      for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
          local distance = (part.Position - rootPart.Position).Magnitude
          if distance < nearestDistance then
            nearestDistance = distance
            nearestBall = part
          end
          break
        end
      end
    end
  end
  return nearestBall
end

local function getBallRoot()
  for _, model in ipairs(Workspace:GetChildren()) do
    if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
      for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part end
      end
    end
  end
  return nil
end

local function getHRP()
  local c = LocalPlayer.Character
  return c and c:FindFirstChild("HumanoidRootPart")
end

local redirectSpikeEnabled = false
local redirectSpikeInstalled = false
local sanjuTiltEnabled = false
local sanjuTiltInstalled = false
local maxChargeEnabled = false
local maxChargeHookActive = false
local mtMaxCharge = nil
local oldNamecallMaxCharge = nil
local newSilentSpikeEnabled = false
local newSpikeButton = nil
local stopBallButton = nil
local aimButton = nil
local stopBallVisible = false
local aimVisible = false
local dashButton = nil
local akariDashEnabled = false
local leadFeetEnabled = false
local leadFeetButton = nil
local leadFeetLink = nil
local espJumpEnabled = false
local espHighlights = {}
local espConnections = {}
local desyncEnabled = false
local desyncConnection = nil
local maxServeEnabled = false
local maxServeHookActive = false
local mtMaxServe = nil
local oldNamecallMaxServe = nil
local airMovement = false
local airMovementSpeed = 16
local bodyVelocity = nil
local autoShiftLockEnabled = false
local shiftLockConnection = nil
local hitEffectEnabled = false
local selectedEffect = "SupernovaScoreEffect"
local hasFired = false
local isLocalHit = false
local hitConnection = nil
local hitConnection2 = nil
local hitRemovedConnection = nil
local effectList = {}
local playerCardEnabled = false
local selectedCard = "UltimateChampionPlayerCard"
local hasFiredCard = false
local isProcessing = false
local cardConnection = nil
local cardList = {}
local selectedJersey = "DragonTuxedoJersey"
local pickedTeam = nil
local jerseyList = {}
local selectedBallSkin = "ClassicBall"
local ballSkinList = {}
local autoSpin = false
local autoAbilitySpin = false
local desiredStyles = {}
local desiredAbilities = {}
local spinType = "Normal"
local abilitySpinType = "Normal"
local autoApplyJersey = false
local autoApplyBallSkin = false
local fakeSpikeEnabled = false
local tshAnimationEnabled = false
local hidariAnimationEnabled = false
local kazanaBlueEnabled = false
local kazanaWhiteEnabled = false

local originals = {}
local clones = {}
local seen = {}

local linesEnabled = false
local lineDistance = 50
local lines = {}
local lineColors = {
  Color3.fromRGB(255, 0, 0),
  Color3.fromRGB(0, 255, 0),
  Color3.fromRGB(0, 0, 255),
  Color3.fromRGB(255, 165, 0),
  Color3.fromRGB(128, 0, 128),
  Color3.fromRGB(255, 255, 0),
  Color3.fromRGB(139, 0, 0),
  Color3.fromRGB(0, 100, 0)
}

local changedProperties = {}
local oldQualityLevel
local oldSavedQualityLevel
local antilagConnections = {}

local AutoFarm = {
  enabled = false,
  gui = nil,
  loopThread = nil,
  heartbeatLink = nil,
  state = { tp = false, block = false, spike = false, jump = false, interval = 0.05 },
  jumpState = false,
}

function AutoFarm:getRemotes()
  if self.remotes then return self.remotes end
  local svc = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService
  self.remotes = {
    CreateHitbox = svc.RF:FindFirstChild("CreateHitbox"),
    Interact = svc.RF:FindFirstChild("Interact"),
    Jump = svc.RF:FindFirstChild("Jump"),
    UpdateTilt = svc.RF:FindFirstChild("UpdateTilt"),
  }
  return self.remotes
end

function AutoFarm:getBall()
  if self.cachedBall and self.cachedBall.Parent and self.cachedBallPart and self.cachedBallPart.Parent then
    return self.cachedBallPart, self.cachedBallId
  end
  self.cachedBall, self.cachedBallPart, self.cachedBallId = nil, nil, nil
  for _, v in ipairs(Workspace:GetChildren()) do
    if typeof(v.Name) == "string" and v.Name:sub(1, 12) == "CLIENT_BALL_" then
      local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart", true)
      if part then
        local id = tonumber(v.Name:sub(13)) or v:GetAttribute("ServerId") or v:GetAttribute("Id")
        if id then
          self.cachedBall, self.cachedBallPart, self.cachedBallId = v, part, id
          return part, id
        end
      end
    end
  end
  return nil, 0
end

function AutoFarm:timestamp()
  local t = Workspace:GetServerTimeNow()
  if typeof(t) == "number" then return t end
  return tick()
end

function AutoFarm:buildGUI()
  if self.gui then return end
  local sg = Instance.new("ScreenGui")
  sg.Name = MARK .. "_Farm"
  sg.ResetOnSpawn = false
  sg.IgnoreGuiInset = true
  sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  sg.DisplayOrder = 9999

  local placed = false
  if type(gethui) == "function" then
    local ok, container = pcall(gethui)
    if ok and typeof(container) == "Instance" then
      sg.Parent = container
      placed = true
    end
  end
  if not placed then
    local ok = pcall(function()
      sg.Parent = game:GetService("CoreGui")
    end)
    if ok then placed = true end
  end
  if not placed then
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
  end

  local f = Instance.new("Frame")
  f.Size = UDim2.new(0, 150, 0, 175)
  f.Position = UDim2.new(0.05, 0, 0.3, 0)
  f.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
  f.BorderSizePixel = 0
  f.Active = true
  f.Draggable = true
  f.Parent = sg
  local fc = Instance.new("UICorner", f)
  fc.CornerRadius = UDim.new(0, 8)

  local title = Instance.new("TextLabel", f)
  title.Size = UDim2.new(1, 0, 0, 22)
  title.BackgroundTransparency = 1
  title.Text = "Auto Farm"
  title.TextColor3 = Color3.fromRGB(238, 240, 248)
  title.Font = Enum.Font.GothamBold
  title.TextSize = 13

  local function mkTog(y, txt, key)
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(0, 134, 0, 24)
    b.Position = UDim2.new(0, 8, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    b.Text = txt .. " OFF"
    b.TextColor3 = Color3.fromRGB(238, 240, 248)
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    local bc = Instance.new("UICorner", b)
    bc.CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
      self.state[key] = not self.state[key]
      b.Text = txt .. " " .. (self.state[key] and "ON" or "OFF")
      b.BackgroundColor3 = self.state[key] and Color3.fromRGB(0, 140, 0) or Color3.fromRGB(55, 55, 55)
    end)
  end

  mkTog(26, "TP", "tp")
  mkTog(54, "BALL", "block")
  mkTog(82, "SPIKE", "spike")
  mkTog(110, "JUMP", "jump")

  local tb = Instance.new("TextBox", f)
  tb.Size = UDim2.new(0, 134, 0, 24)
  tb.Position = UDim2.new(0, 8, 0, 140)
  tb.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
  tb.Text = "0.05"
  tb.PlaceholderText = "interval"
  tb.TextColor3 = Color3.fromRGB(238, 240, 248)
  tb.TextSize = 13
  tb.Font = Enum.Font.GothamMedium
  tb.ClearTextOnFocus = false
  local tc = Instance.new("UICorner", tb)
  tc.CornerRadius = UDim.new(0, 6)
  tb:GetPropertyChangedSignal("Text"):Connect(function()
    self.state.interval = tonumber(tb.Text) or 0.05
  end)

  self.gui = sg
end

function AutoFarm:start()
  if self.enabled then return end
  self.enabled = true
  self:buildGUI()
  self:getRemotes()

  if self.heartbeatLink then self.heartbeatLink:Disconnect() end
  self.heartbeatLink = RunService.Heartbeat:Connect(function()
    if not self.enabled or not self.state.tp then return end
    local ball = select(1, self:getBall())
    local hrp = getHRP()
    if ball and hrp then hrp.CFrame = ball.CFrame end
  end)

  self.loopThread = task.spawn(function()
    while self.enabled do
      local waitT = self.state.interval or 0.05
      local ball, bid = self:getBall()
      local hrp = getHRP()
      local look = Camera and Camera.CFrame.LookVector or Vector3.new(0, 0, -1)
      local move = hrp and hrp.CFrame.LookVector or Vector3.zero
      local tilt = Vector3.new(0, 1, 0)
      local ts = self:timestamp()
      local remotes = self.remotes

      if self.state.block and bid ~= 0 and ball and remotes.CreateHitbox and remotes.Interact then
        local key = "Block" .. math.random(1000000, 9999999)
        remotes.CreateHitbox:InvokeServer({
          BallId = bid, Charge = 1, Key = key,
          ClientTimestamp = ts, Move = "Block"
        })
        remotes.Interact:InvokeServer({
          Charge = 1, Move = "Block", SpecialCharge = 0,
          TiltDirection = tilt, BallId = bid, MoveDirection = move,
          Key = key, From = "Client", LookVector = look,
          Timestamp = ts, ClientCanRunSpecial = false, CustomClient = {}
        })
      end

      if self.state.spike and bid ~= 0 and ball and remotes.Interact then
        local realTilt = Vector3.new(look.X, 1, look.Z)
        remotes.Interact:InvokeServer({
          Charge = 1, Move = "Spike", SpecialCharge = 0,
          TiltDirection = realTilt, LookVector = look,
          MoveDirection = move, ClientCanRunSpecial = false,
          From = "Client", Timestamp = ts, BallId = bid, CustomClient = {}
        })
      end

      if self.state.jump and remotes.Jump then
        self.jumpState = not self.jumpState
        remotes.Jump:InvokeServer(self.jumpState)
      end

      task.wait(waitT)
    end
  end)
end

function AutoFarm:stop()
  self.enabled = false
  if self.heartbeatLink then self.heartbeatLink:Disconnect() self.heartbeatLink = nil end
  self.loopThread = nil
  self.state.tp = false
  self.state.block = false
  self.state.spike = false
  self.state.jump = false
  self.jumpState = false
  if self.gui then self.gui:Destroy() self.gui = nil end
end

local AutoCounter = {
  enabled = false,
  move = "Auto",
  netRange = 9,
  lateral = 14,
  reach = 16,
  delay = 0.05,
  cooldown = 0.5,
  autoJump = false,
  handlers = nil,
  controller = nil,
  firing = false,
  lastFire = 0,
}

function AutoCounter:bind()
  if self.handlers and self.controller then return true end
  local restore = getthreadidentity and getthreadidentity()
  if setthreadidentity then setthreadidentity(2) end
  self.handlers = require(game:GetService("ReplicatedFirst").Controllers.GameController.Handlers)
  self.controller = require(ReplicatedStorage.Packages.Knit).GetController("GameController")
  if setthreadidentity and restore then setthreadidentity(restore) end
  return self.handlers ~= nil and self.controller ~= nil
end

function AutoCounter:getNet()
  local tagged = CollectionService:GetTagged("Net")[1]
  if tagged and tagged:IsA("BasePart") then return tagged end
  local map = Workspace:FindFirstChild("Map")
  local collide = map and map:FindFirstChild("BallCollideOnly")
  return collide and collide:FindFirstChild("Net")
end

function AutoCounter:ownSide(root, netZ)
  local team = LocalPlayer.Team
  local index = team and team:GetAttribute("Index")
  if index == 1 then return -1 end
  if index == 2 then return 1 end
  return (root.Position.Z >= netZ) and 1 or -1
end

function AutoCounter:findThreat(root, net)
  local netZ = net.Position.Z
  local netTop = net.Position.Y + net.Size.Y * 0.5
  local side = self:ownSide(root, netZ)
  local myGap = (root.Position.Z - netZ) * side
  if myGap < 0 or myGap > self.netRange then return nil end
  local ball = getNearestBall()
  if not ball then return nil end
  if ball.Position.Y < netTop - 3 then return nil end
  if math.abs(ball.Position.Z - netZ) > self.netRange + 6 then return nil end
  if math.abs(ball.Position.X - root.Position.X) > self.lateral then return nil end
  local myTeam = LocalPlayer.Team
  for _, player in ipairs(Players:GetPlayers()) do
    local hostile = player ~= LocalPlayer and (myTeam == nil or player.Team ~= myTeam)
    if hostile then
      local character = player.Character
      local enemyRoot = character and character:FindFirstChild("HumanoidRootPart")
      if enemyRoot and character:GetAttribute("Jumping") then
        local enemyGap = (enemyRoot.Position.Z - netZ) * side
        if enemyGap < 0 and -enemyGap <= self.netRange + 4
          and (ball.Position - enemyRoot.Position).Magnitude <= self.reach
          and math.abs(enemyRoot.Position.X - root.Position.X) <= self.lateral then
          return ball, netZ, side
        end
      end
    end
  end
  return nil
end

function AutoCounter:pickMove(ball, netZ, side)
  if self.move ~= "Auto" then return self.move end
  if (ball.Position.Z - netZ) * side > 0 then return "Spike" end
  return "Block"
end

function AutoCounter:fire(move)
  if not self:bind() then return end
  local states = self.handlers.States
  if states.IsBusy:get() or states.IsStunned:get() or states.IsServing:get() then return end
  if not states.IsPlaying:get() then return end
  if ReplicatedStorage:GetAttribute("ServedByTeam") then return end
  self.firing = true
  task.spawn(function()
    local restore = getthreadidentity and getthreadidentity()
    if setthreadidentity then setthreadidentity(2) end
    if self.autoJump and not states.IsJumping:get() then
      self.controller:PerformJump()
    end
    if self.delay > 0 then task.wait(self.delay) end
    self.controller:DoMove({
      ActionName = move, IsAerial = true,
      InputState = Enum.UserInputState.Begin, Metadata = {}
    })
    if setthreadidentity and restore then setthreadidentity(restore) end
    self.lastFire = os.clock()
    self.firing = false
  end)
end

function AutoCounter:step()
  if not self.enabled or self.firing then return end
  if os.clock() - self.lastFire < self.cooldown then return end
  local character = LocalPlayer.Character
  local root = character and character:FindFirstChild("HumanoidRootPart")
  if not root then return end
  local net = self:getNet()
  if not net then return end
  local ball, netZ, side = self:findThreat(root, net)
  if not ball then return end
  self:fire(self:pickMove(ball, netZ, side))
end

RunService.Heartbeat:Connect(function()
  AutoCounter:step()
end)

local SAGEBAIT = {
  NameTag = "ZERITH  PROTECTION",
  Title = "<font color='#FF0000'><b>Pro</b></font>",
  NotifConn = nil, NotifConn2 = nil, CardLoopConn = nil, CharWatcher = nil,
  Enabled = false,
}

local function updateNametag()
  if not SAGEBAIT.Enabled then return end
  local player = LocalPlayer
  if player and player.Character then
    local nameTag = player.Character:FindFirstChild("Nametag")
    if nameTag then
      local label = nameTag:FindFirstChild("PlayerName")
      if label and label:IsA("TextLabel") then label.Text = SAGEBAIT.NameTag end
    end
  end
end

local function updateTitle()
  if not SAGEBAIT.Enabled then return end
  if LocalPlayer then LocalPlayer:SetAttribute("User_Title", SAGEBAIT.Title) end
end

local function processNotification(notification)
  if not SAGEBAIT.Enabled or not notification then return end
  local player = LocalPlayer
  if not player then return end
  task.wait(0.2)
  if not SAGEBAIT.Enabled then return end
  local textLabel = notification:FindFirstChild("TextLabel")
  if not textLabel then
    for _, child in ipairs(notification:GetDescendants()) do
      if child:IsA("TextLabel") then textLabel = child break end
    end
  end
  if not textLabel then return end
  local text = textLabel.Text or ""
  if string.find(text, player.Name) then
    textLabel.Text = string.gsub(text, player.Name, SAGEBAIT.NameTag)
  end
end

local function setupNotifications()
  if SAGEBAIT.NotifConn then SAGEBAIT.NotifConn:Disconnect() SAGEBAIT.NotifConn = nil end
  if SAGEBAIT.NotifConn2 then SAGEBAIT.NotifConn2:Disconnect() SAGEBAIT.NotifConn2 = nil end
  if not SAGEBAIT.Enabled then return end
  local player = LocalPlayer
  if not player then return end
  local gui = player.PlayerGui:FindFirstChild("Interface")
  if gui then
    gui = gui:FindFirstChild("Persistent")
    if gui then gui = gui:FindFirstChild("Notifications") end
  end
  if not gui then return end
  for _, child in ipairs(gui:GetChildren()) do processNotification(child) end
  SAGEBAIT.NotifConn = gui.ChildAdded:Connect(function(child) processNotification(child) end)
  SAGEBAIT.NotifConn2 = gui.DescendantAdded:Connect(function(child)
    if child:IsA("TextLabel") then processNotification(child) end
  end)
end

local function protectPlayerCard()
  if not SAGEBAIT.Enabled then return end
  local playerName = string.upper(LocalPlayer.Name)
  local persistent = LocalPlayer.PlayerGui:FindFirstChild("Interface")
  if persistent then
    persistent = persistent:FindFirstChild("Persistent")
    if persistent then
      for _, child in ipairs(persistent:GetChildren()) do
        if child.Name == "FlashPlayerCardFrame" then
          local username = child:FindFirstChild("Username", true)
          if username and username:IsA("TextLabel") then
            local currentText = string.upper(username.Text or "")
            if string.find(currentText, playerName) then username.Text = SAGEBAIT.NameTag end
          end
        end
      end
    end
  end
end

local function startCardLoop()
  if SAGEBAIT.CardLoopConn then SAGEBAIT.CardLoopConn:Disconnect() SAGEBAIT.CardLoopConn = nil end
  if not SAGEBAIT.Enabled then return end
  SAGEBAIT.CardLoopConn = RunService.Heartbeat:Connect(protectPlayerCard)
end

local function stopCardLoop()
  if SAGEBAIT.CardLoopConn then SAGEBAIT.CardLoopConn:Disconnect() SAGEBAIT.CardLoopConn = nil end
end

local function installCharacterWatcher()
  if SAGEBAIT.CharWatcher then SAGEBAIT.CharWatcher:Disconnect() SAGEBAIT.CharWatcher = nil end
  if not SAGEBAIT.Enabled then return end
  SAGEBAIT.CharWatcher = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateNametag()
    updateTitle()
    setupNotifications()
  end)
end

local function toggleProtection(state)
  SAGEBAIT.Enabled = state and true or false
  if state then
    updateNametag(); updateTitle(); setupNotifications()
    startCardLoop(); installCharacterWatcher(); protectPlayerCard()
  else
    if SAGEBAIT.NotifConn then SAGEBAIT.NotifConn:Disconnect() SAGEBAIT.NotifConn = nil end
    if SAGEBAIT.NotifConn2 then SAGEBAIT.NotifConn2:Disconnect() SAGEBAIT.NotifConn2 = nil end
    if SAGEBAIT.CharWatcher then SAGEBAIT.CharWatcher:Disconnect() SAGEBAIT.CharWatcher = nil end
    stopCardLoop()
    if LocalPlayer.Character then
      local nameTag = LocalPlayer.Character:FindFirstChild("Nametag")
      if nameTag then
        local label = nameTag:FindFirstChild("PlayerName")
        if label and label:IsA("TextLabel") then label.Text = LocalPlayer.Name end
      end
    end
    LocalPlayer:SetAttribute("User_Title", "")
  end
end

_G.enableZERITH  = toggleProtection

local CustomProtect = {
  Enabled = false, Name = "CUSTOM NAME",
  Title = "<font color='#00FF00'><b>Custom</b></font>",
  NotifConn = nil, NotifConn2 = nil, CardLoopConn = nil, CharWatcher = nil,
}

CustomProtect.updateNametag = function()
  if not CustomProtect.Enabled then return end
  local player = LocalPlayer
  if player and player.Character then
    local nameTag = player.Character:FindFirstChild("Nametag")
    if nameTag then
      local label = nameTag:FindFirstChild("PlayerName")
      if label and label:IsA("TextLabel") then label.Text = CustomProtect.Name end
    end
  end
end

CustomProtect.updateTitle = function()
  if not CustomProtect.Enabled then return end
  if LocalPlayer then LocalPlayer:SetAttribute("User_Title", CustomProtect.Title) end
end

CustomProtect.processNotification = function(notification)
  if not CustomProtect.Enabled or not notification then return end
  local player = LocalPlayer
  if not player then return end
  local textLabel = notification:FindFirstChild("TextLabel")
  if not textLabel then
    for _, child in ipairs(notification:GetDescendants()) do
      if child:IsA("TextLabel") then textLabel = child break end
    end
  end
  if not textLabel then return end
  local text = textLabel.Text or ""
  if string.find(text, player.Name) then
    textLabel.Text = string.gsub(text, player.Name, CustomProtect.Name)
  end
end

CustomProtect.setupNotifications = function()
  if CustomProtect.NotifConn then CustomProtect.NotifConn:Disconnect() CustomProtect.NotifConn = nil end
  if CustomProtect.NotifConn2 then CustomProtect.NotifConn2:Disconnect() CustomProtect.NotifConn2 = nil end
  if not CustomProtect.Enabled then return end
  local player = LocalPlayer
  if not player then return end
  local gui = player.PlayerGui:FindFirstChild("Interface")
  if gui then
    gui = gui:FindFirstChild("Persistent")
    if gui then gui = gui:FindFirstChild("Notifications") end
  end
  if not gui then return end
  for _, child in ipairs(gui:GetChildren()) do CustomProtect.processNotification(child) end
  CustomProtect.NotifConn = gui.ChildAdded:Connect(CustomProtect.processNotification)
  CustomProtect.NotifConn2 = gui.DescendantAdded:Connect(function(child)
    if child:IsA("TextLabel") then CustomProtect.processNotification(child) end
  end)
end

CustomProtect.protectPlayerCard = function()
  if not CustomProtect.Enabled then return end
  local playerName = string.upper(LocalPlayer.Name)
  local persistent = LocalPlayer.PlayerGui:FindFirstChild("Interface")
  if persistent then
    persistent = persistent:FindFirstChild("Persistent")
    if persistent then
      for _, child in ipairs(persistent:GetChildren()) do
        if child.Name == "FlashPlayerCardFrame" then
          local username = child:FindFirstChild("Username", true)
          if username and username:IsA("TextLabel") then
            local currentText = string.upper(username.Text or "")
            if string.find(currentText, playerName) then username.Text = CustomProtect.Name end
          end
        end
      end
    end
  end
end

CustomProtect.toggle = function(state)
  CustomProtect.Enabled = state and true or false
  if state then
    CustomProtect.updateNametag(); CustomProtect.updateTitle()
    CustomProtect.setupNotifications(); CustomProtect.protectPlayerCard()
    if CustomProtect.CardLoopConn then CustomProtect.CardLoopConn:Disconnect() end
    CustomProtect.CardLoopConn = RunService.Heartbeat:Connect(CustomProtect.protectPlayerCard)
    if CustomProtect.CharWatcher then CustomProtect.CharWatcher:Disconnect() end
    CustomProtect.CharWatcher = LocalPlayer.CharacterAdded:Connect(function()
      task.wait(0.5)
      CustomProtect.updateNametag()
      CustomProtect.updateTitle()
      CustomProtect.setupNotifications()
    end)
  else
    if CustomProtect.NotifConn then CustomProtect.NotifConn:Disconnect() CustomProtect.NotifConn = nil end
    if CustomProtect.NotifConn2 then CustomProtect.NotifConn2:Disconnect() CustomProtect.NotifConn2 = nil end
    if CustomProtect.CardLoopConn then CustomProtect.CardLoopConn:Disconnect() CustomProtect.CardLoopConn = nil end
    if CustomProtect.CharWatcher then CustomProtect.CharWatcher:Disconnect() CustomProtect.CharWatcher = nil end
    if LocalPlayer.Character then
      local nameTag = LocalPlayer.Character:FindFirstChild("Nametag")
      if nameTag then
        local label = nameTag:FindFirstChild("PlayerName")
        if label and label:IsA("TextLabel") then label.Text = LocalPlayer.Name end
      end
    end
    LocalPlayer:SetAttribute("User_Title", "")
  end
end

local RandomVisual = { EffectEnabled = false, CardEnabled = false, BallEnabled = false }

local function getRandomFromFolder(folderPath)
  local folder
  if type(folderPath) == "string" then
    folder = ReplicatedStorage.Assets:FindFirstChild(folderPath)
    if not folder then folder = ReplicatedStorage:FindFirstChild(folderPath) end
    if not folder then folder = ReplicatedStorage.Content:FindFirstChild(folderPath) end
  end
  if not folder then return nil end
  local items = {}
  for _, child in ipairs(folder:GetChildren()) do
    if child:IsA("ModuleScript") or child:IsA("Model") or child:IsA("Folder") then
      table.insert(items, child.Name)
    end
  end
  if #items == 0 then return nil end
  return items[math.random(1, #items)]
end

local function applyRandomEffect()
  local randomEffect = getRandomFromFolder("ScoreEffect")
  if randomEffect then
    selectedEffect = randomEffect
    Notify({ Title = "Random Effect", Content = randomEffect, Type = "Success", Duration = 2 })
  end
end

local function applyRandomBall()
  local randomBall = getRandomFromFolder("Ball")
  if randomBall then
    selectedBallSkin = randomBall
    if autoApplyBallSkin then sweep() end
    Notify({ Title = "Random Ball", Content = randomBall, Type = "Success", Duration = 2 })
  end
end

local function onHitIndicator(child)
  if not RandomVisual.EffectEnabled then return end
  if child.Name == "HitIndicator" then applyRandomEffect() end
end

local function onBallAppear(model)
  if not RandomVisual.BallEnabled then return end
  if model:IsA("Model") and model.Name:match("^CLIENT_BALL_") then
    task.wait(0.1)
    applyRandomBall()
  end
end

Workspace.ChildAdded:Connect(onBallAppear)
Workspace.DescendantAdded:Connect(onHitIndicator)

local function fireCardRemote()
  if hasFiredCard or isProcessing then return end
  local Remote = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.PlayerCardService.RE.OnFlashCard
  if Remote and firesignal then
    isProcessing = true
    hasFiredCard = true
    firesignal(Remote.OnClientEvent, {
      ["PlayerCardItemId"] = selectedCard,
      ["Context"] = { ["Custom"] = {}, ["PlacementId"] = "ScoredPoint" },
      ["Player"] = LocalPlayer,
    })
    task.wait(0.3)
    hasFiredCard = false
    isProcessing = false
  end
end

local function applyPlayerCard(cardName)
  if cardName and cardName ~= "" then selectedCard = cardName end
  if not playerCardEnabled then return end
  seen.__cardFiredFor = nil
  fireCardRemote()
end

local function changePlayerCard()
  if isProcessing then return end
  if not playerCardEnabled and not RandomVisual.CardEnabled then return end
  local persistent = LocalPlayer.PlayerGui:FindFirstChild("Interface")
  if persistent then
    persistent = persistent:FindFirstChild("Persistent")
    if persistent then
      for _, child in ipairs(persistent:GetChildren()) do
        if child.Name == "FlashPlayerCardFrame" then
          local username = child:FindFirstChild("Username", true)
          if username and username:IsA("TextLabel") then
            local currentText = string.upper(username.Text or "")
            local playerName = string.upper(LocalPlayer.Name)
            if string.find(currentText, playerName) then
              if seen.__cardFiredFor == child then return end
              if RandomVisual.CardEnabled then
                local randomCard = getRandomFromFolder("PlayerCard")
                if randomCard then selectedCard = randomCard end
              end
              seen.__cardFiredFor = child
              child:Destroy()
              task.wait(0.1)
              fireCardRemote()
            end
          end
        end
      end
    end
  end
end

local function enablePlayerCard()
  if cardConnection then return end
  local persistent = LocalPlayer.PlayerGui:FindFirstChild("Interface")
  if persistent then
    persistent = persistent:FindFirstChild("Persistent")
    if persistent then
      cardConnection = persistent.ChildAdded:Connect(function(child)
        if child.Name == "FlashPlayerCardFrame" then
          task.wait(0.1)
          changePlayerCard()
        end
      end)
    end
  end
end

local function disablePlayerCard()
  if cardConnection then cardConnection:Disconnect() cardConnection = nil end
  seen.__cardFiredFor = nil
  hasFiredCard = false
  isProcessing = false
end

local BallESP = { enabled = false, color = Color3.fromRGB(255, 80, 80), currentPlayer = nil, originalColors = {}, connection = nil }

BallESP.saveAndPaint = function(character)
  if not character then return end
  for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") then
      if BallESP.originalColors[part] == nil then BallESP.originalColors[part] = part.Color end
      part.Color = BallESP.color
    end
  end
end

BallESP.restoreColors = function(character)
  if not character then return end
  for _, part in ipairs(character:GetDescendants()) do
    if part:IsA("BasePart") and BallESP.originalColors[part] then
      part.Color = BallESP.originalColors[part]
      BallESP.originalColors[part] = nil
    end
  end
end

BallESP.clearCurrent = function()
  if BallESP.currentPlayer then
    BallESP.restoreColors(BallESP.currentPlayer.Character)
    BallESP.currentPlayer = nil
  end
end

BallESP.start = function()
  if BallESP.connection then return end
  local Remote = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService.RE.BallTouched
  if not Remote then return end
  BallESP.connection = Remote.OnClientEvent:Connect(function(player)
    if not BallESP.enabled then return end
    if not (typeof(player) == "Instance" and player:IsA("Player")) then return end
    if BallESP.currentPlayer and BallESP.currentPlayer ~= player then
      BallESP.restoreColors(BallESP.currentPlayer.Character)
    end
    if BallESP.currentPlayer ~= player then
      local char = player.Character
      if char then BallESP.saveAndPaint(char)
      else
        player.CharacterAdded:Once(function(c)
          task.wait(0.1)
          if BallESP.enabled then BallESP.saveAndPaint(c) end
        end)
      end
    end
    BallESP.currentPlayer = player
  end)
end

BallESP.stop = function()
  if BallESP.connection then BallESP.connection:Disconnect() BallESP.connection = nil end
  BallESP.clearCurrent()
end

BallESP.setColor = function(color)
  BallESP.color = color
  if BallESP.enabled and BallESP.currentPlayer then BallESP.saveAndPaint(BallESP.currentPlayer.Character) end
end

local AutoReceive = {
  enabled = false,
  wasInRange = false,
  cooldownActive = false,
  radius = 20,
  method = "Bump",
  connection = nil,
  charConnection = nil,
}

AutoReceive.getNearestBall = function()
  local nearestBall, nearestDistance = nil, math.huge
  local character = LocalPlayer.Character
  if not character then return nil, nil end
  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return nil, nil end
  for _, model in ipairs(Workspace:GetChildren()) do
    if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
      for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
          local d = (part.Position - rootPart.Position).Magnitude
          if d < nearestDistance then nearestDistance = d nearestBall = part end
          break
        end
      end
    end
  end
  return nearestBall, nearestDistance
end

AutoReceive.isOnGround = function()
  local character = LocalPlayer.Character
  if not character then return false end
  local humanoid = character:FindFirstChild("Humanoid")
  if not humanoid then return false end
  return humanoid.FloorMaterial ~= Enum.Material.Air
end

AutoReceive.triggerCooldown = function()
  AutoReceive.cooldownActive = true
  AutoReceive.wasInRange = true
  task.delay(2, function()
    AutoReceive.cooldownActive = false
    AutoReceive.wasInRange = false
  end)
end

AutoReceive.fireMethod = function()
  if not firesignal then return end
  local method = AutoReceive.method
  if method == "Bump" then
    firesignal(doMove.OnClientEvent, "Bump", false, false)
    firesignal(StopAllEmotes.OnClientEvent)
  elseif method == "Set" then
    firesignal(doMove.OnClientEvent, "Set", false, false)
    firesignal(StopAllEmotes.OnClientEvent)
  elseif method == "Dive" then
    firesignal(doMove.OnClientEvent, "Dive", false, false)
    firesignal(StopAllEmotes.OnClientEvent)
  end
end

AutoReceive.step = function()
  if not AutoReceive.enabled or AutoReceive.cooldownActive then return end
  local character = LocalPlayer.Character
  if not character then return end
  local humanoid = character:FindFirstChild("Humanoid")
  if not humanoid then return end
  if humanoid:GetState() == Enum.HumanoidStateType.Jumping
    or humanoid:GetState() == Enum.HumanoidStateType.Freefall
    or humanoid.Jump == true then
    AutoReceive.wasInRange = false
    return
  end
  if not AutoReceive.isOnGround() then AutoReceive.wasInRange = false return end
  local ball, distance = AutoReceive.getNearestBall()
  if not ball then AutoReceive.wasInRange = false return end
  local isInRange = distance <= AutoReceive.radius
  if isInRange and not AutoReceive.wasInRange then
    AutoReceive.fireMethod()
    AutoReceive.triggerCooldown()
  end
  AutoReceive.wasInRange = isInRange
end

AutoReceive.start = function()
  if AutoReceive.connection then return end
  AutoReceive.connection = RunService.Heartbeat:Connect(AutoReceive.step)
  if not AutoReceive.charConnection then
    AutoReceive.charConnection = LocalPlayer.CharacterAdded:Connect(function()
      AutoReceive.wasInRange = false
      AutoReceive.cooldownActive = false
    end)
  end
end

AutoReceive.stop = function()
  if AutoReceive.connection then AutoReceive.connection:Disconnect() AutoReceive.connection = nil end
  if AutoReceive.charConnection then AutoReceive.charConnection:Disconnect() AutoReceive.charConnection = nil end
  AutoReceive.wasInRange = false
  AutoReceive.cooldownActive = false
end

AutoReceive.setRadius = function(value)
  AutoReceive.radius = value or 20
end

AutoReceive.setMethod = function(value)
  AutoReceive.method = value or "Bump"
end

local AutoSet = { enabled = false, connection = nil, lookVector = nil, direction = nil, tilt = nil, mode = "Nearest" }

AutoSet.isSameTeam = function(player)
  local myTeam = LocalPlayer.Team
  if not myTeam then return false end
  return player.Team == myTeam
end

AutoSet.getTarget = function()
  local myChar = LocalPlayer.Character
  if not myChar then return nil end
  local myHRP = myChar:FindFirstChild("HumanoidRootPart")
  if not myHRP then return nil end
  local candidates = {}
  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and AutoSet.isSameTeam(player) then
      local char = player.Character
      if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if hrp and humanoid and humanoid.Health > 0 then table.insert(candidates, hrp) end
      end
    end
  end
  if #candidates == 0 then return nil end
  if AutoSet.mode == "Random" then return candidates[math.random(1, #candidates)] end
  local nearest, nearestDist = nil, math.huge
  for _, hrp in ipairs(candidates) do
    local d = (hrp.Position - myHRP.Position).Magnitude
    if d < nearestDist then nearestDist = d nearest = hrp end
  end
  return nearest
end

AutoSet.calculateDirection = function()
  local myChar = LocalPlayer.Character
  if not myChar then return end
  local myHRP = myChar:FindFirstChild("HumanoidRootPart")
  if not myHRP then return end
  local target = AutoSet.getTarget()
  if not target then return end
  local flat = Vector3.new(target.Position.X - myHRP.Position.X, 0, target.Position.Z - myHRP.Position.Z)
  if flat.Magnitude < 0.01 then return end
  local unit = flat.Unit
  AutoSet.lookVector = Vector3.new(unit.X, 0, unit.Z)
  AutoSet.direction = Vector3.new(unit.X, 0, unit.Z)
  AutoSet.tilt = Vector3.new(unit.X, 1, unit.Z)
end

AutoSet.fire = function()
  if not AutoSet.lookVector then return false end
  local ballId = getBallId()
  if not ballId then return false end
  BallService.RF.Interact:InvokeServer({
    ["Charge"] = 1, ["Move"] = "JumpSet", ["SpecialCharge"] = 1,
    ["TiltDirection"] = AutoSet.tilt, ["LookVector"] = AutoSet.lookVector,
    ["Direction"] = AutoSet.direction, ["MoveDirection"] = Vector3.new(0, 0, 0),
    ["ClientCanRunSpecial"] = false, ["From"] = "Client",
    ["Timestamp"] = Workspace:GetServerTimeNow(), ["BallId"] = ballId, ["CustomClient"] = {},
  })
  return true
end

AutoSet.start = function()
  if AutoSet.connection then return end
  AutoSet.connection = RunService.Heartbeat:Connect(function()
    if AutoSet.enabled then AutoSet.calculateDirection() end
  end)
end

AutoSet.stop = function()
  if AutoSet.connection then AutoSet.connection:Disconnect() AutoSet.connection = nil end
end

local AimSet = { enabled = false, connection = nil, namecallOld = nil, hooked = false, direction = nil, mode = "Nearest" }
AimSet.isSameTeam = AutoSet.isSameTeam

AimSet.getTarget = function()
  local myChar = LocalPlayer.Character
  if not myChar then return nil end
  local myHRP = myChar:FindFirstChild("HumanoidRootPart")
  if not myHRP then return nil end
  local candidates = {}
  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and AimSet.isSameTeam(player) then
      local char = player.Character
      if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if hrp and humanoid and humanoid.Health > 0 then table.insert(candidates, hrp) end
      end
    end
  end
  if #candidates == 0 then return nil end
  if AimSet.mode == "Random" then return candidates[math.random(1, #candidates)] end
  local nearest, nearestDist = nil, math.huge
  for _, hrp in ipairs(candidates) do
    local d = (hrp.Position - myHRP.Position).Magnitude
    if d < nearestDist then nearestDist = d nearest = hrp end
  end
  return nearest
end

AimSet.calculateDirection = function()
  local myChar = LocalPlayer.Character
  if not myChar then return end
  local myHRP = myChar:FindFirstChild("HumanoidRootPart")
  if not myHRP then return end
  local target = AimSet.getTarget()
  if not target then AimSet.direction = nil return end
  local flat = Vector3.new(target.Position.X - myHRP.Position.X, 0, target.Position.Z - myHRP.Position.Z)
  if flat.Magnitude < 0.01 then AimSet.direction = nil return end
  AimSet.direction = flat.Unit
end

AimSet.start = function()
  if not BallService then return end
  if AimSet.connection then return end
  AimSet.connection = RunService.Heartbeat:Connect(function()
    if AimSet.enabled then AimSet.calculateDirection() end
  end)
  if AimSet.hooked then return end
  if not (getrawmetatable and setreadonly and getnamecallmethod) then return end
  local mt = getrawmetatable(game)
  AimSet.namecallOld = mt.__namecall
  setreadonly(mt, false)
  mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if AimSet.enabled and self == BallService.RF.Interact and method == "InvokeServer" then
      local data = args[1]
      if type(data) == "table" and data.Move == "JumpSet" then
        if AimSet.direction then
          data.LookVector = Vector3.new(AimSet.direction.X, 0, AimSet.direction.Z)
          data.TiltDirection = Vector3.new(AimSet.direction.X, 1, AimSet.direction.Z)
          data.MoveDirection = Vector3.new(0, 0, 0)
        end
      end
      return AimSet.namecallOld(self, data)
    end
    return AimSet.namecallOld(self, ...)
  end
  setreadonly(mt, true)
  AimSet.hooked = true
end

AimSet.stop = function()
  if AimSet.connection then AimSet.connection:Disconnect() AimSet.connection = nil end
  AimSet.direction = nil
end

local JinkoCurve = {
  enabled = false, connection = nil, namecallOld = nil, hooked = false,
  config = {
    Charge = 1, SpecialCharge = 0.9999993954121975,
    TiltDirection = Vector3.new(-0.053983259946107864, 1, -0.9985418319702148),
    HeightOffset = 2, NotifyCooldown = 0.5,
  },
  lastNotify = 0,
}

JinkoCurve.getBallRoot = function()
  for _, model in ipairs(Workspace:GetChildren()) do
    if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
      for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then return part end
      end
    end
  end
  return nil
end

JinkoCurve.getNet = function()
  local map = Workspace:FindFirstChild("Map")
  if not map then return nil end
  local ballNoCollide = map:FindFirstChild("BallNoCollide")
  if ballNoCollide then
    local net = ballNoCollide:FindFirstChild("Net")
    if net then return net end
  end
  local ballCollide = map:FindFirstChild("BallCollideOnly")
  if ballCollide then return ballCollide:FindFirstChild("Net") end
  return nil
end

JinkoCurve.checkSlingshot = function()
  local ball = JinkoCurve.getBallRoot()
  if not ball then return end
  local net = JinkoCurve.getNet()
  if not net then return end
  local netTop = net.Position.Y + net.Size.Y * 0.5
  local triggerHeight = netTop + JinkoCurve.config.HeightOffset
  local now = os.clock()
  if now - JinkoCurve.lastNotify < JinkoCurve.config.NotifyCooldown then return end
  if math.abs(ball.Position.Y - triggerHeight) <= 1.5 then
    JinkoCurve.lastNotify = now
    Notify({ Title = "SLINGSHOT", Content = "Indicator triggered", Icon = "activity", Type = "Warning", Duration = 2 })
  end
end

JinkoCurve.start = function()
  if not BallService then return end
  if JinkoCurve.connection then return end
  JinkoCurve.connection = RunService.Heartbeat:Connect(function()
    if JinkoCurve.enabled then JinkoCurve.checkSlingshot() end
  end)
  if JinkoCurve.hooked then return end
  if not (getrawmetatable and setreadonly and getnamecallmethod) then return end
  local mt = getrawmetatable(game)
  JinkoCurve.namecallOld = mt.__namecall
  setreadonly(mt, false)
  mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if self == BallService.RF.Interact and method == "InvokeServer" then
      local data = args[1]
      if type(data) == "table" and data.Move == "Spike" and JinkoCurve.enabled then
        data.Charge = JinkoCurve.config.Charge
        data.SpecialCharge = JinkoCurve.config.SpecialCharge
        data.TiltDirection = JinkoCurve.config.TiltDirection
      end
      return JinkoCurve.namecallOld(self, data)
    end
    return JinkoCurve.namecallOld(self, ...)
  end
  setreadonly(mt, true)
  JinkoCurve.hooked = true
end

JinkoCurve.stop = function()
  if JinkoCurve.connection then JinkoCurve.connection:Disconnect() JinkoCurve.connection = nil end
end

local FFlags = { lastCount = 0 }
FFlags.cleanName = function(name)
  return name:gsub("^DFInt", ""):gsub("^DFFlag", ""):gsub("^FFFlag", ""):gsub("^FFlag", ""):gsub("^FInt", ""):gsub("^FString", ""):gsub("^FLog", "")
end

FFlags.apply = function(jsonString)
  if type(setfflag) ~= "function" then
    Notify({ Title = "FFlags", Content = "setfflag unsupported", Type = "Error" })
    return 0
  end
  local flags = game:GetService("HttpService"):JSONDecode(jsonString)
  if type(flags) ~= "table" then
    Notify({ Title = "FFlags", Content = "Invalid JSON", Type = "Error" })
    return 0
  end
  local count, index = 0, 0
  for name, value in pairs(flags) do
    index = index + 1
    if index % 15 == 0 then task.wait() end
    local cleaned = FFlags.cleanName(name)
    local current = nil
    if type(getfflag) == "function" then current = getfflag(cleaned) end
    if current ~= nil or type(getfflag) ~= "function" then
      setfflag(cleaned, tostring(value))
      count = count + 1
    end
  end
  Notify({ Title = "FFlags", Content = "Applied " .. count .. " flag(s)", Type = "Success" })
  return count
end

local Hush = {
  active = false, links = {}, damped = {}, paused = {},
  loud = {
    [Enum.AnimationPriority.Action] = true,
    [Enum.AnimationPriority.Action2] = true,
    [Enum.AnimationPriority.Action3] = true,
    [Enum.AnimationPriority.Action4] = true,
  },
}

Hush.gag = function(signal)
  if type(getconnections) ~= "function" then return end
  local cons = getconnections(signal)
  if type(cons) ~= "table" then return end
  for _, con in ipairs(cons) do
    if con.Enabled ~= false then
      con:Disable()
      Hush.paused[#Hush.paused + 1] = con
    end
  end
end

Hush.quiet = function(inst)
  if not inst:IsA("Sound") then return end
  Hush.damped[#Hush.damped + 1] = { inst = inst, level = inst.Volume }
  inst.Volume = 0
  inst:Stop()
end

Hush.start = function()
  if Hush.active then return end
  Hush.active = true
  Hush.gag(EffectsRemote.OnClientEvent)
  Hush.gag(GameEffectRemote.OnClientEvent)
  Hush.animUntil = os.clock() + 0.2
  local character = LocalPlayer.Character
  local animator = character and character:FindFirstChildWhichIsA("Animator", true)
  if animator then
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
      if Hush.loud[track.Priority] then track:Stop(0) end
    end
    Hush.links[#Hush.links + 1] = animator.AnimationPlayed:Connect(function(track)
      if not Hush.active or os.clock() > Hush.animUntil then return end
      if Hush.loud[track.Priority] then track:Stop(0) end
    end)
  end
  for _, root in ipairs({ Workspace, game:GetService("SoundService"), character }) do
    if root then
      Hush.links[#Hush.links + 1] = root.DescendantAdded:Connect(function(inst)
        if Hush.active then Hush.quiet(inst) end
      end)
    end
  end
end

Hush.stop = function()
  if not Hush.active then return end
  Hush.active = false
  for _, link in ipairs(Hush.links) do link:Disconnect() end
  Hush.links = {}
  for _, con in ipairs(Hush.paused) do con:Enable() end
  Hush.paused = {}
  for _, record in ipairs(Hush.damped) do
    if record.inst.Parent then record.inst.Volume = record.level end
  end
  Hush.damped = {}
end

local AutoCorner = { enabled = false, side = "Auto", reach = "All", aimed = false, steer = nil, drift = Vector3.zero }

AutoCorner.physics = function()
  local reached, module = pcall(require, ReplicatedStorage.Common.Physics)
  return reached and module or nil
end

AutoCorner.bounds = function()
  local physics = AutoCorner.physics()
  if physics and physics._getCourtlines then
    local found, lines = pcall(physics._getCourtlines)
    if found and lines and lines:IsA("BasePart") then
      return lines.Position, lines.Size * 0.5, lines.Position.Y
    end
  end
  local map = Workspace:FindFirstChild("Map")
  local court = map and map:FindFirstChild("Court")
  if court then
    return court.Position, court.Size * 0.5 - Vector3.new(1, 0, 1), court.Position.Y + court.Size.Y * 0.5
  end
  return nil
end

AutoCorner.trackBall = function(ball, before, elapsed)
  if elapsed <= 0 then return end
  local drift = ball.Position - before
  AutoCorner.drift = drift / elapsed
end

AutoCorner.origin = function()
  local ball = getNearestBall()
  local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
  if not ball then
    return root and root.Position or Vector3.zero
  end
  local drift = AutoCorner.drift
  if not root or typeof(drift) ~= "Vector3" or drift.Magnitude < 1 then
    return ball.Position
  end
  local gap = ball.Position - root.Position
  local closing = drift - root.AssemblyLinearVelocity
  local speed = closing:Dot(closing)
  if speed < 1 then
    return ball.Position
  end
  local reach = math.clamp(-gap:Dot(closing) / speed, 0, 0.45)
  return ball.Position + drift * reach
end

AutoCorner.cornerPoint = function()
  local char = LocalPlayer.Character
  local root = char and char:FindFirstChild("HumanoidRootPart")
  local centre, half, surfaceY = AutoCorner.bounds()
  if not root or not centre then return nil end

  local map = Workspace:FindFirstChild("Map")
  local collide = map and map:FindFirstChild("BallCollideOnly")
  local net = collide and collide:FindFirstChild("Net")
  local netZ = net and net.Position.Z or centre.Z

  local courtHalfX = half.X
  if net and net.Size.X > 1 then
    courtHalfX = math.min(half.X, net.Size.X * 0.5)
  end
  local halfX = math.max(courtHalfX - 4.5, 1)
  local halfZ = math.max(half.Z - 4, 1)

  local index = LocalPlayer.Team and LocalPlayer.Team:GetAttribute("Index")
  local sign
  if index == 1 then sign = 1
  elseif index == 2 then sign = -1
  else sign = (root.Position.Z < netZ) and 1 or -1 end

  local deepZ = centre.Z + sign * halfZ
  local leftX = centre.X + sign * halfX
  local rightX = centre.X - sign * halfX

  local pivot = AutoCorner.origin()
  local attackLine = half.Z / 3
  local standoff = math.abs(root.Position.Z - netZ)
  local hugging = 1 - math.clamp(standoff / attackLine, 0, 1)
  AutoCorner.lean = hugging

  local shortZ = centre.Z + sign * halfZ * 0.3
  local midZ = centre.Z + sign * halfZ * 0.62

  local corners = {}
  corners[#corners + 1] = { at = Vector3.new(leftX, surfaceY, deepZ), reward = 0 }
  corners[#corners + 1] = { at = Vector3.new(rightX, surfaceY, deepZ), reward = 0 }
  corners[#corners + 1] = { at = Vector3.new(leftX, surfaceY, midZ), reward = 0.05 }
  corners[#corners + 1] = { at = Vector3.new(rightX, surfaceY, midZ), reward = 0.05 }
  if hugging > 0 then
    corners[#corners + 1] = { at = Vector3.new(leftX, surfaceY, shortZ), reward = 0.45 * hugging }
    corners[#corners + 1] = { at = Vector3.new(rightX, surfaceY, shortZ), reward = 0.45 * hugging }
  end

  local eye = Workspace.CurrentCamera or Camera
  local heading = eye and eye.CFrame.LookVector or root.CFrame.LookVector
  heading = Vector3.new(heading.X, 0, heading.Z)
  if heading.Magnitude < 0.01 then return corners[1].at end
  heading = heading.Unit

  local physics = AutoCorner.physics()
  local bounds = physics and physics._getCourtlines and physics._getCourtlines()

  local guards = {}
  local blockers = {}
  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and (not LocalPlayer.Team or player.Team ~= LocalPlayer.Team) then
      local guardChar = player.Character
      local guardRoot = guardChar and guardChar:FindFirstChild("HumanoidRootPart")
      local guardHum = guardChar and guardChar:FindFirstChildOfClass("Humanoid")
      if guardRoot then
        local v = guardRoot.AssemblyLinearVelocity
        local predicted = Vector3.new(guardRoot.Position.X + v.X * 0.35, surfaceY, guardRoot.Position.Z + v.Z * 0.35)
        guards[#guards + 1] = predicted

        local airborne = guardHum ~= nil and guardHum.FloorMaterial == Enum.Material.Air
        local nearNet = math.abs(guardRoot.Position.Z - netZ) < 9
        local weight = 0
        if airborne and nearNet then weight = 1.2
        elseif airborne then weight = 0.4
        elseif nearNet then weight = 0.5 end
        if weight > 0 then
          blockers[#blockers + 1] = { x = guardRoot.Position.X + v.X * 0.25, weight = weight, reach = airborne and 6 or 4.2 }
        end
      end
    end
  end

  local function netCrossing(target)
    local dz = target.Z - pivot.Z
    if math.abs(dz) < 0.01 then return nil end
    local t = (netZ - pivot.Z) / dz
    if t < 0 or t > 1 then return nil end
    return pivot.X + (target.X - pivot.X) * t
  end

  local best, bestScore
  for _, corner in ipairs(corners) do
    local legal = true
    if bounds and physics.isPositionInCourt then
      local ok, inside = pcall(physics.isPositionInCourt, corner.at, bounds, 0, nil)
      legal = not ok or inside
    end
    local line = Vector3.new(corner.at.X - pivot.X, 0, corner.at.Z - pivot.Z)
    if legal and line.Magnitude > 0.01 then
      local dot = math.clamp(line.Unit:Dot(heading), -1, 1)

      local nearest = 60
      for _, guard in ipairs(guards) do
        local gap = (guard - corner.at).Magnitude
        if gap < nearest then nearest = gap end
      end

      local penalty = 0
      local crossX = netCrossing(corner.at)
      if crossX then
        for _, blocker in ipairs(blockers) do
          local dx = math.abs(crossX - blocker.x)
          if dx < blocker.reach then
            penalty = penalty + blocker.weight * (1 - dx / blocker.reach)
          end
        end
      end

      local score = (math.min(nearest, 45) / 45) * 0.8 + corner.reward - penalty * 0.9 + dot * 0.3
      if not bestScore or score > bestScore then
        bestScore = score
        best = corner.at
      end
    end
  end

  return best or corners[1].at
end

AutoCorner.facingRaw = function()
  local spot = AutoCorner.cornerPoint()
  if not spot then return nil end

  local char = LocalPlayer.Character
  local root = char and char:FindFirstChild("HumanoidRootPart")
  if not root then return nil end

  local pivot = AutoCorner.origin()

  local map = Workspace:FindFirstChild("Map")
  local collide = map and map:FindFirstChild("BallCollideOnly")
  local net = collide and collide:FindFirstChild("Net")
  local netZ = net and net.Position.Z
  local ownSide = (netZ and root.Position.Z > netZ) and 1 or -1
  if not netZ then
    local centre = AutoCorner.bounds()
    ownSide = (centre and root.Position.Z > centre.Z) and 1 or -1
  end

  local minForward = 0.5
  local function shape(vec)
    local mag = vec.Magnitude
    if mag < 0.01 then return nil end
    local unit = vec / mag
    if unit.Z * -ownSide < minForward then
      local lateral = math.sqrt(1 - minForward * minForward)
      local sx
      if math.abs(unit.X) > 0.001 then
        sx = unit.X >= 0 and 1 or -1
      else
        sx = (spot.X >= root.Position.X) and 1 or -1
      end
      unit = Vector3.new(sx * lateral, 0, -ownSide * minForward)
    end
    return unit, mag
  end

  local aimUnit, aimMag = shape(Vector3.new(spot.X - pivot.X, 0, spot.Z - pivot.Z))
  if not aimUnit then return nil end
  local turnUnit = shape(Vector3.new(spot.X - root.Position.X, 0, spot.Z - root.Position.Z)) or aimUnit
  AutoCorner.turn = turnUnit

  local flat = aimUnit * aimMag

  local _, courtHalf = AutoCorner.bounds()
  local depth = courtHalf and math.max(courtHalf.Z, 10) or 30
  AutoCorner.push = math.clamp((flat.Magnitude - depth * 0.9) / (depth * 0.9), -1, 0)

  local height = math.max(pivot.Y - spot.Y, 0)
  local baseTilt = math.clamp(height / math.max(flat.Magnitude, 1), 0.22, 1.0)

  local drift = AutoCorner.drift
  local speed = typeof(drift) == "Vector3" and drift.Magnitude or 0
  local speedFactor = math.clamp(speed / 60, 0, 1.5)
  local farFactor = math.clamp(flat.Magnitude / depth - 1, 0, 1)

  local rv = root.AssemblyLinearVelocity
  local along = rv.X * aimUnit.X + rv.Z * aimUnit.Z
  local bodyFactor = math.clamp(along / 40, -0.3, 0.6) * 0.5

  local vy = typeof(drift) == "Vector3" and drift.Y or 0
  local vertFactor = math.clamp(vy / 30, -1, 1) * 0.35
  local heightRatio = height / math.max(depth, 1)
  local band = heightRatio < 0.12 and 1 or (heightRatio < 0.25 and 2 or 3)
  local key = tostring(band) .. (vy >= 0 and "u" or "d")
  AutoCorner.biases = AutoCorner.biases or {}
  AutoCorner.lastKey = key
  local bias = AutoCorner.biases[key] or 1

  AutoCorner.tilt = math.clamp(baseTilt * (1 + 0.45 * speedFactor + 0.25 * farFactor + bodyFactor + vertFactor) * bias, 0.22, 1.4)
  AutoCorner.lastFrom = pivot
  AutoCorner.lastSpot = spot
  AutoCorner.lastDist = flat.Magnitude
  AutoCorner.push = math.clamp(AutoCorner.push - 0.35 * speedFactor - 0.15 * farFactor, -1, 0)

  return aimUnit
end

AutoCorner.facing = function()
  local ok, result = pcall(AutoCorner.facingRaw)
  if ok then return result end
  return nil
end

AutoCorner.cutCompute = function()
  local char = LocalPlayer.Character
  local root = char and char:FindFirstChild("HumanoidRootPart")
  local centre, half, surfaceY = AutoCorner.bounds()
  if not root or not centre then return nil end

  local map = Workspace:FindFirstChild("Map")
  local collide = map and map:FindFirstChild("BallCollideOnly")
  local net = collide and collide:FindFirstChild("Net")
  local netZ = net and net.Position.Z or centre.Z

  local standoff = math.abs(root.Position.Z - netZ)
  if standoff > (AutoCorner.cutRange or 9) then return nil end

  local ownSide = (root.Position.Z > netZ) and 1 or -1
  local forwardSign = -ownSide

  local courtHalfX = half.X
  if net and net.Size.X > 1 then
    courtHalfX = math.min(half.X, net.Size.X * 0.5)
  end
  local halfX = math.max(courtHalfX - 4.5, 1)

  local pivot = AutoCorner.origin()
  local tipZ = netZ + forwardSign * 8
  local candidates = {
    Vector3.new(centre.X - halfX, surfaceY, tipZ),
    Vector3.new(centre.X + halfX, surfaceY, tipZ),
  }

  local eye = Workspace.CurrentCamera or Camera
  local heading = eye and eye.CFrame.LookVector or root.CFrame.LookVector
  heading = Vector3.new(heading.X, 0, heading.Z)
  if heading.Magnitude > 0.01 then heading = heading.Unit else heading = Vector3.new(0, 0, forwardSign) end

  local guards = {}
  local blockers = {}
  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and (not LocalPlayer.Team or player.Team ~= LocalPlayer.Team) then
      local guardChar = player.Character
      local guardRoot = guardChar and guardChar:FindFirstChild("HumanoidRootPart")
      local guardHum = guardChar and guardChar:FindFirstChildOfClass("Humanoid")
      if guardRoot then
        local v = guardRoot.AssemblyLinearVelocity
        guards[#guards + 1] = Vector3.new(guardRoot.Position.X + v.X * 0.35, surfaceY, guardRoot.Position.Z + v.Z * 0.35)
        local airborne = guardHum ~= nil and guardHum.FloorMaterial == Enum.Material.Air
        local nearNet = math.abs(guardRoot.Position.Z - netZ) < 9
        local weight = 0
        if airborne and nearNet then weight = 1.2
        elseif airborne then weight = 0.4
        elseif nearNet then weight = 0.5 end
        if weight > 0 then
          blockers[#blockers + 1] = { x = guardRoot.Position.X + v.X * 0.25, weight = weight, reach = airborne and 6 or 4.2 }
        end
      end
    end
  end

  local best, bestScore
  for _, spot in ipairs(candidates) do
    local line = Vector3.new(spot.X - pivot.X, 0, spot.Z - pivot.Z)
    if line.Magnitude > 0.01 then
      local dot = math.clamp(line.Unit:Dot(heading), -1, 1)
      local nearest = 60
      for _, guard in ipairs(guards) do
        local gap = (guard - spot).Magnitude
        if gap < nearest then nearest = gap end
      end
      local penalty = 0
      local dz = spot.Z - pivot.Z
      if math.abs(dz) > 0.01 then
        local tNet = (netZ - pivot.Z) / dz
        if tNet >= 0 and tNet <= 1 then
          local crossX = pivot.X + (spot.X - pivot.X) * tNet
          for _, blocker in ipairs(blockers) do
            local dx = math.abs(crossX - blocker.x)
            if dx < blocker.reach then
              penalty = penalty + blocker.weight * (1 - dx / blocker.reach)
            end
          end
        end
      end
      local score = (math.min(nearest, 45) / 45) * 0.8 - penalty * 0.9 + dot * 0.3
      if not bestScore or score > bestScore then
        bestScore = score
        best = spot
      end
    end
  end
  if not best then return nil end

  local minForward = 0.15
  local function shape(vec)
    local mag = vec.Magnitude
    if mag < 0.01 then return nil end
    local unit = vec / mag
    if unit.Z * forwardSign < minForward then
      local lateral = math.sqrt(1 - minForward * minForward)
      local sx
      if math.abs(unit.X) > 0.001 then sx = unit.X >= 0 and 1 or -1 else sx = (best.X >= root.Position.X) and 1 or -1 end
      unit = Vector3.new(sx * lateral, 0, forwardSign * minForward)
    end
    return unit, mag
  end

  local dir, dist = shape(Vector3.new(best.X - pivot.X, 0, best.Z - pivot.Z))
  if not dir then return nil end
  local turn = shape(Vector3.new(best.X - root.Position.X, 0, best.Z - root.Position.Z)) or dir

  local height = math.max(pivot.Y - best.Y, 0)
  local tilt = math.clamp(height / math.max(dist, 1), 0.6, 1.6)

  return { dir = dir, turn = turn, tilt = tilt, forward = 1 }
end

AutoCorner.airborne = function()
  local char = LocalPlayer.Character
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  return hum ~= nil and hum.FloorMaterial == Enum.Material.Air
end

AutoCorner.watch = function()
  if AutoCorner.watcher then return end
  local lastBall, lastPos, lastTime, nextCheck, nextSteer = nil, nil, 0, 0, 0
  AutoCorner.watcher = RunService.Heartbeat:Connect(function()
    if not (AutoCorner.enabled or AutoCorner.cutEnabled) then
      lastBall = nil
      AutoCorner.inAir = false
      AutoCorner.pendingTurn = nil
      AutoCorner.turnDir = nil
      AutoCorner.push = 0
      AutoCorner.cut = nil
      return
    end

    local now = os.clock()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    AutoCorner.inAir = hum ~= nil and hum.FloorMaterial == Enum.Material.Air

    local root = char and char:FindFirstChild("HumanoidRootPart")
    AutoCorner.root = root

    local turn = AutoCorner.pendingTurn
    if turn and (turn.X ~= turn.X or turn.Z ~= turn.Z or turn.Magnitude < 0.01) then
      turn = nil
      AutoCorner.pendingTurn = nil
    end
    if turn then
      AutoCorner.pendingTurn = nil
      AutoCorner.turnDir = turn
      AutoCorner.turnUntil = now + 0.6
    end
    if AutoCorner.turnDir and now < (AutoCorner.turnUntil or 0) then
      if root then
        if hum then hum.AutoRotate = false end
        root.CFrame = CFrame.lookAt(root.Position, root.Position + AutoCorner.turnDir)
      end
    else
      AutoCorner.turnDir = nil
    end

    if now >= nextCheck then
      nextCheck = now + 0.05
      local ball = getNearestBall()
      if ball and lastBall == ball and lastPos and now > lastTime then
        AutoCorner.drift = (ball.Position - lastPos) / (now - lastTime)
      end
      lastBall = ball
      lastPos = ball and ball.Position or nil
      lastTime = now

      local shot = AutoCorner.shot
      if shot then
        if now - shot.t > 3 then
          AutoCorner.shot = nil
        elseif now - shot.t > 0.15 and ball and ball.Position.Y <= shot.target.Y + 2.2 then
          local dx, dz = ball.Position.X - shot.from.X, ball.Position.Z - shot.from.Z
          local actual = math.sqrt(dx * dx + dz * dz)
          if shot.dist > 8 and actual > 4 then
            local ratio = math.clamp(actual / shot.dist, 0.5, 2)
            local biases = AutoCorner.biases or {}
            AutoCorner.biases = biases
            local k = shot.key or "1u"
            biases[k] = math.clamp((biases[k] or 1) * ratio ^ 0.6, 0.5, 3)
          end
          AutoCorner.shot = nil
        end
      end
    end

    if AutoCorner.inAir and now >= nextSteer then
      nextSteer = now + 0.05
      pcall(function()
        if AutoCorner.enabled then
          local facing = AutoCorner.facing()
          if typeof(facing) == "Vector3" then AutoCorner.steer = facing end
        end
        if AutoCorner.cutEnabled then
          AutoCorner.cut = AutoCorner.cutCompute()
        else
          AutoCorner.cut = nil
        end
      end)
    end
  end)
end

AutoCorner.installAim = function()
  if AutoCorner.aimed then return end
  if not (getrawmetatable and setreadonly and getnamecallmethod) then return end
  local mt = getrawmetatable(game)
  local oldNamecall = mt.__namecall
  setreadonly(mt, false)
  mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    if self == BallService.RF.Interact and method == "InvokeServer" then
      local data = (...)
      local cut = AutoCorner.cutEnabled and AutoCorner.cut or nil
      if cut and AutoCorner.inAir and type(data) == "table" and (data.Move == "Spike" or data.Move == "ServeSpike") then
        local aim = (cut.dir - Vector3.new(0, cut.tilt, 0)).Unit
        data.LookVector = aim
        data.Direction = aim
        data.MoveDirection = Vector3.new(cut.dir.X * cut.forward, 0, cut.dir.Z * cut.forward)
        AutoCorner.pendingTurn = cut.turn
        local body = AutoCorner.root
        if body then
          body.CFrame = CFrame.lookAt(body.Position, body.Position + cut.turn)
        end
      elseif AutoCorner.enabled and AutoCorner.inAir and type(data) == "table" and (data.Move == "Spike" or data.Move == "ServeSpike") then
        local steer = AutoCorner.steer
        if typeof(steer) == "Vector3" then
          local flat = Vector3.new(steer.X, 0, steer.Z)
          if flat.Magnitude > 0.01 then
            flat = flat.Unit
            local aim = (flat - Vector3.new(0, AutoCorner.tilt or 0.35, 0)).Unit
            data.LookVector = aim
            data.Direction = aim
            local push = AutoCorner.push or 0
            data.MoveDirection = Vector3.new(-flat.X * push, 0, -flat.Z * push)
            local faceDir = AutoCorner.turn or flat
            AutoCorner.pendingTurn = faceDir
            if AutoCorner.lastFrom and AutoCorner.lastSpot then
              AutoCorner.shot = { t = os.clock(), from = AutoCorner.lastFrom, target = AutoCorner.lastSpot, dist = AutoCorner.lastDist or 0, key = AutoCorner.lastKey }
            end
            local body = AutoCorner.root
            if body then
              body.CFrame = CFrame.lookAt(body.Position, body.Position + faceDir)
            end
          end
        end
      end
      return oldNamecall(self, data)
    end
    return oldNamecall(self, ...)
  end
  setreadonly(mt, true)
  AutoCorner.aimed = true
end

local function doFakeSpike()
  if not fakeSpikeEnabled then return end
  local char = LocalPlayer.Character
  if not char then return end
  local hum = char:FindFirstChildOfClass("Humanoid")
  if not hum then return end
  if _AC and _AC.PlayAnimation then
    hum.Jump = true
    _AC:PlayAnimation("SpikeJump")
    task.delay(0.28, function()
      _AC:PlayAnimation("Spike")
    end)
  end
end

UserInputService.JumpRequest:Connect(function()
  if fakeSpikeEnabled then
    doFakeSpike()
  end
end)

local function setupCharacter(character)
  local humanoid = character:WaitForChild("Humanoid")
  local rootPart = character:WaitForChild("HumanoidRootPart")
  if shiftLockConnection then shiftLockConnection:Disconnect() shiftLockConnection = nil end
  shiftLockConnection = humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
    if humanoid.Jump and autoShiftLockEnabled then
      task.defer(function()
        local tracked = nil
        local before = tracked and tracked.Position
        local stamp = os.clock()
        task.wait(0.03)
        if tracked and before and tracked.Parent then
          AutoCorner.trackBall(tracked, before, os.clock() - stamp)
        end
        local lookVector = nil
        if not lookVector and autoShiftLockEnabled then
          lookVector = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
        end
        if lookVector and lookVector.Magnitude > 0 then
          AutoCorner.steer = lookVector
          if autoShiftLockEnabled then
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + lookVector.Unit)
            humanoid.AutoRotate = false
          end
        end
      end)
    else
      humanoid.AutoRotate = false
    end
  end)
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

local Silent = { steer = nil, expiry = 0, hooked = false }

Silent.install = function()
  if Silent.hooked then return end
  if not (getrawmetatable and setreadonly and getnamecallmethod) then return end
  local mt = getrawmetatable(game)
  local oldNamecall = mt.__namecall
  setreadonly(mt, false)
  mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    if self == BallService.RF.Interact and method == "InvokeServer" then
      local data = (...)
      local steer = Silent.steer
      if type(data) == "table" and typeof(steer) == "Vector3" and os.clock() < Silent.expiry then
        if data.Move == "Spike" or data.Move == "ServeSpike" then
          data.LookVector = steer
          data.Direction = steer
          local ground = Vector3.new(steer.X, 0, steer.Z)
          if typeof(data.TiltDirection) == "Vector3" and ground.Magnitude > 0.01 then
            local power = Vector3.new(data.TiltDirection.X, 0, data.TiltDirection.Z).Magnitude
            if power > 0.05 then
              local lean = ground.Unit * power
              data.TiltDirection = Vector3.new(lean.X, data.TiltDirection.Y, lean.Z)
            end
          end
        end
      end
      return oldNamecall(self, data)
    end
    return oldNamecall(self, ...)
  end
  setreadonly(mt, true)
  Silent.hooked = true
end

local function enemyAim()
  local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
  if not root then return nil end
  local centre, half, surfaceY = nil, nil, nil
  local physics = nil
  physics = require(ReplicatedStorage.Common.Physics)
  if physics and physics._getCourtlines then
    local found, lines = pcall(physics._getCourtlines)
    if found and lines and lines:IsA("BasePart") then
      centre, half, surfaceY = lines.Position, lines.Size * 0.5, lines.Position.Y
    end
  end
  if not centre then
    local map = Workspace:FindFirstChild("Map")
    local court = map and map:FindFirstChild("Court")
    if court then centre, half, surfaceY = court.Position, court.Size * 0.5, court.Position.Y end
  end
  if not centre then return nil end

  local map = Workspace:FindFirstChild("Map")
  local collide = map and map:FindFirstChild("BallCollideOnly")
  local net = collide and collide:FindFirstChild("Net")
  local netZ = net and net.Position.Z or centre.Z
  local netTop = net and (net.Position.Y + net.Size.Y * 0.5) or surfaceY

  local index = LocalPlayer.Team and LocalPlayer.Team:GetAttribute("Index")
  local sign
  if index == 1 then sign = 1 elseif index == 2 then sign = -1 else sign = (root.Position.Z < netZ) and 1 or -1 end

  local ball = getNearestBall()
  local origin = ball and ball.Position or (root.Position + Vector3.new(0, 6, 0))
  local headroom = origin.Y - netTop
  local standoff = math.max(math.abs(netZ - origin.Z), 2)
  local drop = math.clamp(0.45 * headroom / standoff, -0.05, 0.30)

  local halfZ = math.max(half.Z - 2, 1)
  local target = Vector3.new(centre.X + (origin.X - centre.X) * 0.25, surfaceY, centre.Z + sign * halfZ * 0.55)
  local flat = Vector3.new(target.X - origin.X, 0, target.Z - origin.Z)
  if flat.Magnitude < 0.01 then return nil end
  return (flat.Unit - Vector3.new(0, drop, 0)).Unit
end

local function fireNewSpike()
  if not newSilentSpikeEnabled or not firesignal then return end
  local newRemote = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService.RE.DoMove
  Hush.start()
  local hadHitbox = hitboxEnabled
  hitboxEnabled = true
  Hitbox.setSize(300.0)
  local dir = enemyAim() or Camera.CFrame.LookVector
  Silent.steer = dir
  Silent.expiry = os.clock() + 0.8
  Silent.install()
  firesignal(newRemote.OnClientEvent, "Spike", false, false, dir)
  task.spawn(function()
    task.wait(0.3)
    hitboxEnabled = hadHitbox
    if hadHitbox then Hitbox.setSize(hitboxScale) else Hitbox.disable() end
    Hush.stop()
  end)
end

local function stopBall()
  if not BallService then return end
  local ballId = getBallId()
  if not ballId then return end
  BallService.RF.Interact:InvokeServer({
    ["Charge"] = 1, ["Move"] = "Block", ["SpecialCharge"] = 0,
    ["TiltDirection"] = Vector3.new(-0.126, 1, 0.992),
    ["LookVector"] = Vector3.new(0, -1, 0),
    ["MoveDirection"] = Vector3.new(0, 0, 0),
    ["ClientCanRunSpecial"] = false, ["From"] = "Client",
    ["BallId"] = ballId, ["Timestamp"] = tick(), ["CustomClient"] = {},
  })
end

local function aim()
  if not BallService then return end
  local ballId = getBallId()
  if not ballId then return end
  local nearest = nil
  local shortest = math.huge
  local playerRoot = getHRP()
  if not playerRoot then return end
  for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and player.Team == LocalPlayer.Team then
      local c = player.Character
      if c then
        local r = c:FindFirstChild("HumanoidRootPart")
        if r then
          local d = (r.Position - playerRoot.Position).Magnitude
          if d < shortest then shortest = d nearest = r end
        end
      end
    end
  end
  if not nearest then return end
  local direction = (nearest.Position - playerRoot.Position).Unit
  local tiltDir = Vector3.new(direction.X, 1, direction.Z)
  local lookVec = Vector3.new(direction.X, 0, direction.Z)
  if lookVec.Magnitude > 0 then lookVec = lookVec.Unit else lookVec = Vector3.new(0.175, 0, -0.984) end
  BallService.RF.Interact:InvokeServer({
    ["Charge"] = 1, ["Move"] = "JumpSet", ["SpecialCharge"] = 0.9999996364706223,
    ["TiltDirection"] = tiltDir, ["LookVector"] = lookVec,
    ["MoveDirection"] = Vector3.new(0, 0, 0), ["ClientCanRunSpecial"] = false,
    ["From"] = "Client", ["Timestamp"] = tick(), ["BallId"] = ballId, ["CustomClient"] = {},
  })
end

local function akariDash()
  if not akariDashEnabled then return end
  local character = LocalPlayer.Character
  if not character then return end
  local hrp = character:FindFirstChild("HumanoidRootPart")
  if not hrp then return end
  local direction, distance = nil, 10
  local ball = getNearestBall()
  if ball then
    local flat = Vector3.new(ball.Position.X - hrp.Position.X, 0, ball.Position.Z - hrp.Position.Z)
    if flat.Magnitude > 0.01 then
      direction = flat.Unit
      distance = math.clamp(flat.Magnitude - 1, 0, 16)
    end
  end
  if not direction then
    local fwd = Camera.CFrame.LookVector
    direction = Vector3.new(fwd.X, 0, fwd.Z).Unit
  end
  local restore = getthreadidentity and getthreadidentity()
  if setthreadidentity then setthreadidentity(2) end
  local Effect = require(ReplicatedStorage.Content.Effect)
  Effect:Play("KuraiDashFX")({ Player = LocalPlayer, Direction = direction })
  if setthreadidentity and restore then setthreadidentity(restore) end
  local tween = TweenService:Create(hrp, TweenInfo.new(0.2, Enum.EasingStyle.Linear), {
    CFrame = CFrame.new(hrp.Position + (direction * distance)) * CFrame.Angles(0, math.rad(hrp.Orientation.Y), 0)
  })
  tween:Play()
end

local function leadFeetSlam()
  if not leadFeetEnabled then return end
  local character = LocalPlayer.Character
  if not character or not character.PrimaryPart then return end
  local root = character.PrimaryPart
  local humanoid = character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.Health <= 0 then return end
  local tuning = { Acceleration = -10000, TerminalVelocity = -300, Duration = 2 }
  local controller = nil
  local restore = getthreadidentity and getthreadidentity()
  if setthreadidentity then setthreadidentity(2) end
  local ability = require(ReplicatedStorage.Content.Ability.LeadFeet)
  if type(ability) == "table" and type(ability.Metadata) == "table" then tuning = ability.Metadata end
  controller = require(ReplicatedStorage.Packages.Knit).GetController("GameController")
  if controller then controller.IsBusy:set(false) end
  require(ReplicatedStorage.Content.Effect):Play("LeadFeetFX")({ Player = LocalPlayer })
  require(game:GetService("ReplicatedFirst").Controllers.GameController.Actions.Move.Jump).stop()
  if controller then controller.IsBusy:set(true) end
  if setthreadidentity and restore then setthreadidentity(restore) end
  if leadFeetLink then leadFeetLink:Disconnect() leadFeetLink = nil end
  local expiry = os.clock() + (tuning.Duration or 2)
  leadFeetLink = RunService.Heartbeat:Connect(function(delta)
    if not root.Parent or humanoid.FloorMaterial ~= Enum.Material.Air or os.clock() >= expiry then
      if controller then controller.IsBusy:set(false) end
      if leadFeetLink then leadFeetLink:Disconnect() leadFeetLink = nil end
      return
    end
    local velocity = root.AssemblyLinearVelocity
    local drop = math.max(velocity.Y + (tuning.Acceleration or -10000) * delta, tuning.TerminalVelocity or -300)
    root.AssemblyLinearVelocity = Vector3.new(velocity.X, drop, velocity.Z)
  end)
end

local function loadJerseys()
  jerseyList = {}
  local itemModule = require(ReplicatedStorage.Content.Item)
  local entities = ReplicatedStorage.Content.Item:FindFirstChild("Entities")
  if entities and itemModule and itemModule.Type then
    for _, child in ipairs(entities:GetChildren()) do
      if child:IsA("ModuleScript") then
        local item = require(child)
        if item and type(item) == "table" and item.Type == itemModule.Type.Jersey then
          table.insert(jerseyList, tostring(item.Id or child.Name))
        end
      end
    end
  end
  if #jerseyList == 0 then
    local assets = ReplicatedStorage.Assets and ReplicatedStorage.Assets:FindFirstChild("Jersey")
    if assets then
      for _, child in ipairs(assets:GetChildren()) do table.insert(jerseyList, child.Name) end
    end
  end
  table.sort(jerseyList)
end

loadJerseys()

local function applyJersey(id)
  local character = LocalPlayer.Character
  if not character or not character:FindFirstChild("UpperTorso") then return false end
  local jerseyFolder = ReplicatedStorage:FindFirstChild("Assets")
  jerseyFolder = jerseyFolder and jerseyFolder:FindFirstChild("Jersey")
  if not jerseyFolder then return false end
  if not seen.__jerseyHook then
    seen.__jerseyHook = LocalPlayer.CharacterAdded:Connect(function(character2)
      pickedTeam = nil
      if character2:WaitForChild("UpperTorso", 10) and autoApplyJersey then
        task.wait(1)
        applyJersey(selectedJersey)
      end
    end)
  end
  local function clearWorn()
    for _, child in ipairs(character:GetChildren()) do
      if child.Name == "JerseyFront" or child.Name == "JerseyBack" or child.Name == "_jerseyInstances"
        or child:IsA("Clothing") or child:IsA("ShirtGraphic") then child:Destroy() end
    end
  end
  if not autoApplyJersey then
    local backup = originals[character]
    if backup then
      clearWorn()
      for _, saved in ipairs(backup) do
        local restored = saved:Clone()
        if restored:IsA("SurfaceGui") then restored.Adornee = character:FindFirstChild("UpperTorso") end
        restored.Parent = character
      end
      originals[character] = nil
    end
    pickedTeam = nil
    return true
  end
  if not originals[character] then
    local backup = {}
    for _, child in ipairs(character:GetChildren()) do
      if child.Name == "JerseyFront" or child.Name == "JerseyBack" or child:IsA("Clothing") or child:IsA("ShirtGraphic") then
        table.insert(backup, child:Clone())
      end
    end
    originals[character] = backup
  end
  local function resolveTeam()
    local worn = character:FindFirstChildOfClass("Shirt")
    if not worn then return nil end
    for _, asset in ipairs(jerseyFolder:GetChildren()) do
      for _, team in ipairs(asset:GetChildren()) do
        local shirt = team:FindFirstChild("Shirt")
        if shirt and shirt:IsA("Shirt") and shirt.ShirtTemplate == worn.ShirtTemplate then
          return team.Name
        end
      end
    end
    return nil
  end
  local Jersey = require(ReplicatedStorage.Tools.Jersey)
  if type(Jersey) ~= "table" or not Jersey.set then return false end
  pickedTeam = pickedTeam or resolveTeam()
  Jersey.set({
    Player = LocalPlayer, Character = character,
    Id = id or selectedJersey, TeamName = pickedTeam,
  })
  pickedTeam = pickedTeam or resolveTeam()
  return true
end

local function sweep()
  local ballFolder = ReplicatedStorage:FindFirstChild("Assets")
  ballFolder = ballFolder and ballFolder:FindFirstChild("Ball")
  if not ballFolder then return end
  local function strip(model)
    local holder = clones[model]
    if holder then holder:Destroy() clones[model] = nil end
    local saved = originals[model]
    if saved then
      for piece, record in pairs(saved) do
        if piece.Parent then piece[record.field] = record.value end
      end
      originals[model] = nil
    end
  end
  local function skin(model)
    local driver = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    local source = ballFolder:FindFirstChild(selectedBallSkin)
    if not driver or not source then return end
    strip(model)
    local saved = {}
    local function stash(piece, field, value)
      saved[piece] = { field = field, value = piece[field] }
      piece[field] = value
    end
    for _, piece in ipairs(model:GetDescendants()) do
      if piece:IsA("BasePart") then
        if piece.Name ~= MARK then stash(piece, "Transparency", 1) end
      elseif piece:IsA("Decal") or piece:IsA("Texture") then
        stash(piece, "Transparency", 1)
      elseif piece:IsA("Trail") or piece:IsA("ParticleEmitter") or piece:IsA("Beam") or piece:IsA("Light") or piece:IsA("Smoke") or piece:IsA("Fire") or piece:IsA("Sparkles") then
        stash(piece, "Enabled", false)
      end
    end
    originals[model] = saved
    local holder = source:Clone()
    holder.Name = MARK2
    holder.Parent = model
    local pieces = {}
    if holder:IsA("BasePart") then pieces[#pieces + 1] = holder end
    for _, candidate in ipairs(holder:GetDescendants()) do
      if candidate:IsA("BasePart") then pieces[#pieces + 1] = candidate end
    end
    local anchor = holder:IsA("Model") and holder.PrimaryPart or nil
    if not anchor then
      local bestScore
      for _, candidate in ipairs(pieces) do
        if candidate:IsA("BasePart") then
          local vol = candidate.Size.X * candidate.Size.Y * candidate.Size.Z
          local roundish = math.abs(candidate.Size.X - candidate.Size.Y) < 0.5 and math.abs(candidate.Size.Y - candidate.Size.Z) < 0.5
          local score = vol
          if candidate:IsA("Part") and candidate.Shape == Enum.PartType.Ball then score = score * 6
          elseif roundish then score = score * 3 end
          if not bestScore or score > bestScore then bestScore = score anchor = candidate end
        end
      end
    end
    if anchor then
      local offset = holder:GetPivot():ToObjectSpace(anchor.CFrame)
      holder:PivotTo(driver.CFrame * offset:Inverse())
    else
      holder:PivotTo(driver.CFrame)
    end
    for _, part in ipairs(pieces) do
      part.Anchored = false
      part.CanCollide = false
      part.CanQuery = false
      part.CanTouch = false
      part.Massless = true
      local weld = Instance.new("WeldConstraint")
      weld.Part0 = driver
      weld.Part1 = part
      weld.Parent = part
    end
    clones[model] = holder
  end
  local tracked = {}
  for model in pairs(clones) do table.insert(tracked, model) end
  for _, model in ipairs(tracked) do strip(model) end
  if not autoApplyBallSkin then return end
  for _, model in ipairs(Workspace:GetChildren()) do
    if model:IsA("Model") and model.Name:match("^CLIENT_BALL_") then skin(model) end
  end
  if not seen.__ballHook then
    seen.__ballHook = Workspace.ChildAdded:Connect(function(child)
      if not autoApplyBallSkin or not child:IsA("Model") or not child.Name:match("^CLIENT_BALL_") then return end
      task.spawn(function()
        for _ = 1, 40 do
          if child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart") then break end
          task.wait(0.05)
        end
        if autoApplyBallSkin and child.Parent then sweep() end
      end)
    end)
  end
end

local function loadEffects()
  effectList = {}
  local effectFolder = ReplicatedStorage.Assets:FindFirstChild("ScoreEffect")
  if effectFolder then
    for _, child in ipairs(effectFolder:GetChildren()) do
      if child:IsA("ModuleScript") then table.insert(effectList, child.Name) end
    end
  end
  table.sort(effectList)
  if #effectList == 0 then
    table.insert(effectList, "SupernovaScoreEffect")
    table.insert(effectList, "GroundHit1")
    table.insert(effectList, "GroundHit2")
  end
end

local function loadCards()
  cardList = {}
  local ItemEntities = ReplicatedStorage.Content.Item.Entities
  if ItemEntities then
    for _, child in ipairs(ItemEntities:GetChildren()) do
      if child:IsA("ModuleScript") then
        local name = child.Name
        if string.match(name, "Card") or string.match(name, "PlayerCard") then table.insert(cardList, name) end
      end
    end
  end
  table.sort(cardList)
  if #cardList == 0 then table.insert(cardList, "UltimateChampionPlayerCard") end
end

local function loadBallSkins()
  ballSkinList = {}
  local ASSETS = ReplicatedStorage:FindFirstChild("Assets")
  local BALL_FOLDER = ASSETS and ASSETS:FindFirstChild("Ball")
  if BALL_FOLDER then
    for _, child in ipairs(BALL_FOLDER:GetChildren()) do
      if child:IsA("Model") then table.insert(ballSkinList, child.Name) end
    end
  end
  table.sort(ballSkinList)
  if #ballSkinList == 0 then table.insert(ballSkinList, "ClassicBall") end
end

loadEffects()
loadCards()
loadBallSkins()

local function enableRedirectSpike()
  redirectSpikeEnabled = true
  if redirectSpikeInstalled then return end
  if not (getrawmetatable and setreadonly and getnamecallmethod) then return end
  local mt = getrawmetatable(game)
  local oldNamecall = mt.__namecall
  setreadonly(mt, false)
  mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if self == BallService.RF.Interact and method == "InvokeServer" then
      local data = args[1]
      if type(data) == "table" and data.Move == "Spike" and redirectSpikeEnabled then
        local dir = Camera.CFrame.LookVector
        data.LookVector = dir
        data.Direction = dir
        if data.MoveDirection then data.MoveDirection = dir end
      end
      return oldNamecall(self, data)
    end
    return oldNamecall(self, ...)
  end
  setreadonly(mt, true)
  redirectSpikeInstalled = true
end

local function disableRedirectSpike() redirectSpikeEnabled = false end

local function enableSanjuTilt()
  sanjuTiltEnabled = true
  if sanjuTiltInstalled then return end
  if not (getrawmetatable and setreadonly and getnamecallmethod) then return end
  local mt = getrawmetatable(game)
  local oldNamecall = mt.__namecall
  setreadonly(mt, false)
  mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if self == BallService.RF.Interact and method == "InvokeServer" then
      local data = args[1]
      if type(data) == "table" and data.Move == "Spike" and sanjuTiltEnabled then
        if data.TiltDirection and data.LookVector then
          local tiltDir = data.TiltDirection
          if math.abs(tiltDir.X) > 0.01 or math.abs(tiltDir.Z) > 0.01 then
            local lookVec = data.LookVector
            local bend = Vector3.new(tiltDir.X, 0, tiltDir.Z)
            data.LookVector = Vector3.new(lookVec.X + bend.X * 0.3, lookVec.Y, lookVec.Z + bend.Z * 0.3).Unit
            data.TiltDirection = Vector3.new(tiltDir.X * 1.35, tiltDir.Y, tiltDir.Z * 1.35)
          end
        end
      end
      return oldNamecall(self, data)
    end
    return oldNamecall(self, ...)
  end
  setreadonly(mt, true)
  sanjuTiltInstalled = true
end

local function disableSanjuTilt() sanjuTiltEnabled = false end

local function enableMaxCharge()
  maxChargeEnabled = true
  if maxChargeHookActive then return end
  if not (getrawmetatable and setreadonly and getnamecallmethod) then return end
  mtMaxCharge = getrawmetatable(game)
  oldNamecallMaxCharge = mtMaxCharge.__namecall
  setreadonly(mtMaxCharge, false)
  mtMaxCharge.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if self == BallService.RF.Interact and method == "InvokeServer" then
      local data = args[1]
      if type(data) == "table" and data.Move == "Spike" and maxChargeEnabled then
        data.Charge = 1.0
        data.SpecialCharge = 1.0
        data.HoldDuration = 1.0
        if type(data.CustomClient) == "table" then
          data.CustomClient.HoldDuration = 1.0
          data.CustomClient.Charge = 1.0
          data.CustomClient.SpecialCharge = 1.0
        else
          data.CustomClient = { HoldDuration = 1.0, Charge = 1.0, SpecialCharge = 1.0 }
        end
      end
      return oldNamecallMaxCharge(self, unpack(args))
    end
    return oldNamecallMaxCharge(self, ...)
  end
  setreadonly(mtMaxCharge, true)
  maxChargeHookActive = true
end

local function disableMaxCharge() maxChargeEnabled = false end

local function enableMaxServe()
  maxServeEnabled = true
  if maxServeHookActive then return end
  if not (getrawmetatable and setreadonly and getnamecallmethod) then return end
  mtMaxServe = getrawmetatable(game)
  oldNamecallMaxServe = mtMaxServe.__namecall
  setreadonly(mtMaxServe, false)
  mtMaxServe.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if self == Serve and method == "InvokeServer" and maxServeEnabled then
      args[2] = 5
      return oldNamecallMaxServe(self, unpack(args))
    end
    return oldNamecallMaxServe(self, ...)
  end
  setreadonly(mtMaxServe, true)
  maxServeHookActive = true
end

local function disableMaxServe() maxServeEnabled = false end

local function enableDesync()
  if desyncConnection then return end

  local RunService = game:GetService("RunService")
  local stepName = "ZerithDesyncSpike"
  local gameSettings = nil
  pcall(function() gameSettings = UserSettings():GetService("UserGameSettings") end)

  local previousDev = nil
  pcall(function()
    previousDev = LocalPlayer.DevEnableMouseLock
    LocalPlayer.DevEnableMouseLock = true
  end)

  local mouseLock = nil
  pcall(function()
    local playerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local cameras = playerModule:GetCameras()
    mouseLock = cameras.activeMouseLockController
  end)

  local active = false
  local endAt = 0
  local savedRotation = nil
  local savedAutoRotate = nil
  local activeHum = nil
  local lockedByUs = false

  local function restore()
    if not active then return end
    active = false
    if lockedByUs and mouseLock then
      pcall(function()
        if mouseLock:GetIsMouseLocked() then mouseLock:OnMouseLockToggled() end
      end)
    end
    lockedByUs = false
    if gameSettings and savedRotation then
      pcall(function() gameSettings.RotationType = savedRotation end)
    end
    if activeHum and activeHum.Parent and savedAutoRotate ~= nil then
      pcall(function() activeHum.AutoRotate = savedAutoRotate end)
    end
    activeHum = nil
    savedRotation = nil
    savedAutoRotate = nil
  end

  local jumpConn = UserInputService.JumpRequest:Connect(function()
    if not desyncEnabled or active then return end

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    active = true
    activeHum = hum
    savedAutoRotate = hum.AutoRotate
    if gameSettings then
      pcall(function()
        savedRotation = gameSettings.RotationType
        gameSettings.RotationType = Enum.RotationType.CameraRelative
      end)
    end

    if mouseLock then
      pcall(function()
        if not mouseLock:GetIsMouseLocked() then
          mouseLock:OnMouseLockToggled()
          lockedByUs = true
        end
      end)
    end

    endAt = os.clock() + 0.55

    task.delay(0.04, function()
      if desyncEnabled and firesignal then
        pcall(firesignal, doMove.OnClientEvent, "Spike", false, false)
      end
    end)
  end)

  RunService:BindToRenderStep(stepName, Enum.RenderPriority.Last.Value, function()
    if not active then return end

    local now = os.clock()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera

    if not hum or not root or not cam or hum.Health <= 0 or now >= endAt then
      restore()
      return
    end

    local look = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
    if look.Magnitude < 0.01 then return end
    look = look.Unit

    hum.AutoRotate = false
    root.CFrame = CFrame.lookAt(root.Position, root.Position + look)
  end)

  desyncConnection = {
    Disconnect = function()
      jumpConn:Disconnect()
      pcall(function() RunService:UnbindFromRenderStep(stepName) end)
      restore()
      if previousDev ~= nil then
        pcall(function() LocalPlayer.DevEnableMouseLock = previousDev end)
      end
    end
  }
  desyncEnabled = true
end

local function disableDesync()
  desyncEnabled = false
  if desyncConnection then desyncConnection:Disconnect() desyncConnection = nil end
end

local function applyESP(player)
  if not player.Character or espHighlights[player] then return end
  local tone = Color3.fromRGB(255, 72, 72)
  local highlight = Instance.new("Highlight")
  highlight.Name = MARK
  highlight.Adornee = player.Character
  highlight.FillColor = tone
  highlight.FillTransparency = 0.72
  highlight.OutlineTransparency = 0
  highlight.OutlineColor = tone
  highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
  highlight.Parent = player.Character
  espHighlights[player] = highlight
end

local function removeESP(player)
  if espHighlights[player] then espHighlights[player]:Destroy() espHighlights[player] = nil end
end

local function isEnemy(player)
  if player == LocalPlayer then return false end
  if not player.Team or not LocalPlayer.Team then return false end
  return player.Team ~= LocalPlayer.Team
end

local function setupESP(player)
  if player == LocalPlayer then return end
  local function onCharacterAdded(character)
    if espConnections[player] then
      for _, c in pairs(espConnections[player]) do c:Disconnect() end
      espConnections[player] = nil
    end
    removeESP(player)
    local humanoid = character:WaitForChild("Humanoid", 3)
    if not humanoid then return end
    local stateConn = humanoid.StateChanged:Connect(function(_, newState)
      if not espJumpEnabled or not isEnemy(player) then removeESP(player) return end
      if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
        applyESP(player)
      elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
        removeESP(player)
      end
    end)
    espConnections[player] = { stateConn }
  end
  if player.Character then onCharacterAdded(player.Character) end
  player.CharacterAdded:Connect(onCharacterAdded)
end

for _, player in ipairs(Players:GetPlayers()) do setupESP(player) end
Players.PlayerAdded:Connect(setupESP)

local function getLineColor(index)
  return lineColors[(index - 1) % #lineColors + 1]
end

local function createLineFor(player, index)
  local att0 = Instance.new("Attachment")
  att0.Name = MARK .. "_att0"
  local att1 = Instance.new("Attachment")
  att1.Name = MARK .. "_att1"
  att1.Position = Vector3.new(0, 0, -1.5)
  local hrp = getHRP()
  if not hrp then return end
  att0.Parent = hrp
  local targetHead = player.Character and (player.Character:FindFirstChild("Head") or player.Character:FindFirstChild("HumanoidRootPart"))
  if targetHead then
    att1.Parent = targetHead
  end
  local beam = Instance.new("Beam")
  beam.Name = MARK .. "_beam"
  beam.Attachment0 = att0
  beam.Attachment1 = att1
  beam.Color = ColorSequence.new(getLineColor(index))
  beam.Width0 = 0.08
  beam.Width1 = 0.08
  beam.FaceCamera = true
  beam.Transparency = NumberSequence.new(0.2)
  beam.Parent = att0
  lines[player] = { att0 = att0, att1 = att1, beam = beam, head = targetHead }
end

local function removeLine(player)
  local line = lines[player]
  if line then
    if line.att0 then line.att0:Destroy() end
    if line.att1 then line.att1:Destroy() end
    lines[player] = nil
  end
end

local function updateLines()
  if not linesEnabled then return end
  local hrp = getHRP()
  if not hrp then return end
  for i, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
      if not lines[player] then
        createLineFor(player, i)
      end
    end
  end
  for player, line in pairs(lines) do
    local char = player.Character
    if not char then
      removeLine(player)
    else
      local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
      if not head then
        removeLine(player)
      else
        if line.att1.Parent ~= head then
          line.att1.Parent = head
          line.head = head
        end
        line.beam.Enabled = true
      end
    end
  end
end

RunService.RenderStepped:Connect(updateLines)

local Landing = (function()
local Landing
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local SharedBallPrediction = _G.__BallPredictionState or {}
_G.__BallPredictionState = SharedBallPrediction

if SharedBallPrediction.connection then
    SharedBallPrediction.connection:Disconnect()
end

if SharedBallPrediction.destroy then
    pcall(SharedBallPrediction.destroy)
end

local BallPredictionSettings = {
    enabled = false,
    showArc = false,
    showMarker = false,
    showInfo = false,
    projectionTime = 3,
    landsInColor = Color3.fromRGB(70, 220, 100),
    landsOutColor = Color3.fromRGB(255, 90, 90),
    netColor = Color3.fromRGB(255, 190, 70),
    arcColor = Color3.fromRGB(255, 255, 255),
    beamColor = Color3.fromRGB(255, 90, 90),
    ringColor = Color3.fromRGB(255, 255, 255),
    outerRingRadius = 1.65,
    innerRingRadius = 0.55,
    outerRingThickness = 1.4,
    innerRingThickness = 1.9,
    outerRingOpacity = 0.9,
    innerRingOpacity = 1,
    useVerdictColorForOuterRing = true,
    showBeam = false,
    useVerdictColorForArc = true,
    updateInterval = 1 / 30,
    stateGracePeriod = 0.18,
    arcMinSegments = 8,
    arcMaxSegments = 14,
    outerRingSegments = 24,
    innerRingSegments = 18,
}

Landing = {
    enabled = false,
    tracked = nil,
    last = nil,
    stamp = 0,
    drift = Vector3.zero,
    settings = BallPredictionSettings,
}

local Renderer = {
    outerRing = {},
    innerRing = {},
    arc = {},
    beam = nil,
    text = nil,
}

local cachedBall = nil
local lastBallCheck = 0
local lastPredictionUpdate = 0
local lastPredictionBall = nil
local lastRenderState = nil
local lastSuccessfulStateTime = 0
local CachedPhysicsModule = nil
local CachedKnitController = nil
local CachedGameConfig = nil
local CachedStateModule = nil

local function removeDrawing(obj)
    if obj then
        pcall(function()
            obj.Visible = false
        end)
        pcall(function()
            obj:Remove()
        end)
    end
end

local function hideList(list)
    for i = 1, #list do
        list[i].Visible = false
    end
end

local function makeLine(color, thickness)
    local line = Drawing.new("Line")
    line.Visible = false
    line.Color = color
    line.Thickness = thickness
    line.Transparency = 1
    return line
end

local function makeText()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = true
    text.Size = 16
    text.Font = 2
    text.Transparency = 1
    text.Color = Color3.fromRGB(20, 20, 20)
    pcall(function()
        text.OutlineColor = Color3.fromRGB(255, 255, 255)
    end)
    return text
end

local function ensureLines(pool, count, color, thickness)
    for i = #pool + 1, count do
        pool[i] = makeLine(color, thickness)
    end
    for i = 1, #pool do
        pool[i].Color = color
        pool[i].Thickness = thickness
    end
end

local function clearRenderer()
    for i = 1, #Renderer.outerRing do
        removeDrawing(Renderer.outerRing[i])
    end
    for i = 1, #Renderer.innerRing do
        removeDrawing(Renderer.innerRing[i])
    end
    for i = 1, #Renderer.arc do
        removeDrawing(Renderer.arc[i])
    end
    removeDrawing(Renderer.beam)
    removeDrawing(Renderer.text)
    Renderer.outerRing = {}
    Renderer.innerRing = {}
    Renderer.arc = {}
    Renderer.beam = nil
    Renderer.text = nil
end

local function hideRenderer()
    hideList(Renderer.outerRing)
    hideList(Renderer.innerRing)
    hideList(Renderer.arc)
    if Renderer.beam then
        Renderer.beam.Visible = false
    end
    if Renderer.text then
        Renderer.text.Visible = false
    end
end

local function buildRenderer()
    if not Renderer.beam then
        Renderer.beam = makeLine(BallPredictionSettings.beamColor, 2)
    end
    if not Renderer.text then
        Renderer.text = makeText()
    end
end

local function worldToScreen(position)
    local vector, visible = Camera:WorldToViewportPoint(position)
    return Vector2.new(vector.X, vector.Y), visible and vector.Z > 0, vector.Z
end

local function drawPolyline(points, pool, color, thickness, transparency)
    if #points < 2 then
        hideList(pool)
        return
    end

    ensureLines(pool, #points - 1, color, thickness)

    for i = 1, #points - 1 do
        local line = pool[i]
        line.From = points[i]
        line.To = points[i + 1]
        line.Color = color
        line.Thickness = thickness
        line.Transparency = transparency or 1
        line.Visible = true
    end

    for i = #points, #pool do
        pool[i].Visible = false
    end
end

local function drawScreenCircle(center2D, radiusPixels, segments, pool, color, thickness, transparency)
    if radiusPixels <= 0 then
        hideList(pool)
        return
    end

    local points = {}

    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        points[#points + 1] = Vector2.new(
            center2D.X + math.cos(angle) * radiusPixels,
            center2D.Y + math.sin(angle) * radiusPixels
        )
    end

    drawPolyline(points, pool, color, thickness, transparency)
end

local function drawWorldCircle(center, radius, segments, pool, color, thickness, transparency)
    local center2D, centerVisible = worldToScreen(center)
    if not centerVisible then
        hideList(pool)
        return
    end

    local edge2D, edgeVisible = worldToScreen(center + Vector3.new(radius, 0, 0))
    if not edgeVisible then
        hideList(pool)
        return
    end

    local radiusPixels = math.max((edge2D - center2D).Magnitude, 1)
    drawScreenCircle(center2D, radiusPixels, segments, pool, color, thickness, transparency)
end

local function drawArc(pos, vel, gravity, flight, verdictColor)
    if not BallPredictionSettings.showArc then
        hideList(Renderer.arc)
        return
    end

    local segments = math.clamp(
        math.floor(flight * 8),
        BallPredictionSettings.arcMinSegments,
        BallPredictionSettings.arcMaxSegments
    )
    local points = {}

    for i = 0, segments do
        local t = flight * (i / segments)
        local world = Vector3.new(
            pos.X + vel.X * t,
            pos.Y + vel.Y * t - 0.5 * gravity * t * t,
            pos.Z + vel.Z * t
        )
        local screen, visible = worldToScreen(world)
        if visible then
            points[#points + 1] = screen
        end
    end

    local arcColor = BallPredictionSettings.useVerdictColorForArc and verdictColor or BallPredictionSettings.arcColor
    drawPolyline(points, Renderer.arc, arcColor, 1.5, 1)
end

local function drawBeam(spot, verdictColor, flight)
    if not BallPredictionSettings.showMarker or not BallPredictionSettings.showBeam then
        if Renderer.beam then
            Renderer.beam.Visible = false
        end
        return
    end

    local topWorld = spot + Vector3.new(0, math.clamp(8 + flight * 8, 8, 20), 0)
    local from2D, visibleA = worldToScreen(topWorld)
    local to2D, visibleB = worldToScreen(spot)

    if not visibleA or not visibleB then
        Renderer.beam.Visible = false
        return
    end

    Renderer.beam.From = from2D
    Renderer.beam.To = to2D
    Renderer.beam.Color = verdictColor
    Renderer.beam.Thickness = 1.6
    Renderer.beam.Transparency = 1
    Renderer.beam.Visible = true
end

local function drawMarker(spot, verdictColor)
    if not BallPredictionSettings.showMarker then
        hideList(Renderer.outerRing)
        hideList(Renderer.innerRing)
        return
    end

    local outerColor = BallPredictionSettings.useVerdictColorForOuterRing and verdictColor or BallPredictionSettings.ringColor

    drawWorldCircle(
        spot + Vector3.new(0, 0.05, 0),
        BallPredictionSettings.outerRingRadius,
        BallPredictionSettings.outerRingSegments,
        Renderer.outerRing,
        outerColor,
        BallPredictionSettings.outerRingThickness,
        BallPredictionSettings.outerRingOpacity
    )

    drawWorldCircle(
        spot + Vector3.new(0, 0.05, 0),
        BallPredictionSettings.innerRingRadius,
        BallPredictionSettings.innerRingSegments,
        Renderer.innerRing,
        verdictColor,
        BallPredictionSettings.innerRingThickness,
        BallPredictionSettings.innerRingOpacity
    )
end

local function distanceFromPlayer(spot)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return 0
    end

    local flat = Vector3.new(spot.X - root.Position.X, 0, spot.Z - root.Position.Z)
    return flat.Magnitude
end

local function drawInfo(spot, verdictText, verdictColor, flight)
    if not BallPredictionSettings.showInfo then
        if Renderer.text then
            Renderer.text.Visible = false
        end
        return
    end

    local screen, visible = worldToScreen(spot + Vector3.new(0, 2.2, 0))
    if not visible then
        Renderer.text.Visible = false
        return
    end

    local distance = math.floor(distanceFromPlayer(spot) + 0.5)
    Renderer.text.Position = screen
    Renderer.text.Text = string.format("%.2fs | %d studs | %s", flight, distance, verdictText)
    Renderer.text.Color = Color3.fromRGB(25, 25, 25)
    pcall(function()
        Renderer.text.OutlineColor = verdictColor
    end)
    Renderer.text.Visible = true
end

local function resolveBallPart(item)
    if not item then
        return nil
    end

    if item:IsA("BasePart") then
        return item
    end

    if item:IsA("Model") then
        return item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
    end

    return nil
end

local function getNearestBall()
    local now = os.clock()
    if cachedBall and cachedBall.Parent and now - lastBallCheck < 0.08 then
        return cachedBall
    end

    lastBallCheck = now

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        cachedBall = nil
        return nil
    end

    local nearest = nil
    local nearestDistance = math.huge

    for _, tagged in ipairs(CollectionService:GetTagged("Ball")) do
        local part = resolveBallPart(tagged)
        if part and part.Parent then
            local distance = (part.Position - root.Position).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearest = part
            end
        end
    end

    if not nearest then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj.Name:match("^CLIENT_BALL_%d+$") then
                local part = resolveBallPart(obj)
                if part and part.Parent then
                    local distance = (part.Position - root.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearest = part
                    end
                end
            end
        end
    end

    cachedBall = nearest
    return nearest
end

function Landing.clear()
    hideRenderer()
    Landing.tracked = nil
    Landing.last = nil
    Landing.stamp = 0
    Landing.drift = Vector3.zero
    cachedBall = nil
    lastPredictionBall = nil
    lastRenderState = nil
    lastPredictionUpdate = 0
    lastSuccessfulStateTime = 0
end

local function getGameConfig()
    if CachedGameConfig then
        return CachedGameConfig
    end

    local ok, module = pcall(require, ReplicatedStorage.Configuration.Game)
    if ok then
        CachedGameConfig = module
        return module
    end
end

local function getStateModule()
    if CachedStateModule then
        return CachedStateModule
    end

    local ok, module = pcall(require, ReplicatedStorage.Common.State)
    if ok then
        CachedStateModule = module
        return module
    end
end

local function getPhysicsModule()
    if CachedPhysicsModule then
        return CachedPhysicsModule
    end

    local ok, module = pcall(require, ReplicatedStorage.Common.Physics)
    if ok then
        CachedPhysicsModule = module
        return module
    end
end

local function getBallController()
    if CachedKnitController then
        return CachedKnitController
    end

    local reached, Knit = pcall(require, ReplicatedStorage.Packages.Knit)
    if not reached then
        return nil
    end

    local found, controller = pcall(Knit.GetController, "BallController")
    if found and type(controller) == "table" then
        CachedKnitController = controller
        return controller
    end
end

function Landing.gravity()
    local ok, value = pcall(function()
        local Game = getGameConfig()
        local State = getStateModule()
        if not Game or not State then
            return nil
        end
        return State.get(ReplicatedStorage, State.Id.Modifier, "BallGravity", Game.Physics.Gravity)
    end)

    if ok and type(value) == "number" and value > 0 then
        return value
    end

    return 17
end

function Landing.velocity(part)
    local controller = getBallController()
    if controller and type(controller.ActiveBalls) == "table" then
        for _, record in pairs(controller.ActiveBalls) do
            local model = record.Ball
            if model and model.Parent and model:IsAncestorOf(part) and typeof(record.Velocity) == "Vector3" then
                return record.Velocity
            end
        end
    end
    return Landing.drift
end

function Landing.solve(pos, vel, gravity, floorY)
    local drop = pos.Y - floorY
    if drop < 0 then
        return nil
    end

    local disc = vel.Y * vel.Y + 2 * gravity * drop
    if disc < 0 then
        return nil
    end

    local flight = (vel.Y + math.sqrt(disc)) / gravity
    if flight ~= flight or flight <= 0 or flight > 15 then
        return nil
    end

    if flight > BallPredictionSettings.projectionTime then
        return nil
    end

    return flight
end

function Landing.netHit(pos, vel, gravity, flight)
    local map = Workspace:FindFirstChild("Map")
    local collide = map and map:FindFirstChild("BallCollideOnly")
    local net = collide and collide:FindFirstChild("Net")
    if not net then
        return false
    end

    local netZ = net.Position.Z
    local gap = netZ - pos.Z
    if math.abs(vel.Z) < 0.01 then
        return false
    end

    local moment = gap / vel.Z
    if moment <= 0 or moment >= flight then
        return false
    end

    local height = pos.Y + vel.Y * moment - 0.5 * gravity * moment * moment
    local across = pos.X + vel.X * moment
    local top = net.Position.Y + net.Size.Y * 0.5
    local base = net.Position.Y - net.Size.Y * 0.5

    if height > top or height < base then
        return false
    end

    return math.abs(across - net.Position.X) <= net.Size.X * 0.5
end

function Landing.predict(ball)
    local module = getPhysicsModule()
    if not module then
        return nil
    end

    local gravity = Landing.gravity()
    local pos = ball.Position
    local vel = Landing.velocity(ball)
    if typeof(vel) ~= "Vector3" then
        return nil
    end

    local floorY = module.LastFloorHeight
    if not floorY then
        local found, height = pcall(module.calculateFloorHeight, pos, true)
        floorY = found and height or nil
    end
    if not floorY then
        return nil
    end

    local flight = Landing.solve(pos, vel, gravity, floorY)
    if not flight then
        return nil
    end

    local spot = Vector3.new(
        pos.X + vel.X * flight,
        floorY,
        pos.Z + vel.Z * flight
    )

    local probed, ground = pcall(module.calculateFloorHeight, Vector3.new(spot.X, pos.Y, spot.Z), true)
    if probed and type(ground) == "number" and math.abs(ground - floorY) > 0.05 then
        local refined = Landing.solve(pos, vel, gravity, ground)
        if refined then
            flight = refined
            spot = Vector3.new(
                pos.X + vel.X * flight,
                ground,
                pos.Z + vel.Z * flight
            )
        end
    end

    return spot, module, flight, Landing.netHit(pos, vel, gravity, flight), pos, vel, gravity
end

local function buildRenderState(ball)
    local spot, physics, flight, netted, pos, vel, gravity = Landing.predict(ball)
    if not spot then
        return nil
    end

    local inside = true
    if physics and physics.isPositionInCourt then
        local ok, verdict = pcall(physics.isPositionInCourt, spot, nil, ball.Size.X * 0.5, nil)
        inside = not ok or verdict
    end

    local verdictText
    local verdictColor

    if netted then
        verdictText = "NET"
        verdictColor = BallPredictionSettings.netColor
    elseif inside then
        verdictText = "IN"
        verdictColor = BallPredictionSettings.landsInColor
    else
        verdictText = "OUT"
        verdictColor = BallPredictionSettings.landsOutColor
    end

    lastRenderState = {
        spot = spot,
        flight = flight,
        pos = pos,
        vel = vel,
        gravity = gravity,
        verdictText = verdictText,
        verdictColor = verdictColor,
    }
    lastSuccessfulStateTime = os.clock()

    return lastRenderState
end

local function renderState(state)
    if not state then
        hideRenderer()
        return
    end

    drawArc(state.pos, state.vel, state.gravity, state.flight, state.verdictColor)
    drawMarker(state.spot, state.verdictColor)
    drawBeam(state.spot, state.verdictColor, state.flight)
    drawInfo(state.spot, state.verdictText, state.verdictColor, state.flight)
end

pcall(buildRenderer)

local connection = RunService.RenderStepped:Connect(function()
  pcall(function()
    local now = os.clock()

    if not Landing.enabled then
        lastRenderState = nil
        lastPredictionBall = nil
        hideRenderer()
        return
    end

    local ball = getNearestBall()
    if not ball then
        Landing.last = nil
        if lastRenderState and now - lastSuccessfulStateTime <= BallPredictionSettings.stateGracePeriod then
            renderState(lastRenderState)
        else
            lastRenderState = nil
            lastPredictionBall = nil
            hideRenderer()
        end
        return
    end

    if Landing.tracked == ball and Landing.last and now > Landing.stamp then
        Landing.drift = (ball.Position - Landing.last) / (now - Landing.stamp)
    end

    Landing.tracked = ball
    Landing.last = ball.Position
    Landing.stamp = now

    if ball ~= lastPredictionBall or not lastRenderState or now - lastPredictionUpdate >= BallPredictionSettings.updateInterval then
        lastPredictionBall = ball
        lastPredictionUpdate = now
        if not buildRenderState(ball) then
            if lastRenderState and now - lastSuccessfulStateTime <= BallPredictionSettings.stateGracePeriod then
                renderState(lastRenderState)
            else
                hideRenderer()
            end
            return
        end
    end

    renderState(lastRenderState)
  end)
end)

SharedBallPrediction.connection = connection
SharedBallPrediction.destroy = function()
    clearRenderer()
end
return Landing
end)()

local function enableHitEffect()
  if hitConnection then return end
  hasFired = false
  isLocalHit = false
  local Remote = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService.RE.HitGround
  Remote.OnClientEvent:Connect(function(...)
    local args = {...}
    local myName = LocalPlayer.Name
    for _, val in pairs(args) do
      if tostring(val) == myName then isLocalHit = true break end
    end
  end)
  local function fireHitRemote(hitPos)
    if hasFired then return end
    if not isLocalHit then return end
    if not hitEffectEnabled then return end
    hasFired = true
    local targetObject = workspace:FindFirstChild(LocalPlayer.Name)
    local effectId = selectedEffect
    local hardHit = true
    if effectId == "GroundHit1" or effectId == "GroundHit2" then
      hardHit = effectId == "GroundHit2"
      effectId = nil
    end
    if firesignal then
      firesignal(Remote.OnClientEvent, table.unpack({
        hitPos, hardHit, false, 5, effectId, targetObject,
        Vector3.new(-0.000002, 1, -0.000004)
      }, 1, 7))
    end
    task.wait(0.5)
    hasFired = false
    isLocalHit = false
  end
  hitConnection = workspace.ChildAdded:Connect(function(child)
    if child.Name == "HitIndicator" and child.Color == Color3.fromRGB(0, 255, 0) then
      fireHitRemote(child.Position)
    end
  end)
  hitConnection2 = workspace.DescendantAdded:Connect(function(child)
    if child.Name == "HitIndicator" and child:IsA("BasePart") and child.Color == Color3.fromRGB(0, 255, 0) then
      fireHitRemote(child.Position)
    end
  end)
  hitRemovedConnection = workspace.DescendantRemoving:Connect(function(child)
    if child.Name == "HitIndicator" then
      hasFired = false
      isLocalHit = false
    end
  end)
end

local function disableHitEffect()
  if hitConnection then hitConnection:Disconnect() hitConnection = nil end
  if hitConnection2 then hitConnection2:Disconnect() hitConnection2 = nil end
  if hitRemovedConnection then hitRemovedConnection:Disconnect() hitRemovedConnection = nil end
  hasFired = false
  isLocalHit = false
end

local function enableAntiLag()
  local function safeGet(inst, prop)
    local ok, val = pcall(function() return inst[prop] end)
    if ok then return val end
    return nil
  end
  local function safeSet(inst, prop, value) inst[prop] = value end
  local function remember(inst, prop)
    if not inst then return false end
    local data = changedProperties[inst]
    if not data then data = {} changedProperties[inst] = data end
    if data[prop] == nil then
      local current = safeGet(inst, prop)
      if current == nil then return false end
      data[prop] = current
    end
    return true
  end
  local function set(inst, prop, value)
    if not inst then return end
    if not remember(inst, prop) then return end
    safeSet(inst, prop, value)
  end
  local function skip(inst)
    if not inst then return true end
    local char = LocalPlayer.Character
    if char and inst:IsDescendantOf(char) then return true end
    return false
  end
  local function opt(inst)
    if skip(inst) then return end
    if inst:IsA("BasePart") then
      set(inst, "Material", Enum.Material.SmoothPlastic)
      set(inst, "Reflectance", 0)
      set(inst, "CastShadow", false)
      if inst:IsA("MeshPart") then
        set(inst, "RenderFidelity", Enum.RenderFidelity.Performance)
        set(inst, "TextureID", "")
      end
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
      set(inst, "Transparency", 1)
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
      set(inst, "Enabled", false)
    elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
      set(inst, "Enabled", false)
    end
  end
  set(Lighting, "GlobalShadows", false)
  set(Lighting, "FogEnd", 1e9)
  for _, e in ipairs(Lighting:GetChildren()) do
    if e:IsA("PostEffect") then set(e, "Enabled", false) end
  end
  for _, inst in ipairs(workspace:GetDescendants()) do opt(inst) end
  table.insert(antilagConnections, workspace.DescendantAdded:Connect(opt))
end

local function disableAntiLag()
  for inst, props in pairs(changedProperties) do
    for prop, value in pairs(props) do inst[prop] = value end
  end
  changedProperties = {}
  for _, conn in ipairs(antilagConnections) do conn:Disconnect() end
  antilagConnections = {}
end

local function startAutoSpin()
  task.spawn(function()
    while autoSpin do
      local lobby = LocalPlayer.PlayerGui:FindFirstChild("Interface")
      local lobbyFolder = lobby and lobby:FindFirstChild("Lobby")
      local stylesFolder = lobbyFolder and lobbyFolder:FindFirstChild("Styles")
      local topPanel = stylesFolder and stylesFolder:FindFirstChild("TopPanel")
      local displayName = topPanel and topPanel:FindFirstChild("DisplayName")
      local currentStyle = displayName and displayName.Text or ""
      local matched = false
      for _, style in ipairs(desiredStyles) do
        if currentStyle == style then
          matched = true
          break
        end
      end
      if matched then
        autoSpin = false
        Notify({ Title = "Auto Style Spin", Content = "Got: " .. currentStyle, Type = "Success", Duration = 3 })
        break
      end
      local StyleService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.StyleService
      if StyleService then
        local RF = StyleService:FindFirstChild("RF")
        if RF then
          local Roll = RF:FindFirstChild("Roll")
          if Roll then
            Roll:InvokeServer(spinType == "Lucky")
          end
        end
      end
      task.wait(0.5)
    end
  end)
end

local function startAutoAbilitySpin()
  task.spawn(function()
    while autoAbilitySpin do
      local lobby = LocalPlayer.PlayerGui:FindFirstChild("Interface")
      local lobbyFolder = lobby and lobby:FindFirstChild("Lobby")
      local abilitiesFolder = lobbyFolder and lobbyFolder:FindFirstChild("Abilities")
      local topPanel = abilitiesFolder and abilitiesFolder:FindFirstChild("TopPanel")
      local displayName = topPanel and topPanel:FindFirstChild("DisplayName")
      local currentAbility = displayName and displayName.Text or ""
      local matched = false
      for _, ability in ipairs(desiredAbilities) do
        if currentAbility == ability then
          matched = true
          break
        end
      end
      if matched then
        autoAbilitySpin = false
        Notify({ Title = "Auto Ability Spin", Content = "Got: " .. currentAbility, Type = "Success", Duration = 3 })
        break
      end
      local AbilityService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.AbilityService
      if AbilityService then
        local RF = AbilityService:FindFirstChild("RF")
        if RF then
          local Roll = RF:FindFirstChild("Roll")
          if Roll then
            Roll:InvokeServer(abilitySpinType == "Lucky")
          end
        end
      end
      task.wait(0.5)
    end
  end)
end

local function createDraggableButton(btnName, text, color, startPos, onClick)
  local sg = Instance.new("ScreenGui")
  sg.Name = MARK .. "_" .. btnName
  sg.ResetOnSpawn = false
  sg.IgnoreGuiInset = true
  sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  sg.DisplayOrder = 9999

  local placed = false
  if type(gethui) == "function" then
    local ok, container = pcall(gethui)
    if ok and typeof(container) == "Instance" then
      sg.Parent = container
      placed = true
    end
  end
  if not placed then
    local ok = pcall(function()
      sg.Parent = game:GetService("CoreGui")
    end)
    if ok then placed = true end
  end
  if not placed then
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
  end

  local btn = Instance.new("TextButton")
  btn.Size = UDim2.new(0, 50, 0, 50)
  btn.Position = startPos
  btn.BackgroundColor3 = color
  btn.Text = text
  btn.TextColor3 = Color3.fromRGB(255, 255, 255)
  btn.TextScaled = true
  btn.Font = Enum.Font.GothamBold
  btn.Parent = sg
  btn.BackgroundTransparency = 0.2
  btn.BorderSizePixel = 0
  btn.Selectable = false
  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(1, 0)
  corner.Parent = btn

  local dragging = false
  local dragStart = nil
  local startPos2 = nil
  btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true
      dragStart = input.Position
      startPos2 = btn.Position
      input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then dragging = false end
      end)
    end
  end)
  btn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
      local delta = input.Position - dragStart
      btn.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset + delta.X, startPos2.Y.Scale, startPos2.Y.Offset + delta.Y)
    end
  end)
  btn.MouseButton1Click:Connect(onClick)
  btn.Visible = false
  return btn
end

newSpikeButton = createDraggableButton("Spike", "Spike", Color3.fromRGB(255, 165, 0), UDim2.new(0.5, -25, 0.85, -25), fireNewSpike)
stopBallButton = createDraggableButton("Stop", "Stop", Color3.fromRGB(255, 50, 50), UDim2.new(0.35, -25, 0.8, -25), stopBall)
aimButton = createDraggableButton("Aim", "Aim", Color3.fromRGB(50, 150, 255), UDim2.new(0.65, -25, 0.8, -25), aim)
dashButton = createDraggableButton("Dash", "Dash", Color3.fromRGB(255, 200, 0), UDim2.new(0.15, -25, 0.8, -25), akariDash)
leadFeetButton = createDraggableButton("LF", "LF", Color3.fromRGB(0, 255, 200), UDim2.new(0.25, -25, 0.8, -25), leadFeetSlam)

local function buildUI()
  local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
  local UISize = isMobile and UDim2.new(0, 540, 0, 340) or UDim2.new(0, 640, 0, 480)

  local Window = Library:Window({
    Logo = "110085358460110",
    FadeSpeed = 0.15,
    PagePadding = 19,
    Size = UISize
  })

  local MainPage = Window:Page({
    Name = "Main",
    Icon = "house",
    Search = true
  })

  local CharacterPage = Window:Page({
    Name = "Character",
    Icon = "user",
    Search = true
  })

  local VisualsPage = Window:Page({
    Name = "Visuals",
    Icon = "eye",
    Search = true
  })

  local MiscPage = Window:Page({
    Name = "Misc",
    Icon = "info",
    Search = true
  })

  local GamePage = Window:Page({
    Name = "Game Join",
    Icon = "gamepad-2",
    Search = true
  })

  Window:Seperator()

  local SettingsPage = Window:Page({
    Name = "Settings",
    Icon = "settings"
  })

  local actionKeys = {}

  local function bindAction(section, name, default, fn, flag)
    table.insert(actionKeys, { Flag = flag, Fn = fn })
    section:Keybind({
      Name = name,
      Flag = flag,
      Default = default,
      Mode = "Toggle",
      Callback = function() end
    })
  end

  UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    for _, entry in ipairs(actionKeys) do
      local data = Library.Flags[entry.Flag]
      if type(data) == "table" and data.Key then
        if data.Key == tostring(input.KeyCode) then
          task.spawn(entry.Fn)
        end
      end
    end
  end)

  local SpikeSub = MainPage:SubPage({ Name = "Spike" })
  local AutoSub = MainPage:SubPage({ Name = "Auto" })
  local HitboxSub = MainPage:SubPage({ Name = "Hitbox" })
  local MovementSub = MainPage:SubPage({ Name = "Movement" })

  do
    local AutoSpike = (function()
      local RunService = game:GetService("RunService")
      local player = Players.LocalPlayer

      local cfg = { enabled = false, range = 14, waitWindow = false, cooldown = 0.65 }

      local connection
      local lastFire = 0
      local airborneSince = nil
      local nextBall = 0
      local cachedBall = nil

      local function step()
        if not cfg.enabled then return end

        local now = os.clock()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not root or hum.Health <= 0 then
          airborneSince = nil
          return
        end

        if hum.FloorMaterial ~= Enum.Material.Air then
          airborneSince = nil
          return
        end
        airborneSince = airborneSince or now

        if now - lastFire < cfg.cooldown then return end
        if now - airborneSince < 0.08 then return end

        if not (cachedBall and cachedBall.Parent) or now >= nextBall then
          nextBall = now + 0.04
          cachedBall = getNearestBall()
        end
        local ball = cachedBall
        if not ball or not ball.Parent then return end

        local offset = ball.Position - root.Position
        if offset.Y < -2 then return end
        local dist = offset.Magnitude
        if dist > cfg.range then return end

        if cfg.waitWindow then
          local vy = root.AssemblyLinearVelocity.Y
          local inWindow = dist <= math.max(cfg.range * 0.55, 6) or math.abs(vy) <= 8
          if not inWindow then return end
        end

        lastFire = now

        if firesignal then
          pcall(firesignal, doMove.OnClientEvent, "Spike", false, false)
        end
      end

      local M = { cfg = cfg }

      function M.set(v)
        cfg.enabled = v and true or false
        if cfg.enabled then
          if not connection then
            connection = RunService.Heartbeat:Connect(function()
              pcall(step)
            end)
          end
        else
          if connection then connection:Disconnect() connection = nil end
          airborneSince = nil
          cachedBall = nil
        end
      end

      return M
    end)()

    local AutoSpikeSection = SpikeSub:Section({ Name = "Auto Spike", Side = "Left" })

    AutoSpikeSection:Toggle({
      Name = "Auto Spike",
      Flag = "autospike",
      Default = false,
      Callback = function(v) AutoSpike.set(v) end
    })

    AutoSpikeSection:Slider({
      Name = "Spike range",
      Flag = "autospike_range",
      Min = 6,
      Max = 20,
      Default = 14,
      Decimals = 0,
      Callback = function(v) AutoSpike.cfg.range = v end
    })

    AutoSpikeSection:Toggle({
      Name = "Wait for the power window",
      Flag = "autospike_window",
      Default = false,
      Callback = function(v) AutoSpike.cfg.waitWindow = v end
    })
  end

  local SpikeSection = SpikeSub:Section({ Name = "Spike Settings", Side = "Left" })
  local ServeSection = SpikeSub:Section({ Name = "Max Serve", Side = "Right" })
  local SmartAimSection = SpikeSub:Section({ Name = "Smart Aim", Side = "Right" })

  SpikeSection:Toggle({
    Name = "Redirect Spike",
    Flag = "redirectspike",
    Default = false,
    Callback = function(v)
      if v then enableRedirectSpike() else disableRedirectSpike() end
    end
  })

  SmartAimSection:Toggle({
    Name = "Auto Cut",
    Flag = "autocut",
    Default = false,
    Callback = function(v)
      AutoCorner.cutEnabled = v
      if v then
        AutoCorner.installAim()
        AutoCorner.watch()
      else
        AutoCorner.cut = nil
      end
    end
  })

  SmartAimSection:Slider({
    Name = "Cut distance from net",
    Flag = "autocut_range",
    Min = 4,
    Max = 14,
    Default = 9,
    Decimals = 0,
    Callback = function(v) AutoCorner.cutRange = v end
  })

  SmartAimSection:Toggle({
    Name = "Auto Perfect Corner",
    Flag = "autocorner",
    Default = false,
    Callback = function(v)
      AutoCorner.enabled = v
      if v then
        AutoCorner.installAim()
        AutoCorner.watch()
      else
        AutoCorner.drift = Vector3.zero
        AutoCorner.steer = nil
      end
    end
  })

  SpikeSection:Toggle({
    Name = "Silent Spike",
    Flag = "newspike",
    Default = false,
    Callback = function(v)
      newSilentSpikeEnabled = v
      if newSpikeButton then newSpikeButton.Visible = v end
    end
  })

  bindAction(SpikeSection, "Silent Spike bind", Enum.KeyCode.R, fireNewSpike, "silentspikebind")

  SpikeSection:Toggle({
    Name = "Sanju Tilt",
    Flag = "sanju",
    Default = false,
    Callback = function(v)
      if v then enableSanjuTilt() else disableSanjuTilt() end
    end
  })

  SpikeSection:Toggle({
    Name = "Max Charge Special",
    Flag = "maxcharge",
    Default = false,
    Callback = function(v)
      if v then enableMaxCharge() else disableMaxCharge() end
    end
  })

  SpikeSection:Toggle({
    Name = "Fake Spike",
    Flag = "fakespike",
    Default = false,
    Callback = function(v) fakeSpikeEnabled = v end
  })

  ServeSection:Toggle({
    Name = "Max Serve",
    Flag = "maxserve",
    Default = false,
    Callback = function(v)
      if v then enableMaxServe() else disableMaxServe() end
    end
  })

  local FarmSection = AutoSub:Section({ Name = "Auto Farm", Side = "Left" })
  local CounterSection = AutoSub:Section({ Name = "Auto Counter", Side = "Right" })
  local SetSection = AutoSub:Section({ Name = "Auto Set", Side = "Left" })
  local AimSetSection = AutoSub:Section({ Name = "Aim Set", Side = "Right" })

  FarmSection:Toggle({
    Name = "Auto Farm",
    Flag = "autofarm",
    Default = false,
    Callback = function(v)
      if v then AutoFarm:start() else AutoFarm:stop() end
    end
  })

  CounterSection:Toggle({
    Name = "Auto Counter",
    Flag = "autocounter",
    Default = false,
    Callback = function(v) AutoCounter.enabled = v end
  })

  CounterSection:Dropdown({
    Name = "Counter Move",
    Flag = "autocountermove",
    Items = { "Auto", "Block", "Spike" },
    Default = "Auto",
    Callback = function(v) AutoCounter.move = v end
  })

  CounterSection:Slider({
    Name = "Counter Net Range",
    Flag = "autocounternetrange",
    Min = 3,
    Max = 20,
    Default = 9,
    Decimals = 0,
    Callback = function(v) AutoCounter.netRange = v end
  })

  CounterSection:Slider({
    Name = "Counter Width",
    Flag = "autocounterlateral",
    Min = 4,
    Max = 30,
    Default = 14,
    Decimals = 0,
    Callback = function(v) AutoCounter.lateral = v end
  })

  CounterSection:Slider({
    Name = "Counter Delay",
    Flag = "autocounterdelay",
    Min = 0,
    Max = 0.5,
    Default = 0.05,
    Decimals = 0.05,
    Callback = function(v) AutoCounter.delay = v end
  })

  CounterSection:Toggle({
    Name = "Counter Auto Jump",
    Flag = "autocounterjump",
    Default = false,
    Callback = function(v) AutoCounter.autoJump = v end
  })

  SetSection:Toggle({
    Name = "Auto Set",
    Flag = "autoset",
    Default = false,
    Callback = function(v)
      AutoSet.enabled = v
      if v then AutoSet.start() else AutoSet.stop() end
    end
  })

  SetSection:Dropdown({
    Name = "Auto Set Target",
    Flag = "autosettarget",
    Items = { "Nearest", "Random" },
    Default = "Nearest",
    Callback = function(v) AutoSet.mode = v end
  })

  bindAction(SetSection, "Set keybind", Enum.KeyCode.F, function()
    if not AutoSet.enabled then return end
    if AutoSet.fire() then
      Notify({ Title = "Set fired", Duration = 1 })
    else
      Notify({ Title = "No target or ball", Duration = 1 })
    end
  end, "autosetbind")

  AimSetSection:Toggle({
    Name = "Aim Set",
    Flag = "aimset",
    Default = false,
    Callback = function(v)
      AimSet.enabled = v
      if v then AimSet.start() else AimSet.stop() end
    end
  })

  AimSetSection:Dropdown({
    Name = "Aim Set Target",
    Flag = "aimsettarget",
    Items = { "Nearest", "Random" },
    Default = "Nearest",
    Callback = function(v) AimSet.mode = v end
  })

  AimSetSection:Toggle({
    Name = "Jinko Curve Spike",
    Flag = "jinkocurve",
    Default = false,
    Callback = function(v)
      JinkoCurve.enabled = v
      if v then JinkoCurve.start() else JinkoCurve.stop() end
    end
  })

  local HitboxSection = HitboxSub:Section({ Name = "Hitbox Settings", Side = "Left" })
  local HelperSection = HitboxSub:Section({ Name = "Helpers", Side = "Right" })

  HitboxSection:Toggle({
    Name = "Enable Hitbox",
    Flag = "hitboxenable",
    Default = false,
    Callback = function(v)
      if v then enableHitbox() else disableHitbox() end
    end
  })

  HitboxSection:Slider({
    Name = "Hitbox Size",
    Flag = "hitboxsize",
    Min = 0,
    Max = 20,
    Default = 5,
    Suffix = " studs",
    Decimals = 0,
    Callback = setHitboxScale
  })

  HitboxSection:Label("Hitbox Color", "Left"):Colorpicker({
    Name = "Hitbox Color",
    Flag = "hitboxcolor",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(color) setHitboxColor(color) end
  })

  HitboxSection:Button({
    Name = "Remove Hitboxes",
    Callback = function() Hitbox.disable() end
  })

  HelperSection:Button({
    Name = "Show Stop Ball",
    Callback = function()
      stopBallVisible = not stopBallVisible
      if stopBallButton then stopBallButton.Visible = stopBallVisible end
    end
  })

  HelperSection:Button({
    Name = "Show Aim",
    Callback = function()
      aimVisible = not aimVisible
      if aimButton then aimButton.Visible = aimVisible end
    end
  })

  HelperSection:Button({
    Name = "Data Rollback",
    Callback = function()
      local Remote = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index")
        :WaitForChild("sleitnick_knit@1.7.0"):WaitForChild("knit")
        :WaitForChild("Services"):WaitForChild("SettingsService"):WaitForChild("RF")
        :WaitForChild("UpdateKeybind")
      Remote:InvokeServer("MouseButton1", true, "Spike\xE2\x80\x8B\x8F")
      game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
  })

  local MoveSection = MovementSub:Section({ Name = "Movement", Side = "Left" })
  local PerfSection = MovementSub:Section({ Name = "Performance", Side = "Right" })

  SmartAimSection:Toggle({
    Name = "Desync Spike",
    Flag = "desync",
    Default = false,
    Callback = function(v)
      if v then enableDesync() else disableDesync() end
    end
  })

  do
    local AutoDive = (function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Workspace = game:GetService("Workspace")
      local player = Players.LocalPlayer

      local cfg = { enabled = false, range = 16, cooldown = 0.6 }

      local connection
      local lastBall, lastPos, lastTime = nil, nil, 0
      local velocity = Vector3.zero
      local lastSpeed = 0
      local lastDive = 0
      local dive = nil
      local savedAutoRotate = nil
      local physicsModule, gameConfig, stateModule

      local function loadModules()
        if not physicsModule then
          local ok, m = pcall(require, ReplicatedStorage.Common.Physics)
          if ok then physicsModule = m end
        end
        if not gameConfig then
          local ok, m = pcall(require, ReplicatedStorage.Configuration.Game)
          if ok then gameConfig = m end
        end
        if not stateModule then
          local ok, m = pcall(require, ReplicatedStorage.Common.State)
          if ok then stateModule = m end
        end
      end

      local function gravity()
        local ok, value = pcall(function()
          if not gameConfig or not stateModule then return nil end
          return stateModule.get(ReplicatedStorage, stateModule.Id.Modifier, "BallGravity", gameConfig.Physics.Gravity)
        end)
        if ok and type(value) == "number" and value > 0 then return value end
        return 17
      end

      local function floorHeight(pos, fallback)
        if physicsModule then
          if physicsModule.LastFloorHeight then return physicsModule.LastFloorHeight end
          local ok, h = pcall(physicsModule.calculateFloorHeight, pos, true)
          if ok and type(h) == "number" then return h end
        end
        return fallback
      end

      local function endDive(hum)
        if savedAutoRotate ~= nil and hum and hum.Parent then
          pcall(function() hum.AutoRotate = savedAutoRotate end)
        end
        savedAutoRotate = nil
        dive = nil
      end

      local ballController = nil
      local cachedBall = nil
      local nextBallSearch = 0

      local function controllerVelocity(part)
        if not ballController then
          local ok, controller = pcall(function()
            local Knit = require(ReplicatedStorage.Packages.Knit)
            return Knit.GetController("BallController")
          end)
          if ok and type(controller) == "table" then ballController = controller end
        end
        if ballController and type(ballController.ActiveBalls) == "table" then
          for _, record in pairs(ballController.ActiveBalls) do
            local model = record.Ball
            if model and model.Parent and model:IsAncestorOf(part) and typeof(record.Velocity) == "Vector3" then
              return record.Velocity
            end
          end
        end
        return nil
      end

      local function findBall(now)
        if cachedBall and cachedBall.Parent and now < nextBallSearch then return cachedBall end
        nextBallSearch = now + 0.2
        cachedBall = getNearestBall()
        return cachedBall
      end

      local function evaluate(ball, vel, root, hum)
        local pos = ball.Position
        local g = gravity()
        local radius = ball.Size.Y * 0.5
        local floorY = floorHeight(pos, root.Position.Y - 3) + radius
        local drop = pos.Y - floorY
        if drop <= 0 then return nil end

        local disc = vel.Y * vel.Y + 2 * g * drop
        if disc < 0 then return nil end
        local t = (vel.Y + math.sqrt(disc)) / g
        if t ~= t or t <= 0 or t > 4 then return nil end

        local landing = Vector3.new(pos.X + vel.X * t, floorY, pos.Z + vel.Z * t)

        local map = Workspace:FindFirstChild("Map")
        local collide = map and map:FindFirstChild("BallCollideOnly")
        local net = collide and collide:FindFirstChild("Net")
        if net then
          local ownSide = (root.Position.Z > net.Position.Z) and 1 or -1
          if (landing.Z - net.Position.Z) * ownSide <= 0 then return nil end
        end

        if physicsModule and physicsModule.isPositionInCourt then
          local ok, inside = pcall(physicsModule.isPositionInCourt, landing, nil, radius, nil)
          if ok and inside == false then return nil end
        end

        return landing, t
      end

      local function step()
        local now = os.clock()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")

        local ball = nil
        local landing, t = nil, nil
        if cfg.enabled and hum and root and hum.Health > 0 then
          ball = findBall(now)
          if ball then
            loadModules()
            local vel = controllerVelocity(ball)
            if not vel then
              if lastBall == ball and lastPos and now > lastTime then
                local raw = (ball.Position - lastPos) / (now - lastTime)
                velocity = velocity:Lerp(raw, 0.7)
              else
                velocity = Vector3.zero
              end
              vel = velocity
            end
            lastBall = ball
            lastPos = ball.Position
            lastTime = now
            if vel.Magnitude >= 4 then
              landing, t = evaluate(ball, vel, root, hum)
              lastSpeed = vel.Magnitude
            end
          else
            lastBall = nil
          end
        end

        if dive then
          if not root or not hum or hum.Health <= 0 or now >= dive.untilT then
            endDive(hum)
          else
            if landing then
              local d = Vector3.new(landing.X - root.Position.X, 0, landing.Z - root.Position.Z).Magnitude
              if d <= cfg.range + 4 then dive.target = landing end
            end
            local toTarget = Vector3.new(dive.target.X - root.Position.X, 0, dive.target.Z - root.Position.Z)
            if toTarget.Magnitude < 1.5 then
              endDive(hum)
            else
              local dir = toTarget.Unit
              hum.AutoRotate = false
              hum:Move(dir, false)
              local v = root.AssemblyLinearVelocity
              root.AssemblyLinearVelocity = Vector3.new(dir.X * dive.speed, v.Y, dir.Z * dive.speed)
              root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
            end
          end
          return
        end

        if not landing or not hum or not root then return end
        if now - lastDive < cfg.cooldown then return end
        if hum.FloorMaterial == Enum.Material.Air then return end

        local toLanding = Vector3.new(landing.X - root.Position.X, 0, landing.Z - root.Position.Z)
        local dist = toLanding.Magnitude
        if dist < 4 or dist > cfg.range then return end

        local walkReach = hum.WalkSpeed * t * 0.85
        if dist <= walkReach then return end

        local ping = 0.05
        pcall(function() ping = player:GetNetworkPing() end)
        local duration = math.clamp(dist / 45, 0.25, 0.55)
        local lead = duration + ping + 0.06 + math.clamp(lastSpeed / 500, 0, 0.12)
        if t > lead then return end

        local urgent = t < duration * 0.55
        if urgent then duration = math.max(t + 0.05, 0.18) end

        lastDive = now
        savedAutoRotate = hum.AutoRotate
        dive = {
          target = landing,
          speed = math.clamp(dist / duration, 24, urgent and 90 or 70),
          untilT = now + duration + 0.15,
        }

        local dir = toLanding.Unit
        hum.AutoRotate = false
        root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)

        if firesignal then
          pcall(firesignal, doMove.OnClientEvent, "Dive", false, false)
        end
      end

      local M = { cfg = cfg }

      function M.set(v)
        cfg.enabled = v and true or false
        if cfg.enabled then
          if not connection then
            connection = RunService.Heartbeat:Connect(function()
              pcall(step)
            end)
          end
        else
          if connection then connection:Disconnect() connection = nil end
          local char = player.Character
          endDive(char and char:FindFirstChildOfClass("Humanoid"))
          lastBall = nil
          velocity = Vector3.zero
        end
      end

      return M
    end)()

    local DiveSection = AutoSub:Section({ Name = "Auto Dive", Side = "Left" })

    DiveSection:Toggle({
      Name = "Auto Dive",
      Flag = "autodive",
      Default = false,
      Callback = function(v) AutoDive.set(v) end
    })

    DiveSection:Slider({
      Name = "Dive range",
      Flag = "autodive_range",
      Min = 6,
      Max = 30,
      Default = 16,
      Decimals = 0,
      Callback = function(v) AutoDive.cfg.range = v end
    })
  end

  local AutoReceiveToggle = MoveSection:Toggle({
    Name = "Auto Receive",
    Flag = "autoreceive",
    Default = false,
    Callback = function(v)
      AutoReceive.enabled = v
      if v then AutoReceive.start() else AutoReceive.stop() end
    end
  })

  bindAction(MoveSection, "Auto Receive bind", Enum.KeyCode.X, function()
    AutoReceive.enabled = not AutoReceive.enabled
    if AutoReceive.enabled then
      AutoReceive.start()
    else
      AutoReceive.stop()
    end
    AutoReceiveToggle:Set(AutoReceive.enabled)
    Notify({
      Title = "Auto Receive",
      Content = AutoReceive.enabled and "Enabled" or "Disabled",
      Duration = 1
    })
  end, "autoreceivebind")

  MoveSection:Dropdown({
    Name = "Receive Method",
    Flag = "autoreceivemethod",
    Items = { "Bump", "Set", "Dive" },
    Default = "Bump",
    Callback = function(v) AutoReceive.setMethod(v) end
  })

  MoveSection:Slider({
    Name = "Receive Range",
    Flag = "autoreceiverange",
    Min = 3,
    Max = 50,
    Default = 20,
    Decimals = 0,
    Callback = function(v) AutoReceive.setRadius(v) end
  })

  MoveSection:Toggle({
    Name = "Akari Dash",
    Flag = "akaridash",
    Default = false,
    Callback = function(v)
      akariDashEnabled = v
      if dashButton then dashButton.Visible = v end
    end
  })

  bindAction(MoveSection, "Akari Dash bind", Enum.KeyCode.F, akariDash, "akaridashbind")

  MoveSection:Toggle({
    Name = "Lead Feet",
    Flag = "leadfeet",
    Default = false,
    Callback = function(v)
      leadFeetEnabled = v
      if leadFeetButton then leadFeetButton.Visible = v end
    end
  })

  bindAction(MoveSection, "Lead Feet bind", Enum.KeyCode.G, leadFeetSlam, "leadfeetbind")

  PerfSection:Toggle({
    Name = "Anti-Lag",
    Flag = "antilag",
    Default = false,
    Callback = function(v)
      if v then enableAntiLag() else disableAntiLag() end
    end
  })

  PerfSection:Toggle({
    Name = "Jump ESP",
    Flag = "esp",
    Default = false,
    Callback = function(v)
      espJumpEnabled = v
      if not v then
        for player in pairs(espHighlights) do removeESP(player) end
      end
    end
  })

  local AttrSub = CharacterPage:SubPage({ Name = "Attributes" })
  local CharMoveSub = CharacterPage:SubPage({ Name = "Movement" })

  local AttrSection = AttrSub:Section({ Name = "Attributes", Side = "Left" })
  local BallEspSection = AttrSub:Section({ Name = "Ball ESP", Side = "Right" })

  AttrSection:Textbox({
    Name = "Dive Speed",
    Flag = "divespeed",
    Placeholder = "0.95",
    Callback = function(v)
      local n = tonumber(v)
      if n then LocalPlayer:SetAttribute("Multiplier_DiveSpeed", n) end
    end
  })

  AttrSection:Textbox({
    Name = "Jump Power",
    Flag = "jumppower",
    Placeholder = "1.1",
    Callback = function(v)
      local n = tonumber(v)
      if n then LocalPlayer:SetAttribute("Multiplier_JumpPower", n) end
    end
  })

  AttrSection:Textbox({
    Name = "Speed",
    Flag = "speed",
    Placeholder = "0.85",
    Callback = function(v)
      local n = tonumber(v)
      if n then LocalPlayer:SetAttribute("Multiplier_Speed", n) end
    end
  })

  BallEspSection:Toggle({
    Name = "Ball ESP",
    Flag = "ballesp",
    Default = false,
    Callback = function(v)
      BallESP.enabled = v
      if v then BallESP.start() else BallESP.stop() end
    end
  })

  BallEspSection:Label("ESP Color", "Left"):Colorpicker({
    Name = "ESP Color",
    Flag = "ballespcolor",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(color) BallESP.setColor(color) end
  })

  local AirSection = CharMoveSub:Section({ Name = "Movement", Side = "Left" })
  local LinesSection = CharMoveSub:Section({ Name = "Character Lines", Side = "Right" })

  AirSection:Toggle({
    Name = "Air Movement",
    Flag = "airmove",
    Default = false,
    Callback = function(v)
      airMovement = v
      if not v and bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
      end
    end
  })

  AirSection:Slider({
    Name = "Air Movement Speed",
    Flag = "airspeed",
    Min = 0,
    Max = 100,
    Default = 16,
    Decimals = 0,
    Callback = function(v) airMovementSpeed = v end
  })

  AirSection:Toggle({
    Name = "Auto Shift Lock",
    Flag = "autoshiftlock",
    Default = false,
    Callback = function(v)
      autoShiftLockEnabled = v
      if not v then
        local c = LocalPlayer.Character
        if c then
          local h = c:FindFirstChild("Humanoid")
          if h then h.AutoRotate = false end
        end
      end
    end
  })

  LinesSection:Toggle({
    Name = "Character Lines",
    Flag = "characterlines",
    Default = false,
    Callback = function(v)
      linesEnabled = v
      if not v then
        for player in pairs(lines) do removeLine(player) end
      end
    end
  })

  LinesSection:Slider({
    Name = "Line Distance",
    Flag = "linedistance",
    Min = 10,
    Max = 200,
    Default = 50,
    Decimals = 0,
    Callback = function(v) lineDistance = v end
  })

  local UnlockAll = (function()
    local ran = false
    local active = false
    local scripts = {}
    local loopFns = {}
    local loopRunning = {}
    local entryProviders = {}
    local skinFn = nil
    local saved = {}
    local restoreFns = {}
    local SAVE_FILE = "zerith_vbl_equipped_" .. tostring(game:GetService("Players").LocalPlayer.UserId) .. ".json"

    local function loadSaved()
      pcall(function()
        if isfile and readfile and isfile(SAVE_FILE) then
          local data = game:GetService("HttpService"):JSONDecode(readfile(SAVE_FILE))
          if type(data) == "table" then saved = data end
        end
      end)
    end

    local function saveEquip(key, value, slot)
      if slot ~= nil then
        if type(saved[key]) ~= "table" then saved[key] = {} end
        saved[key][tostring(slot)] = value
      else
        saved[key] = value
      end
      pcall(function()
        if writefile then
          writefile(SAVE_FILE, game:GetService("HttpService"):JSONEncode(saved))
        end
      end)
    end
    local hookedFns = setmetatable({}, { __mode = "k" })

    local function installHooks()
      local found = {}
      local n = 0
      for _, func in ipairs(getgc()) do
        n = n + 1
        if n % 500 == 0 then task.wait() end
        if typeof(func) == "function" and not hookedFns[func] then
          local ok, name = pcall(function() return tostring(getfenv(func).script) end)
          if ok and (name == "buildEntries" or name == "BallController") then
            local okl, line = pcall(debug.info, func, "l")
            found[#found + 1] = { func = func, name = name, line = okl and line or nil }
          end
        end
      end
      for _, e in ipairs(found) do
        if not hookedFns[e.func] then
          if e.name == "buildEntries" then
            hookedFns[e.func] = true
            local old
            old = hookfunction(e.func, function(p1, p2)
              if active and type(p1) == "table" then
                for _, prov in ipairs(entryProviders) do
                  local r = prov(p1)
                  if r then return r end
                end
              end
              return old(p1, p2)
            end)
          elseif e.name == "BallController" and e.line == 62 then
            hookedFns[e.func] = true
            local old4
            old4 = hookfunction(e.func, function(p1)
              if active and skinFn and type(p1) == "table" and p1.Skin and not workspace:FindFirstChild("CLIENT_BALL_" .. tostring(p1.ID)) then
                local sk = skinFn()
                if sk then p1.Skin = sk end
              end
              return old4(p1)
            end)
          end
        end
      end
    end

    loopFns[#loopFns + 1] = function()
      while active do
        task.wait(6)
        if not active then break end
        pcall(installHooks)
      end
    end

    scripts[#scripts + 1] = function()
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Knit = require(ReplicatedStorage.Packages.Knit)
      local Item = require(ReplicatedStorage.Content.Item)
      local InventoryController = Knit.GetController("InventoryController")
      local InventoryService = Knit.GetService("InventoryService")
      local InventoryValue = InventoryController.Inventory
      local inv = InventoryValue:get()
      local isEquipped = require(game.ReplicatedFirst.Controllers.InventoryController.IsEquipped)
      local Players = game:GetService("Players")
      local TextChatService = game:GetService("TextChatService")

      local TargetItemType = Item.Type.Title 

      local toggled = {}
      local Items = {}
      local allTargetItems = Item:GetAllFromType(TargetItemType)

      for _, item in pairs(allTargetItems) do
          Items[item.Id] = true
          inv[item.Id] = 1
      end
      InventoryValue:set(table.clone(inv))

      local old3
      old3 = hookfunction(isEquipped, function(item, equippedTable, selected)
          if active and Items[selected] and toggled[selected] ~= nil then
              return toggled[selected]
          end
          return old3(item, equippedTable, selected)
      end)

      local old2
      old2 = hookfunction(InventoryService.Equip, function(self, id)
          local result = old2(self, id)
          if active and Items[id] then
              for k, _ in pairs(toggled) do
                  toggled[k] = nil
              end
              toggled[id] = true
              saveEquip("Title", id)
              local eq = InventoryController.Equipped:get()
              InventoryController.Equipped:set(table.clone(eq))
          end
          return result
      end)

      local fakeEntries = {}
      for _, item in pairs(allTargetItems) do
          table.insert(fakeEntries, {
              Name = item.Id, 
              Item = item, 
              Count = 1, 
              IsRandom = false
          })
      end

      entryProviders[#entryProviders + 1] = function(p1)
          if p1.ItemType == TargetItemType then return fakeEntries end
      end

      restoreFns[#restoreFns + 1] = function()
          local id = saved.Title
          if id and Items[id] then
              for k, _ in pairs(toggled) do toggled[k] = nil end
              toggled[id] = true
          end
      end

      local function color3ToHex(c3)
          return string.format("#%02X%02X%02X", math.round(c3.R*255), math.round(c3.G*255), math.round(c3.B*255))
      end

      local function extractColor(item)
          local keys = {"Color", "TagColor", "TitleColor", "ChatColor", "TextColor", "NameColor", "PrefixColor", "Color3", "DisplayColor"}
          for _, key in ipairs(keys) do
              if typeof(item[key]) == "Color3" then return item[key] end
              if typeof(item[key]) == "string" and item[key]:sub(1,1) == "#" then
                  local success, c3 = pcall(function() return Color3.fromHex(item[key]) end)
                  if success then return c3 end
              end
          end
          if type(item.Rarity) == "table" and typeof(item.Rarity.Color) == "Color3" then
              return item.Rarity.Color
          end
          if type(item) == "table" then
              for _, v in pairs(item) do
                  if typeof(v) == "Color3" then return v end
              end
          end
          return Color3.fromRGB(255, 255, 255)
      end

      local function getEquippedTitleData()
          if not active then return "", nil end
          for id, isToggled in pairs(toggled) do
              if isToggled then
                  for _, item in pairs(allTargetItems) do
                      if item.Id == id then
                          local name = item.DisplayName or item.Name or id
                          return name, extractColor(item)
                      end
                  end
                  return id, Color3.fromRGB(255, 255, 255)
              end
          end
          return "", nil
      end

      if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
          TextChatService.OnIncomingMessage = function(message)
              local properties = Instance.new("TextChatMessageProperties")
              if message.TextSource then
                  local player = Players:GetPlayerByUserId(message.TextSource.UserId)
                  if player == Players.LocalPlayer then
                      local currentTitle, titleColor = getEquippedTitleData()
                      if currentTitle ~= "" then
                          local hexColor = color3ToHex(titleColor)
                          properties.PrefixText = "<font color='" .. hexColor .. "'>[" .. currentTitle .. "]</font> " .. (message.PrefixText or "")
                      end
                  end
              end
              return properties
          end
      else
          local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
          if chatEvents then
              local function modifyMessageData(messageData)
                  if messageData and messageData.FromSpeaker == Players.LocalPlayer.Name then
                      local currentTitle, titleColor = getEquippedTitleData()
                      if currentTitle ~= "" then
                          messageData.ExtraData = messageData.ExtraData or {}
                          messageData.ExtraData.Tags = messageData.ExtraData.Tags or {}
                          local hasTag = false
                          for _, tag in pairs(messageData.ExtraData.Tags) do
                              if tag.TagText == currentTitle then
                                  hasTag = true
                                  break
                              end
                          end
                          if not hasTag then
                              table.insert(messageData.ExtraData.Tags, 1, {
                                  TagText = currentTitle,
                                  TagColor = titleColor
                              })
                          end
                      end
                  end
                  return messageData
              end

              local eventsToHook = {"OnNewMessage", "OnMessageDoneFiltering"}
              for _, eventName in ipairs(eventsToHook) do
                  local event = chatEvents:FindFirstChild(eventName)
                  if event then
                      for _, conn in pairs(getconnections(event.OnClientEvent)) do
                          local oldFunc = conn.Function
                          conn:Disable()
                          event.OnClientEvent:Connect(function(messageData, ...)
                              messageData = modifyMessageData(messageData)
                              oldFunc(messageData, ...)
                          end)
                      end
                  end
              end
          end
      end
    end

    scripts[#scripts + 1] = function()
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")
      local LocalPlayer = Players.LocalPlayer
      local Item = require(ReplicatedStorage.Content.Item)
      local Knit = require(ReplicatedStorage.Packages.Knit)
      local InventoryController = Knit.GetController("InventoryController")
      local InventoryService = Knit.GetService("InventoryService")
      local InventoryValue = InventoryController.Inventory
      local isEquipped = require(game.ReplicatedFirst.Controllers.InventoryController.IsEquipped)

      local inv = InventoryValue and InventoryValue.get and InventoryValue:get() or {}
      local Items = {}
      local fakeEntries = {}
      local emoteType = Item.Type.Emote or "Emote"
      local allEmotes = Item:GetAllFromType(emoteType)

      if allEmotes then
          for _, emote in pairs(allEmotes) do
              Items[emote.Id] = emote
              inv[emote.Id] = 1
              if type(emote) == "table" then
                  emote.Challenge = nil
                  emote.ChallengeId = nil
                  emote.ChallengeToUnlock = nil
                  emote.Locked = false
                  emote.IsLocked = false
                  emote.Hidden = false
                  emote.IsHidden = false
                  emote.Gamepass = nil
                  emote.Pass = nil
                  emote.ProductId = nil
                  emote.Exclusive = false
              end
              table.insert(fakeEntries, {Name = emote.Id, Item = emote, Count = 1, IsRandom = false})
          end
      end

      if InventoryValue and InventoryValue.set then
          InventoryValue:set(table.clone(inv))
      end

      local EMOTE_PROP = "WH_EmoteProp"
      local function clearEmoteProps(char)
          char = char or LocalPlayer.Character
          local function wipe(root)
              if not root then return end
              for _, d in ipairs(root:GetChildren()) do
                  if d.Name == EMOTE_PROP or d:GetAttribute("WH_EmoteProp") == true then
                      pcall(function() d:Destroy() end)
                  end
              end
          end
          wipe(char)
          wipe(workspace)
          if char then
              for _, d in ipairs(char:GetDescendants()) do
                  if d:GetAttribute("WH_EmoteProp") == true then
                      pcall(function() d:Destroy() end)
                  end
              end
          end
      end

      local function preparePropClone(clone)
          clone.Name = EMOTE_PROP
          pcall(function() clone:SetAttribute("WH_EmoteProp", true) end)
          for _, d in ipairs(clone:GetDescendants()) do
              if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ProximityPrompt") then
                  pcall(function() d:Destroy() end)
              elseif d:IsA("BasePart") then
                  d.CanCollide = false
                  d.CanTouch = false
                  d.Massless = true
                  d.Anchored = false
              end
          end
          if clone:IsA("BasePart") then
              clone.CanCollide = false
              clone.CanTouch = false
              clone.Massless = true
              clone.Anchored = false
          end
      end

      local function getPropPrimary(inst)
          if inst:IsA("BasePart") then return inst end
          if inst:IsA("Model") then
              return inst.PrimaryPart or inst:FindFirstChildWhichIsA("MeshPart", true) or inst:FindFirstChildWhichIsA("BasePart", true)
          end
          return nil
      end

      local function digInstanceProp(t, depth)
          if typeof(t) ~= "table" or depth > 5 then return nil end
          for k, v in pairs(t) do
              local lk = string.lower(tostring(k))
              if typeof(v) == "Instance" and (v:IsA("Model") or v:IsA("BasePart") or v:IsA("MeshPart")) then
                  if string.find(lk, "prop", 1, true) or string.find(lk, "model", 1, true) or string.find(lk, "prefab", 1, true) or string.find(lk, "rig", 1, true) or string.find(lk, "bed", 1, true) or string.find(lk, "crab", 1, true) or string.find(lk, "template", 1, true) or string.find(lk, "display", 1, true) or string.find(lk, "visual", 1, true) then
                      return v
                  end
              elseif typeof(v) == "table" then
                  local found = digInstanceProp(v, depth + 1)
                  if found then return found end
              end
          end
          return nil
      end

      local function resolveEmotePropSource(id, mod, meta)
          local fromMod = digInstanceProp(mod, 0) or digInstanceProp(meta, 0)
          if fromMod then return fromMod end

          local lid = string.lower(tostring(id or ""))
          local hints = { id, tostring(id):gsub("Emote$", "") }
          if string.find(lid, "sleep", 1, true) then
              local extra = { "Bed", "SleepingBed", "SleepBed", "Cot", "Mattress", "Sleeping", "SleepingEmote", "SleepEmote" }
              for i = 1, #extra do hints[#hints + 1] = extra[i] end
          end
          if string.find(lid, "crab", 1, true) then
              local extra = { "Crab", "CrabRave", "CrabEmote", "Grap", "CrabProp", "CrabModel" }
              for i = 1, #extra do hints[#hints + 1] = extra[i] end
          end

          local content = ReplicatedStorage:FindFirstChild("Content")
          local searchRoots = {
              content,
              content and content:FindFirstChild("Item"),
              content and content:FindFirstChild("Item") and content.Item:FindFirstChild("Assets"),
              content and content:FindFirstChild("Item") and content.Item:FindFirstChild("Models"),
              content and content:FindFirstChild("Item") and content.Item:FindFirstChild("Props"),
              content and content:FindFirstChild("Props"),
              content and content:FindFirstChild("Assets"),
              content and content:FindFirstChild("Emotes"),
              ReplicatedStorage:FindFirstChild("Assets"),
              ReplicatedStorage:FindFirstChild("Models"),
              ReplicatedStorage:FindFirstChild("Props"),
          }

          local function findNamedProp(root, name)
              if not root or not name then return nil end
              local hit = root:FindFirstChild(name, true)
              if hit and (hit:IsA("Model") or hit:IsA("BasePart") or hit:IsA("MeshPart")) then return hit end
              return nil
          end

          for i = 1, #hints do
              local hint = hints[i]
              for r = 1, #searchRoots do
                  local found = findNamedProp(searchRoots[r], hint)
                  if found then return found end
              end
          end

          if content then
              for _, d in ipairs(content:GetDescendants()) do
                  if d:IsA("Model") or d:IsA("MeshPart") then
                      local n = string.lower(d.Name)
                      for i = 1, #hints do
                          local h = string.lower(tostring(hints[i]))
                          if n == h or (string.len(h) >= 4 and string.find(n, h, 1, true)) then
                              return d
                          end
                      end
                  end
              end
          end
          return nil
      end

      local function attachEmoteProp(char, source, id)
          if not char or not source then return false end
          local ok, clone = pcall(function() return source:Clone() end)
          if not ok or not clone then return false end
          preparePropClone(clone)

          local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
          if not root then
              clone:Destroy()
              return false
          end

          local lid = string.lower(tostring(id or ""))
          local offset = CFrame.new(0, -3, 0)
          if string.find(lid, "sleep", 1, true) then
              offset = CFrame.new(0, -2.8, 0.2)
          elseif string.find(lid, "crab", 1, true) then
              offset = CFrame.new(0, -2.4, -0.5)
          end

          clone.Parent = char
          local primary = getPropPrimary(clone)
          if clone:IsA("Model") and primary then
              pcall(function() clone:PivotTo(root.CFrame * offset) end)
          elseif primary then
              primary.CFrame = root.CFrame * offset
          end

          if primary and primary:IsA("BasePart") then
              local weld = Instance.new("WeldConstraint")
              weld.Part0 = root
              weld.Part1 = primary
              weld.Parent = primary
              if clone:IsA("BasePart") then
                  clone.CFrame = root.CFrame * offset
              end
          end

          task.delay(20, function()
              if clone and clone.Parent then
                  pcall(function() clone:Destroy() end)
              end
          end)
          return true
      end

      local function spawnEmoteProps(char, id, mod, meta, asset)
          clearEmoteProps(char)
          pcall(function()
              local EmoteLib
              local m = ReplicatedStorage:FindFirstChild("Common")
              m = m and m:FindFirstChild("EmoteLib")
              if m and m:IsA("ModuleScript") then EmoteLib = require(m) end

              if typeof(EmoteLib) == "table" then
                  if typeof(EmoteLib.defaultDisplayRig) == "function" then
                      EmoteLib.defaultDisplayRig(char)
                  end
                  if typeof(EmoteLib.applyRigTemplateToCharacter) == "function" and asset then
                      EmoteLib.applyRigTemplateToCharacter(char, asset)
                      EmoteLib.applyRigTemplateToCharacter(char, id)
                  end
              end
          end)

          if typeof(meta) == "table" and typeof(meta.Handler) == "table" then
              local h = meta.Handler
              local tries = {
                  function() return h.display(char) end,
                  function() return h.display(LocalPlayer) end,
                  function() return h.display(char, mod) end,
                  function() return h.display(char, meta) end,
                  function() return h.display(char, id) end,
                  function() return h.run(char) end,
                  function() return h.run(LocalPlayer) end,
                  function() return h.run(char, mod) end,
              }
              for i = 1, #tries do pcall(tries[i]) end
          end

          local source = resolveEmotePropSource(id, mod, meta)
          if source then attachEmoteProp(char, source, id) end

          task.defer(function()
              if not char.Parent then return end
              for _, d in ipairs(char:GetChildren()) do
                  local n = string.lower(d.Name)
                  if d ~= char:FindFirstChildOfClass("Humanoid")
                      and d.Name ~= "HumanoidRootPart"
                      and d.Name ~= EMOTE_PROP
                      and (string.find(n, "bed", 1, true) or string.find(n, "crab", 1, true) or string.find(n, "prop", 1, true) or string.find(n, "sleep", 1, true) or string.find(n, "grap", 1, true))
                  then
                      pcall(function()
                          d:SetAttribute("WH_EmoteProp", true)
                          d.Name = EMOTE_PROP
                      end)
                  end
              end
          end)
      end

      local function playEmoteSound(char, soundId)
          if typeof(soundId) == "string" and soundId ~= "" then
              if not string.find(soundId, "rbxassetid://", 1, true) and tonumber(soundId:match("%d+")) then
                  soundId = "rbxassetid://" .. soundId:match("%d+")
              end
              pcall(function()
                  local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
                  if not root then return end
                  
                  local old = root:FindFirstChild("WH_EmoteSound")
                  if old then old:Destroy() end

                  local s = Instance.new("Sound")
                  s.Name = "WH_EmoteSound"
                  s.SoundId = soundId
                  s.Volume = 1
                  s.Parent = root
                  s:Play()
                  
                  s.Ended:Connect(function() s:Destroy() end)
                  game:GetService("Debris"):AddItem(s, 30)
              end)
          end
      end

      local cachedWheel = nil
      local function getEmoteWheel()
          if cachedWheel and cachedWheel.Parent then return cachedWheel end
          for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
              if gui.Name == "EmoteWheel" or gui.Name == "Emote Wheel" then
                  cachedWheel = gui
                  return gui
              end
          end
      end

      local function getAssetId(emote)
          if not emote then return nil end
          local raw = emote.Asset
          if not raw then return nil end
          local numId = tostring(raw):match("%d+")
          if numId then return "rbxassetid://" .. numId end
      end

      local function findInventoryRigForEmote(emoteId)
          local emote = Items[emoteId]
          if not emote then return nil end
          local assetId = getAssetId(emote)
          if not assetId then return nil end

          for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
              if gui.ClassName == "WorldModel" then
                  local rig = gui:FindFirstChild("RigTemplate")
                  if rig then
                      local anim = rig:FindFirstChildWhichIsA("Animation", true)
                      if anim and anim.AnimationId == assetId then return rig end
                  end
              end
          end
      end

      local function playEmoteLocally(emoteId)
          local emote = Items[emoteId]
          if not emote then return end

          local assetId = getAssetId(emote)
          if not assetId then return end

          local character = LocalPlayer.Character
          if not character then return end

          local humanoid = character:FindFirstChildWhichIsA("Humanoid")
          if not humanoid then return end

          local animator = humanoid:FindFirstChildWhichIsA("Animator")
          if not animator then
              animator = Instance.new("Animator")
              animator.Parent = humanoid
          end

          for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
              if track.Name == "CustomEmoteTrack" then track:Stop() end
          end

          local anim = Instance.new("Animation")
          anim.Name = "CustomEmoteTrack"
          anim.AnimationId = assetId

          local track = animator:LoadAnimation(anim)
          track.Priority = Enum.AnimationPriority.Action
          track:Play()

          local meta = emote.Metadata
          local mod = emote
          spawnEmoteProps(character, emoteId, mod, meta, assetId)

          local soundId = nil
          if meta and meta.Sound then soundId = meta.Sound
          elseif emote.SoundId then soundId = emote.SoundId
          elseif emote.Sound then soundId = emote.Sound
          else
              local rig = findInventoryRigForEmote(emoteId)
              if rig then
                  local s = rig:FindFirstChildWhichIsA("Sound", true)
                  if s then soundId = s.SoundId end
              end
          end
          
          if soundId then playEmoteSound(character, tostring(soundId)) end

          local moveConnection
          moveConnection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
              if humanoid.MoveDirection.Magnitude > 0 then track:Stop() end
          end)

          track.Stopped:Connect(function()
              if moveConnection then moveConnection:Disconnect() end
              clearEmoteProps(character)
              local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
              if root then
                  local oldSnd = root:FindFirstChild("WH_EmoteSound")
                  if oldSnd then oldSnd:Destroy() end
              end
          end)
      end

      local lastEquipTime = 0 

      local function patchSlot(slotNum, emoteId)
          local emote = Items[emoteId]
          if not emote then return end

          local wheel = getEmoteWheel()
          if not wheel then return end

          local button = wheel:FindFirstChild("WheelButton_" .. slotNum, true)
          if not button then return end

          local clickTarget = button:FindFirstChildWhichIsA("GuiButton", true) or button
          clickTarget:SetAttribute("PatchedEmoteId", emoteId)

          if clickTarget:IsA("GuiButton") and not clickTarget:GetAttribute("CustomEmoteHooked") then
              clickTarget:SetAttribute("CustomEmoteHooked", true)
              clickTarget.MouseButton1Click:Connect(function()
                  if tick() - lastEquipTime < 0.5 then return end 
                  local eq = InventoryController.Equipped:get()
                  local emotes = eq[emoteType]
                  if type(emotes) == "table" then
                      local currentEmoteId = emotes[slotNum] or emotes[tostring(slotNum)]
                      if currentEmoteId then playEmoteLocally(currentEmoteId) end
                  end
              end)
          end

          local displayName = button:FindFirstChild("DisplayName", true)
          if displayName and (displayName:IsA("TextLabel") or displayName:IsA("TextButton")) then
              displayName.Text = emote.DisplayName or emote.Name or emoteId
          end

          local itemDisplay = button:FindFirstChild("ItemDisplay", true)
          if not itemDisplay then return end

          local vp = itemDisplay:FindFirstChildWhichIsA("ViewportFrame", true)
          if not vp then return end

          local worldModel = vp:FindFirstChildWhichIsA("WorldModel")
          if not worldModel then return end

          local assetId = getAssetId(emote)
          if not assetId then return end

          local inventoryRig = findInventoryRigForEmote(emoteId)
          if inventoryRig then
              local existing = worldModel:FindFirstChild("RigTemplate")
              if existing then existing:Destroy() end

              local cloned = inventoryRig:Clone()
              cloned.Name = "RigTemplate"
              cloned.Parent = worldModel

              local humanoid = cloned:FindFirstChildWhichIsA("Humanoid")
              if humanoid then
                  local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", humanoid)
                  local animInstance = cloned:FindFirstChildWhichIsA("Animation", true)
                  if not animInstance then
                      animInstance = Instance.new("Animation")
                      animInstance.Name = "EmoteAnim"
                      animInstance.AnimationId = assetId
                      animInstance.Parent = cloned
                  end

                  pcall(function()
                      for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
                      animator:LoadAnimation(animInstance):Play()
                  end)
              end
              return
          end

          local rigTemplate = worldModel:FindFirstChild("RigTemplate")
          if not rigTemplate then return end

          local animInstance = rigTemplate:FindFirstChildWhichIsA("Animation", true)
          if not animInstance then
              animInstance = Instance.new("Animation")
              animInstance.Name = "EmoteAnim"
              animInstance.Parent = rigTemplate
          end
          animInstance.AnimationId = assetId

          local humanoid = rigTemplate:FindFirstChildWhichIsA("Humanoid")
          if humanoid then
              local animator = humanoid:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", humanoid)
              pcall(function()
                  for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
                  animator:LoadAnimation(animInstance):Play()
              end)
          end
      end

      local function patchAllSlots()
          local eq = InventoryController.Equipped:get()
          local emotes = eq[emoteType]
          if type(emotes) ~= "table" then return end

          local wheel = getEmoteWheel()
          if not wheel then return end

          for slot, emoteId in pairs(emotes) do
              local slotNum = tonumber(slot)
              if slotNum and slotNum >= 1 and slotNum <= 4 then
                  local button = wheel:FindFirstChild("WheelButton_" .. slotNum, true)
                  if button and button:GetAttribute("PatchedEmoteId") ~= emoteId then
                      patchSlot(slotNum, emoteId)
                  end
              end
          end
      end

      local old3
      old3 = hookfunction(isEquipped, function(item, equippedTable, selected)
          local idToCheck = type(item) == "table" and item.Id or item
          if active and idToCheck and Items[idToCheck] then
              local eq = InventoryController.Equipped:get()
              local emotes = eq[emoteType]
              if type(emotes) == "table" then
                  for _, v in pairs(emotes) do if v == idToCheck then return true end end
              elseif emotes == idToCheck then return true end
          end
          return old3(item, equippedTable, selected)
      end)

      local old2
      old2 = hookfunction(InventoryService.Equip, function(self, id, slot, ...)
          lastEquipTime = tick() 
          if active and Items[id] then
              local eq = InventoryController.Equipped:get()
              if type(eq[emoteType]) ~= "table" then eq[emoteType] = {} end

              local resolvedSlot = slot ~= nil and tonumber(slot) or 1
              eq[emoteType][resolvedSlot] = id
              eq[emoteType][tostring(resolvedSlot)] = id
              saveEquip("Emote", id, resolvedSlot)
              InventoryController.Equipped:set(table.clone(eq))

              task.defer(function()
                  pcall(function()
                      local EmoteCtrl = Knit.GetController("EmoteController")
                      if EmoteCtrl then
                          if type(EmoteCtrl.BuildEmoteWheel) == "function" then EmoteCtrl:BuildEmoteWheel()
                          elseif type(EmoteCtrl.UpdateWheel) == "function" then EmoteCtrl:UpdateWheel()
                          elseif type(EmoteCtrl.Update) == "function" then EmoteCtrl:Update() end
                      end
                  end)
                  task.wait(0.1)
              end)
              return
          end
          return old2(self, id, slot, ...)
      end)

      entryProviders[#entryProviders + 1] = function(p1)
          if p1.ItemType == emoteType or p1.ItemType == Item.Type.Emote then return fakeEntries end
      end

      restoreFns[#restoreFns + 1] = function()
          local slots = saved.Emote
          if type(slots) ~= "table" then return end
          local eq = InventoryController.Equipped:get()
          if type(eq[emoteType]) ~= "table" then eq[emoteType] = {} end
          for slot, id in pairs(slots) do
              if Items[id] then
                  eq[emoteType][tonumber(slot) or slot] = id
                  eq[emoteType][tostring(slot)] = id
              end
          end
          InventoryController.Equipped:set(table.clone(eq))
      end

      local oldIndex
      oldIndex = hookmetamethod(game, "__newindex", function(self, key, value)
          if active and key == "Text" and typeof(self) == "Instance" and self.Name == "DisplayName" then
              local current = self.Parent
              local depth = 0
              while current and current ~= game and depth < 3 do
                  local slotNum = tonumber(string.match(current.Name, "WheelButton_(%d+)"))
                  if slotNum and slotNum >= 1 and slotNum <= 4 then
                      local eq = InventoryController.Equipped:get()
                      if eq and type(eq[emoteType]) == "table" then
                          local emotes = eq[emoteType]
                          local emoteId = emotes[slotNum] or emotes[tostring(slotNum)]
                          if emoteId and Items[emoteId] then
                              local emote = Items[emoteId]
                              return oldIndex(self, key, emote.DisplayName or emote.Name or value)
                          end
                      end
                      break
                  end
                  current = current.Parent
                  depth = depth + 1
              end
          end
          return oldIndex(self, key, value)
      end)

      task.defer(function()
          task.wait(0.5)
          patchAllSlots()
      end)

      loopFns[#loopFns + 1] = function()
          while active do
              task.wait(1.5)
              if not active then break end
              pcall(patchAllSlots)
          end
      end
    end

    scripts[#scripts + 1] = function()
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")
      local LocalPlayer = Players.LocalPlayer

      local Item = require(ReplicatedStorage.Content.Item)
      local Knit = require(ReplicatedStorage.Packages.Knit)
      local InventoryController = Knit.GetController("InventoryController")
      local InventoryService = Knit.GetService("InventoryService")
      local InventoryValue = InventoryController.Inventory
      local inv = InventoryValue:get()

      local isEquipped = require(game.ReplicatedFirst.Controllers.InventoryController.IsEquipped)

      local toggled = {}
      local Items = {}
      local fakeEntries = {}

      local cardType = Item.Type.Card or Item.Type.PlayerCard
      local allCards = Item:GetAllFromType(cardType)

      if allCards then
          for _, card in pairs(allCards) do
              Items[card.Id] = true
              inv[card.Id] = 1
              if type(card) == "table" then
                  card.Challenge = nil
                  card.ChallengeId = nil
                  card.ChallengeToUnlock = nil
                  card.Locked = false
                  card.IsLocked = false
                  card.Hidden = false
                  card.IsHidden = false
                  card.Gamepass = nil
                  card.Pass = nil
                  card.ProductId = nil
                  card.Exclusive = false
              end
              table.insert(fakeEntries, {Name = card.Id, Item = card, Count = 1, IsRandom = false})
          end
      end

      InventoryValue:set(table.clone(inv))

      loopFns[#loopFns + 1] = function()
          while active do
              task.wait(1)
              if not active then break end
              pcall(function()
                  local n = 0
                  for _, v in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                      n = n + 1
                      if n % 400 == 0 then task.wait() end
                      if v:IsA("ImageLabel") or v:IsA("ImageButton") then
                          local name = string.lower(v.Name)
                          if string.find(name, "lock") or string.find(name, "padlock") then
                              v.Visible = false
                          end
                      elseif v:IsA("TextLabel") then
                          local text = string.lower(v.Text)
                          if string.find(text, "locked") or string.find(text, "challenge to unlock") then
                              v.Visible = false
                          end
                      end
                  end
              end)
          end
      end

      local old3
      old3 = hookfunction(isEquipped, function(item, equippedTable, selected)
          if not active then return old3(item, equippedTable, selected) end
          if type(item) == "table" and Items[item.Id] and toggled[item.Id] then
              return true
          elseif type(item) == "string" and Items[item] and toggled[item] then
              return true
          end
          if Items[selected] and toggled[selected] then
              return true
          end
          return old3(item, equippedTable, selected)
      end)

      local old2
      old2 = hookfunction(InventoryService.Equip, function(self, id)
          if active and Items[id] then
              for k, _ in pairs(toggled) do
                  toggled[k] = nil
              end
              toggled[id] = true
              saveEquip("Card", id)
              
              local eq = InventoryController.Equipped:get()
              eq[cardType] = id
              InventoryController.Equipped:set(table.clone(eq))
              
              return
          end
          return old2(self, id)
      end)

      entryProviders[#entryProviders + 1] = function(p1)
          if p1.ItemType == cardType or p1.ItemType == Item.Type.Card or p1.ItemType == Item.Type.PlayerCard then return fakeEntries end
      end

      restoreFns[#restoreFns + 1] = function()
          local id = saved.Card
          if id and Items[id] then
              for k, _ in pairs(toggled) do toggled[k] = nil end
              toggled[id] = true
              local eq = InventoryController.Equipped:get()
              eq[cardType] = id
              InventoryController.Equipped:set(table.clone(eq))
          end
      end

      local FlashCardEvent = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.PlayerCardService.RE.OnFlashCard

      for _, connection in pairs(getconnections(FlashCardEvent.OnClientEvent)) do
          local oldFunc
          oldFunc = hookfunction(connection.Function, function(cardData)
              if active and typeof(cardData) == "table" and cardData.Player == LocalPlayer then
                  for name, isToggled in pairs(toggled) do
                      if isToggled then
                          cardData.PlayerCardItemId = name
                          break
                      end
                  end
              end
              return oldFunc(cardData)
          end)
      end
    end

    scripts[#scripts + 1] = function()
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Players = game:GetService("Players")
      local LocalPlayer = Players.LocalPlayer

      local Item = require(ReplicatedStorage.Content.Item)
      local Knit = require(ReplicatedStorage.Packages.Knit)
      local InventoryController = Knit.GetController("InventoryController")
      local InventoryService = Knit.GetService("InventoryService")
      local InventoryValue = InventoryController.Inventory
      local inv = InventoryValue:get()

      local isEquipped = require(game.ReplicatedFirst.Controllers.InventoryController.IsEquipped)

      local toggled = {}
      local Items = {}
      local fakeEntries = {}

      local allScoreFX = Item:GetAllFromType(Item.Type.ScoreEffect)
      if allScoreFX then
          for _, fx in pairs(allScoreFX) do
              Items[fx.Id] = true
              inv[fx.Id] = 1
              table.insert(fakeEntries, {Name = fx.Id, Item = fx, Count = 1, IsRandom = false})
          end
      end

      InventoryValue:set(table.clone(inv))

      local old3
      old3 = hookfunction(isEquipped, function(item, equippedTable, selected)
          if active and Items[selected] and toggled[selected] ~= nil then
              return toggled[selected]
          end
          return old3(item, equippedTable, selected)
      end)

      local old2
      old2 = hookfunction(InventoryService.Equip, function(self, id)
          local result = old2(self, id)
          if active and Items[id] then
              for k, _ in pairs(toggled) do
                  toggled[k] = nil
              end
              toggled[id] = true
              saveEquip("ScoreEffect", id)
              local eq = InventoryController.Equipped:get()
              InventoryController.Equipped:set(table.clone(eq))
          end
          return result
      end)

      entryProviders[#entryProviders + 1] = function(p1)
          if p1.ItemType == Item.Type.ScoreEffect then return fakeEntries end
      end

      restoreFns[#restoreFns + 1] = function()
          local id = saved.ScoreEffect
          if id and Items[id] then
              for k, _ in pairs(toggled) do toggled[k] = nil end
              toggled[id] = true
          end
      end

      local HitGroundEvent = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService.RE.HitGround

      for _, connection in pairs(getconnections(HitGroundEvent.OnClientEvent)) do
          local oldFunc
          oldFunc = hookfunction(connection.Function, function(p1, p2, p3, p4, effectName, char, p7)
              if active and char == LocalPlayer.Character then
                  for name, isToggled in pairs(toggled) do
                      if isToggled then
                          effectName = name
                          break
                      end
                  end
              end
              return oldFunc(p1, p2, p3, p4, effectName, char, p7)
          end)
      end
    end

    scripts[#scripts + 1] = function()
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Item = require(ReplicatedStorage.Content.Item)
      local Knit = require(ReplicatedStorage.Packages.Knit)
      local InventoryController = Knit.GetController("InventoryController")
      local InventoryService = Knit.GetService("InventoryService")
      local InventoryValue = InventoryController.Inventory
      local inv = InventoryValue:get()

      local isEquipped = require(game.ReplicatedFirst.Controllers.InventoryController.IsEquipped)

      local toggled = {}
      local Items = {}

      local allBalls = Item:GetAllFromType(Item.Type.Ball)
      for _, ball in pairs(allBalls) do
          Items[ball.Id] = true
          inv[ball.Id] = 1
      end

      InventoryValue:set(table.clone(inv))

      local old3
      old3 = hookfunction(isEquipped, function(item, equippedTable, selected)
          if active and Items[selected] and toggled[selected] ~= nil then
              return toggled[selected]
          end
          return old3(item, equippedTable, selected)
      end)

      local old2
      old2 = hookfunction(InventoryService.Equip, function(self, id)
          local result = old2(self, id)
          if active and Items[id] then
              for k, _ in pairs(toggled) do
                  toggled[k] = nil
              end
              toggled[id] = true
              saveEquip("Ball", id)
              local eq = InventoryController.Equipped:get()
              InventoryController.Equipped:set(table.clone(eq))
          end
          return result
      end)

      local fakeEntries = {}
      for _, ball in pairs(allBalls) do
          table.insert(fakeEntries, {Name = ball.Id, Item = ball, Count = 1, IsRandom = false})
      end

      entryProviders[#entryProviders + 1] = function(p1)
          if p1.ItemType == Item.Type.Ball then return fakeEntries end
      end

      restoreFns[#restoreFns + 1] = function()
          local id = saved.Ball
          if id and Items[id] then
              for k, _ in pairs(toggled) do toggled[k] = nil end
              toggled[id] = true
          end
      end

      skinFn = function()
          for name, isToggled in pairs(toggled) do
              if isToggled then return name end
          end
          return nil
      end
    end

    return function(v)
      active = v and true or false
      if active then
        if not ran then
          ran = true
          loadSaved()
          for _, f in ipairs(scripts) do
            pcall(f)
          end
          pcall(installHooks)
          for _, f in ipairs(restoreFns) do
            pcall(f)
          end
          pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local Knit = require(RS.Packages.Knit)
            local IC = Knit.GetController("InventoryController")
            task.wait(0.2)
            IC.Inventory:set(table.clone(IC.Inventory:get()))
            IC.Equipped:set(table.clone(IC.Equipped:get()))
          end)
        end
        for i, f in ipairs(loopFns) do
          if not loopRunning[i] then
            loopRunning[i] = true
            task.spawn(function()
              pcall(f)
              loopRunning[i] = false
            end)
          end
        end
      elseif ran then
        pcall(function()
          local RS = game:GetService("ReplicatedStorage")
          local Knit = require(RS.Packages.Knit)
          local IC = Knit.GetController("InventoryController")
          IC.Inventory:set(table.clone(IC.Inventory:get()))
          IC.Equipped:set(table.clone(IC.Equipped:get()))
        end)
      end
    end
  end)()

  local EffectsSub = VisualsPage:SubPage({ Name = "Visual" })
  local UnlockSub = VisualsPage:SubPage({ Name = "Unlock" })
  local ProtectSub = VisualsPage:SubPage({ Name = "Protection" })

  local LandingSection = EffectsSub:Section({ Name = "Ball Prediction", Side = "Left" })
  local ScoreSection = UnlockSub:Section({ Name = "Unlock All", Side = "Left" })

  LandingSection:Toggle({
    Name = "Ball Prediction",
    Flag = "ballmarker",
    Default = false,
    Callback = function(v)
      Landing.settings.enabled = v
      Landing.enabled = v
      if not v then Landing.clear() end
    end
  })

  LandingSection:Toggle({
    Name = "Trajectory arc",
    Flag = "ballpred_arc",
    Default = false,
    Callback = function(v) Landing.settings.showArc = v end
  })

  LandingSection:Toggle({
    Name = "Landing marker",
    Flag = "ballpred_marker",
    Default = false,
    Callback = function(v) Landing.settings.showMarker = v end
  })

  LandingSection:Toggle({
    Name = "Time and distance",
    Flag = "ballpred_info",
    Default = false,
    Callback = function(v) Landing.settings.showInfo = v end
  })

  LandingSection:Slider({
    Name = "Projection time",
    Flag = "projection_time",
    Min = 1,
    Max = 5,
    Default = 3,
    Decimals = 0,
    Callback = function(v) Landing.settings.projectionTime = v end
  })

  LandingSection:Label("Lands in", "Left"):Colorpicker({
    Name = "Lands in",
    Flag = "lands_in",
    Default = Color3.fromRGB(70, 220, 100),
    Callback = function(v) Landing.settings.landsInColor = v end
  })

  LandingSection:Label("Lands out", "Left"):Colorpicker({
    Name = "Lands out",
    Flag = "lands_out",
    Default = Color3.fromRGB(255, 90, 90),
    Callback = function(v) Landing.settings.landsOutColor = v end
  })

  LandingSection:Label("Net hit", "Left"):Colorpicker({
    Name = "Net hit",
    Flag = "net_hit",
    Default = Color3.fromRGB(255, 190, 70),
    Callback = function(v) Landing.settings.netColor = v end
  })

  ScoreSection:Toggle({
    Name = "Unlock All",
    Flag = "unlockall",
    Default = false,
    Callback = function(v) UnlockAll(v) end
  })

  do
    local AvatarChanger = (function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")

      local player = Players.LocalPlayer
      local description
      local connection
      local generation = 0
      local snapshots = setmetatable({}, { __mode = "k" })

      local limbMap = {
        ["Left Arm"] = {"LeftUpperArm", "LeftLowerArm", "LeftHand"},
        ["Right Arm"] = {"RightUpperArm", "RightLowerArm", "RightHand"},
        ["Left Leg"] = {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
        ["Right Leg"] = {"RightUpperLeg", "RightLowerLeg", "RightFoot"},
        Torso = {"UpperTorso", "LowerTorso"},
      }

      local function getUserId(target)
        local id = tonumber(target)
        if id then
          return id
        end
        local ok, result = pcall(function()
          return Players:GetUserIdFromNameAsync(tostring(target))
        end)
        return ok and result or nil
      end

      local function getDescription(userId)
        for i = 1, 5 do
          local ok, result = pcall(function()
            return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
          end)
          if ok and result then
            return result
          end
          task.wait(0.2 * i)
        end
      end

      local function findPart(char, name)
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
          return part
        end
        for _, alt in ipairs(limbMap[name] or {}) do
          local p = char:FindFirstChild(alt)
          if p and p:IsA("BasePart") then
            return p
          end
        end
      end

      local function clean(char)
        for _, v in ipairs(char:GetChildren()) do
          if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
            v:Destroy()
          end
        end
      end

      local function attach(char, hum, original)
        local acc = original:Clone()
        for _, d in ipairs(acc:GetDescendants()) do
          if d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") then
            d:Destroy()
          end
        end

        local handle = acc:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then
          acc:Destroy()
          return
        end
        handle.Anchored = false
        handle.CanCollide = false
        handle.Massless = true

        local oldHandle = original:FindFirstChild("Handle")
        local oldWeld = oldHandle and oldHandle:FindFirstChild("AccessoryWeld")
        local part, c0, c1

        if oldWeld and oldWeld:IsA("Weld") and oldWeld.Part1 then
          part = findPart(char, oldWeld.Part1.Name)
          c0, c1 = oldWeld.C0, oldWeld.C1
        end

        if not part then
          local att = handle:FindFirstChildOfClass("Attachment")
          if att then
            for _, d in ipairs(char:GetDescendants()) do
              if d:IsA("Attachment") and d.Name == att.Name and not d:IsDescendantOf(acc) then
                part, c0, c1 = d.Parent, att.CFrame, d.CFrame
                break
              end
            end
          end
        end

        if not part then
          part, c0, c1 = char:FindFirstChild("Head"), CFrame.new(0, 0.5, 0), CFrame.new()
        end

        if not part then
          pcall(function()
            hum:AddAccessory(acc)
          end)
          return
        end

        local weld = Instance.new("Weld")
        weld.Name = "AccessoryWeld"
        weld.Part0 = handle
        weld.Part1 = part
        weld.C0 = c0
        weld.C1 = c1
        weld.Parent = handle
        acc.Parent = char
      end

      local function snapshot(char)
        if snapshots[char] then return end
        local snap = { items = {}, colors = nil, face = nil }
        for _, v in ipairs(char:GetChildren()) do
          if v:IsA("Accessory") then
            local c = v:Clone()
            for _, d in ipairs(c:GetDescendants()) do
              if d:IsA("Weld") or d:IsA("WeldConstraint") or d:IsA("Motor6D") then
                d:Destroy()
              end
            end
            table.insert(snap.items, c)
          elseif v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
            table.insert(snap.items, v:Clone())
          end
        end
        local colors = char:FindFirstChildOfClass("BodyColors")
        if colors then snap.colors = colors:Clone() end
        local head = char:FindFirstChild("Head")
        local face = head and head:FindFirstChildOfClass("Decal")
        if face then snap.face = face:Clone() end
        snapshots[char] = snap
      end

      local function restore(char)
        local snap = snapshots[char]
        if not snap then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        clean(char)
        for _, item in ipairs(snap.items) do
          if item:IsA("Accessory") then
            if hum then attach(char, hum, item) end
          else
            item:Clone().Parent = char
          end
        end
        if snap.colors then
          local cur = char:FindFirstChildOfClass("BodyColors")
          if cur then cur:Destroy() end
          snap.colors:Clone().Parent = char
        end
        local head = char:FindFirstChild("Head")
        if head and snap.face then
          local old = head:FindFirstChildOfClass("Decal")
          if old then old:Destroy() end
          snap.face:Clone().Parent = head
        end
        snapshots[char] = nil
      end

      local function apply(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or not description then
          return
        end

        local ok, model = pcall(function()
          return Players:CreateHumanoidModelFromDescriptionAsync(description, hum.RigType, Enum.AssetTypeVerification.Always)
        end)
        if not ok or not model then
          return
        end

        model.Parent = ReplicatedStorage
        RunService.Heartbeat:Wait()
        clean(char)

        for _, item in ipairs(model:GetChildren()) do
          if item:IsA("Accessory") then
            attach(char, hum, item)
          elseif item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
            item:Clone().Parent = char
          end
        end

        local colors = model:FindFirstChildOfClass("BodyColors")
        if colors then
          local mine = char:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", char)
          mine.HeadColor3 = colors.HeadColor3
          mine.TorsoColor3 = colors.TorsoColor3
          mine.LeftArmColor3 = colors.LeftArmColor3
          mine.RightArmColor3 = colors.RightArmColor3
          mine.LeftLegColor3 = colors.LeftLegColor3
          mine.RightLegColor3 = colors.RightLegColor3
        end

        local head = char:FindFirstChild("Head")
        local newHead = model:FindFirstChild("Head")
        local face = newHead and newHead:FindFirstChildOfClass("Decal")
        if head and face then
          local old = head:FindFirstChildOfClass("Decal")
          if old then
            old:Destroy()
          end
          face:Clone().Parent = head
        end

        model:Destroy()
      end

      local function run(char, gen)
        char:WaitForChild("Humanoid")

        local waited = 0
        while not player:HasAppearanceLoaded() and waited < 6 do
          task.wait(0.1)
          waited = waited + 0.1
        end

        if gen ~= generation then
          return
        end
        snapshot(char)

        for _ = 1, 3 do
          if gen ~= generation or not char.Parent then
            return
          end
          apply(char)
          task.wait(1)
        end
      end

      local M = {}

      function M.apply(target)
        target = tostring(target or ""):match("^%s*(.-)%s*$")
        if target == "" then
          Notify({ Title = "Avatar Changer", Content = "Enter a username or UserId first", Duration = 3 })
          return
        end

        generation = generation + 1
        local gen = generation
        if connection then
          connection:Disconnect()
          connection = nil
        end

        task.spawn(function()
          local userId = getUserId(target)
          local desc = userId and getDescription(userId)
          if gen ~= generation then
            return
          end
          if not desc then
            Notify({ Title = "Avatar Changer", Content = "Could not load " .. target, Duration = 3 })
            return
          end
          description = desc

          connection = player.CharacterAdded:Connect(function(c)
            run(c, gen)
          end)

          if player.Character then
            task.spawn(run, player.Character, gen)
          end
          Notify({ Title = "Avatar Changer", Content = "Applied " .. target, Duration = 3 })
        end)
      end

      function M.reset()
        generation = generation + 1
        if connection then
          connection:Disconnect()
          connection = nil
        end
        description = nil
        local char = player.Character
        if char then
          pcall(restore, char)
        end
        Notify({ Title = "Avatar Changer", Content = "Avatar reset", Duration = 3 })
      end

      return M
    end)()

    local AvatarSection = UnlockSub:Section({ Name = "Avatar Changer", Side = "Right" })
    local avatarTarget = ""

    AvatarSection:Textbox({
      Name = "Username / UserId",
      Flag = "avatartarget",
      Placeholder = "kyosi101",
      Callback = function(v) avatarTarget = v or "" end
    })

    AvatarSection:Button({
      Name = "Apply",
      Callback = function() AvatarChanger.apply(avatarTarget) end
    })

    AvatarSection:Button({
      Name = "Reset",
      Callback = function() AvatarChanger.reset() end
    })
  end

  do
    local SpikeSpots = (function()
      local Players = game:GetService("Players")
      local RunService = game:GetService("RunService")
      local ReplicatedStorage = game:GetService("ReplicatedStorage")
      local Workspace = game:GetService("Workspace")
      local LocalPlayer = Players.LocalPlayer

      local State = _G.__SpikeSpotsState or {}
      _G.__SpikeSpotsState = State
      if State.connection then pcall(function() State.connection:Disconnect() end) end
      if State.destroy then pcall(State.destroy) end

      local cfg = {
        enabled = false,
        aimLine = false,
        count = 3,
        bestColor = Color3.fromRGB(255, 205, 60),
        otherColor = Color3.fromRGB(90, 200, 255),
      }

      local picks = {}
      local pool = {}
      local aimLine = nil
      local lastCompute = 0

      local function courtBounds()
        local okP, physics = pcall(require, ReplicatedStorage.Common.Physics)
        if not okP then physics = nil end
        if physics and physics._getCourtlines then
          local found, lines = pcall(physics._getCourtlines)
          if found and typeof(lines) == "Instance" and lines:IsA("BasePart") then
            return lines.Position, lines.Size * 0.5, lines.Position.Y, physics, lines
          end
        end
        local map = Workspace:FindFirstChild("Map")
        local court = map and map:FindFirstChild("Court")
        if court then
          return court.Position, court.Size * 0.5 - Vector3.new(1, 0, 1), court.Position.Y + court.Size.Y * 0.5, physics, nil
        end
        return nil
      end

      local function compute()
        local centre, half, surfaceY, physics, lines = courtBounds()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not centre or not root then
          picks = {}
          return
        end

        local map = Workspace:FindFirstChild("Map")
        local collide = map and map:FindFirstChild("BallCollideOnly")
        local net = collide and collide:FindFirstChild("Net")
        local netZ = net and net.Position.Z or centre.Z

        local index = LocalPlayer.Team and LocalPlayer.Team:GetAttribute("Index")
        local sign
        if index == 1 then sign = 1
        elseif index == 2 then sign = -1
        else sign = (root.Position.Z < netZ) and 1 or -1 end

        local far = centre.Z + sign * half.Z
        local depth = math.abs(far - netZ)
        if depth < 6 then
          picks = {}
          return
        end
        local halfX = math.max(half.X - 1.5, 1)

        local guards = {}
        for _, player in ipairs(Players:GetPlayers()) do
          if player ~= LocalPlayer and (not LocalPlayer.Team or player.Team ~= LocalPlayer.Team) then
            local pc = player.Character
            local hrp = pc and pc:FindFirstChild("HumanoidRootPart")
            local hum = pc and pc:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
              local v = hrp.AssemblyLinearVelocity
              guards[#guards + 1] = Vector3.new(hrp.Position.X + v.X * 0.35, hrp.Position.Y, hrp.Position.Z + v.Z * 0.35)
            end
          end
        end

        local cols, rows = 9, 6
        local cands = {}
        local function scan(useLegal)
          for i = 0, cols - 1 do
            for j = 0, rows - 1 do
              local x = centre.X - halfX + (i + 0.5) / cols * 2 * halfX
              local fz = (j + 0.5) / rows
              local z = netZ + sign * (2 + fz * (depth - 3.5))
              local spot = Vector3.new(x, surfaceY, z)
              local legal = true
              if useLegal and physics and physics.isPositionInCourt then
                local ok, inside = pcall(physics.isPositionInCourt, spot, lines, 0, nil)
                legal = (not ok) or inside
              end
              if legal then
                local lx, lz = x - root.Position.X, z - root.Position.Z
                local len = math.sqrt(lx * lx + lz * lz)
                local forward = len > 0.01 and (lz * sign) / len or 0
                legal = forward >= 0.4
              end
              if legal then
                local nearest = 40
                for _, g in ipairs(guards) do
                  local dx, dz = g.X - x, g.Z - z
                  local d = math.sqrt(dx * dx + dz * dz)
                  if d < nearest then nearest = d end
                end
                local score = nearest / 40 + 0.2 * math.abs(x - centre.X) / halfX + 0.15 * fz
                cands[#cands + 1] = { spot = spot, score = score, gap = nearest }
              end
            end
          end
        end
        scan(true)
        if #cands == 0 then scan(false) end

        table.sort(cands, function(a, b) return a.score > b.score end)

        local out = {}
        for _, c in ipairs(cands) do
          local clear = true
          for _, p in ipairs(out) do
            local dx, dz = p.spot.X - c.spot.X, p.spot.Z - c.spot.Z
            if math.sqrt(dx * dx + dz * dz) < 9 then
              clear = false
              break
            end
          end
          if clear then
            out[#out + 1] = c
            if #out >= cfg.count then break end
          end
        end
        picks = out
      end

      local function newLine()
        local l = Drawing.new("Line")
        l.Visible = false
        l.Thickness = 1.5
        l.Transparency = 1
        return l
      end

      local function newText()
        local t = Drawing.new("Text")
        t.Visible = false
        t.Center = true
        t.Outline = true
        t.Size = 15
        t.Font = 2
        t.Transparency = 1
        return t
      end

      local function newSquare(filled)
        local ok, q = pcall(function()
          local sq = Drawing.new("Square")
          sq.Visible = false
          sq.Filled = filled
          sq.Thickness = 1
          sq.Transparency = 1
          return sq
        end)
        return ok and q or nil
      end

      local function newQuad()
        local ok, q = pcall(function()
          local qd = Drawing.new("Quad")
          qd.Visible = false
          qd.Filled = true
          qd.Thickness = 1
          qd.Transparency = 0.2
          return qd
        end)
        return ok and q or nil
      end

      local function slot(i)
        local s = pool[i]
        if not s then
          s = { lines = {}, fill = newQuad() }
          local count = (i == 1) and 29 or 13
          for k = 1, count do s.lines[k] = newLine() end
          pool[i] = s
        end
        return s
      end

      local function hideSlot(s)
        for _, l in ipairs(s.lines) do l.Visible = false end
        if s.fill then s.fill.Visible = false end
      end

      local function hideAll()
        for _, s in pairs(pool) do hideSlot(s) end
        if aimLine then aimLine.Visible = false end
      end

      local function project(pos)
        local cam = Workspace.CurrentCamera
        if not cam then return nil end
        local v, vis = cam:WorldToViewportPoint(pos)
        if not vis or v.Z <= 0 then return nil end
        return Vector2.new(v.X, v.Y)
      end

      local function diamond(lines, offset, center, r, color, thick, alpha)
        local pts = {
          center + Vector3.new(r, 0, 0),
          center + Vector3.new(0, 0, r),
          center + Vector3.new(-r, 0, 0),
          center + Vector3.new(0, 0, -r),
        }
        local sp = {}
        for i = 1, 4 do sp[i] = project(pts[i]) end
        for i = 1, 4 do
          local l = lines[offset + i]
          local a, b = sp[i], sp[i % 4 + 1]
          if a and b then
            l.From = a
            l.To = b
            l.Color = color
            l.Thickness = thick
            l.Transparency = alpha
            l.Visible = true
          else
            l.Visible = false
          end
        end
      end

      local function step()
        if not cfg.enabled then
          hideAll()
          return
        end

        local now = os.clock()
        if now - lastCompute > 0.12 then
          lastCompute = now
          pcall(compute)
        end

        for i = 1, #picks do
          local s = slot(i)
          local pick = picks[i]
          local best = i == 1
          local color = best and cfg.bestColor or cfg.otherColor
          local pulse = best and (1 + 0.12 * math.sin(now * 5)) or 1
          local r = (best and 2.2 or 1.55) * pulse
          local base = pick.spot + Vector3.new(0, 0.15, 0)
          local fade = best and 1 or math.max(0.55, 0.85 - (i - 2) * 0.12)

          if s.fill then
            local pts = {
              project(base + Vector3.new(r * 0.92, 0, 0)),
              project(base + Vector3.new(0, 0, r * 0.92)),
              project(base + Vector3.new(-r * 0.92, 0, 0)),
              project(base + Vector3.new(0, 0, -r * 0.92)),
            }
            if pts[1] and pts[2] and pts[3] and pts[4] then
              s.fill.PointA = pts[1]
              s.fill.PointB = pts[2]
              s.fill.PointC = pts[3]
              s.fill.PointD = pts[4]
              s.fill.Color = color
              s.fill.Transparency = best and (0.16 + 0.08 * (0.5 + 0.5 * math.sin(now * 5))) or 0.12
              s.fill.Visible = true
            else
              s.fill.Visible = false
            end
          end

          diamond(s.lines, 0, base, r, color, best and 2.4 or 1.5, fade)
          diamond(s.lines, 4, base, r * 0.5, color, best and 1.8 or 1.2, fade)

          if best then
            local ringRadius = r * 1.75
            for k = 0, 11 do
              local line = s.lines[14 + k]
              local a0 = k * (math.pi / 6) + now * 1.6
              local a1 = a0 + math.pi / 14
              local p0 = project(base + Vector3.new(math.cos(a0) * ringRadius, 0, math.sin(a0) * ringRadius))
              local p1 = project(base + Vector3.new(math.cos(a1) * ringRadius, 0, math.sin(a1) * ringRadius))
              if p0 and p1 then
                line.From = p0
                line.To = p1
                line.Color = color
                line.Thickness = 1.6
                line.Transparency = 0.85
                line.Visible = true
              else
                line.Visible = false
              end
            end

            local phase = (now * 0.8) % 1
            diamond(s.lines, 25, base, r * (1 + phase * 1.3), color, 1.4, (1 - phase) * 0.8)
          end

          local stemTop = best and 4.2 or 3
          local stem = s.lines[9]
          local sa = project(base)
          local sb = project(base + Vector3.new(0, stemTop, 0))
          if sa and sb then
            stem.From = sa
            stem.To = sb
            stem.Color = color
            stem.Thickness = best and 1.8 or 1.2
            stem.Transparency = fade
            stem.Visible = true
          else
            stem.Visible = false
          end

          local gh = best and 9 or 6
          local gw = best and 6.5 or 4.5
          if sb then
            local c = Vector2.new(sb.X, sb.Y - gh - 1)
            local verts = {
              Vector2.new(c.X, c.Y - gh),
              Vector2.new(c.X + gw, c.Y),
              Vector2.new(c.X, c.Y + gh),
              Vector2.new(c.X - gw, c.Y),
            }
            for k = 1, 4 do
              local line = s.lines[9 + k]
              line.From = verts[k]
              line.To = verts[k % 4 + 1]
              line.Color = color
              line.Thickness = best and 2 or 1.4
              line.Transparency = fade
              line.Visible = true
            end
          else
            for k = 1, 4 do s.lines[9 + k].Visible = false end
          end
        end

        for i = #picks + 1, #pool do
          if pool[i] then hideSlot(pool[i]) end
        end

        if not aimLine then aimLine = newLine() end
        local first = picks[1]
        local char = LocalPlayer.Character
        local myRoot = char and char:FindFirstChild("HumanoidRootPart")
        if cfg.aimLine and first and myRoot then
          local a = project(myRoot.Position)
          local b = project(first.spot + Vector3.new(0, 0.15, 0))
          if a and b then
            aimLine.From = a
            aimLine.To = b
            aimLine.Color = cfg.bestColor
            aimLine.Thickness = 1.2
            aimLine.Transparency = 0.55
            aimLine.Visible = true
          else
            aimLine.Visible = false
          end
        else
          aimLine.Visible = false
        end
      end

      local connection = RunService.RenderStepped:Connect(function()
        pcall(step)
      end)
      State.connection = connection
      State.destroy = function()
        for _, s in pairs(pool) do
          for _, l in ipairs(s.lines) do
            pcall(function() l.Visible = false l:Remove() end)
          end
          if s.fill then pcall(function() s.fill.Visible = false s.fill:Remove() end) end
        end
        pool = {}
        if aimLine then
          pcall(function() aimLine.Visible = false aimLine:Remove() end)
          aimLine = nil
        end
      end

      return {
        cfg = cfg,
        set = function(v)
          cfg.enabled = v and true or false
          if not cfg.enabled then
            picks = {}
            hideAll()
          end
        end,
      }
    end)()

    local SpikeSection = EffectsSub:Section({ Name = "Spike Spots", Side = "Right" })

    SpikeSection:Toggle({
      Name = "Best Spike Spot",
      Flag = "spikespots",
      Default = false,
      Callback = function(v) SpikeSpots.set(v) end
    })

    SpikeSection:Slider({
      Name = "Spots shown",
      Flag = "spikespots_count",
      Min = 1,
      Max = 5,
      Default = 3,
      Decimals = 0,
      Callback = function(v) SpikeSpots.cfg.count = math.floor(v) end
    })

    SpikeSection:Toggle({
      Name = "Aim line",
      Flag = "spikespots_line",
      Default = false,
      Callback = function(v) SpikeSpots.cfg.aimLine = v end
    })

    SpikeSection:Label("Best spot", "Left"):Colorpicker({
      Name = "Best spot",
      Flag = "spikespot_best",
      Default = Color3.fromRGB(255, 205, 60),
      Callback = function(v) SpikeSpots.cfg.bestColor = v end
    })

    SpikeSection:Label("Other spots", "Left"):Colorpicker({
      Name = "Other spots",
      Flag = "spikespot_other",
      Default = Color3.fromRGB(90, 200, 255),
      Callback = function(v) SpikeSpots.cfg.otherColor = v end
    })
  end

  do
    local SkyChanger = (function()
      local Lighting = game:GetService("Lighting")
      local RunService = game:GetService("RunService")

      local function ids(bk, dn, ft, lf, rt, up)
        local function id(n) return "rbxassetid://" .. tostring(n) end
        return { bk = id(bk), dn = id(dn), ft = id(ft), lf = id(lf), rt = id(rt), up = id(up) }
      end

      local order = {
        "Red Night", "Sunset", "Blue Sky", "Galaxy", "Vaporwave", "Pinkful Morning",
        "White to Purple", "White to Pink",
        "Clear Day", "Golden Sunset", "Purple Dusk", "Dawn Mist", "Starry Night", "Deep Space",
      }

      local presets = {
        ["Red Night"] = {
          time = 0, brightness = 1.2, stars = 0,
          ambient = Color3.fromRGB(80, 40, 50), outdoor = Color3.fromRGB(110, 55, 65),
          shiftTop = Color3.fromRGB(0, 0, 0),
          tex = ids(401664839, 401664862, 401664960, 401664881, 401664901, 401664936),
        },
        ["Sunset"] = {
          time = 17.9, brightness = 2, stars = 0,
          ambient = Color3.fromRGB(140, 100, 80), outdoor = Color3.fromRGB(190, 130, 90),
          shiftTop = Color3.fromRGB(255, 150, 70),
          tex = ids(323494035, 323494368, 323494130, 323494252, 323494067, 323493360),
        },
        ["Blue Sky"] = {
          time = 14, brightness = 2.2, stars = 0,
          ambient = Color3.fromRGB(120, 130, 150), outdoor = Color3.fromRGB(150, 160, 180),
          shiftTop = Color3.fromRGB(0, 0, 0),
          tex = ids(135483466, 135483484, 135483461, 135483495, 135483499, 135483475),
        },
        ["Galaxy"] = {
          time = 0, brightness = 1, stars = 0,
          ambient = Color3.fromRGB(55, 40, 95), outdoor = Color3.fromRGB(80, 60, 130),
          shiftTop = Color3.fromRGB(60, 20, 120),
          tex = ids(159454299, 159454296, 159454293, 159454286, 159454300, 159454288),
        },
        ["Vaporwave"] = {
          time = 0, brightness = 1.4, stars = 0, celestial = false,
          ambient = Color3.fromRGB(110, 70, 140), outdoor = Color3.fromRGB(150, 90, 180),
          shiftTop = Color3.fromRGB(255, 90, 200),
          tex = ids(8631780182, 8631784904, 8631769834, 8631777199, 8631735555, 8631782345),
        },
        ["Pinkful Morning"] = {
          time = 6.5, brightness = 2, stars = 0,
          ambient = Color3.fromRGB(150, 110, 130), outdoor = Color3.fromRGB(190, 140, 165),
          shiftTop = Color3.fromRGB(255, 160, 190),
          tex = ids(12635309703, 12635311686, 12635312870, 12635313718, 12635315817, 12635316856),
          moon = "rbxassetid://1345054856", sun = "rbxassetid://1345009717",
        },
        ["White to Purple"] = {
          time = 14, brightness = 2, stars = 0, celestial = false,
          ambient = Color3.fromRGB(130, 120, 160), outdoor = Color3.fromRGB(160, 150, 190),
          shiftTop = Color3.fromRGB(0, 0, 0),
          tex = ids(8107841671, 6444884785, 8107841671, 8107841671, 8107841671, 8107849791),
        },
        ["White to Pink"] = {
          time = 14, brightness = 2, stars = 0, celestial = false,
          ambient = Color3.fromRGB(150, 125, 140), outdoor = Color3.fromRGB(190, 155, 170),
          shiftTop = Color3.fromRGB(0, 0, 0),
          tex = ids(11427769401, 11427770685, 11427769401, 11427769401, 11427769401, 11427771954),
        },
        ["Clear Day"] = {
          time = 14, brightness = 2.2,
          ambient = Color3.fromRGB(120, 130, 150), outdoor = Color3.fromRGB(150, 160, 180),
          shiftTop = Color3.fromRGB(0, 0, 0), stars = 0,
          atmo = { Color = Color3.fromRGB(199, 215, 235), Decay = Color3.fromRGB(106, 140, 190), Density = 0.28, Offset = 0, Glare = 0, Haze = 0.6 },
        },
        ["Golden Sunset"] = {
          time = 17.9, brightness = 2,
          ambient = Color3.fromRGB(140, 100, 80), outdoor = Color3.fromRGB(190, 130, 90),
          shiftTop = Color3.fromRGB(255, 150, 70), stars = 0,
          atmo = { Color = Color3.fromRGB(255, 190, 130), Decay = Color3.fromRGB(255, 120, 60), Density = 0.35, Offset = 0.2, Glare = 0.4, Haze = 1.4 },
        },
        ["Purple Dusk"] = {
          time = 18.6, brightness = 1.6,
          ambient = Color3.fromRGB(90, 70, 130), outdoor = Color3.fromRGB(120, 90, 170),
          shiftTop = Color3.fromRGB(160, 90, 255), stars = 800,
          atmo = { Color = Color3.fromRGB(190, 150, 235), Decay = Color3.fromRGB(110, 60, 190), Density = 0.4, Offset = 0.25, Glare = 0.2, Haze = 1.8 },
        },
        ["Dawn Mist"] = {
          time = 5.7, brightness = 1.8,
          ambient = Color3.fromRGB(120, 130, 150), outdoor = Color3.fromRGB(160, 170, 190),
          shiftTop = Color3.fromRGB(255, 190, 150), stars = 200,
          atmo = { Color = Color3.fromRGB(230, 210, 215), Decay = Color3.fromRGB(240, 160, 130), Density = 0.45, Offset = 0.1, Glare = 0.1, Haze = 2.2 },
        },
        ["Starry Night"] = {
          time = 0, brightness = 1.1,
          ambient = Color3.fromRGB(40, 50, 90), outdoor = Color3.fromRGB(60, 75, 120),
          shiftTop = Color3.fromRGB(0, 0, 0), stars = 3000,
          atmo = { Color = Color3.fromRGB(40, 55, 100), Decay = Color3.fromRGB(20, 25, 60), Density = 0.2, Offset = 0, Glare = 0, Haze = 0.4 },
        },
        ["Deep Space"] = {
          time = 0, brightness = 1,
          ambient = Color3.fromRGB(55, 40, 95), outdoor = Color3.fromRGB(80, 60, 130),
          shiftTop = Color3.fromRGB(60, 20, 120), stars = 6000,
          atmo = { Color = Color3.fromRGB(20, 10, 45), Decay = Color3.fromRGB(10, 5, 30), Density = 0.05, Offset = 0, Glare = 0, Haze = 0 },
        },
      }

      local propNames = {
        "ClockTime", "Brightness", "Ambient", "OutdoorAmbient",
        "ColorShift_Top", "ColorShift_Bottom", "ExposureCompensation",
      }

      local saved = nil
      local current = nil
      local ours = {}
      local heartbeat
      local childAdded
      local nextCheck = 0

      local function snapshot()
        if saved then return end
        saved = { props = {}, skies = {}, atmos = {} }
        for _, name in ipairs(propNames) do
          pcall(function() saved.props[name] = Lighting[name] end)
        end
        for _, child in ipairs(Lighting:GetChildren()) do
          if child:IsA("Sky") then
            saved.skies[#saved.skies + 1] = child
          elseif child:IsA("Atmosphere") then
            saved.atmos[#saved.atmos + 1] = child
          end
        end
      end

      local function clearOurs()
        for _, inst in ipairs(ours) do
          pcall(function() inst:Destroy() end)
        end
        ours = {}
      end

      local function stopWatching()
        if heartbeat then heartbeat:Disconnect() heartbeat = nil end
        if childAdded then childAdded:Disconnect() childAdded = nil end
      end

      local function enforce(preset)
        pcall(function()
          if math.abs(Lighting.ClockTime - preset.time) > 0.01 then
            Lighting.ClockTime = preset.time
          end
          if Lighting.Brightness ~= preset.brightness then
            Lighting.Brightness = preset.brightness
          end
        end)
      end

      local M = {}
      M.order = order

      function M.apply(name)
        local preset = presets[name]
        if not preset then return end

        snapshot()
        stopWatching()
        clearOurs()

        for _, sky in ipairs(saved.skies) do
          pcall(function() sky.Parent = nil end)
        end
        for _, atmo in ipairs(saved.atmos) do
          pcall(function() atmo.Parent = nil end)
        end

        local sky = Instance.new("Sky")
        sky.Name = "ZerithSky"
        sky.CelestialBodiesShown = preset.celestial ~= false
        sky.StarCount = preset.stars
        if preset.tex then
          sky.SkyboxBk = preset.tex.bk
          sky.SkyboxDn = preset.tex.dn
          sky.SkyboxFt = preset.tex.ft
          sky.SkyboxLf = preset.tex.lf
          sky.SkyboxRt = preset.tex.rt
          sky.SkyboxUp = preset.tex.up
        end
        if preset.moon then sky.MoonTextureId = preset.moon end
        if preset.sun then sky.SunTextureId = preset.sun end
        sky.Parent = Lighting
        ours[#ours + 1] = sky

        local atmo = nil
        if preset.atmo then
          atmo = Instance.new("Atmosphere")
          atmo.Name = "ZerithAtmosphere"
          atmo.Color = preset.atmo.Color
          atmo.Decay = preset.atmo.Decay
          atmo.Density = preset.atmo.Density
          atmo.Offset = preset.atmo.Offset
          atmo.Glare = preset.atmo.Glare
          atmo.Haze = preset.atmo.Haze
          atmo.Parent = Lighting
          ours[#ours + 1] = atmo
        end

        pcall(function()
          Lighting.Ambient = preset.ambient
          Lighting.OutdoorAmbient = preset.outdoor
          Lighting.ColorShift_Top = preset.shiftTop
        end)
        enforce(preset)
        current = preset

        heartbeat = RunService.Heartbeat:Connect(function()
          local now = os.clock()
          if now < nextCheck then return end
          nextCheck = now + 0.25
          enforce(preset)
        end)

        childAdded = Lighting.ChildAdded:Connect(function(child)
          if child == sky or child == atmo then return end
          if child:IsA("Sky") or child:IsA("Atmosphere") then
            task.defer(function()
              if child.Parent == Lighting and saved then
                if child:IsA("Sky") then
                  saved.skies[#saved.skies + 1] = child
                else
                  saved.atmos[#saved.atmos + 1] = child
                end
                pcall(function() child.Parent = nil end)
              end
            end)
          end
        end)
      end

      function M.reset()
        stopWatching()
        clearOurs()
        current = nil
        if not saved then return end
        for name, value in pairs(saved.props) do
          pcall(function() Lighting[name] = value end)
        end
        for _, sky in ipairs(saved.skies) do
          pcall(function() sky.Parent = Lighting end)
        end
        for _, atmo in ipairs(saved.atmos) do
          pcall(function() atmo.Parent = Lighting end)
        end
        saved = nil
      end

      return M
    end)()

    local selectedSky = SkyChanger.order[1]
    local SkySection = EffectsSub:Section({ Name = "Sky Changer", Side = "Right" })

    SkySection:Dropdown({
      Name = "Sky",
      Flag = "skychanger_sky",
      Items = SkyChanger.order,
      Default = SkyChanger.order[1],
      Callback = function(v) selectedSky = v end
    })

    SkySection:Button({
      Name = "Apply",
      Callback = function()
        SkyChanger.apply(selectedSky)
        Notify({ Title = "Sky Changer", Content = "Applied " .. tostring(selectedSky), Duration = 3 })
      end
    })

    SkySection:Button({
      Name = "Reset",
      Callback = function()
        SkyChanger.reset()
        Notify({ Title = "Sky Changer", Content = "Sky reset", Duration = 3 })
      end
    })

    local BallTracer = (function()
      local Workspace = game:GetService("Workspace")
      local CollectionService = game:GetService("CollectionService")
      local RunService = game:GetService("RunService")

      local cfg = { enabled = false, color = Color3.fromRGB(255, 120, 60), life = 0.8 }
      local tracked = {}
      local nextScan = 0
      local connection

      local function resolve(item)
        if not item then return nil end
        if item:IsA("BasePart") then return item end
        if item:IsA("Model") then
          return item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        end
        return nil
      end

      local function colorSeq()
        return ColorSequence.new({
          ColorSequenceKeypoint.new(0, cfg.color),
          ColorSequenceKeypoint.new(1, cfg.color:Lerp(Color3.new(1, 1, 1), 0.55)),
        })
      end

      local function build(part)
        local h = math.max(part.Size.Y * 0.35, 0.3)
        local a0 = Instance.new("Attachment")
        a0.Name = "ZerithTracerA0"
        a0.Position = Vector3.new(0, h, 0)
        a0.Parent = part
        local a1 = Instance.new("Attachment")
        a1.Name = "ZerithTracerA1"
        a1.Position = Vector3.new(0, -h, 0)
        a1.Parent = part

        local trail = Instance.new("Trail")
        trail.Name = "ZerithTracer"
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Lifetime = cfg.life
        trail.MinLength = 0.05
        trail.FaceCamera = true
        trail.LightEmission = 0.9
        trail.Color = colorSeq()
        trail.Transparency = NumberSequence.new({
          NumberSequenceKeypoint.new(0, 0.1),
          NumberSequenceKeypoint.new(1, 1),
        })
        trail.WidthScale = NumberSequence.new({
          NumberSequenceKeypoint.new(0, 1),
          NumberSequenceKeypoint.new(1, 0.2),
        })
        trail.Parent = part
        return { a0 = a0, a1 = a1, trail = trail }
      end

      local function destroyEntry(entry)
        pcall(function() entry.trail:Destroy() end)
        pcall(function() entry.a0:Destroy() end)
        pcall(function() entry.a1:Destroy() end)
      end

      local function clearAll()
        for part, entry in pairs(tracked) do
          destroyEntry(entry)
          tracked[part] = nil
        end
      end

      local function scan()
        local found = {}
        for _, tagged in ipairs(CollectionService:GetTagged("Ball")) do
          local part = resolve(tagged)
          if part and part.Parent then found[part] = true end
        end
        for _, obj in ipairs(Workspace:GetChildren()) do
          if obj:IsA("Model") and obj.Name:match("^CLIENT_BALL_%d+$") then
            local part = resolve(obj)
            if part and part.Parent then found[part] = true end
          end
        end

        for part in pairs(found) do
          local entry = tracked[part]
          if not entry then
            tracked[part] = build(part)
          else
            entry.trail.Color = colorSeq()
            entry.trail.Lifetime = cfg.life
          end
        end

        for part, entry in pairs(tracked) do
          if not found[part] or not part.Parent then
            destroyEntry(entry)
            tracked[part] = nil
          end
        end
      end

      local M = { cfg = cfg }

      function M.set(v)
        cfg.enabled = v and true or false
        if cfg.enabled then
          if not connection then
            connection = RunService.Heartbeat:Connect(function()
              local now = os.clock()
              if now < nextScan then return end
              nextScan = now + 0.2
              pcall(scan)
            end)
          end
        else
          if connection then connection:Disconnect() connection = nil end
          clearAll()
        end
      end

      return M
    end)()

    local TracerSection = EffectsSub:Section({ Name = "Ball Tracer", Side = "Left" })

    TracerSection:Toggle({
      Name = "Ball Tracer",
      Flag = "balltracer",
      Default = false,
      Callback = function(v) BallTracer.set(v) end
    })

    TracerSection:Slider({
      Name = "Trail length",
      Flag = "balltracer_life",
      Min = 0.2,
      Max = 2,
      Default = 0.8,
      Decimals = 1,
      Callback = function(v) BallTracer.cfg.life = v end
    })

    TracerSection:Label("Tracer color", "Left"):Colorpicker({
      Name = "Tracer color",
      Flag = "balltracer_color",
      Default = Color3.fromRGB(255, 120, 60),
      Callback = function(v) BallTracer.cfg.color = v end
    })
  end

  local ProtectSection = ProtectSub:Section({ Name = "Protection", Side = "Left" })
  local CustomSection = ProtectSub:Section({ Name = "Custom Protect", Side = "Right" })

  ProtectSection:Toggle({
    Name = "Protect",
    Flag = "protect",
    Default = false,
    Callback = toggleProtection
  })

  ProtectSection:Toggle({
    Name = "TSH Animation",
    Flag = "tshanimation",
    Default = false,
    Callback = function(v) tshAnimationEnabled = v end
  })

  ProtectSection:Toggle({
    Name = "Hidari Animation",
    Flag = "hidarianimation",
    Default = false,
    Callback = function(v) hidariAnimationEnabled = v end
  })

  ProtectSection:Toggle({
    Name = "Kazana Blue Jump",
    Flag = "kazanabluejump",
    Default = false,
    Callback = function(v) kazanaBlueEnabled = v end
  })

  ProtectSection:Toggle({
    Name = "Kazana White Jump",
    Flag = "kazanawhitejump",
    Default = false,
    Callback = function(v) kazanaWhiteEnabled = v end
  })

  CustomSection:Toggle({
    Name = "Custom Protect",
    Flag = "customprotect",
    Default = false,
    Callback = CustomProtect.toggle
  })

  CustomSection:Textbox({
    Name = "Custom Name",
    Flag = "customprotectname",
    Placeholder = "CUSTOM NAME",
    Callback = function(v) CustomProtect.Name = v end
  })

  CustomSection:Textbox({
    Name = "Custom Title",
    Flag = "customprotecttitle",
    Placeholder = "<font color='#00FF00'><b>Custom</b></font>",
    Callback = function(v) CustomProtect.Title = v end
  })

  local FFlagSub = MiscPage:SubPage({ Name = "FFlags" })
  local SpinSub = MiscPage:SubPage({ Name = "Spins" })
  local RewardSub = MiscPage:SubPage({ Name = "Rewards" })

  local FFlagSection = FFlagSub:Section({ Name = "FFlags Applier", Side = "Left" })
  local fflagsText = ""

  FFlagSection:Textbox({
    Name = "FFlags JSON",
    Flag = "fflagsjson",
    Placeholder = '{ "DFIntTaskSchedulerTargetFps": "9999" }',
    Callback = function(v) fflagsText = v or "" end
  })

  FFlagSection:Button({
    Name = "Apply FFlags",
    Callback = function()
      if fflagsText == "" then
        Notify({ Title = "Paste JSON first" })
        return
      end
      FFlags.apply(fflagsText)
    end
  })

  local StyleSection = SpinSub:Section({ Name = "Auto Style Spin", Side = "Left" })
  local AbilitySection = SpinSub:Section({ Name = "Auto Ability Spin", Side = "Right" })

  StyleSection:Toggle({
    Name = "Auto Style Spin",
    Flag = "autostyle",
    Default = false,
    Callback = function(v)
      autoSpin = v
      if v then startAutoSpin() end
    end
  })

  StyleSection:Dropdown({
    Name = "Spin Type",
    Flag = "spintype",
    Items = { "Normal", "Lucky" },
    Default = "Normal",
    Callback = function(v) spinType = v end
  })

  StyleSection:Dropdown({
    Name = "Target Style",
    Flag = "targetstyle",
    Items = {
      "Ronin", "Hidari", "Jinko", "Timeskip Hinto", "Timeskip Kyamo",
      "Akuto", "Taichou", "Sanju", "Mikage", "Kazana", "Timeskip Okazu",
      "Kisuki", "Bakuri", "Kyamo", "Okazu", "Hirakumi"
    },
    Default = "Ronin",
    Callback = function(v) desiredStyles = { v } end
  })

  AbilitySection:Toggle({
    Name = "Auto Ability Spin",
    Flag = "autoabilityspin",
    Default = false,
    Callback = function(v)
      autoAbilitySpin = v
      if v then startAutoAbilitySpin() end
    end
  })

  AbilitySection:Dropdown({
    Name = "Ability Spin Type",
    Flag = "abilityspintype",
    Items = { "Normal", "Lucky" },
    Default = "Normal",
    Callback = function(v) abilitySpinType = v end
  })

  AbilitySection:Dropdown({
    Name = "Target Ability",
    Flag = "targetability",
    Items = {
      "Shield Breaker", "Magnetic Pull", "Lead Feet", "Extra Touch", "Godly",
      "Redirection Jump", "Curve Spike", "Divine Strength", "Legendary",
      "Steel Block", "Zero Gravity Set", "Rare", "Boom Jump", "Moonball"
    },
    Default = "Shield Breaker",
    Callback = function(v) desiredAbilities = { v } end
  })

  local ShopSection = RewardSub:Section({ Name = "Shop", Side = "Left" })
  local ClaimSection = RewardSub:Section({ Name = "Claim Rewards", Side = "Right" })

  ShopSection:Button({
    Name = "Buy Emote",
    Callback = function()
      local RF = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.PackService.RF
      if RF then
        local Open = RF:FindFirstChild("Open")
        if Open then Open:InvokeServer("Emote1") end
      end
    end
  })

  ShopSection:Button({
    Name = "Buy Effect",
    Callback = function()
      local RF = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.PackService.RF
      if RF then
        local Open = RF:FindFirstChild("Open")
        if Open then Open:InvokeServer("ScoreEffect1") end
      end
    end
  })

  ClaimSection:Button({
    Name = "Claim Level Rewards",
    Callback = function()
      local Svc = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.LevelService
      if Svc then
        local RF = Svc:FindFirstChild("RF")
        if RF then
          local C = RF:FindFirstChild("ClaimLevelRewards")
          if C then C:InvokeServer() end
        end
      end
    end
  })

  ClaimSection:Button({
    Name = "Claim Quest Rewards",
    Callback = function()
      local Svc = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.QuestService
      if Svc then
        local RF = Svc:FindFirstChild("RF")
        if RF then
          local C = RF:FindFirstChild("ClaimAll")
          if C then C:InvokeServer(true) end
        end
      end
    end
  })

  ClaimSection:Button({
    Name = "Redeem All Codes",
    Callback = function()
      local function fetchCodes()
        local success, data = pcall(function()
          return game:HttpGet("https://beebom.com/haikyuu-legends-codes/")
        end)
        if not success or not data then return {} end
        local newCodes = {}
        local processed = {}
        for line in string.gmatch(data, "[^\n]+") do
          if string.find(line, "(NEW)") then
            local code = string.match(line, "(%u+[%u%d_]+)")
            if code and not processed[code] then
              processed[code] = true
              table.insert(newCodes, code)
            end
          end
          if #newCodes >= 3 then break end
        end
        return newCodes
      end
      local codes = fetchCodes()
      if #codes == 0 then
        Notify({ Title = "Redeem", Content = "No codes found" })
        return
      end
      local CodeService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.CodeService
      if CodeService then
        local RF = CodeService:FindFirstChild("RF")
        if RF then
          local Redeem = RF:FindFirstChild("Redeem")
          if Redeem then
            for _, code in ipairs(codes) do
              Redeem:InvokeServer(code)
              task.wait(0.2)
            end
          end
        end
      end
      Notify({ Title = "Redeem", Content = "Redeemed " .. #codes .. " code(s)" })
    end
  })

  local ModesSub = GamePage:SubPage({ Name = "Game Modes" })
  local ModesSection = ModesSub:Section({ Name = "Game Modes", Side = "Left" })

  for _, mode in ipairs({
    { "Chaos Mode", "ChaosMode" }, { "1v1 Mini Map", "OnesMini" },
    { "2v2 Ranked", "Twos" }, { "3v3 Ranked", "Threes" },
    { "4v4 Ranked", "Fours" }, { "6v6 Ranked", "Sixes" },
    { "Training", "Training" }
  }) do
    ModesSection:Button({
      Name = mode[1],
      Callback = function()
        local RF = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.PartyService.RF
        if RF then
          local RT = RF:FindFirstChild("RequestTeleport")
          if RT then RT:InvokeServer(mode[2]) end
        end
      end
    })
  end

  local SettingsSub = SettingsPage:SubPage({ Name = "Settings" })
  local ConfigSection = SettingsSub:Section({ Name = "Config", Side = "Left" })
  local ThemeSection = SettingsSub:Section({ Name = "Theme", Side = "Right" })
  local UnloadSection = SettingsSub:Section({ Name = "Menu", Side = "Left" })

  UnloadSection:Keybind({
    Name = "Menu keybind",
    Flag = "MenuKeybind",
    Default = Enum.KeyCode.Z,
    Mode = "Toggle",
    Callback = function()
      local data = Library.Flags["MenuKeybind"]
      if type(data) == "table" and data.Key then
        Library.MenuKeybind = data.Key
      end
    end
  })

  for Index, Value in Library.Theme do
    ThemeSection:Label(Index, "Left"):Colorpicker({
      Name = Index,
      Flag = "Theme_" .. Index,
      Default = Value,
      Callback = function(NewColor)
        Library.Theme[Index] = NewColor
        Library:ChangeTheme(Index, NewColor)
      end
    })
  end

  Library:SetFolder("ZERITH STUDIO/Configs")

  local ConfigName = ""

  ConfigSection:Textbox({
    Name = "Config Name",
    Flag = "ConfigName",
    Placeholder = "Enter config name",
    Default = "",
    Callback = function(Value)
      ConfigName = (Value:gsub("[^%w_%-%s]", ""))
    end
  })

  ConfigSection:Button({
    Name = "Save Config",
    Callback = function()
      if ConfigName == "" then
        Library:Notification("Config", "Enter a config name first.", 3)
        return
      end
      writefile(Library.Folders.Configs .. "/" .. ConfigName, Library:GetConfig())
      Library:Notification("Config", "Saved config: " .. ConfigName, 3)
    end
  })

  ConfigSection:Button({
    Name = "Load Config",
    Callback = function()
      if ConfigName == "" then
        Library:Notification("Config", "Enter a config name first.", 3)
        return
      end
      local path = Library.Folders.Configs .. "/" .. ConfigName
      if not isfile(path) then
        Library:Notification("Config", "Config not found.", 3)
        return
      end
      Library:LoadConfig(readfile(path))
      Library:Notification("Config", "Loaded config: " .. ConfigName, 3)
    end
  })

  ConfigSection:Button({
    Name = "Delete Config",
    Callback = function()
      if ConfigName == "" then
        Library:Notification("Config", "Enter a config name first.", 3)
        return
      end
      local path = Library.Folders.Configs .. "/" .. ConfigName
      if isfile(path) then
        Library:DeleteConfig(ConfigName)
        ConfigName = ""
      else
        Library:Notification("Config", "Config not found.", 3)
      end
    end
  })

  UnloadSection:Button({
    Name = "Unload",
    Callback = function()
      toggleProtection(false)
      if BallESP.connection then BallESP.connection:Disconnect() end
      if AutoReceive.connection then AutoReceive.connection:Disconnect() end
      if AutoSet.connection then AutoSet.connection:Disconnect() end
      if AimSet.connection then AimSet.connection:Disconnect() end
      if JinkoCurve.connection then JinkoCurve.connection:Disconnect() end
      if cardConnection then cardConnection:Disconnect() end
      if desyncConnection then desyncConnection:Disconnect() end
      if hitConnection then hitConnection:Disconnect() end
      if hitConnection2 then hitConnection2:Disconnect() end
      if hitRemovedConnection then hitRemovedConnection:Disconnect() end
      AutoFarm:stop()
      Hitbox.disable()
      disableAntiLag()
      actionKeys = {}
      Library:Unload()
    end
  })

  Library:Notification("ZERITH  STUDIO", "Script loaded!", 4)
end

buildUI()
