(function() {
  /*
   Global accessor to the base info
  */
  var $indicator_, $inputs_, $msgBox_, currentDocs_, delayTimerId_, message, postLocked_, socket, socketInit, time, userId_, words;
  currentDocs_ = [];
  userId_ = '';
  socket = null;
  words = null;
  message = null;
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
    parseToken: function(hashStr) {
      var expires, params, token;
      hashStr = hashStr.replace(/^#/, '');
      params = _.parseParamString(hashStr);
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
    },
    getSocket: function() {
      return socket;
    }
  });
  /*
   Initialize a page.
  */
  message === null;
  words = null;
  time = null;
  $(function() {
    var $form, token;
    message = new Message('#msg-box');
    words = new WordList('#word-list');
    time = new TimeComponent();
    socketInit();
    token = _.getToken();
    if (token) {
      socket.emit('got token', {
        token: token
      });
    } else {
      _.showLoginLink();
    }
    _.disableForm(false);
    $form = $('#post');
    return $form.submit(function(e) {
      var content, id, lastDoc;
      if (_.isLocked()) {
        return false;
      }
      _.disableForm(true);
      id = _.getUserId();
      content = $('input[name="content"]', $form).val();
      if (_.isEmpty(id) || _.isEmpty(content)) {
        _.disableForm(false);
      } else if (_.isValidWord(content)) {
        lastDoc = words.getLastWord();
        if (id === lastDoc.createdBy) {
          message.show('It\'s not your turn.');
          _.disableForm(false);
        } else if (_.isValidLastFirst(lastDoc.content, content)) {
          socket.emit('post word', {
            content: content,
            createdBy: id
          });
        } else {
          message.show('I\'m not sure it\'s being Last and First.');
          _.disableForm(false);
        }
      } else {
        message.show('Please enter a word in HIRAGANA.');
        _.disableForm(false);
      }
      return false;
    });
  });
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
  socketInit = function() {
    socket = io.connect(location.protocol + '//' + location.host);
    socket.on('update', function(docs) {
      var doc, word, _i, _len, _results;
      words.empty();
      _results = [];
      for (_i = 0, _len = docs.length; _i < _len; _i++) {
        doc = docs[_i];
        word = new Word(doc, _i < 2, _i === 0);
        word.render();
        word.attachTime(time);
        _results.push(words.push(word));
      }
      return _results;
    });
    socket.on('need login', function() {
      message.show('Expired. Need another login.');
      return _.showLoginLink();
    });
    socket.on('validated nicely!', function(data) {
      var id;
      id = data.userId;
      _.setUserId(id);
      _.setUserIdToHiddenInput(id);
      message.show('Authorized fine.');
      _.hideLoginLink();
      return _.showPostForm();
    });
    socket.on('error message', function(data) {
      message.show(data.message);
      return _.disableForm(false);
    });
    socket.on('posted successfully', function(post) {
      message.show('"' + post.content + '" posted!');
      return _.disableForm(false);
    });
    socket.on('got penalty', function(data) {
      message.show(data.message);
      _.disableForm(true);
      return _.showIndicator(false);
    });
    socket.on('release penalty', function(data) {
      message.show(data.message);
      return _.disableForm(false);
    });
    return socket.on('update like', function(data) {
      var word;
      word = words.get(data._id);
      if (word) {
        word.liked = data.liked;
        word.render();
        if (word.createdBy === _.getUserId()) {
          return message.showImportant('Somebody liked your post, "' + word.content + '"');
        }
      }
    });
  };
}).call(this);
