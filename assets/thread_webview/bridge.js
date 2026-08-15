(function () {
  function post(type, payload) {
    var message = JSON.stringify({
      type: type,
      payload: payload || {},
    });
    if (window.Galden && typeof window.Galden.postMessage === 'function') {
      window.Galden.postMessage(message);
    }
  }

  window.GaldenBridge = {
    post: post,
    receive: function (command) {
      if (!command || !command.type) {
        return;
      }
      if (window.GaldenRender && typeof window.GaldenRender.handle === 'function') {
        window.GaldenRender.handle(command);
      }
    },
  };

  function sendReady() {
    post('ready', {});
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', sendReady);
  } else {
    sendReady();
  }
})();
