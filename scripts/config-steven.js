// IMPORTANT: Start your code on the 2nd line
(function () {
  /* config-steven.js — robust userChrome loader (safe fallback, logs to Browser Console) */
  "use strict";
  try {
    // Import Services reliably (works in autoconfig)
    const { Services } = Components.utils.import("resource://gre/modules/Services.jsm");
    const Ci = Components.interfaces;

    function log() {
      try { console.log.apply(console, ["ucjs: "].concat(Array.from(arguments))); } catch (e) {}
    }
    function warn() {
      try { console.warn.apply(console, ["ucjs: "].concat(Array.from(arguments))); } catch (e) {}
    }
    function err() {
      try { console.error.apply(console, ["ucjs: "].concat(Array.from(arguments))); } catch (e) {}
    }

    // Safe helper to set key attributes (non-destructive)
    function setKeyBinding(doc, keyElem, keyChar, modifiers) {
      try {
        if (!keyElem) return false;
        // record old attributes (non-persistent) for debugging
        keyElem.dataset && (keyElem.dataset.ucjsOldKey = keyElem.getAttribute("key") || "");
        keyElem.dataset && (keyElem.dataset.ucjsOldMods = keyElem.getAttribute("modifiers") || "");
        keyElem.setAttribute("key", keyChar);
        keyElem.setAttribute("modifiers", modifiers);
        keyElem.removeAttribute("disabled");
        return true;
      } catch (e) {
        err("setKeyBinding error:", e);
        return false;
      }
    }

    // Robust finder for key elements by command or known ids
    function findKeyForCommand(doc, command, fallbackIds) {
      try {
        let k = doc.querySelector('key[command="' + command + '"]');
        if (k) return k;
        for (const id of (fallbackIds || [])) {
          let x = doc.getElementById(id);
          if (x) return x;
        }
        return null;
      } catch (e) {
        err("findKeyForCommand error:", e);
        return null;
      }
    }

    function applyCustomScriptToNewWindow(win) {
      try {
        if (!win || !win.document) return;
        const doc = win.document;

        // 1) Rebind Open Location -> accel+D
        let openKey = findKeyForCommand(doc, "Browser:OpenLocation", ["focusURLBar", "key_openLocation"]);
        if (openKey) {
          if (setKeyBinding(doc, openKey, "D", "accel")) {
            log("assigned Browser:OpenLocation -> accel+D");
          } else {
            warn("found openLocation key but failed to set binding");
          }
        } else {
          // Create a non-destructive key in the main keyset
          try {
            let keyset = doc.getElementById("mainKeyset") || doc.querySelector("keyset") || doc.documentElement;
            let newKey = doc.createElement("key");
            newKey.setAttribute("id", "ucjs_key_openLocation_accelD");
            newKey.setAttribute("command", "Browser:OpenLocation");
            newKey.setAttribute("key", "D");
            newKey.setAttribute("modifiers", "accel");
            newKey.setAttribute("data-ucjs-created", "true");
            keyset.appendChild(newKey);
            log("created key for Browser:OpenLocation -> accel+D");
          } catch (e) {
            err("failed creating openLocation key:", e);
          }
        }

        // 2) Rebind Bookmark shortcut -> accel+B (if you still want that)
        let bookmarkKey = findKeyForCommand(doc, "Browser:AddBookmark", ["addBookmarkAsKb", "key_bookmarkPage"]);
        if (bookmarkKey) {
          if (setKeyBinding(doc, bookmarkKey, "B", "accel")) {
            log("assigned Browser:AddBookmark -> accel+B");
          } else {
            warn("found bookmark key but failed to set binding");
          }
        } else {
          warn("bookmark key not found; leaving default");
        }

      } catch (e) {
        err("applyCustomScriptToNewWindow error:", e);
      }
    }

    // Observer style used originally — attach listener for chrome windows
    function installObserver() {
      try {
        function onChromeDocumentGlobalCreated(subject, topic) {
          try {
            // subject is the chrome document global (document)
            // wait for the window 'load' so UI elements exist
            subject.addEventListener("load", function onload() {
              subject.removeEventListener("load", onload);
              try {
                const win = subject.defaultView;
                if (win && win.gBrowser) {
                  applyCustomScriptToNewWindow(win);
                }
              } catch (e) {
                err("onload handler error:", e);
              }
            }, { once: true });
          } catch (e) {
            err("onChromeDocumentGlobalCreated error:", e);
          }
        }

        const observer = {
          observe(subj, topic) {
            if (topic === "chrome-document-global-created") {
              onChromeDocumentGlobalCreated(subj, topic);
            }
          }
        };

        Services.obs.addObserver(observer, "chrome-document-global-created", false);
        log("observer installed (chrome-document-global-created)");
      } catch (e) {
        err("installObserver failed:", e);
      }
    }

    // Install now (unless in Safe Mode)
    try {
      if (!Services.appinfo.inSafeMode) {
        installObserver();
      } else {
        warn("Firefox in Safe Mode — customizations not installed");
      }
    } catch (e) {
      err("install check failed:", e);
    }

  } catch (outer) {
    try { console.error("ucjs init outer error:", outer); } catch (_) {}
  }
})();

