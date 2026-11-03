// ==UserScript==
// @name         Arrow keys = volume (YouTube, Twitch)
// @namespace    arturious
// @version      1.1
// @description  Up/Down change video volume right away, without clicking the player first
// @match        https://www.youtube.com/*
// @match        https://www.twitch.tv/*
// @run-at       document-start
// @grant        none
// @updateURL    https://raw.githubusercontent.com/arturious/dotfiles/main/userscripts/arrow-volume.user.js
// @downloadURL  https://raw.githubusercontent.com/arturious/dotfiles/main/userscripts/arrow-volume.user.js
// ==/UserScript==

(() => {
  const STEP = 0.05;

  const isTyping = (el) =>
    el && (el.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName));

  const findVideo = () =>
    [...document.querySelectorAll("video")].find((v) => v.offsetWidth > 0 && v.readyState > 0);

  let hint;
  const show = (pct) => {
    if (!hint) {
      hint = document.createElement("div");
      hint.style.cssText =
        "position:fixed;top:20px;left:50%;transform:translateX(-50%);z-index:2147483647;" +
        "background:rgba(0,0,0,.75);color:#fff;font:600 16px system-ui;padding:8px 14px;" +
        "border-radius:10px;pointer-events:none;transition:opacity .3s";
      document.documentElement.appendChild(hint);
    }
    hint.textContent = `🔊 ${pct}%`;
    hint.style.opacity = "1";
    clearTimeout(hint._t);
    hint._t = setTimeout(() => (hint.style.opacity = "0"), 800);
  };

  window.addEventListener(
    "keydown",
    (e) => {
      if (e.key !== "ArrowUp" && e.key !== "ArrowDown") return;
      if (e.metaKey || e.ctrlKey || e.altKey || isTyping(document.activeElement)) return;
      const video = findVideo();
      if (!video) return;

      e.preventDefault();
      e.stopImmediatePropagation();
      const dir = e.key === "ArrowUp" ? 1 : -1;

      // YouTube: use the player API so its own slider and saved volume stay in sync.
      const yt = document.getElementById("movie_player");
      if (yt && typeof yt.setVolume === "function") {
        const vol = Math.max(0, Math.min(100, Math.round(yt.getVolume() + dir * STEP * 100)));
        yt.setVolume(vol);
        if (vol > 0 && yt.isMuted()) yt.unMute();
        show(vol);
        return;
      }

      // Twitch: drive its own slider (a React input) so the UI and saved volume follow.
      const slider = document.querySelector('input[data-a-target="player-volume-slider"]');
      if (slider) {
        if (video.muted && dir > 0) {
          document.querySelector('button[data-a-target="player-mute-unmute-button"]')?.click();
        }
        const cur = video.muted ? 0 : parseFloat(slider.value);
        const vol = Math.max(0, Math.min(1, Math.round((cur + dir * STEP) * 100) / 100));
        const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "value").set;
        setter.call(slider, String(vol));
        slider.dispatchEvent(new Event("input", { bubbles: true }));
        slider.dispatchEvent(new Event("change", { bubbles: true }));
        show(Math.round(vol * 100));
        return;
      }

      const vol = Math.max(0, Math.min(1, video.volume + dir * STEP));
      video.volume = vol;
      if (vol > 0) video.muted = false;
      show(Math.round(vol * 100));
    },
    true
  );
})();
