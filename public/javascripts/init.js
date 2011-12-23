(function() {
  var $indicator_, $inputs_, $msgBox_, cn, delayTimerId_, postLocked_, renderWords, socket, words;
  cn = console.log;
  /*
   Initialize a page.
  */
  words = null;
  $(function() {
    var $form, token;
    token = _.getToken();
    if (token) {
      socket.emit('got token', {
        token: token
      });
    } else {
      _.showLoginLink();
    }
    words = new WordList('#word-list');
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
        lastDoc = words.getLastWord();
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
  renderWords = function(docs) {
    var doc, word, _i, _len;
    words.empty();
    for (_i = 0, _len = docs.length; _i < _len; _i++) {
      doc = docs[_i];
      word = new Word(doc);
      words.push(word);
    }
    return words.renderWords();
  };
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
    return renderWords(docs);
  });
  socket.on('need login', function() {
    _.showMessage('Expired. Need another login.');
    return _.showLoginLink();
  });
  socket.on('validated nicely!', function(data) {
    var id;
    id = data.userId;
    console.log(id);
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
