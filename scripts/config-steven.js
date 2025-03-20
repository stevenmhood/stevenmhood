// config1.js file for [Firefox program folder]
// file name must match the name in [Firefox program folder]\defaults\pref
function applyCustomScriptToNewWindow(win){
  /*** Context menu changes ***/ 
  var key = win.document.getElementById('focusURLBar');
  key.setAttribute('key', 'D');
  key.setAttribute('modifiers', 'accel');

  var key = win.document.getElementById('addBookmarkAsKb');
  key.setAttribute('key', 'B');
  key.setAttribute('modifiers', 'accel');

  /*** Other changes ***/ 
}
/* Single function userChrome.js loader to run the above init function (no external scripts)
  derived from https://www.reddit.com/r/firefox/comments/kilmm2/ */

try {
  //let { classes: Cc, interfaces: Ci, manager: Cm  } = Components;
  const Services = globalThis.Services;
  function ConfigJS() { 
    Services.obs.addObserver(this, 'chrome-document-global-created', false); 
  }
  ConfigJS.prototype = {
    observe: function (aSubject) { 
      aSubject.addEventListener('load', this, {once: true}); 
    },
    handleEvent: function (aEvent) {
      let document = aEvent.originalTarget; 
      let window = document.defaultView; 
      let location = window.location;
      if (/^(chrome:(?!\/\/(global\/content\/commonDialog|browser\/content\/webext-panels)\.x?html)|about:(?!blank))/i.test(location.href)) {
        if (window.gBrowser) {
          applyCustomScriptToNewWindow(window);
        }
      }
    }
  };
  if (!Services.appinfo.inSafeMode) { 
    new ConfigJS(); 
  }
} catch(ex) {};

