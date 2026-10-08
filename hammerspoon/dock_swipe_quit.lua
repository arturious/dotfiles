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

-- Прямоугольник Dock (AXList у процесса Dock) и край экрана, где он стоит.
-- Кэшируем и пересчитываем только после запуска/завершения приложений,
-- смены мониторов или раз в минуту (размер и положение Dock), чтобы на
-- скролл вне Dock не делать ни одного Accessibility-запроса.
local dockFrame, dockEdge, dockDirty = nil, "bottom", true
local natural = true

-- Аналог NSEvent.isDirectionInvertedFromDevice: включён ли natural scrolling.
-- Ключа нет, пока его ни разу не меняли, а по умолчанию natural включён
-- (hs.mouse.scrollDirection() в этом случае ошибочно отвечает "normal").
-- defaults read - внешний процесс, поэтому читаем вместе с кэшем Dock,
-- а не на каждый жест.
local function readNaturalScrolling()
  local out, ok = hs.execute("defaults read -g com.apple.swipescrolldirection 2>/dev/null")
  return not (ok and out:match("^%s*0"))
end

local function refreshDockFrame()
  dockDirty = false
  natural = readNaturalScrolling()
  dockFrame = nil
  local dock = hs.application.applicationsForBundleID("com.apple.dock")[1]
  local el = dock and hs.axuielement.applicationElement(dock)
  for _, c in ipairs(el and el:attributeValue("AXChildren") or {}) do
    if c:attributeValue("AXRole") == "AXList" then
      local f = c:attributeValue("AXFrame")
      dockFrame = f
      -- горизонтальный Dock - снизу; вертикальный - у ближнего края экрана
      if f and f.w < f.h then
        local screen = hs.mouse.getCurrentScreen() or hs.screen.primaryScreen()
        local full = screen:fullFrame()
        dockEdge = (f.x - full.x < full.x + full.w - (f.x + f.w)) and "left" or "right"
      else
        dockEdge = "bottom"
      end
      return
    end
  end
end

local function overDock(p)
  if dockDirty then refreshDockFrame() end
  local f = dockFrame
  return f ~= nil and p.x >= f.x and p.x <= f.x + f.w and p.y >= f.y and p.y <= f.y + f.h
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
  local phase = e:getProperty(props.scrollWheelEventScrollPhase)
  -- вне жеста интересует только его начало: всё остальное отбрасываем сразу
  if not gesture and phase ~= PHASE_MAY_BEGIN and phase ~= PHASE_BEGAN then return false end

  -- только трекпад (точные дельты) и без инерции после отпускания пальцев
  if e:getProperty(props.scrollWheelEventIsContinuous) == 0 then return false end
  if e:getProperty(props.scrollWheelEventMomentumPhase) ~= 0 then return false end

  if not gesture then
    local loc = e:location()
    if not overDock(loc) then return false end
    local id = bundleIDAt(loc)
    if id then
      gesture = {
        id = id, start = loc, edge = dockEdge,
        mult = natural and -1 or 1, sum = 0, fired = false,
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

  local function markDirty() dockDirty = true end
  M.appWatcher = hs.application.watcher.new(function(_, event)
    if event == hs.application.watcher.launched or event == hs.application.watcher.terminated then
      markDirty()
    end
  end):start()
  M.screenWatcher = hs.screen.watcher.new(markDirty):start()
  M.dockTimer = hs.timer.doEvery(60, markDirty)
  return M
end

return M
