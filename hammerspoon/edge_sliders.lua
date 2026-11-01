-- С зажатым Option ведёшь одним пальцем вверх/вниз у левого края трекпада -
-- яркость, у правого - громкость, с системной плашкой (как Slidr / Glissé).
-- Жест начинается, только если палец коснулся узкой полосы у края, пока
-- зажат Option, и пошёл вертикально; пока он идёт,
-- курсор стоит на месте. Сразу после набора текста не срабатывает.
-- Нужно разрешение Accessibility для Hammerspoon.

local M = {}

local EDGE       = 0.05    -- ширина полосы у края, доля ширины трекпада
local START_Y    = 0.011   -- сколько пройти вертикально, чтобы жест начался
local MAX_DRIFT  = 0.045   -- если до начала увело вбок дальше, это не жест
local TYPE_PAUSE = 0.5     -- секунд после нажатия клавиши, когда не срабатывает

-- step - на столько высоты один шаг. Мелкими шагами: клавиша с Shift+Option -
-- 1/64 шкалы вместо 1/16, как делает сама macOS.
local SIDES = {
  left  = { up = "BRIGHTNESS_UP", down = "BRIGHTNESS_DOWN", step = 0.016, fine = true },
  right = { up = "SOUND_UP",      down = "SOUND_DOWN",      step = 0.016, fine = true },
}

local slide = nil          -- текущий жест: палец, сторона, точки
local lastKey = 0

local function press(key, fine)
  for _, down in ipairs({ true, false }) do
    local e = hs.eventtap.event.newSystemKeyEvent(key, down)
    if fine then e:setFlags({ shift = true, alt = true }) end
    e:post()
  end
end

-- Пальцы, которые касаются трекпада (без лежащих неподвижно).
local function activeTouches(e)
  local list = {}
  for _, t in ipairs(e:getTouches() or {}) do
    if t.touching and not t.resting then list[#list + 1] = t end
  end
  return list
end

local function onGesture(e)
  local touches = activeTouches(e)

  if #touches ~= 1 then
    slide = nil
    return false
  end
  local t = touches[1]
  local p = t.normalizedPosition   -- 0..1, начало координат внизу слева

  if not slide then
    if t.phase ~= "began" then return false end
    if not hs.eventtap.checkKeyboardModifiers().alt then return false end
    if hs.timer.secondsSinceEpoch() - lastKey < TYPE_PAUSE then return false end
    local side = (p.x <= EDGE and "left") or (p.x >= 1 - EDGE and "right") or nil
    if side then
      slide = { id = t.identity, side = side, startX = p.x, startY = p.y, lastY = p.y, active = false }
    end
    return false
  end

  if t.identity ~= slide.id then
    slide = nil
    return false
  end

  if not slide.active then
    if math.abs(p.x - slide.startX) > MAX_DRIFT then
      slide = nil
      return false
    end
    if math.abs(p.y - slide.startY) < START_Y then return false end
    slide.active = true
    slide.lastY = p.y
  end

  local s = SIDES[slide.side]
  while p.y - slide.lastY >= s.step do
    press(s.up, s.fine)
    slide.lastY = slide.lastY + s.step
  end
  while slide.lastY - p.y >= s.step do
    press(s.down, s.fine)
    slide.lastY = slide.lastY - s.step
  end
  return false
end

function M.start()
  M.gestureTap = hs.eventtap.new({ hs.eventtap.event.types.gesture }, onGesture):start()

  -- Пока жест идёт, курсор не двигается.
  M.pointerTap = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
    return slide ~= nil and slide.active
  end):start()

  M.keyTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function()
    lastKey = hs.timer.secondsSinceEpoch()
    return false
  end):start()
  return M
end

return M
