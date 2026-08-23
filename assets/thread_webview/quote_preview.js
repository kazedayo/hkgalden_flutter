(function () {
  function scrollToEnd() {
    window.scrollTo(0, document.body.scrollHeight);
  }

  function reportHeight() {
    var content = document.getElementById('content');
    if (!content || !window.GaldenBridge) {
      return;
    }
    var height = content.scrollHeight;
    window.GaldenBridge.post('contentHeight', { height: height });
  }

  function afterLayout() {
    reportHeight();
    scrollToEnd();
  }

  function setTheme(tokens) {
    var root = document.documentElement;
    for (var key in tokens) {
      if (Object.prototype.hasOwnProperty.call(tokens, key)) {
        root.style.setProperty('--' + key, tokens[key]);
      }
    }
  }

  function setHtml(html) {
    var content = document.getElementById('content');
    if (!content) {
      return;
    }
    content.innerHTML = html || '';
    afterLayout();
    var smileys = content.querySelectorAll('img.smiley');
    for (var i = 0; i < smileys.length; i++) {
      smileys[i].addEventListener('load', afterLayout);
      smileys[i].addEventListener('error', afterLayout);
    }
  }

  var contentEl = document.getElementById('content');
  if (contentEl && typeof ResizeObserver !== 'undefined') {
    new ResizeObserver(afterLayout).observe(contentEl);
  }

  window.GaldenRender = {
    handle: function (command) {
      if (!command || !command.type) {
        return;
      }
      var payload = command.payload || {};
      switch (command.type) {
        case 'setTheme':
          setTheme(payload);
          break;
        case 'setHtml':
          setHtml(payload.html);
          break;
      }
    },
  };
})();
