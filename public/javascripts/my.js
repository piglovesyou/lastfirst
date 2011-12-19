(function() {
  /*
   Utils.
   Depends on underscore.js
  */
  var $indicator_, $inputs_, $list_, $msgBox_, currentDocs_, delayTimerId_, postLocked_, socket, userId_;
  window.getFirstLetter_ = function(str) {
    var count, len, result;
    count = 1;
    len = str.length;
    if (len >= 2 && /^[ゃ-ょ|ー]$/.test(str[1])) {
      if (len >= 3 && /^[ー]$/.test(str[2])) {
        count = 3;
      } else {
        count = 2;
      }
    }
    result = [];
    _(count).times(function(i) {
      return result.push(str.slice(0, i + 1));
    });
    return result;
  };
  window.getLastLetter_ = function(str) {
    var count, lastIndex, len;
    count = 1;
    len = str.length;
    lastIndex = len - 1;
    if (len >= 2 && /^[ゃ-ょ|ー]$/.test(str[lastIndex])) {
      if (len >= 3 && /^[ー]$/.test(str[lastIndex - 1])) {
        count = 3;
      } else {
        count = 2;
      }
    }
    str = _.last(str, count);
    if (_.isArray(str)) {
      return str = str.join('');
    }
  };
  _.mixin({
    isValidWord: function(str) {
      if (_.isString(str) && /^[あ-ん|ー]+$/.test(str) && /^[^を]+$/.test(str) && !/っ$/.test(str)) {
        return _.all(str.split(''), function(letter, index, array) {
          if (index === 0) {
            return /^[^ゃ-ょ|^っ]$/.test(letter);
          } else {
            if (/^[ゃ-ょ]$/.test(letter)) {
              return /^[きしちにひみりぎじぢび]$/.test(array[index - 1]);
            }
            if (letter === 'っ') {
              return /^[^っ]$/.test(array[index - 1]);
            }
            return true;
          }
        });
      } else {
        return false;
      }
    },
    isEndsN: function(str) {
      return /ん$/.test(str);
    },
    isValidLastFirst: function(last, first) {
      return _.include(getFirstLetter_(first), getLastLetter_(last));
    }
  });
  _.mixin({
    parseParamString: function(str, sep) {
      var pairArr, pairStr, result, _i, _len, _ref;
      if (sep == null) {
        sep = '&';
      }
      result = {};
      _ref = str.split(sep);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pairStr = _ref[_i];
        pairArr = pairStr.split('=');
        result[pairArr[0]] = pairArr[1];
      }
      return result;
    },
    stringifyParam: function(paramObj, sep) {
      var key, keys, lastIndex, result, _i, _len;
      if (sep == null) {
        sep = '&';
      }
      result = '';
      keys = _.keys(paramObj);
      lastIndex = keys.length - 1;
      for (_i = 0, _len = keys.length; _i < _len; _i++) {
        key = keys[_i];
        result += key + '=' + paramObj[key];
        if (_i !== lastIndex) {
          result += sep;
        }
      }
      return result;
    },
    now: function() {
      return Date.now() || +new Date();
    },
    getCookies: function() {
      return _.parseParamString(document.cookie, '; ');
    },
    setCookies: function(keyValuePairs) {
      var key, _results;
      _results = [];
      for (key in keyValuePairs) {
        _results.push(document.cookie = key + '=' + keyValuePairs[key]);
      }
      return _results;
    }
  });
  /*
   global accessor to the base info
  */
  currentDocs_ = [];
  userId_ = '';
  _.mixin({
    setToken: function(token, expires) {
      return _.setCookies({
        token: token,
        expires: expires
      });
    },
    getToken: function() {
      var cookies;
      cookies = _.getCookies();
      return cookies.token;
    },
    setUserId: function(userId) {
      return userId_ = userId;
    },
    getUserId: function() {
      return userId_;
    },
    getLastDoc: function() {
      return currentDocs_[0] || null;
    },
    parseToken: function(hashStr) {
      var expires, params, token;
      hashStr = hashStr.replace(/^#/, '');
      params = _.parseParamString(hashStr);
      console.log('parseToken', params);
      token = params.access_token || '';
      expires = params.expires_in;
      if (token && expires) {
        expires = new Date(_.now() + expires * 1000).toString();
        _.setToken(token, expires);
        return socket.emit('got token', {
          token: token
        });
      } else {

      }
    }
  });
  /*
   jQuery init
  */
  $(function() {
    var $form, $list, $list_, token;
    token = _.getToken();
    if (token) {
      socket.emit('got token', {
        token: token
      });
    } else {
      _.showLoginLink();
    }
    $list = $list_ || ($list_ = $('#word-list'));
    $form = $('#post');
    return $form.submit(function(e) {
      var content, id, lastDoc;
      if (_.isLocked()) {
        return;
      }
      _.disableForm(true);
      id = _.getUserId();
      content = $('input[name="content"]', $form).val();
      if (_.isEmpty(content)) {
        return;
      }
      if (id && content && _.isValidWord(content)) {
        lastDoc = _.getLastDoc();
        if (id === lastDoc.createdBy) {
          _.showMessage('It\'s not your turn.');
          return _.disableForm(false);
        } else if (_.isValidLastFirst(lastDoc.content, content)) {
          return socket.emit('post word', {
            content: content,
            createdBy: id
          });
        } else {
          _.showMessage('I\'m not sure it\'s being Last and First.');
          return _.disableForm(false);
        }
      } else {
        _.showMessage('Please enter a word in HIRAGANA.');
        return _.disableForm(false);
      }
    });
  });
  $list_ = null;
  $msgBox_ = null;
  postLocked_ = false;
  $indicator_ = null;
  $inputs_ = null;
  _.mixin({
    isLocked: function() {
      return postLocked_;
    },
    disableForm: function(lock, withoutIndicator) {
      var $inputs;
      postLocked_ = lock;
      $inputs = $inputs_ || ($inputs_ = $('#post-form input'));
      if (lock) {
        $inputs.attr({
          disabled: 'disabled'
        });
      } else {
        $inputs.removeAttr('disabled');
      }
      if (!withoutIndicator) {
        return _.showIndicator(lock);
      }
    }
  });
  delayTimerId_ = null;
  _.mixin({
    hideWaitSecMessage: function() {
      return $('#wait-sec-message').hide();
    },
    showIndicator: function(show) {
      var $indicator;
      $indicator = $indicator_ || ($indicator_ = $('#post-form #indicator'));
      if ($indicator) {
        if (show) {
          return $indicator.addClass('loading');
        } else {
          return $indicator.removeClass('loading');
        }
      }
    }
  });
  _.mixin({
    showLoginLink: function() {
      _.hideWaitSecMessage();
      return $('#login-link').show();
    },
    hideLoginLink: function() {
      return $('#login-link').hide();
    },
    showPostForm: function() {
      _.hideWaitSecMessage();
      return $('#post-form').show();
    },
    setUserIdToHiddenInput: function() {
      return $('#user-id-input').val(_.getUserId());
    },
    showMessage: function(str) {
      var $msgBox;
      if (delayTimerId_) {
        window.clearTimeout(delayTimerId_);
      }
      $msgBox = $msgBox_ || ($msgBox_ = $('#msg-box').click(function(e) {
        return $(this).fadeOut();
      }));
      $msgBox.text(str).fadeIn();
      return delayTimerId_ = _.delay(function() {
        return $msgBox.fadeOut();
      }, 8888);
    }
  });
  /*
   Sockets init
  */
  socket = io.connect(location.protocol + '//' + location.host);
  socket.on('update', function(docs) {
    var $list, doc, html, postfix, _i, _len, _results;
    currentDocs_ = docs;
    $list = $list_ || ($list_ = $('#word-list'));
    $list.empty();
    _results = [];
    for (_i = 0, _len = docs.length; _i < _len; _i++) {
      doc = docs[_i];
      postfix = '';
      if (_.isEndsN(doc.content)) {
        postfix = '<span class="warn">*</span>';
      }
      html = "<tr>";
      html += "<td>" + doc.content + postfix + " </td>";
      if (_i === 0) {
        html += "<td>&lt;-last post </td>";
      }
      if (doc.createdBy === _.getUserId()) {
        html += "<td>&lt;-your post!</td>";
      }
      html += "</tr>";
      _results.push($list.append(html));
    }
    return _results;
  });
  socket.on('need login', function() {
    _.showMessage('Expired. Need another login.');
    return _.showLoginLink();
  });
  socket.on('validated nicely!', function(data) {
    var id;
    console.log('validated good.', data);
    id = data.userId;
    _.setUserId(id);
    _.setUserIdToHiddenInput(id);
    _.showMessage('Authorized fine.');
    _.hideLoginLink();
    return _.showPostForm();
  });
  socket.on('error message', function(data) {
    _.showMessage(data.message);
    return _.disableForm(false);
  });
  socket.on('posted successfully', function(post) {
    _.showMessage('"' + post.content + '" posted!');
    return _.disableForm(false);
  });
  socket.on('got penalty', function(data) {
    _.showMessage(data.message);
    _.disableForm(true);
    return _.showIndicator(false);
  });
  socket.on('release penalty', function(data) {
    _.showMessage(data.message);
    return _.disableForm(false);
  });
}).call(this);
