-- F7 / F8 / F9 (назад / пауза / вперёд) всегда управляют Spotify, а не тем,
-- что играло последним (вкладкой браузера и т.п.). F8, когда Spotify не
-- запущен, открывает его; когда запущен - пауза/воспроизведение.
-- Нужно разрешение Automation (Hammerspoon -> Spotify), macOS спросит его в
-- первый раз.

local M = {}

local ACTIONS = {
  PREVIOUS = hs.spotify.previous,
  NEXT     = hs.spotify.next,
  PLAY     = hs.spotify.playpause,
}

local function onSystemKey(e)
  local key = e:systemKey()
  local action = ACTIONS[key.key]
  if not action then return false end

  if key.down and not key["repeat"] then
    if hs.spotify.isRunning() then
      action()
    elseif key.key == "PLAY" then
      hs.application.launchOrFocus("Spotify")
    end
  end
  return true   -- и нажатие, и отпускание: системе клавиша не достаётся
end

function M.start()
  M.tap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, onSystemKey):start()
  return M
end

return M
