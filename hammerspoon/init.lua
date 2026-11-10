require("hs.ipc")  -- CLI `hs`

-- Глобальная таблица, иначе GC соберёт таймеры, watcher'ы и eventtap'ы.
-- pcall на каждый модуль: ошибка в одном не ломает остальные.
_G.tools = {}
for name, module in pairs({
  dockSwipeQuit   = "dock_swipe_quit",
  windowCloseQuit = "window_close_quit",}) do
  local ok, result = pcall(function() return require(module).start() end)
  if ok then
    _G.tools[name] = result
  else
    print("*** " .. module .. ": " .. tostring(result))
  end
end
