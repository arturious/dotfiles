-- Часы в строке меню вместо системных (те скрыты: Control Center → Clock выкл.):
-- HH:MM мелкими цифрами в тонкой обводке, как дата у Itsycal.

local M = {}

local W, H     = 58, 23         -- размер холста
local MARGIN_R = 19             -- отступ от правого края: зазор до Control Center как у Itsycal
local MENU_H   = 33             -- высота строки меню (с вырезом)

local FONT     = { name = ".AppleSystemUIFontMedium", size = 12 }
local BOX_H    = 16             -- высота рамки
local PAD_X    = 4              -- отступ текста от рамки по бокам
local WHITE    = { white = 1, alpha = 0.9 }
local FILL     = { hex = "#0C0C0C" }   -- на экране выходит #0D0D0D

-- на месте системных часов: правый верхний угол, по центру высоты строки меню
local function frameFor(screen)
  local full = screen:fullFrame()
  return { x = full.x + full.w - W - MARGIN_R, y = full.y + (MENU_H - H) / 2, w = W, h = H }
end

local function tick()
  local text = os.date("%H:%M")
  local size = hs.drawing.getTextDrawingSize(text, FONT)
  local w = math.ceil(size.w) + PAD_X * 2
  local x, y = W - w, (H - BOX_H) / 2 + 1.5     -- прижата вправо; +1.5 - по центру значков строки меню
  M.canvas[1].frame = { x = x + 0.5, y = y + 0.5, w = w - 1, h = BOX_H - 1 }
  M.canvas[2].frame = { x = x, y = y + (BOX_H - size.h) / 2, w = w, h = size.h }
  M.canvas[2].text = text
end

function M.start()
  M.canvas = hs.canvas.new(frameFor(hs.screen.primaryScreen()))
  -- выше строки меню и её значков, чтобы перекрывать системные часы
  M.canvas:level(hs.canvas.windowLevels.overlay)
  M.canvas:behavior({ "canJoinAllSpaces", "stationary", "fullScreenAuxiliary" })
  M.canvas:clickActivating(false)
  M.canvas:canvasMouseEvents(false)   -- клики проходят сквозь

  M.canvas[1] = {                     -- обводка с фоном внутри
    type = "rectangle",
    action = "strokeAndFill",
    fillColor = FILL,
    roundedRectRadii = { xRadius = 3, yRadius = 3 },
    strokeColor = WHITE,
    strokeWidth = 1,
  }
  M.canvas[2] = {                     -- время
    type = "text",
    text = "",
    textAlignment = "center",
    textColor = WHITE,
    textFont = FONT.name,
    textSize = FONT.size,
  }

  tick()
  M.canvas:show()

  -- обновляем в начале каждой минуты, а дальше раз в 60 секунд
  M.timer = hs.timer.doAt(os.date("%H:%M", os.time() + 60), "1m", tick)

  -- переставляем часы при смене мониторов
  M.watcher = hs.screen.watcher.new(function()
    M.canvas:frame(frameFor(hs.screen.primaryScreen()))
  end):start()

  return M
end

return M
