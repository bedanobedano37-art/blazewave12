local HttpService = game:GetService("HttpService")

local URL = "https://blazewave.pages.dev/load"
local KEY = "YOUR_LOAD_KEY"

local env = getgenv and getgenv() or _G

if env.Blazewave_Running then
  warn("[BLAZEWAVE]: Script is already running.")
  return
end

local Request = (syn and syn.request) or (http and http.request) or http_request or request

if typeof(Request) ~= "function" then
  warn("[BLAZEWAVE]: Your executor does not support HTTP requests.")
  return
end

local function PostLoad(file)
  local ok, res = pcall(function()
    return Request({
      Url = URL,
      Method = "POST",
      Headers = { ["Content-Type"] = "application/json" },
      Body = HttpService:JSONEncode({ auth_key = KEY, file = file })
    })
  end)
  if not ok or not res then
    return nil
  end
  if res.Success or res.StatusCode == 200 then
    return res.Body
  end
  return nil
end

local Library
local libBody = PostLoad("src/Library.lua")
if libBody then
  local libFn = loadstring(libBody)
  if libFn then
    local ok, lib = pcall(libFn)
    if ok then
      Library = lib
    end
  end
end

local function Notify(msg)
  if Library and Library.Notification then
    pcall(function()
      Library:Notification("Blazewave", msg, 4)
    end)
  else
    warn("[BLAZEWAVE]: " .. msg)
  end
end

local listBody = PostLoad("gamelist.lua")
if not listBody then
  Notify("Failed to load gamelist.")
  return
end

local GameList
local listOk = pcall(function()
  GameList = loadstring(listBody)()
end)
if not listOk or type(GameList) ~= "table" then
  Notify("Gamelist parse error.")
  return
end

local scriptFile = GameList[game.GameId]
if not scriptFile then
  warn("[BLAZEWAVE]: This game is not supported.")
  return
end

local scriptBody = PostLoad(scriptFile)
if not scriptBody then
  Notify("Script load failed.")
  return
end

local fn, loadErr = loadstring(scriptBody)
if not fn then
  Notify("Parse error: " .. tostring(loadErr))
  return
end

env.Blazewave_Running = true

local success, runtimeErr = pcall(fn)
if not success then
  Notify("Runtime error: " .. tostring(runtimeErr))
end
