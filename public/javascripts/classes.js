(function() {
  /*
   Classes used in LastFirstApp
   http://lastfirst.stakam.net/
  
   Depands on:
     socket.io.js
     underscore.js
     jquery-1.7.js
  */
  var AbstractComponent, Message, Time, Word, WordList, exports;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  exports = window;
  /*
   Abstract class to manage DOM components.
   usage:
      # create instance
      component = new Component() 
      # append dom in body
      component.render()          
      # unbind all eventHandlers and remove dom
      component.dispose()         
  */
  AbstractComponent = (function() {
    function AbstractComponent() {}
    AbstractComponent.prototype.element = null;
    AbstractComponent.prototype.getElement = function() {
      return this.element;
    };
    AbstractComponent.prototype.isInDocument = false;
    AbstractComponent.prototype.canRender = function() {
      return true;
    };
    AbstractComponent.prototype.render = function() {
      return this.isInDocument = true;
    };
    AbstractComponent.prototype.decorate = function(elmSelector) {
      this.isInDocument = true;
      return this.element = $(elmSelector);
    };
    AbstractComponent.prototype.dispose = function() {
      var prop, _results;
      if (this.isInDocument) {
        this.element.unbind();
        this.element.remove();
        _results = [];
        for (prop in this) {
          _results.push(_.isObject(this[prop]) ? this[prop] = null : void 0);
        }
        return _results;
      }
    };
    return AbstractComponent;
  })();
  /*
   Singleton class for words.
  */
  WordList = (function() {
    __extends(WordList, AbstractComponent);
    function WordList() {
      WordList.__super__.constructor.apply(this, arguments);
    }
    WordList.prototype.wordInstances_ = [];
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
  _.addSingletonGetter(WordList);
  /*
   Class for a word.
  */
  Word = (function() {
    __extends(Word, AbstractComponent);
    function Word(data, isLastPost) {
      this.isLastPost = isLastPost;
      this.sendLike = __bind(this.sendLike, this);
      this.id = data._id;
      this.content = data.content;
      this.createdBy = data.createdBy;
      this.createdAt = data.createdAt;
      this.liked = data.liked;
      if (this.canRender()) {
        this.element = $('<div class="word"></div>');
      }
    }
    Word.prototype.canRender = function() {
      return !!(this.id && this.content && this.createdBy && this.createdAt && this.liked);
    };
    Word.prototype.render = function() {
      var content, i, lastPostElm, likeButtonElm, likedElm, text, userId, yourPostElm, _i, _len, _ref;
      if (this.canRender()) {
        Word.__super__.render.call(this);
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
        if (this.isLastPost) {
          lastPostElm = $('<span class="last-post">&lt-last post</span>');
          this.element.append(lastPostElm);
        }
        if (userId === this.createdBy) {
          yourPostElm = $('<span class="your-post">&lt-your post!</span>');
          return this.element.append(yourPostElm);
        }
      }
    };
    Word.prototype.attachTime = function(time) {
      this.time = time;
      return this.time.attachElement(this.element, this.createdAt);
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
    return Word;
  })();
  _.addSingletonGetter(Word);
  /*
   Singleton class for showing messages.
  */
  Message = (function() {
    __extends(Message, AbstractComponent);
    function Message() {
      Message.__super__.constructor.apply(this, arguments);
    }
    Message.prototype.messageElm_ = null;
    Message.prototype.importantMessageElm_ = null;
    Message.prototype.render = function() {
      var importantMessageTimer, messageTimer, onDocMouseMove;
      Message.__super__.render.call(this);
      importantMessageTimer = null;
      messageTimer = null;
      this.element = $('<div id="msg-box" title="close this message"></div>');
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
      return this.element.append(this.importantMessageElm_).append(this.messageElm_).appendTo('body');
    };
    Message.prototype.show = function(str) {
      return this.messageElm_.trigger('show', str);
    };
    Message.prototype.showImportant = function(str) {
      return this.importantMessageElm_.trigger('show', str);
    };
    Message.prototype.dispose = function() {
      this.importantMessageElm_.unbind();
      this.messageElm_.unbind();
      return Message.__super__.dispose.call(this);
    };
    return Message;
  })();
  _.addSingletonGetter(Message);
  /*
   Singleton class for time.
  */
  Time = (function() {
    __extends(Time, AbstractComponent);
    function Time() {
      Time.__super__.constructor.apply(this, arguments);
    }
    Time.prototype.shortTickElm = null;
    Time.prototype.longTickElm = null;
    Time.prototype.titleElm = null;
    Time.prototype.height = 0;
    Time.prototype.hideTimer = null;
    Time.prototype.render = function() {
      Time.__super__.render.call(this);
      this.element = $("<div class=\"time\" style=\"display:none\"><div class=\"time-arrow\"></div><div class=\"time-bg\"><div class=\"time-round clearfix\"><div class=\"time-label\"><div class=\"time-label-twelve\">12</div><div class=\"time-label-three\">3</div><div class=\"time-label-six\">6</div><div class=\"time-label-nine\">9</div></div><div class=\"time-tick\"><div class=\"time-tick-short\"></div><div class=\"time-tick-long\"></div></div><div class=\"time-tick-center\"></div></div><div class=\"time-title\"><div class=\"time-title-content\"></div></div></div></div>");
      $('body').append(this.element);
      this.element.css({
        'margin-top': this.element.height() / -2
      });
      this.shortTickElm = $('.time-tick-short', this.element);
      this.longTickElm = $('.time-tick-long', this.element);
      return this.titleElm = $('.time-title-content', this.element);
    };
    Time.prototype.attachElement = function(elm, time) {
      var date, hourDeg, minuteDeg, pos;
      elm = $(elm);
      date = new Date(time);
      hourDeg = this.getHourDeg_(date);
      minuteDeg = this.getMinuteDeg_(date);
      pos = null;
      _.defer(function() {
        pos = elm.offset();
        pos.left += elm.width() / 2;
        return pos.top += elm.height() / 2;
      });
      return $(elm).bind('mouseover', __bind(function() {
        window.clearTimeout(this.hideTimer);
        this.setRotate_(this.shortTickElm, hourDeg);
        this.setRotate_(this.longTickElm, minuteDeg);
        this.titleElm.html(this.createTitleHTML(date));
        return this.element.css({
          top: pos.top,
          left: pos.left
        }).fadeIn();
      }, this)).bind('mouseout', __bind(function() {
        return this.hideTimer = _.delay(__bind(function() {
          return this.element.fadeOut();
        }, this), 3000);
      }, this));
    };
    Time.prototype.createTitleHTML = function(date) {
      var digits, niceDate;
      digits = _.padString(date.getHours(), 2) + ':' + _.padString(date.getMinutes(), 2);
      niceDate = _.niceDate(date);
      return "<span class=\"time-title-digits\">" + digits + "</span><br />\n<span class=\"time-title-nice\">" + niceDate + "</span>";
    };
    Time.prototype.setRotate_ = function(elm, deg) {
      return elm.css(_.getCssPrefix() + 'transform', "rotate(" + deg + "deg)");
    };
    Time.prototype.getHourDeg_ = function(date) {
      return Math.floor(360 / 12 * date.getHours());
    };
    Time.prototype.getMinuteDeg_ = function(date) {
      return Math.floor(360 / 60 * date.getMinutes());
    };
    return Time;
  })();
  _.addSingletonGetter(Time);
  exports.WordList = WordList;
  exports.Word = Word;
  exports.Message = Message;
  exports.Time = Time;
}).call(this);
