-- Наводишь курсор на иконку в Dock, свайпаешь двумя пальцами к краю экрана,
-- где стоит Dock, и приложение закрывается. Порт DockSwipeQuitController.swift
-- из github.com/arturious/q: те же пороги и та же логика.
-- Нужно разрешение Accessibility для Hammerspoon.

local M = {}

local SWIPE_THRESHOLD  = 45   -- сколько надо «проскроллить» к краю, чтобы закрыть
local MAX_POINTER_MOVE = 18   -- если курсор уехал дальше, это не свайп по иконке

-- общий список и для window_close_quit.lua
local PROTECTED = {
  ["com.apple.dock"] = true,
  ["com.apple.finder"] = true,
  ["org.hammerspoon.Hammerspoon"] = true,
}

M.PROTECTED = PROTECTED

local props = hs.eventtap.event.properties
-- значения kCGScrollWheelEventScrollPhase
local PHASE_BEGAN, PHASE_ENDED, PHASE_CANCELLED, PHASE_MAY_BEGIN = 1, 4, 8, 128

local gesture = nil

local function defaultsRead(args)
  local out, ok = hs.execute("defaults read " .. args .. " 2>/dev/null")
  return ok and (out:gsub("%s+$", "")) or nil
end

local function dockEdge()
  local v = defaultsRead("com.apple.dock orientation")
  if v == "left" or v == "right" then return v end
  return "bottom"
end

-- аналог NSEvent.isDirectionInvertedFromDevice: включён ли natural scrolling
-- (ключа нет, пока его ни разу не меняли, а по умолчанию natural включён)
local function naturalScrolling()
  return defaultsRead("-g com.apple.swipescrolldirection") ~= "0"
end

local function bundleIDAt(point)
  local el = hs.axuielement.systemElementAtPosition(point)
  if not el or el:attributeValue("AXSubrole") ~= "AXApplicationDockItem" then return nil end

  local url = el:attributeValue("AXURL")
  local path = type(url) == "table" and url.filePath or nil
  if path then
    local info = hs.application.infoForBundlePath(path)
    if info and info.CFBundleIdentifier then return info.CFBundleIdentifier end
  end

  local title = el:attributeValue("AXTitle")
  if not title then return nil end
  for _, app in ipairs(hs.application.runningApplications()) do
    if app:name() == title and app:kind() == 1 then return app:bundleID() end
  end
end

local function quit(bundleID)
  if PROTECTED[bundleID] then return end
  local app = hs.application.applicationsForBundleID(bundleID)[1]
  if app then app:kill() end   -- обычное завершение, как NSRunningApplication.terminate()
end

local function onScroll(e)
  -- только трекпад (точные дельты) и без инерции после отпускания пальцев
  if e:getProperty(props.scrollWheelEventIsContinuous) == 0 then return false end
  if e:getProperty(props.scrollWheelEventMomentumPhase) ~= 0 then return false end

  local phase = e:getProperty(props.scrollWheelEventScrollPhase)

  if not gesture and (phase == PHASE_MAY_BEGIN or phase == PHASE_BEGAN) then
    local loc = e:location()
    local id = bundleIDAt(loc)
    if id then
      gesture = {
        id = id, start = loc, edge = dockEdge(),
        mult = naturalScrolling() and -1 or 1, sum = 0, fired = false,
      }
    end
  end
  if not gesture then return false end

  local loc = e:location()
  if math.sqrt((loc.x - gesture.start.x) ^ 2 + (loc.y - gesture.start.y) ^ 2) > MAX_POINTER_MOVE then
    gesture = nil
    return false
  end

  local dy = e:getProperty(props.scrollWheelEventPointDeltaAxis1) * gesture.mult
  local dx = e:getProperty(props.scrollWheelEventPointDeltaAxis2) * gesture.mult
  if gesture.edge == "bottom" then
    gesture.sum = gesture.sum + dy
  elseif gesture.edge == "left" then
    gesture.sum = gesture.sum + dx
  else
    gesture.sum = gesture.sum - dx
  end

  if not gesture.fired and gesture.sum >= SWIPE_THRESHOLD then
    gesture.fired = true
    quit(gesture.id)
  end

  if phase == PHASE_ENDED or phase == PHASE_CANCELLED then gesture = nil end
  return false   -- событие не глотаем, скролл работает как обычно
end

function M.start()
  M.tap = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, onScroll):start()
  return M
end

return M
