(function() {
  /*
   Classes used in LastFirstApp
   http://lastfirst.stakam.net/
  
   Depands on:
     socket.io.js
     underscore.js
     jquery-1.7.js
  */
  var Message, Word, WordList, exports;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  exports = window;
  /*
   Singleton class for words.
  */
  WordList = (function() {
    WordList.prototype.wordInstances_ = [];
    WordList.prototype.element = null;
    WordList.prototype.getElement = function() {
      return this.element;
    };
    function WordList(containerSelector) {
      this.element = $(containerSelector);
    }
    WordList.prototype.empty = function() {
      var word, _i, _len, _ref;
      _ref = this.wordInstances_;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        word = _ref[_i];
        word.dispose();
      }
      this.wordInstances_ = [];
      return this.element.empty();
    };
    WordList.prototype.renderWords = function() {
      var word, _i, _len, _ref, _results;
      this.element.empty();
      _ref = this.wordInstances_;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        word = _ref[_i];
        _results.push(word.render());
      }
      return _results;
    };
    WordList.prototype.push = function(word) {
      this.wordInstances_.push(word);
      return this.element.append(word.getElement());
    };
    WordList.prototype.shift = function(word) {
      return this.wordInstances_.shift(word);
    };
    WordList.prototype.pop = function() {
      var word;
      word = this.wordInstances_.pop();
      return word.dispose();
    };
    WordList.prototype.get = function(id) {
      return _.find(this.wordInstances_, function(word) {
        return word.id === id;
      });
    };
    WordList.prototype.getLastWord = function() {
      return this.wordInstances_[0];
    };
    return WordList;
  })();
  /*
   Class for a word.
  */
  Word = (function() {
    Word.prototype.element = null;
    Word.prototype.getElement = function() {
      return this.element;
    };
    Word.prototype.canRender = false;
    function Word(data, showCreatedAt, lastPost) {
      var className;
      this.showCreatedAt = showCreatedAt;
      this.lastPost = lastPost;
      this.sendLike = __bind(this.sendLike, this);
      this.id = data._id;
      this.content = data.content;
      this.createdBy = data.createdBy;
      this.createdAt = data.createdAt;
      this.liked = data.liked;
      this.canRender = !!(this.id && this.content && this.createdBy && this.createdAt && this.liked);
      if (this.canRender) {
        className = 'word';
        this.element = $("<div class='" + className + "'></div>");
      }
    }
    Word.prototype.render = function() {
      var content, createdAt, i, lastPostElm, likeButtonElm, likedElm, text, userId, yourPostElm, _i, _len, _ref;
      if (this.canRender) {
        this.element.empty();
        text = '';
        userId = _.getUserId();
        text = this.content;
        if (_.isEndsN(this.content)) {
          text += '*';
        }
        content = $("<span class='content' title='" + this.createdAt + "'>" + text + "</span>");
        text = '';
        _ref = this.liked;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          text += '6';
        }
        likedElm = $("<span class='liked i'>" + text + "</span>");
        this.element.append(content).append(likedElm);
        if (userId && userId !== this.createdBy && !_.include(this.liked, userId)) {
          likeButtonElm = $("<span class='like i' title='like it'>6</span>").bind('click', this.sendLike);
          this.element.append(likeButtonElm);
        }
        if (this.lastPost) {
          lastPostElm = $('<span class="last-post">&lt-last post</span>');
          this.element.append(lastPostElm);
        }
        if (userId === this.createdBy) {
          yourPostElm = $('<span class="your-post">&lt-your post!</span>');
          this.element.append(yourPostElm);
        }
        if (this.showCreatedAt) {
          text = ' <-' + _.niceDate(this.createdAt, 'en');
          createdAt = $("<span class='createdat'>" + text + "</span>");
          return this.element.append(createdAt);
        }
      }
    };
    Word.prototype.sendLike = function(e) {
      var socket;
      socket = _.getSocket();
      if (socket) {
        return socket.emit('like', {
          wordId: this.id,
          userId: _.getUserId()
        });
      }
    };
    Word.prototype.dispose = function() {
      var prop, _results;
      this.element.unbind();
      this.element.remove();
      _results = [];
      for (prop in this) {
        _results.push(this[prop] = null);
      }
      return _results;
    };
    return Word;
  })();
  /*
   Singleton class for showing messages.
  */
  Message = (function() {
    Message.prototype.element = null;
    Message.prototype.messageElm_ = null;
    Message.prototype.importantMessageElm_ = null;
    function Message(containerSelector) {
      var importantMessageTimer, messageTimer, onDocMouseMove;
      importantMessageTimer = null;
      messageTimer = null;
      this.element = $(containerSelector);
      onDocMouseMove = function(e) {
        var $that;
        $that = e.data.$that;
        $(window.document).unbind('mousemove', onDocMouseMove);
        return importantMessageTimer = _.delay(function() {
          return $that.trigger('hide');
        }, 7 * 1000);
      };
      this.importantMessageElm_ = $('<div class="msg important"></div>').hide().bind('hide', function(e) {
        window.clearTimeout(importantMessageTimer);
        $(window.document).unbind('mousemove', onDocMouseMove);
        return $(this).fadeOut();
      }).bind('show', function(e, msg) {
        var $that;
        window.clearTimeout(importantMessageTimer);
        $that = $(this).text(msg);
        $that.fadeIn();
        return $(window.document).bind('mousemove', {
          $that: $that
        }, onDocMouseMove);
      }).bind('click', function(e) {
        return $(this).trigger('hide');
      });
      this.messageElm_ = $('<div class="msg"></div>').hide().bind('hide', function(e) {
        window.clearTimeout(messageTimer);
        return $(this).fadeOut();
      }).bind('show', function(e, msg) {
        var $that;
        window.clearTimeout(messageTimer);
        $that = $(this).text(msg);
        $that.fadeIn();
        return messageTimer = _.delay(function() {
          return $that.trigger('hide');
        }, 7 * 1000);
      }).bind('click', function(e) {
        return $(this).trigger('hide');
      });
      this.element.append(this.importantMessageElm_).append(this.messageElm_);
    }
    Message.prototype.show = function(str) {
      return this.messageElm_.trigger('show', str);
    };
    Message.prototype.showImportant = function(str) {
      return this.importantMessageElm_.trigger('show', str);
    };
    return Message;
  })();
  exports.WordList = WordList;
  exports.Word = Word;
  exports.Message = Message;
}).call(this);
