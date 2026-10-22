-- Часы в строке меню вместо системных (те скрыты: Control Center → Clock выкл.):
-- тёмная плашка с HH:MM в правом верхнем углу.

local M = {}

local W, H     = 60, 24         -- размер плашки: узкая, чтобы зазор до Control Center был как у Itsycal
local MARGIN_R = 8             -- отступ от правого края экрана
local MENU_H   = 33             -- высота строки меню (с вырезом)
local OFFSET_Y = 2              -- ниже центра: на одной линии со значками строки меню

-- правый верхний угол, по высоте - вровень со значками строки меню
local function frameFor(screen)
  local full = screen:fullFrame()
  return { x = full.x + full.w - W - MARGIN_R, y = full.y + (MENU_H - H) / 2 + OFFSET_Y, w = W, h = H }
end

local function tick()
  M.canvas[2].text = os.date("%H:%M")
end

function M.start()
  M.canvas = hs.canvas.new(frameFor(hs.screen.primaryScreen()))
  -- выше строки меню и её значков
  M.canvas:level(hs.canvas.windowLevels.overlay)
  M.canvas:behavior({ "canJoinAllSpaces", "stationary", "fullScreenAuxiliary" })
  M.canvas:clickActivating(false)
  M.canvas:canvasMouseEvents(false)   -- клики проходят сквозь

  M.canvas[1] = {                     -- фон
    type = "rectangle",
    action = "fill",
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
    fillColor = { red = 0.16, green = 0.16, blue = 0.16, alpha = 1 },
  }
  M.canvas[2] = {                     -- время (окно ставится по целым точкам, поэтому ещё +0.5 тут)
    type = "text",
    text = "",
    frame = { x = 0, y = 3.5, w = W, h = H },
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
