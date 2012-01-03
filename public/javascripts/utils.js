(function() {
  /*
   Utils in LastFirstApp
   http://lastfirst.stakam.net/
  
   Depands on:
     socket.io.js
     underscore.js
     jquery-1.7.js
  */
  /*
   Utils common in server and client.
  */
  var BrowserType, CSS_PREFIX, getFirstLetter_, getLastLetter_;
  var __slice = Array.prototype.slice;
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
    if (_.isArray(str)) {
      return str = str.join('');
    }
  };
  _.mixin({
    isValidWord: function(str) {
      if (_.isString(str) && /^[あ-ん|ー]+$/.test(str) && /^[^を]+$/.test(str) && !/っ$/.test(str)) {
        return _.all(str.split(''), function(letter, index, array) {
          if (index === 0) {
            return /^[^ゃゅょ|^っ|^ー]$/.test(letter);
          } else {
            if (/^[ゃゅょ]$/.test(letter)) {
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
    },
    padString: function(str, howmany, padStr) {
      var diff, pad;
      if (padStr == null) {
        padStr = "0";
      }
      if (!_.isString(str)) {
        str = str.toString();
      }
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
        if (_.isString(date) || _.isNumber(date)) {
          date = new Date(date);
        }
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
}).call(this);
