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
  exports = window;
  /*
   Singleton class for words.
  */
  WordList = (function() {
    WordList.prototype.wordInstances_ = [];
    WordList.prototype.element_ = null;
    WordList.prototype.getElement = function() {
      return this.element_;
    };
    function WordList(containerSelector) {
      this.element_ = $(containerSelector);
    }
    WordList.prototype.empty = function() {
      var word, _i, _len, _ref;
      _ref = this.wordInstances_;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        word = _ref[_i];
        word.dispose();
      }
      this.wordInstances_ = [];
      return this.element_.empty();
    };
    WordList.prototype.renderWords = function() {
      var word, _i, _len, _ref, _results;
      this.element_.empty();
      _ref = this.wordInstances_;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        word = _ref[_i];
        _results.push(word.render(this.element_));
      }
      return _results;
    };
    WordList.prototype.push = function(word) {
      return this.wordInstances_.push(word);
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
      var word, _i, _len, _ref;
      _ref = this.wordInstances_;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        word = _ref[_i];
        if (word.id === id) {
          return word;
        }
      }
      return null;
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
    var canRender_, element_, timeElm_;
    element_ = null;
    timeElm_ = null;
    canRender_ = false;
    function Word(data) {
      this.content = data.content;
      this.createdBy = data.createdBy;
      this.createdAt = data.createdAt;
      this.canRender_ = !!(this.content && this.createdBy && this.createdAt);
    }
    Word.prototype.render = function($parent) {
      var className, content;
      if (this.canRender_) {
        content = $("<span class='content'>" + this.content + "</span>");
        this.timeElm_ = $("<span class='time'>" + this.createdAt + "</span>");
        className = 'word';
        this.element_ = $("<div class='" + className + "'></div>").append(content).append(this.$timeElm_);
        return $parent.append(this.element_);
      }
    };
    Word.prototype.dispose = function() {
      var prop, _results;
      this.element_.remove();
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
    Message.prototype.element_ = null;
    Message.prototype.messageElm_ = null;
    Message.prototype.importantMessageElm_ = null;
    function Message(containerSelector) {
      var importantMessageTimer, messageTimer, onDocMouseMove;
      importantMessageTimer = null;
      messageTimer = null;
      this.element_ = $(containerSelector);
      onDocMouseMove = function(e) {
        var $that;
        $that = e.data.$that;
        $(window.document).unbind('mousemove', onDocMouseMove);
        return importantMessageTimer = _.delay(function() {
          return $that.trigger('hide');
        }, 3 * 1000);
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
        }, 3 * 1000);
      }).bind('click', function(e) {
        return $(this).trigger('hide');
      });
      this.element_.append(this.importantMessageElm_).append(this.messageElm_);
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
