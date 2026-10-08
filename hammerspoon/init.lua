-- ~/dotfiles/hammerspoon/init.lua (~/.hammerspoon -> ~/dotfiles/hammerspoon)
-- Каждый инструмент лежит в отдельном файле рядом и подключается здесь.

require("hs.ipc")  -- для управления через CLI `hs`

-- Модули держим в глобальной таблице, иначе сборщик мусора удалит их
-- таймеры, watcher'ы и eventtap'ы. Каждый запускаем отдельно: ошибка в
-- одном не должна оставить остальные без ссылки в _G.tools.
_G.tools = {}
for name, module in pairs({
  clock           = "clock",
  dockSwipeQuit   = "dock_swipe_quit",
  windowCloseQuit = "window_close_quit",
}) do
  local ok, result = pcall(function() return require(module).start() end)
  if ok then
    _G.tools[name] = result
  else
    print("*** " .. module .. ": " .. tostring(result))
  end
end
