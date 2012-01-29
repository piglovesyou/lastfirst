
/*
 Extends underscore with word validation function.
*/

var $indicator_, $msgBox_, AbstractComponent, BrowserType, CSS_PREFIX, Message, Time, Word, WordList, currentDocs_, delayTimerId_, message, postLocked_, socket, socketInit, time, userId_, words;
var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

(function() {
  var getFirstLetter_, getLastLetter_, _;
  if (this._ === void 0) {
    _ = require('underscore');
  } else {
    _ = this._;
  }
  getFirstLetter_ = function(str) {
    var count, len, result;
    count = 1;
    len = str.length;
    if (len >= 2 && /^[ゃゅょ|ー]$/.test(str[1])) {
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
  getLastLetter_ = function(str) {
    var count, lastIndex, len;
    count = 1;
    len = str.length;
    lastIndex = len - 1;
    if (len >= 2 && /^[ゃゅょ|ー]$/.test(str[lastIndex])) {
      if (len >= 3 && /^[ゃゅょ]$/.test(str[lastIndex - 1])) {
        count = 3;
      } else {
        count = 2;
      }
    }
    str = _.last(str, count);
    if (_.isArray(str)) return str = str.join('');
  };
  return _.mixin({
    isValidWord: function(str) {
      if (_.isString(str) && /^[あ-ん|ー]+$/.test(str) && /^[^を]+$/.test(str) && !/っ$/.test(str)) {
        return _.all(str.split(''), function(letter, index, array) {
          if (index === 0) {
            return /^[^ゃゅょ|^っ|^ー]$/.test(letter);
          } else {
            if (/^[ゃゅょ]$/.test(letter)) {
              return /^[きしちにひみりぎじぢび]$/.test(array[index - 1]);
            }
            if (letter === 'っ') return /^[^っ]$/.test(array[index - 1]);
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
})();

/*
 Utils in LastFirstApp
 http://lastfirst.stakam.net/

 Depands on:
   socket.io.js
   underscore.js
   jquery-1.7.js
*/

/*
 Client side utils.
*/

_.mixin({
  addSingletonGetter: function(ctor) {
    return ctor.getInstance = function() {
      return ctor.instance_ || (ctor.instance_ = new ctor());
    };
  },
  parseParamString: function(str, sep) {
    var pairArr, pairStr, result, _i, _len, _ref;
    if (sep == null) sep = '&';
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
    if (sep == null) sep = '&';
    result = '';
    keys = _.keys(paramObj);
    lastIndex = keys.length - 1;
    for (_i = 0, _len = keys.length; _i < _len; _i++) {
      key = keys[_i];
      result += key + '=' + paramObj[key];
      if (_i !== lastIndex) result += sep;
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
  },
  clearCookies: function() {
    return _.setCookies({
      token: '',
      expires: new Date(_.now() - 60 * 60 * 1000).toString()
    });
  },
  padString: function(str, howmany, padStr) {
    var diff, pad;
    if (padStr == null) padStr = "0";
    if (!_.isString(str)) str = str.toString();
    diff = howmany - str.length;
    pad = '';
    if (diff >= 1) {
      _(diff).times(function() {
        return pad += padStr;
      });
      str = pad + str;
    }
    return str;
  }
});

BrowserType = {
  WEBKIT: 0,
  GECKO: 1,
  MSIE: 2,
  OPERA: 3,
  OTHER: 4
};

_.mixin({
  getBrowserVendor: function() {
    var userAgent;
    userAgent = navigator.userAgent.toLowerCase();
    if (userAgent.indexOf('webkit') >= 0) {
      return BrowserType.WEBKIT;
    } else if (userAgent.indexOf('gecko') >= 0) {
      return BrowserType.GECKO;
    } else if (userAgent.indexOf('msie') >= 0) {
      return BrowserType.MSIE;
    } else if (userAgent.indexOf('opera') >= 0) {
      return BrowserType.OPERA;
    } else {
      return BrowserType.OTHER;
    }
  }
});

CSS_PREFIX = null;

_.mixin({
  getCssPrefix: function() {
    if (!_.isNull(CSS_PREFIX)) {
      return CSS_PREFIX;
    } else {
      switch (_.getBrowserVendor()) {
        case BrowserType.WEBKIT:
          return CSS_PREFIX = '-webkit-';
        case BrowserType.GECKO:
          return CSS_PREFIX = '-moz-';
        case BrowserType.MSIE:
          return CSS_PREFIX = '-ms-';
        case BrowserType.OPERA:
          return CSS_PREFIX = '-o-';
        case BrowserType.OTHER:
          return CSS_PREFIX = '';
      }
    }
  },
  niceDate: (function(date, lang) {
    var DAY, HOUR, MINUTE, MONTH, SECOND, WEEK, YEAR, dateFormat, formatize, langs, pluralize;
    SECOND = 1000;
    MINUTE = 60 * SECOND;
    HOUR = 60 * MINUTE;
    DAY = 24 * HOUR;
    WEEK = 7 * DAY;
    MONTH = 31 * DAY;
    YEAR = 365 * DAY;
    langs = {
      en: {
        AGO: ' ago',
        AFTER: ' after',
        SECOND: ' second',
        MINUTE: ' minute',
        HOUR: ' hour',
        DAY: ' day',
        WEEK: ' week',
        MONTH: ' month',
        YEAR: ' year',
        PLURAL: 's'
      },
      ja: {
        AGO: '前',
        AFTER: '後',
        SECOND: '秒',
        MINUTE: '分',
        HOUR: '時間',
        DAY: '日',
        WEEK: '週',
        MONTH: '月',
        YEAR: '年'
      }
    };
    dateFormat = {
      en: {
        HOUR_MINUTE: "%_:%_",
        MONTH_DATE: "%_.%_",
        YEAR_MONTH_DATE: "%_.%_.%_"
      },
      ja: {
        HOUR_MINUTE: "%_:%_",
        MONTH_DATE: ["%_", langs.ja.MONTH, "%_", langs.ja.DAY].join(''),
        YEAR_MONTH_DATE: ["%_", langs.ja.YEAR, "%_", langs.ja.MONTH, "%_", langs.ja.DAY].join('')
      }
    };
    pluralize = function(num, str, lang) {
      num = Math.floor(num);
      if (lang.PLURAL && num > 1) {
        return num + str + lang.PLURAL;
      } else {
        return num + str;
      }
    };
    formatize = function() {
      var format, value, values, _i, _len;
      format = arguments[0], values = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      for (_i = 0, _len = values.length; _i < _len; _i++) {
        value = values[_i];
        format = format.replace("%_", value);
      }
      return format;
    };
    return function(date, lang_) {
      var agoOrLater, dist, fmt, now;
      if (_.isString(date) || _.isNumber(date)) date = new Date(date);
      if (_.isDate(date)) {
        now = new Date().getTime();
        lang_ = _.isString(lang_) && langs[lang_] ? lang_ : "ja";
        lang = langs[lang_];
        fmt = dateFormat[lang_];
        dist = now - date.getTime();
        agoOrLater = dist > 0 ? lang.AGO : lang.AFTER;
        dist = Math.abs(dist);
        if (dist < MINUTE) {
          return "" + (pluralize(dist / SECOND, lang.SECOND, lang)) + agoOrLater;
        } else if (dist < HOUR) {
          return "" + (pluralize(dist / MINUTE, lang.MINUTE, lang)) + agoOrLater;
        } else if (dist < DAY) {
          return "" + (pluralize(dist / HOUR, lang.HOUR, lang)) + agoOrLater;
        } else if (dist < DAY * 3) {
          return "" + (pluralize(dist / DAY, lang.DAY, lang)) + agoOrLater;
        } else if (dist < YEAR) {
          return "" + (formatize(fmt.MONTH_DATE, date.getMonth() + 1, date.getDate()));
        } else {
          return "" + (formatize(fmt.YEAR_MONTH_DATE, date.getFullYear(), date.getMonth() + 1, date.getDate()));
        }
      }
    };
  })()
});

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
    this.element = $(elmSelector);
    if (this.element) return this.isInDocument = true;
  };

  AbstractComponent.prototype.dispose = function() {
    var prop, _results;
    if (this.isInDocument) {
      this.element.unbind();
      this.element.remove();
      _results = [];
      for (prop in this) {
        if (_.isObject(this[prop])) {
          _results.push(this[prop] = null);
        } else {
          _results.push(void 0);
        }
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

  WordList.prototype.onEnterLastWordTimer = null;

  WordList.prototype.onLeaveBlankTimer = null;

  WordList.prototype.wordInstances_ = [];

  WordList.prototype.lastWord_ = null;

  function WordList() {
    this.onMouseleaveBlankElm = __bind(this.onMouseleaveBlankElm, this);
    this.onMouseEnterBlankElm = __bind(this.onMouseEnterBlankElm, this);
    this.onClickLastWord = __bind(this.onClickLastWord, this);
    var inner;
    inner = "<div class=\"inner\">\n  <div class=\"image\"></div>\n  <div class=\"label\">\n    <div id=\"post-form\">\n    	<form id=\"post\" action=\"javascript:void(0)\" method=\"POST\">\n    		<input name=\"content\" type=\"text\">\n        <input style=\"display:none\" type=\"submit\" />\n    	</form>\n    </div>\n    <div class=\"please-login yeah\">(Please login.)</div> \n  </div>\n</div>".replace(/(<\/.+?>)[\s\S]*?(<)/g, "$1$2");
    this.blankElmInner = $(inner);
    this.blankElm = $('<div class="word word-blank" style="display:none"></div>').append(this.blankElmInner);
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

  WordList.prototype.setAsLastWord = function(lastWord_) {
    this.lastWord_ = lastWord_;
    this.lastWord_.element.addClass("last-post");
    return this.lastWord_.elementInner.bind('click', this.onClickLastWord);
  };

  WordList.prototype.onClickLastWord = function() {
    var _this = this;
    window.clearTimeout(this.onEnterLastWordTimer);
    return this.onEnterLastWordTimer = _.delay(function() {
      _this.element.prepend(_this.blankElm);
      _this.blankElm.fadeIn();
      _this.blankElmInner.bind('mouseenter', _this.onMouseEnterBlankElm).bind('mouseleave', _this.onMouseleaveBlankElm).find('input[type="text"]').val('').focus();
      return Time.getInstance().hide();
    }, 400);
  };

  WordList.prototype.onMouseEnterBlankElm = function() {
    return window.clearTimeout(this.onLeaveBlankTimer);
  };

  WordList.prototype.onMouseleaveBlankElm = function() {
    var _this = this;
    window.clearTimeout(this.onLeaveBlankTimer);
    return this.onLeaveBlankTimer = _.delay(function() {
      _this.blankElmInner.unbind('mouseleave');
      return _this.blankElm.hide().remove();
    }, 3000);
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
    this.notAsLastWord = __bind(this.notAsLastWord, this);
    this.id = data._id;
    this.content = data.content;
    this.createdBy = data.createdBy;
    this.createdAt = data.createdAt;
    this.liked = data.liked;
    this.words_ = null;
    this.wasAttachedAsLastWord = false;
    if (this.canRender()) this.element = $('<div class="word"></div>');
  }

  Word.prototype.canRender = function() {
    return !!(this.id && this.content && this.createdBy && this.createdAt && this.liked);
  };

  Word.prototype.render = function() {
    var i, image, label, likeButtonElm, likeText, likedElm, text, title, titleElm, userId, _i, _len, _ref;
    if (this.canRender()) {
      Word.__super__.render.call(this);
      this.element.empty();
      text = '';
      userId = _.getUserId();
      image = $("<div class='image'>\n<img src=\"/images/dev2.png\" />\n</div>");
      label = $("<div class='label'></div>");
      title = this.content;
      if (_.isEndsN(this.content)) title += '*';
      titleElm = $("<span class='titleElm' title='" + this.createdAt + "'>" + title + "</span>");
      label.append(titleElm);
      if (!_.isEmpty(this.liked)) {
        likeText = '';
        _ref = this.liked;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          likeText += '6';
        }
        likedElm = $("<span class='liked i'>" + likeText + "</span>");
        label.append(likedElm);
      }
      if (userId && userId !== this.createdBy && !_.include(this.liked, userId)) {
        likeButtonElm = $("<span class='like i' title='like it'>6</span>").bind('click', this.sendLike);
        label.append(likeButtonElm);
      }
      this.elementInner = $("<div class='inner'></div>").append(image).append(label);
      this.element.append(this.elementInner);
      if (this.isLastPost) {
        WordList.getInstance().setAsLastWord(this);
      } else {
        this.element.removeClass("last-post");
      }
      if (userId === this.createdBy) {
        return this.element.addClass("your-post");
      } else {
        return this.element.removeClass("your-post");
      }
    }
  };

  Word.prototype.notAsLastWord = function() {
    this.element.removeClass("last-post");
    if (this.wasAttachedAsLastWord) {
      this.elementInner.unbind('mouseenter');
      this.elementInner.unbind('mouseleave');
      return this.wasAttachedAsLastWord = false;
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
 ingleton class for showing messages.
*/

Message = (function() {

  __extends(Message, AbstractComponent);

  function Message() {
    Message.__super__.constructor.apply(this, arguments);
  }

  Message.prototype.messageElm_ = null;

  Message.prototype.importantMessageElm_ = null;

  Message.prototype.decorate = function(elmSelector) {
    var importantMessageTimer, messageTimer, onDocMouseMove;
    Message.__super__.decorate.call(this, elmSelector);
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

  Message.prototype.show = function(str) {};

  Message.prototype.showImportant = function(str) {};

  Message.prototype.dispose = function() {};

  return Message;

})();

_.addSingletonGetter(Message);

/*
 Singleton class for time.
*/

Time = (function() {

  __extends(Time, AbstractComponent);

  function Time() {
    this.hide = __bind(this.hide, this);
    this.hideAfterDelay = __bind(this.hideAfterDelay, this);
    Time.__super__.constructor.apply(this, arguments);
  }

  Time.prototype.shortTickElm = null;

  Time.prototype.longTickElm = null;

  Time.prototype.titleElm = null;

  Time.prototype.height = 0;

  Time.prototype.hideTimer = null;

  Time.prototype.hoverTimer = null;

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
    var _this = this;
    elm = $(elm);
    date = new Date(time);
    hourDeg = this.getHourDeg_(date);
    minuteDeg = this.getMinuteDeg_(date);
    pos = {};
    return $(elm).bind('mouseover', function() {
      return _this.hoverTimer = _.delay(function() {
        var span;
        _this.clearTimers();
        span = $('.label span:last-child', elm);
        pos = span.offset();
        pos.top += span.height() / 2;
        pos.left += span.width();
        window.clearTimeout(_this.hideTimer);
        _this.setRotate_(_this.shortTickElm, hourDeg);
        _this.setRotate_(_this.longTickElm, minuteDeg);
        _this.titleElm.html(_this.createTitleHTML(date));
        return _this.element.css({
          top: pos.top,
          left: pos.left
        }).fadeIn();
      }, 400);
    }).bind('mouseout', this.hideAfterDelay);
  };

  Time.prototype.hideAfterDelay = function() {
    this.clearTimers();
    return this.hideTimer = _.delay(this.hide, 3000);
  };

  Time.prototype.hide = function() {
    return this.element.fadeOut();
  };

  Time.prototype.createTitleHTML = function(date) {
    var digits, niceDate;
    digits = _.padString(date.getHours(), 2) + ':' + _.padString(date.getMinutes(), 2);
    niceDate = _.niceDate(date);
    return "<span class=\"time-title-digits\">" + digits + "</span><br />\n<span class=\"time-title-nice\">" + niceDate + "</span>";
  };

  Time.prototype.clearTimers = function() {
    window.clearTimeout(this.hoverTimer);
    return window.clearTimeout(this.hideTimer);
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

/*
 Global accessor to the base info
*/

currentDocs_ = [];

userId_ = '';

socket = null;

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

$msgBox_ = null;

postLocked_ = false;

$indicator_ = null;

_.mixin;

delayTimerId_ = null;

_.mixin;

_.mixin({
  showLoginLink: function() {
    return $('#login-link').show();
  },
  hideLoginLink: function() {
    return $('#login-link').hide();
  },
  setUserIdToHiddenInput: function() {
    return $('#user-id-input').val(_.getUserId());
  },
  showMessage: function(str) {
    var $msgBox;
    if (delayTimerId_) window.clearTimeout(delayTimerId_);
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
      word = new Word(doc, _i === 0);
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
    $('#logout-link').show();
    $('body').addClass('logged-in').removeClass('not-logged-in');
    return socket.emit('pull update');
  });
  socket.on('error message', function(data) {
    return message.show(data.message);
  });
  socket.on('posted successfully', function(post) {
    return message.show('"' + post.content + '" posted!');
  });
  socket.on('got penalty', function(data) {
    return message.show(data.message);
  });
  socket.on('release penalty', function(data) {
    return message.show(data.message);
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

message === null;

words = null;

time = null;

$(function() {
  var token;
  message = Message.getInstance();
  message.decorate('.message');
  words = WordList.getInstance();
  words.decorate('.word-list');
  time = Time.getInstance();
  time.render();
  socketInit();
  token = _.getToken();
  if (token) {
    socket.emit('got token', {
      token: token
    });
  } else if (window.noAuthForDev) {} else {
    _.showLoginLink();
  }
  return words.element.on('submit', '#post', function(e) {
    var content, id, lastDoc;
    id = _.getUserId();
    content = $('input[name="content"]', this).val();
    if (_.isEmpty(id) || _.isEmpty(content)) {} else if (_.isValidWord(content)) {
      lastDoc = words.getLastWord();
      if (id === lastDoc.createdBy) {
        message.show('It\'s not your turn.');
      } else if (_.isValidLastFirst(lastDoc.content, content)) {
        socket.emit('post word', {
          content: content,
          createdBy: id
        });
      } else {
        message.show('I\'m not sure it\'s being Last and First.');
      }
    } else {
      message.show('Please enter a word in HIRAGANA.');
    }
    return false;
  });
});
