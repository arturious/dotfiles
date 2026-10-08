-- Часы в строке меню поверх системных: тёмная плашка с HH:MM в правом верхнем углу.

local M = {}

local W, H     = 58, 23         -- размер плашки
local MARGIN_R = 8              -- отступ от правого края экрана
local MENU_H   = 33             -- высота строки меню (с вырезом)

-- на месте системных часов: правый верхний угол, по центру высоты строки меню
local function frameFor(screen)
  local full = screen:fullFrame()
  return { x = full.x + full.w - W - MARGIN_R, y = full.y + (MENU_H - H) / 2, w = W, h = H }
end

local function tick()
  M.canvas[2].text = os.date("%H:%M")
end

function M.start()
  M.canvas = hs.canvas.new(frameFor(hs.screen.primaryScreen()))
  -- выше строки меню и её значков, чтобы перекрывать системные часы
  M.canvas:level(hs.canvas.windowLevels.overlay)
  M.canvas:behavior({ "canJoinAllSpaces", "stationary", "fullScreenAuxiliary" })
  M.canvas:clickActivating(false)
  M.canvas:canvasMouseEvents(false)   -- клики проходят сквозь

  M.canvas[1] = {                     -- фон
    type = "rectangle",
    action = "fill",
    roundedRectRadii = { xRadius = 5, yRadius = 5 },
    fillColor = { red = 0.16, green = 0.16, blue = 0.16, alpha = 1 },
  }
  M.canvas[2] = {                     -- время
    type = "text",
    text = "",
    frame = { x = 0, y = 3, w = W, h = H },
    textAlignment = "center",
    textColor = { white = 0.82, alpha = 1 },
    textFont = ".AppleSystemUIFont",
    textSize = 13,
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
