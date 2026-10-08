-- Закрыл последнее окно приложения, и оно завершается целиком, а не остаётся
-- висеть в Dock. Порт WindowCloseQuitManager.swift из github.com/arturious/q.
-- Окна каждого приложения отслеживаются через Accessibility (AXWindowCreated,
-- AXUIElementDestroyed). Нужно разрешение Accessibility для Hammerspoon.

local M = {}

local PROTECTED = require("dock_swipe_quit").PROTECTED

local LAUNCH_DELAY = 0.5   -- дать приложению создать первые окна, потом начинать следить
local QUIT_DELAY   = 0.3   -- не закрывать, если окно просто сменилось другим

local apps = {}            -- pid -> { observer = ..., windows = { el, ... } }

local function eligible(app)
  return app and app:kind() == 1 and not PROTECTED[app:bundleID() or ""]
end

local function indexOf(list, el)
  for i, w in ipairs(list) do
    if w == el then return i end
  end
end

-- Считаем только обычные окна: у некоторых приложений (Things) есть невидимое
-- служебное окно с subrole AXUnknown, которое не закрывается никогда - из-за
-- него последнее настоящее окно никогда не было бы «последним».
local function isRealWindow(win)
  return win and win:attributeValue("AXSubrole") == "AXStandardWindow"
end

local function trackWindow(entry, win)
  if not isRealWindow(win) or indexOf(entry.windows, win) then return end
  if not pcall(entry.observer.addWatcher, entry.observer, win, "AXUIElementDestroyed") then return end
  table.insert(entry.windows, win)
end

local function quitIfStillWindowless(pid)
  hs.timer.doAfter(QUIT_DELAY, function()
    local entry = apps[pid]
    local app = hs.application.applicationForPID(pid)
    if not (entry and #entry.windows == 0 and eligible(app)) then return end

    -- Доп. проверка, которой нет в Swift-оригинале: AXWindows не видит окна
    -- в других Spaces и полноэкранные (у Ghostty здесь бывает 0 окон, хотя
    -- окно открыто), так что «все отслеживаемые закрылись» ещё не значит
    -- «окон нет». Не закрываем, если у приложения ещё есть фокус/главное окно.
    local appEl = hs.axuielement.applicationElement(app)
    if appEl then
      if isRealWindow(appEl:attributeValue("AXFocusedWindow"))
          or isRealWindow(appEl:attributeValue("AXMainWindow")) then
        return
      end
      for _, win in ipairs(appEl:attributeValue("AXWindows") or {}) do
        if isRealWindow(win) then return end
      end
    end

    app:kill()   -- обычное завершение, как NSRunningApplication.terminate()
  end)
end

local observe

-- Приложение, которое ещё грузится или зависло, отвечает на Accessibility
-- ошибкой "Messaging failed" - пробуем подписаться позже, а не падать.
local RETRY_DELAYS = { 2, 5, 15, 60 }
local retries = {}         -- pid -> таймер повтора (ссылка, чтобы его не собрал GC)

local function retryLater(app, attempt)
  local delay = RETRY_DELAYS[attempt]
  if not delay then return end
  local pid = app:pid()
  retries[pid] = hs.timer.doAfter(delay, function()
    retries[pid] = nil
    if app:isRunning() and eligible(app) then observe(app, attempt + 1) end
  end)
end

observe = function(app, attempt)
  attempt = attempt or 1
  local pid = app:pid()
  if apps[pid] then return end

  local appEl = hs.axuielement.applicationElement(app)
  if not appEl then return end

  local entry = { windows = {} }
  entry.observer = hs.axuielement.observer.new(pid):callback(function(_, el, notification)
    if notification == "AXWindowCreated" then
      trackWindow(entry, el)
    elseif notification == "AXUIElementDestroyed" then
      local i = indexOf(entry.windows, el)
      if i then
        table.remove(entry.windows, i)
        if #entry.windows == 0 then quitIfStillWindowless(pid) end
      end
    end
  end)
  if not pcall(entry.observer.addWatcher, entry.observer, appEl, "AXWindowCreated") then
    retryLater(app, attempt)
    return
  end

  local function sync()
    for _, win in ipairs(appEl:attributeValue("AXWindows") or {}) do
      trackWindow(entry, win)
    end
  end
  sync()

  entry.observer:start()
  apps[pid] = entry

  -- Первое окно у только что запущенного приложения часто появляется
  -- чуть позже, уже после sync() и мимо AXWindowCreated - досинхронизируем.
  entry.resync = {
    hs.timer.doAfter(1, sync),
    hs.timer.doAfter(3, sync),
  }
end

local function forget(pid)
  local entry = apps[pid]
  if entry then
    entry.observer:stop()
    for _, t in ipairs(entry.resync) do t:stop() end
    apps[pid] = nil
  end
  if retries[pid] then
    retries[pid]:stop()
    retries[pid] = nil
  end
end

function M.start()
  for _, app in ipairs(hs.application.runningApplications()) do
    if eligible(app) then observe(app) end
  end

  M.watcher = hs.application.watcher.new(function(_, event, app)
    if event == hs.application.watcher.launched then
      hs.timer.doAfter(LAUNCH_DELAY, function()
        if eligible(app) then observe(app) end
      end)
    elseif event == hs.application.watcher.terminated then
      -- pid у завершённого приложения может быть уже недоступен, поэтому
      -- просто убираем всех, кого больше нет среди запущенных
      for pid in pairs(apps) do
        if not hs.application.applicationForPID(pid) then forget(pid) end
      end
      for pid in pairs(retries) do
        if not hs.application.applicationForPID(pid) then forget(pid) end
      end
    end
  end):start()

  M.apps = apps
  return M
end

return M
