(function () {
  var post = function (type, payload) {
    if (window.GaldenBridge) {
      window.GaldenBridge.post(type, payload);
    }
  };

  var flags = {
    canReply: false,
    locked: false,
    onLastPage: false,
    appending: false,
    currentPage: 1,
    canPullPrevious: false,
    pullMaxExtent: 200,
  };

  var blocked = {};
  var scrollEndTimer = null;
  var lastScrollY = 0;
  var pulling = false;
  var pullStartY = 0;
  var pullExtent = 0;
  var menuUserId = null;

  var previousRoot = document.getElementById('previous');
  var mainRoot = document.getElementById('main');
  var footerRoot = document.getElementById('footer');
  var userMenu = document.getElementById('user-menu');
  var menuBackdrop = document.getElementById('menu-backdrop');

  function pageLabel(floor) {
    if (floor === 1) {
      return '第 1 頁';
    }
    return '第 ' + Math.floor((floor + 49) / 50) + ' 頁';
  }

  function escapeAttr(value) {
    return String(value == null ? '' : value)
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/</g, '&lt;');
  }

  function text(value) {
    return String(value == null ? '' : value);
  }

  function groupClass(groupId) {
    if (!groupId) {
      return 'group-none';
    }
    return groupId === 'ADMIN' ? 'group-admin' : 'group-other';
  }

  function genderClass(gender) {
    if (gender === 'M') {
      return 'gender-m';
    }
    if (gender === 'F') {
      return 'gender-f';
    }
    return '';
  }

  function applyBlocked(article) {
    var id = article.getAttribute('data-author-id');
    article.hidden = !!(id && blocked[id]);
  }

  function bindContent(article) {
    var html = article.querySelector('.comment-html');
    if (!html) {
      return;
    }
    html.addEventListener('click', function (event) {
      var img = event.target.closest('img.content-img');
      if (img) {
        event.preventDefault();
        event.stopPropagation();
        post('openImage', {
          url: img.getAttribute('src') || '',
          sx: parseInt(img.getAttribute('data-sx'), 10) || null,
          sy: parseInt(img.getAttribute('data-sy'), 10) || null,
          floor: parseInt(article.getAttribute('data-floor'), 10) || null,
        });
        return;
      }
      var preview = event.target.closest('.preview-chip, .link-preview a');
      if (preview) {
        event.preventDefault();
        var href = preview.getAttribute('data-href') || preview.getAttribute('href');
        if (href) {
          post('openLink', { url: href });
        }
        return;
      }
      var link = event.target.closest('a');
      if (link && link.getAttribute('href')) {
        event.preventDefault();
        post('openLink', { url: link.getAttribute('href') });
      }
    });

    var images = html.querySelectorAll('img.content-img');
    for (var i = 0; i < images.length; i++) {
      (function (img) {
        img.addEventListener('load', function () {
          if (img.naturalWidth > 0 && img.naturalHeight > 0) {
            post('imageMetrics', {
              url: img.getAttribute('src') || '',
              width: img.naturalWidth,
              height: img.naturalHeight,
            });
          }
        });
        img.addEventListener('error', function () {
          var box = document.createElement('div');
          box.className = 'img-error';
          box.textContent = '圖片載入錯誤';
          if (img.parentNode) {
            img.parentNode.replaceChild(box, img);
          }
        });
      })(images[i]);
    }
  }

  function renderReply(reply) {
    var article = document.createElement('article');
    article.className = 'comment';
    article.style.paddingTop = '52px';
    article.setAttribute('data-floor', String(reply.floor));
    if (reply.replyId) {
      article.setAttribute('data-reply-id', reply.replyId);
    }
    var author = reply.author || {};
    article.setAttribute('data-author-id', text(author.userId));

    var avatarInner;
    if (author.avatar) {
      avatarInner = '<img class="avatar" src="' + escapeAttr(author.avatar) + '" alt="">';
    } else {
      avatarInner = '<span class="avatar placeholder"></span>';
    }

    var fragment = document.createElement('div');
    fragment.innerHTML =
      '<div class="comment-meta">' +
        '<button type="button" class="avatar-btn" data-user-id="' + escapeAttr(author.userId) + '">' +
          '<span class="avatar-ring ' + groupClass(author.groupId) + '">' + avatarInner + '</span>' +
        '</button>' +
        '<div class="author-col">' +
          '<div class="nickname ' + genderClass(author.gender) + '"></div>' +
          '<div class="floor">#' + escapeAttr(reply.floor) + '</div>' +
        '</div>' +
        '<div class="date"></div>' +
      '</div>' +
      '<div class="card">' +
        '<div class="comment-html"></div>' +
        '<div class="comment-actions">' +
          '<button type="button" class="quote-btn" aria-label="quote">' +
            '<svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true">' +
              '<path d="M6 17h3l2-4V7H5v6h3zm8 0h3l2-4V7h-6v6h3z"/>' +
            '</svg>' +
          '</button>' +
        '</div>' +
      '</div>';

    while (fragment.firstChild) {
      article.appendChild(fragment.firstChild);
    }

    article.querySelector('.nickname').textContent = text(author.nickname);
    article.querySelector('.date').textContent = text(reply.dateText);
    article.querySelector('.comment-html').innerHTML = reply.html || '';

    applyBlocked(article);
    bindContent(article);
    return article;
  }

  function pageHeader(floor) {
    var header = document.createElement('div');
    header.className = 'page-header';
    header.setAttribute('data-page-start', String(floor));
    header.textContent = pageLabel(floor);
    return header;
  }

  function appendReplyNodes(root, replies, prepend) {
    var nodes = [];
    for (var i = 0; i < replies.length; i++) {
      var reply = replies[i];
      if (reply.isPageStart) {
        nodes.push(pageHeader(reply.floor));
      }
      nodes.push(renderReply(reply));
    }
    if (prepend) {
      var first = root.firstChild;
      for (var j = 0; j < nodes.length; j++) {
        root.insertBefore(nodes[j], first);
      }
    } else {
      for (var k = 0; k < nodes.length; k++) {
        root.appendChild(nodes[k]);
      }
    }
  }

  function renderFooter() {
    var skeletonHidden = flags.onLastPage ? 'hidden' : '';
    var refreshHidden = flags.onLastPage ? '' : 'hidden';
    var label = flags.appending ? '撈緊...' : '重新整理';
    var icon = flags.appending
      ? '<span class="spinner"></span>'
      : '<span style="font-size:20px;line-height:1">↻</span>';
    footerRoot.innerHTML =
      '<div class="footer-skeleton" ' + skeletonHidden + '><span></span></div>' +
      '<button type="button" class="footer-refresh" ' + refreshHidden + '>' +
        icon + '<span>' + label + '</span></button>';
  }

  function setTheme(tokens) {
    var root = document.documentElement;
    for (var key in tokens) {
      if (Object.prototype.hasOwnProperty.call(tokens, key)) {
        root.style.setProperty('--' + key, tokens[key]);
      }
    }
  }

  function setFlags(next) {
    for (var key in next) {
      if (Object.prototype.hasOwnProperty.call(next, key)) {
        flags[key] = next[key];
      }
    }
    document.body.classList.toggle('locked', !!flags.locked);
    document.body.classList.toggle('no-reply', !flags.canReply);
    renderFooter();
  }

  function setBlockedUsers(ids) {
    blocked = {};
    if (ids && ids.length) {
      for (var i = 0; i < ids.length; i++) {
        blocked[ids[i]] = true;
      }
    }
    var articles = document.querySelectorAll('article.comment');
    for (var j = 0; j < articles.length; j++) {
      applyBlocked(articles[j]);
    }
  }

  function setSafeInsets(insets) {
    var root = document.documentElement.style;
    if (insets.left != null) {
      root.setProperty('--safe-left', insets.left + 'px');
    }
    if (insets.right != null) {
      root.setProperty('--safe-right', insets.right + 'px');
    }
    if (insets.bottom != null) {
      root.setProperty('--safe-bottom', insets.bottom + 'px');
    }
  }

  function clearRoot(el) {
    while (el.firstChild) {
      el.removeChild(el.firstChild);
    }
  }

  function renderThread(payload) {
    clearRoot(previousRoot);
    clearRoot(mainRoot);
    appendReplyNodes(previousRoot, payload.previous || [], false);
    appendReplyNodes(mainRoot, payload.replies || [], false);
    renderFooter();
    if (payload.scrollToFloor) {
      scrollToFloor(payload.scrollToFloor);
    }
    post('contentReady', {});
  }

  function prependReplies(replies) {
    if (!replies || !replies.length) {
      return;
    }
    var before = document.documentElement.scrollHeight;
    appendReplyNodes(previousRoot, replies, true);
    var delta = document.documentElement.scrollHeight - before;
    window.scrollTo(0, window.scrollY + delta);
  }

  function appendReplies(replies) {
    if (!replies || !replies.length) {
      return;
    }
    appendReplyNodes(mainRoot, replies, false);
  }

  function replaceLastPage(replies) {
    clearRoot(mainRoot);
    appendReplyNodes(mainRoot, replies || [], false);
  }

  function hydratePreviews(items) {
    if (!items) {
      return;
    }
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var selector = '.link-preview[data-preview="' + escapeAttr(item.kind) +
        '"][data-id="' + escapeAttr(item.id) + '"]';
      var nodes = document.querySelectorAll(selector);
      for (var j = 0; j < nodes.length; j++) {
        var el = nodes[j];
        if (item.title) {
          var title = el.querySelector('.preview-title');
          if (title) {
            title.textContent = item.title;
          }
        }
        if (item.subtitle) {
          var sub = el.querySelector('.preview-sub');
          if (sub) {
            sub.textContent = item.subtitle;
          }
        }
        if (item.body) {
          var body = el.querySelector('.preview-text');
          if (body) {
            body.textContent = item.body;
          }
        }
        if (item.imageUrl) {
          var thumb = el.querySelector('.preview-thumb');
          if (thumb) {
            thumb.classList.add('has-image');
            thumb.classList.remove('preview-accent');
            thumb.style.backgroundImage = "url('" + String(item.imageUrl).replace(/'/g, '%27') + "')";
          }
        }
      }
    }
  }

  function findFloorEl(floor) {
    var exact = document.querySelector('article.comment[data-floor="' + floor + '"]');
    if (exact) {
      return exact;
    }
    var articles = document.querySelectorAll('article.comment');
    var best = null;
    var bestFloor = Infinity;
    for (var i = 0; i < articles.length; i++) {
      var f = parseInt(articles[i].getAttribute('data-floor'), 10);
      if (f >= floor && f < bestFloor) {
        best = articles[i];
        bestFloor = f;
      }
    }
    return best;
  }

  function scrollToFloor(floor) {
    var el = findFloorEl(floor);
    if (el) {
      var top = el.getBoundingClientRect().top + window.scrollY;
      window.scrollTo(0, Math.max(0, top));
    }
  }

  function scrollToBottom() {
    window.scrollTo({
      top: document.documentElement.scrollHeight,
      behavior: 'smooth',
    });
  }

  function floorAtViewport(y) {
    var articles = document.querySelectorAll('article.comment:not([hidden])');
    var bestFloor = null;
    var bestTop = -Infinity;
    var nearest = null;
    var nearestDist = Infinity;
    for (var i = 0; i < articles.length; i++) {
      var rect = articles[i].getBoundingClientRect();
      var floor = parseInt(articles[i].getAttribute('data-floor'), 10);
      if (rect.top <= y + 24) {
        if (rect.top >= bestTop) {
          bestTop = rect.top;
          bestFloor = floor;
        }
      } else if (rect.bottom > y) {
        var dist = rect.top - y;
        if (dist < nearestDist) {
          nearestDist = dist;
          nearest = floor;
        }
      }
    }
    return bestFloor != null ? bestFloor : nearest;
  }

  function lastVisibleFloor(top, bottom) {
    var articles = document.querySelectorAll('article.comment:not([hidden])');
    var best = null;
    for (var i = 0; i < articles.length; i++) {
      var rect = articles[i].getBoundingClientRect();
      if (rect.bottom > top && rect.top < bottom) {
        var floor = parseInt(articles[i].getAttribute('data-floor'), 10);
        if (best == null || floor > best) {
          best = floor;
        }
      }
    }
    return best;
  }

  function emitScroll(settled) {
    var y = window.scrollY || 0;
    var maxY = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
    var payload = {
      y: y,
      maxY: maxY,
      atStart: y <= 0.5,
      atEnd: y >= maxY - 1,
      viewportTopFloor: floorAtViewport(0),
      lastVisibleFloor: lastVisibleFloor(0, window.innerHeight),
      settled: !!settled,
    };
    post('scroll', payload);
    lastScrollY = y;
  }

  function hideMenu() {
    userMenu.hidden = true;
    menuBackdrop.hidden = true;
    menuUserId = null;
  }

  function showMenu(btn, userId) {
    menuUserId = userId;
    var rect = btn.getBoundingClientRect();
    userMenu.style.left = Math.max(8, rect.left) + 'px';
    userMenu.style.top = (rect.bottom + 6) + 'px';
    userMenu.hidden = false;
    menuBackdrop.hidden = false;
  }

  document.addEventListener('click', function (event) {
    var avatar = event.target.closest('.avatar-btn');
    if (avatar) {
      showMenu(avatar, avatar.getAttribute('data-user-id'));
      return;
    }
    var quote = event.target.closest('.quote-btn');
    if (quote) {
      var article = quote.closest('article.comment');
      if (article) {
        post('quote', {
          replyId: article.getAttribute('data-reply-id'),
          floor: parseInt(article.getAttribute('data-floor'), 10) || null,
        });
      }
      return;
    }
    var refresh = event.target.closest('.footer-refresh');
    if (refresh) {
      post('refreshLastPage', {});
    }
  });

  userMenu.addEventListener('click', function (event) {
    var action = event.target.closest('button');
    if (!action || !menuUserId) {
      return;
    }
    var type = action.getAttribute('data-action') === 'block' ? 'blockUser' : 'openUser';
    post(type, { userId: menuUserId });
    hideMenu();
  });

  menuBackdrop.addEventListener('click', hideMenu);

  document.addEventListener('copy', function () {
    requestAnimationFrame(function () {
      var sel = window.getSelection();
      if (sel) {
        sel.removeAllRanges();
      }
    });
  });

  window.addEventListener('scroll', function () {
    emitScroll(false);
    if (scrollEndTimer) {
      clearTimeout(scrollEndTimer);
    }
    scrollEndTimer = setTimeout(function () {
      emitScroll(true);
    }, 160);
  }, { passive: true });

  document.addEventListener('touchstart', function (event) {
    if (!flags.canPullPrevious) {
      return;
    }
    if ((window.scrollY || 0) > 0.5) {
      pulling = false;
      return;
    }
    pulling = true;
    pullStartY = event.touches[0].clientY;
    pullExtent = 0;
    post('pullPrevious', { phase: 'start', extent: 0 });
  }, { passive: true });

  document.addEventListener('touchmove', function (event) {
    if (!pulling || !flags.canPullPrevious) {
      return;
    }
    var dy = event.touches[0].clientY - pullStartY;
    if ((window.scrollY || 0) <= 0.5 && dy > 0) {
      pullExtent = Math.min(dy * 0.85, flags.pullMaxExtent || 200);
      post('pullPrevious', { phase: 'move', extent: pullExtent });
    } else if (dy <= 0) {
      pulling = false;
    }
  }, { passive: true });

  document.addEventListener('touchend', function () {
    if (!pulling) {
      return;
    }
    pulling = false;
    post('pullPrevious', { phase: 'end', extent: pullExtent });
    pullExtent = 0;
  });

  window.GaldenRender = {
    handle: function (command) {
      var type = command.type;
      var payload = command.payload || {};
      switch (type) {
        case 'setTheme':
          setTheme(payload);
          break;
        case 'setFlags':
          setFlags(payload);
          break;
        case 'setBlockedUsers':
          setBlockedUsers(payload.ids || []);
          break;
        case 'setSafeInsets':
          setSafeInsets(payload);
          break;
        case 'renderThread':
          renderThread(payload);
          break;
        case 'prependReplies':
          prependReplies(payload.replies || []);
          break;
        case 'appendReplies':
          appendReplies(payload.replies || []);
          break;
        case 'replaceLastPage':
          replaceLastPage(payload.replies || []);
          break;
        case 'hydratePreviews':
          hydratePreviews(payload.items || []);
          break;
        case 'scrollToFloor':
          scrollToFloor(payload.floor);
          break;
        case 'scrollToBottom':
          scrollToBottom();
          break;
        default:
          break;
      }
    },
  };
})();
