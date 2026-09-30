-- ~/dotfiles/hammerspoon.lua (symlinked to ~/.hammerspoon/hammerspoon.lua)

require("hs.ipc")  -- для управления через CLI `hs`

local clock = {}

local W, H     = 58, 23         -- размер плашки
local MARGIN_R = 8              -- отступ от правого края экрана
local MENU_H   = 33             -- высота строки меню (с вырезом)

-- на месте системных часов: правый верхний угол, по центру высоты строки меню
local function frameFor(screen)
  local full = screen:fullFrame()
  return { x = full.x + full.w - W - MARGIN_R, y = full.y + (MENU_H - H) / 2, w = W, h = H }
end

clock.canvas = hs.canvas.new(frameFor(hs.screen.mainScreen()))
-- выше строки меню и её значков, чтобы перекрывать системные часы
clock.canvas:level(hs.canvas.windowLevels.overlay)
clock.canvas:behavior({ "canJoinAllSpaces", "stationary", "fullScreenAuxiliary" })
clock.canvas:clickActivating(false)
clock.canvas:canvasMouseEvents(false)   -- клики проходят сквозь

clock.canvas[1] = {                     -- фон
  type = "rectangle",
  action = "fill",
  roundedRectRadii = { xRadius = 5, yRadius = 5 },
  fillColor = { red = 0.16, green = 0.16, blue = 0.16, alpha = 1 },
}
clock.canvas[2] = {                     -- время
  type = "text",
  text = "",
  frame = { x = 0, y = 3, w = W, h = H },
  textAlignment = "center",
  textColor = { white = 0.82, alpha = 1 },
  textFont = ".AppleSystemUIFont",
  textSize = 13,
}

local function tick()
  clock.canvas[2].text = os.date("%H:%M")
end

tick()
clock.canvas:show()

-- обновляем в начале каждой минуты, а дальше раз в 60 секунд
clock.timer = hs.timer.doAt(os.date("%H:%M", os.time() + 60), "1m", tick)

-- переставляем часы при смене мониторов
clock.watcher = hs.screen.watcher.new(function()
  clock.canvas:frame(frameFor(hs.screen.mainScreen()))
end):start()

_G.clock = clock  -- чтобы сборщик мусора не удалил таймер и watcher
