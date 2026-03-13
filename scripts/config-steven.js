// IMPORTANT: Start your code on the 2nd line
(function () {
  // config-steven.js — robust userChrome loader (safe fallback, logs to Browser Console)
  "use strict";
  try {
    // Import Services reliably (works in autoconfig)
    const S = globalThis.Services;
    const Ci = Components.interfaces;
    const Cu = Components.utils;

    function log() {
      try {
        S.console.logStringMessage("rebind: " + Array.from(arguments).join(" "));
      } catch (e) {}
    }
    function warn() {
      try {
        Cu.reportError("rebind WARN: " + Array.from(arguments).join(" "));
      } catch (e) {}
    }
    function err() {
      try {
        Cu.reportError("rebind ERROR: " + Array.from(arguments).join(" "));
      } catch (e) {}
    }

    function findKeyByModifierAndKey(doc, modifiers, key) {
      try {
        return doc.querySelector('key[modifiers="' + modifiers + '"][key="' + key + '"]');
      } catch (e) {
        err("findKeyByModifierAndKey error:", e);
        return null;
      }
    }

    // Robust finder for key elements by command or known ids
    function findKeyForCommand(doc, command) {
      try {
        return doc.querySelector('key[command="' + command + '"]');
      } catch (e) {
        err("findKeyForCommand error:", e);
        return null;
      }
    }

    function applyToWindow(win) {
      if (!win || !win.document) return;
      const doc = win.document;

      // Delay until after l10n system runs
      win.requestIdleCallback(function() {
        log("Applying keybindings when idle:");

        // 0) Find existing cmd+B (show bookmark sidebar)
        let bookmarkSidebarKey = findKeyByModifierAndKey(doc, "accel", "B");
        if (bookmarkSidebarKey) {
          bookmarkSidebarKey.remove();
          log("Removed Bookmark Sidebar Hotkey");
        }

        // 1) Move Bookmark to cmd+B
        let bookmarkKey = findKeyForCommand(doc, "Browser:AddBookmarkAs");
        if (bookmarkKey) {
          bookmarkKey.setAttribute("key", "B");
          log("Set Browser:AddBookmarkAs to accel+B");
        }

        // 1) Rebind Open Location -> accel+D
        let openKey = findKeyForCommand(doc, "Browser:OpenLocation");
        if (openKey) {
          openKey.setAttribute("key", "D");
          log("Set Browser:OpenLocation to accel+D");
        } 
      });
    }

    // Observer style used originally — attach listener for chrome windows
    // Install now (unless in Safe Mode)
    try {
      if (!Services.appinfo.inSafeMode) {
        log("Rebind initializing");
        Services.obs.addObserver(function(subject, topic) {
          let win = subject;
          win.addEventListener("load", () => applyToWindow(win), {once: true});
        }, "domwindowopened", false);

        log("Rebinding existing windows");
        let enumerator = Services.wm.getEnumerator("navigator:browser");
        while (enumerator.hasMoreElements()) {
          applyToWindow(enumerator.getNext());
        }

        log("Rebinding complete");
      } else {
        warn("Firefox in Safe Mode — customizations not installed");
      }
    } catch (e) {
      err("install check failed:", e);
    }

  } catch (outer) {
    try { console.error("rebind init outer error:", outer); } catch (_) {}
  }
})();

