-- ~/dotfiles/hammerspoon/init.lua (~/.hammerspoon -> ~/dotfiles/hammerspoon)
-- Каждый инструмент лежит в отдельном файле рядом и подключается здесь.

require("hs.ipc")  -- для управления через CLI `hs`

-- модули держим в глобальной таблице, чтобы сборщик мусора не удалил
-- их таймеры, watcher'ы и eventtap'ы
_G.tools = {
  clock          = require("clock").start(),
  dockSwipeQuit  = require("dock_swipe_quit").start(),
  windowCloseQuit = require("window_close_quit").start(),
}
