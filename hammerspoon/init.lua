-- ~/dotfiles/hammerspoon/init.lua (~/.hammerspoon -> ~/dotfiles/hammerspoon)
-- Каждый инструмент лежит в отдельном файле рядом и подключается здесь.

require("hs.ipc")  -- для управления через CLI `hs`

-- модули держим в глобальной таблице, чтобы сборщик мусора не удалил
-- их таймеры, watcher'ы и eventtap'ы
-- Каждый модуль запускаем отдельно: ошибка в одном не должна оставить
-- остальные без ссылки в _G.tools (их бы потом собрал сборщик мусора).
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
