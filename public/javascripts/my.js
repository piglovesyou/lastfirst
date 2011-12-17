(function() {
  /*
   util
  */
  var $list_, $msgBox_, currentDocs_, delayTimerId_, getFirstLetter_, getLastLetter_, socket, token_, userId_;
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
    isValidWord: function(str) {
      if (_.isString(str) && /^[あ-ん|ー]+$/.test(str) && /^[^を]+$/.test(str)) {
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
    }
  });
  getFirstLetter_ = function(str) {
    var count, len;
    count = 1;
    len = str.length;
    if (len >= 2 && /^[ゃ-ょ|っ]$/.test(str[1])) {
      if (len >= 3 && /^[っ]$/.test(str[2])) {
        count = 3;
      } else {
        count = 2;
      }
    }
    return str.slice(0, count);
  };
  getLastLetter_ = function(str) {
    var count, lastIndex, len;
    count = 1;
    len = str.length;
    lastIndex = len - 1;
    if (len >= 2 && /^[ゃ-ょ|っ]$/.test(str[lastIndex])) {
      if (len >= 3 && /^[ゃ-ょ]$/.test(str[lastIndex - 1])) {
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
    isValidLastFirst: function(last, first) {
      console.log(last, first);
      return getLastLetter_(last) === getFirstLetter_(first);
    }
  });
  /*
   global accessor to the base info
  */
  token_ = '';
  userId_ = '';
  _.mixin({
    setToken: function(token) {
      return token_ = token;
    },
    getToken: function() {
      return token_;
    },
    setUserId: function(userId) {
      return userId_ = userId;
    },
    getUserId: function() {
      return userId_;
    }
  });
  currentDocs_ = [];
  _.mixin({
    getLastDoc: function() {
      return currentDocs_[0] || null;
    },
    parseToken: function(hashStr) {
      var params, token;
      hashStr = hashStr.replace(/^#/, '');
      params = _.parseParamString(hashStr);
      console.log('parseToken', params);
      token = params.access_token || '';
      if (token) {
        _.setToken(token);
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
  $list_ = null;
  $msgBox_ = null;
  $(function() {
    var $form, $list;
    $list = $list_ || ($list_ = $('#word-list'));
    $form = $('#post');
    $form.submit(function(e) {
      var content, id, lastDoc;
      content = $('input[name="word"]', this).val();
      id = _.getUserId();
      if (id && content && _.isValidWord(content)) {
        lastDoc = _.getLastDoc();
        if (id === lastDoc.createdBy) {
          return _.showMessage('You can post only once a turn.');
        } else if (_.isValidLastFirst(lastDoc.content, content)) {
          return socket.emit('post word', {
            content: content,
            createdBy: id,
            createdAt: new Date()
          });
        } else {
          return _.showMessage('I\'m not sure it\'s Last and First.');
        }
      } else {
        return _.showMessage('Do you speak japanese?');
      }
    });
    return $("#login-link > a").click();
  });
  delayTimerId_ = null;
  _.mixin({
    hideLoginLink: function() {
      return $('#login-link').hide();
    },
    showPostForm: function() {
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
  socket = io.connect('http://localhost');
  socket.on('update', function(docs) {
    var $list, doc, html, _i, _len, _results;
    currentDocs_ = docs;
    $list = $list_ || ($list_ = $('#word-list'));
    $list.empty();
    _results = [];
    for (_i = 0, _len = docs.length; _i < _len; _i++) {
      doc = docs[_i];
      html = "<tr><td>" + doc.content + "</td>";
      if (doc.createdBy === _.getUserId()) {
        html += "<td>&lt;-your post!</td>";
      }
      html += "</tr>";
      _results.push($list.append(html));
    }
    return _results;
  });
  socket.on('validated nicely!', function(data) {
    var id;
    console.log('validated good.', data);
    id = data.user_id;
    _.setUserId(id);
    _.setUserIdToHiddenInput(id);
    _.showMessage('logged in. thank you.');
    _.hideLoginLink();
    return _.showPostForm();
  });
  socket.on('validation fail', function(data) {
    return console.log('too bad.', data);
  });
  socket.on('posted successfully', function(post) {
    return _.showMessage('"' + post.content + '" is posted successfully!');
  });
}).call(this);
