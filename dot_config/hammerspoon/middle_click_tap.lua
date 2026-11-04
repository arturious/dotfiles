-- Тап или нажатие тремя пальцами по трекпаду = клик средней кнопкой
-- (как MiddleClick). Тап срабатывает, если три пальца коснулись и почти сразу
-- отпустили, не сдвинувшись; нажатие - обычный (или правый) клик, пока на
-- трекпаде три пальца. Логика и пороги как в github.com/artginzburg/MiddleClick.
-- Системный тап тремя пальцами (поиск по слову) должен быть выключен.
-- Нужно разрешение Accessibility для Hammerspoon.

local M = {}

local TAP_TIME = 0.3    -- секунд от первого касания до отпускания всех пальцев
local MAX_MOVE = 0.03   -- насколько палец может сдвинуться, доля размера трекпада
local SWALLOW  = 0.3    -- секунд после тапа, когда гасится левый клик от macOS
local DEBUG    = false  -- true: писать события в консоль Hammerspoon

local types = hs.eventtap.event.types
local props = hs.eventtap.event.properties

local tap = nil          -- текущее касание: время начала, точки пальцев, максимум пальцев
local fingers = 0        -- сколько пальцев сейчас на трекпаде
local pressing = false   -- идёт нажатие, заменённое на среднюю кнопку
local swallowUntil = 0   -- до этого времени левый клик гасится

local function log(...)
  if DEBUG then print("MCT", ...) end
end

local DOWN = { [types.leftMouseDown] = true, [types.rightMouseDown] = true }
local UP   = { [types.leftMouseUp] = true, [types.rightMouseUp] = true }

local DRAG_PX = 6        -- на сколько пикселей курсор уходит, чтобы это было перетаскивание
local MARK    = 0x4D4354 -- метка своих событий, чтобы не ловить их снова

local lastPress = 0      -- когда было нажатие тремя пальцами
local lastMiddle = 0     -- когда был последний средний клик от тапа
local held = nil         -- придержанное нажатие тремя пальцами: копия события и точка

-- Нажатие тремя пальцами и начало перетаскивания тремя пальцами приходят
-- одинаковым leftMouseDown. Поэтому нажатие придерживается: если курсор
-- уехал - это выделение текста, нажатие отпускается как обычное левое;
-- если палец поднялся на месте - это средний клик. Копия исходного события
-- хранит модификаторы, так что Cmd+средний клик работает.
local function post(ev, kind)
  ev:setProperty(props.eventSourceUserData, MARK)
  if kind then
    ev:setType(kind)
    ev:setProperty(props.mouseEventButtonNumber, 2)
  end
  ev:post()
end

local function onMouse(e)
  if e:getProperty(props.eventSourceUserData) == MARK then return false end
  local kind = e:getType()
  local now = hs.timer.secondsSinceEpoch()
  log("mouse", kind, "fingers", fingers, "pressing", pressing)

  if DOWN[kind] then
    if fingers == 3 then
      pressing = "held"
      lastPress = now
      if tap then tap.ok = false end   -- это нажатие, а не тап
      held = { ev = e:copy(), pos = e:location() }
      return true
    end
    if kind == types.leftMouseDown and (now < swallowUntil or (tap and tap.max == 3)) then
      pressing = "swallow"
      return true
    end
    return false
  end

  if not pressing then return false end

  if pressing == "held" then
    if UP[kind] then
      pressing = false
      post(held.ev, types.otherMouseDown)
      e:setType(types.otherMouseUp)
      e:setProperty(props.mouseEventButtonNumber, 2)
      held = nil
      log("press click")
      return false
    end
    local p = e:location()
    if math.abs(p.x - held.pos.x) > DRAG_PX or math.abs(p.y - held.pos.y) > DRAG_PX then
      -- перетаскивание: отдать придержанное нажатие как есть
      pressing = false
      post(held.ev)
      held = nil
      log("drag")
      return false
    end
    return true                        -- мелкое дрожание во время нажатия
  end

  if UP[kind] then pressing = false end
  return true                          -- погашенный клик macOS после тапа
end

local function onGesture(e)
  local all = e:getTouches()
  -- События жестов без списка касаний ничего не говорят о пальцах:
  -- считать их «все отпустили» нельзя, иначе клики сыплются очередью.
  if not all or #all == 0 then return false end

  local touches = {}
  for _, t in ipairs(all) do
    if t.touching then touches[#touches + 1] = t end
  end
  fingers = #touches
  local now = hs.timer.secondsSinceEpoch()

  if #touches == 0 then
    if tap and tap.ok and tap.max == 3 and now - tap.start <= TAP_TIME
        and now - lastPress > TAP_TIME * 0.75     -- только что было нажатие
        and now - lastMiddle > TAP_TIME * 0.3 then -- не два клика подряд
      log("tap click")
      lastMiddle = now
      swallowUntil = now + SWALLOW
      hs.eventtap.otherClick(hs.mouse.absolutePosition(), nil, 2)
    end
    tap = nil
    return false
  end

  if not tap then
    tap = { start = now, points = {}, max = 0, ok = true }
  end
  if not tap.ok then return false end

  if #touches > tap.max then tap.max = #touches end
  if tap.max > 3 or now - tap.start > TAP_TIME then
    tap.ok = false
    return false
  end

  for _, t in ipairs(touches) do
    local p = t.normalizedPosition
    local first = tap.points[t.identity]
    if not first then
      tap.points[t.identity] = { x = p.x, y = p.y }
    elseif math.abs(p.x - first.x) > MAX_MOVE or math.abs(p.y - first.y) > MAX_MOVE then
      tap.ok = false
      return false
    end
  end
  return false
end

function M.start()
  M.gestureTap = hs.eventtap.new({ types.gesture }, onGesture):start()
  M.mouseTap = hs.eventtap.new({
    types.leftMouseDown, types.leftMouseUp, types.leftMouseDragged,
    types.rightMouseDown, types.rightMouseUp, types.rightMouseDragged,
  }, onMouse):start()
  return M
end

function M.debug(on) DEBUG = on end

return M
