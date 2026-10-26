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
-- смены мониторов или Space, или раз в минуту (размер и положение Dock), чтобы на
-- скролл вне Dock не делать ни одного Accessibility-запроса.
local dockFrame, dockEdge, dockDirty = nil, "bottom", true
local natural = true

-- Аналог NSEvent.isDirectionInvertedFromDevice: включён ли natural scrolling.
-- Ключа нет, пока его ни разу не меняли, а по умолчанию natural включён
-- (hs.mouse.scrollDirection() в этом случае ошибочно отвечает "normal").
-- defaults read - внешний процесс, поэтому читаем при старте и потом только
-- по уведомлению macOS о переключении настройки (см. M.start).
local function readNaturalScrolling()
  local out, ok = hs.execute("defaults read -g com.apple.swipescrolldirection 2>/dev/null")
  return not (ok and out:match("^%s*0"))
end

-- Dock спрятан за краем экрана (в полноэкранном Space он выезжает только по
-- наведению): такой прямоугольник не кэшируем, иначе после возврата в обычный
-- Space свайп не срабатывал бы, пока кэш не обновится. Пока он спрятан,
-- перечитываем его только когда курсор у его края - там, где он выезжает.
local EDGE_ZONE = 100      -- px от края экрана с Dock (выехавший Dock ~50-60 px)
local dockHidden = false

local function onAnyScreen(f)
  for _, s in ipairs(hs.screen.allScreens()) do
    local full = s:fullFrame()
    if f.x < full.x + full.w and f.x + f.w > full.x and f.y < full.y + full.h and f.y + f.h > full.y then
      return true
    end
  end
  return false
end

local function refreshDockFrame()
  dockDirty = false
  dockFrame = nil
  local dock = hs.application.applicationsForBundleID("com.apple.dock")[1]
  local el = dock and hs.axuielement.applicationElement(dock)
  for _, c in ipairs(el and el:attributeValue("AXChildren") or {}) do
    if c:attributeValue("AXRole") == "AXList" then
      local f = c:attributeValue("AXFrame")
      -- горизонтальный Dock - снизу; вертикальный - у ближнего края экрана
      -- (считается и по спрятанному: он лежит сразу за своим краем)
      if f and f.w < f.h then
        local screen = hs.mouse.getCurrentScreen() or hs.screen.primaryScreen()
        local full = screen:fullFrame()
        dockEdge = (f.x - full.x < full.x + full.w - (f.x + f.w)) and "left" or "right"
      else
        dockEdge = "bottom"
      end
      dockHidden = f ~= nil and not onAnyScreen(f)
      if dockHidden then
        dockDirty = true   -- перечитаем, когда курсор будет у края и Dock выедет
      else
        dockFrame = f
      end
      return
    end
  end
end

local function nearDockEdge(p)
  local screen = hs.mouse.getCurrentScreen() or hs.screen.primaryScreen()
  local full = screen:fullFrame()
  if dockEdge == "left" then return p.x - full.x <= EDGE_ZONE end
  if dockEdge == "right" then return full.x + full.w - p.x <= EDGE_ZONE end
  return full.y + full.h - p.y <= EDGE_ZONE
end

local function overDock(p)
  -- спрятанный Dock: без Accessibility-запроса, пока курсор не у его края
  if dockDirty and dockHidden and not nearDockEdge(p) then return false end
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

  natural = readNaturalScrolling()
  M.scrollWatcher = hs.distributednotifications.new(function()
    natural = readNaturalScrolling()
  end, "SwipeScrollDirectionDidChangeNotification"):start()

  local function markDirty() dockDirty = true end
  M.appWatcher = hs.application.watcher.new(function(_, event)
    if event == hs.application.watcher.launched or event == hs.application.watcher.terminated then
      markDirty()
    end
  end):start()
  M.screenWatcher = hs.screen.watcher.new(markDirty):start()
  M.spaceWatcher = hs.spaces.watcher.new(markDirty):start()   -- в другом Space Dock мог быть спрятан
  M.dockTimer = hs.timer.doEvery(60, markDirty)
  return M
end

return M
